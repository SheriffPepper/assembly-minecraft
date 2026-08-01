[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; Windows backend for the "window" library (see "include/libs/window/window.inc").
; Owns every Win32/WGL call in the project - if you're hunting for a HWND
; anywhere else in the codebase, that's a bug.
;

%include "../definitions.inc"
%include "winapi.inc"


; Application constants
    section .data
; Class name for Windows' window class
className  db  "RubyDungWindowClass", 0x00

; PIXEL_FORMAT_DESCRIPTOR, filled by hand once - field order is fixed by the Win32 ABI,
; not by us, so no named offsets, just a byte-by-byte comment next to each other.
pfd:
    .size:            dw  40      ; Size of the structure (40B)
    .version:         dw  1       ; Version of the structure
    .flags:           dd  PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLE_BUFFER
    .pixelType:       db  PFD_TYPE_RGBA
    .colorBits:       db  32      ; Size of the color buffer
    ; R/G/B/A bits + shifts - let the driver pick
    .redBits:         db  0x00    ; Specifies the number of red bitplanes in each RGBA color buffer
    .redShift:        db  0x00    ; Specifies the shift count for red bitplanes in each RGBA color buffer
    .greenBits:       db  0x00    ; Specifies the number of green bitplanes in each RGBA color buffer
    .greenShift:      db  0x00    ; Specifies the shift count for green bitplanes in each RGBA color buffer
    .blueBits:        db  0x00    ; Specifies the number of blue bitplanes in each RGBA color buffer
    .blueShift:       db  0x00    ; Specifies the shift count for blue bitplanes in each RGBA color buffer
    .alphaBits:       db  0x00    ; Specifies the number of alpha bitplanes in each RGBA color buffer
    .alphaShift:      db  0x00    ; Specifies the shift count for alpha bitplanes in each RGBA color buffer
    ; Accum* - unused
    .accumBits:       db  0x00    ; Specifies the total number of bitplanes in the accumulation buffer
    .accumRedBits:    db  0x00    ; Specifies the number of red bitplanes in the accumulation buffer
    .accumGreenBits:  db  0x00    ; Specifies the number of green bitplanes in the accumulation buffer
    .accumBlueBits:   db  0x00    ; Specifies the number of blue bitplanes in the accumulation buffer
    .accumAlphaBits:  db  0x00    ; Specifies the number of alpha bitplanes in the accumulation buffer

    .depthBits:       db  24      ; Specifies the depth of the depth (Z-axis) buffer
    .stencilBits:     db  8       ; Specifies the depth of the stencil buffer
    .auxBuffers:      db  0x00    ; Specifies the number of auxiliary buffers (Not Supported)
    .layerType:       db  PFD_MAIN_PLANE
    .reserved:        db  0x00
    ; Masks
    .layerMask:       dd  0x00000000
    .visibleMask:     dd  0x00000000
    .damageMask:      dd  0x00000000


; Application uninitialized data
    section .bss
instance_handle  resq  1     ; Current Process Handle
window_handle    resq  1     ; Created Window Handle
DC_handle        resq  1     ; Device Context Handle
GL_RC_handle     resq  1     ; GL Rendering Context Handle
msg_buffer       resb  48    ; MSG struct - we never read its fields ourselves,
                             ; DispatchMessageA does that on our behalf
should_close     resb  1     ; Whether the window should close


; Application code
    section .text

; List of imported functions
extern GetModuleHandleA
extern RegisterClassExA
extern CreateWindowExA
extern DefWindowProcA
extern ShowWindow
extern UpdateWindow
extern PeekMessageA
extern TranslateMessage
extern DispatchMessageA
extern DestroyWindow
extern GetDC
extern ReleaseDC
extern ChoosePixelFormat
extern SetPixelFormat
extern SwapBuffers
extern wglCreateContext
extern wglMakeCurrent
extern wglDeleteContext

; List of exported functions
global Window.create
global Window.destroy
global Window.pollEvents
global Window.shouldClose
global Window.swapBuffers


;
; Registers the window class, creates the Window + DC, picks the pixel format,
; and makes a WGL context current on this thread.
; After a successful return, every gl* call anywhere in the program just works.
;
; Everything gets spilled straight to globals rather than juggled across register saves -
; this runs exactly once at startup, so a handful of extra loads/stores costs nothing
; and reads a lot cleaner than fighting over six non-volatile registers
; for a dozen sequential Win32 calls
;
;   @param width:  u32  Window width
;   @param height: u32  Window height
;   @param title: *str  pointer to the Window null-terminated title
;
;   @return  boolean of whether Window was created (true) or failed (false)
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads, writes
;
Window.create:
    ;
    ;   Calling convention:
    ; @param width   ecx (u32 integer)
    ; @param height  edx (u32 integer)
    ; @param title   r8  (pointer)
    ;

    ; Save non-volatile registers
    ; And align odd-8-aligned (post-call convention) stack to 16 bytes
    push rbx
    push rsi
    push rdi
    push r12
    push r13

    mov r12d, ecx    ; Width
    mov r13d, edx    ; Height
    mov rsi, r8      ; Title

    ; --- 16-bytes aligned stack ---

    ; Reserve 32 bytes of "Shadow Space" on the stack
    sub rsp, SHADOW_SPACE

    xor rcx, rcx
    call GetModuleHandleA

    mov [instance_handle], rax    ; Save current process handle
    mov rdi, rax

    ; --- Register the Window Class (WNDCLASSEXA, 80 bytes) ---
    sub rsp, WindowClassEx_size    ; Allocate 80 bytes on stack for the Window Class structure

        mov dword [rsp + HOME_SPACE + WindowClassEx.size],  WindowClassEx_size
        mov dword [rsp + HOME_SPACE + WindowClassEx.style], WindowClass.style@OWN_DC

        lea rax, [WindowProcedure]
        mov qword [rsp + HOME_SPACE + WindowClassEx.window_procedure], rax

        mov dword [rsp + HOME_SPACE + WindowClassEx.class_extra],  0
        mov dword [rsp + HOME_SPACE + WindowClassEx.window_extra], 0

        mov qword [rsp + HOME_SPACE + WindowClassEx.instance], rdi

        mov qword [rsp + HOME_SPACE + WindowClassEx.icon],       0    ; default, don't care
        mov qword [rsp + HOME_SPACE + WindowClassEx.cursor],     0    ; default, don't care
        mov qword [rsp + HOME_SPACE + WindowClassEx.background], 0    ; GL repaints every frame anyway
        mov qword [rsp + HOME_SPACE + WindowClassEx.menu_name],  0    ; No menu

        lea rax, [className]
        mov qword [rsp + HOME_SPACE + WindowClassEx.class_name], rax

        mov qword [rsp + HOME_SPACE + WindowClassEx.small_icon], 0    ; default, don't care

        ; Register Class
        lea rcx, [rsp + HOME_SPACE]    ; Pointer to the Window Class
        call RegisterClassExA

    add rsp, WindowClassEx_size    ; Release the allocated space

    ; Something went wrong: Couldn't register the Class
    test ax, ax
    jz .fail

    ; --- Create Window: 12 args, 4 in registers + 8 on the stack ---
    sub rsp, 64    ; Allocate 64 bytes for 8 additional stack parameters

        xor ecx, ecx            ; Extended Window Style
        lea rdx, [className]    ; Class Name
        mov r8, rsi             ; Window Title
        mov r9d, Window.style@OVERLAPPED_WINDOW | Window.style@VISIBLE

        mov dword [rsp + STACK_PARAM#4], CW_USE_DEFAULT    ; Initial X-position of the window
        mov dword [rsp + STACK_PARAM#5], CW_USE_DEFAULT    ; Initial Y-position of the window
        mov dword [rsp + STACK_PARAM#6], r12d              ; Window width
        mov dword [rsp + STACK_PARAM#7], r13d              ; Window height
        mov qword [rsp + STACK_PARAM#8], 0                 ; No parent window
        mov qword [rsp + STACK_PARAM#9], 0                 ; Don't care about window menu
        mov qword [rsp + STACK_PARAM#10], rdi              ; Handle of the owner process
        mov qword [rsp + STACK_PARAM#11], 0                ; No parameters needed

        call CreateWindowExA

    add rsp, 64    ; Release 8 additional stack parameters

    ; Something went wrong: Couldn't create a window
    test rax, rax
    jz .fail

    mov [window_handle], rax    ; Save the Window handler
    mov rbx, rax

    ; --- Get Window's Device Context ---

    mov rcx, rax
    call GetDC

    ; Something went wrong: Couldn't get Device Context
    test rax, rax
    jz .fail

    mov [DC_handle], rax    ; Save the Device Context handle
    mov r12, rax

    ; --- Choose Pixel Format ---

    mov rcx, r12      ; DC handle
    lea rdx, [pfd]    ; Pixel Format Descriptor

    call ChoosePixelFormat

    ; Existential crisis: I understand there's no choice (for pixel format)
    test eax, eax
    jz .fail

    ; --- Set Pixel Format ---

    mov rcx, r12    ; DC handle
    mov edx, eax    ; Pixel Format
    lea r8, [pfd]

    call SetPixelFormat

    ; Something went wrong: Couldn't set pixel format
    test eax, eax
    jz .fail

    ; --- Create GL Context ---

    mov rcx, r12    ; DC handle
    call wglCreateContext

    ; Something went wrong: Couldn't create GL context
    test rax, rax
    jz .fail

    mov [GL_RC_handle], rax    ; Save the GL Rendering Context handle

    ; --- Make the GL context current ---

    mov rcx, r12    ; DC handle
    mov rdx, rax    ; GL Rendering Context handle

    call wglMakeCurrent

    ; Something went wrong: how much can go wrong these days...
    test eax, eax
    jz .fail

    ; --- Show the Window ---

    mov rcx, rbx          ; Window handle
    mov edx, SW_NORMAL    ; Show parameter

    call ShowWindow

    ; --- Update the Window ---

    mov rcx, rbx
    call UpdateWindow

    ; Window created successfully!
    mov eax, true
    jmp .exit

.fail:
    ; Return 'false' as the "created successfully" part...
    xor eax, eax

.exit:
    add rsp, SHADOW_SPACE    ; Release Shadow Space

    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx

    ret


;
; Called BY Windows via DispatchMessageA - this is the other end of the
; WindowProcedure pointer we handed over above.
; We only care about the window going away; everything else gets punted to DefWindowProcA.
;
;   @param window:  u64  window handle to process
;   @param message: u32  message code
;   @param wParam:  u64  additional data
;   @param lParam:  u64  additional data
;
;   @return  some pointer (idk)
;
; @convention  Windows ABI
; @features    x64
; @effects     writes, decides
;
WindowProcedure:
    ;
    ;   Calling convention:
    ; @param window   rcx (u64 as window handle)
    ; @param message  edx (u32 integer)
    ; @param wParam   r8  (u64 integer)
    ; @param lParam   r9  (u64 integer)
    ;

    ; We close Window if it needs to be closed or destroyed
    cmp edx, WindowMessage.code@CLOSE
    je .closing
    cmp edx, WindowMessage.code@DESTROY
    je .closing

.default:
    ; Since we didn't use our Shadow Space, we can share it and just jump, not call
    jmp DefWindowProcA    ; Args already sitting where they need to - free ride

.closing:    ; We decided to close the Window
    mov byte [should_close], true
    xor rax, rax

    ret


;
; Drains the message queue for this thread.
; PM_REMOVE + no blocking GetMessage call, so this fits a real-time game loop
; instead of stalling it waiting for the next OS event.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads, writes
;
Window.pollEvents:
    ; Function doesn't take or return any values

    ; Reserve Shadow Space and one additional stack parameter
    ; And align odd-8-aligned (post-call convention) stack to 16 bytes
    sub rsp, SHADOW_SPACE + 8

.loop:
    ; --- Get the Message ---
    lea rcx, [msg_buffer]    ; Message buffer
    xor rdx, rdx             ; Window handler (null -> any thread message)
    ; No filtering needed
    xor r8d, r8d             ; Message Filter Min
    xor r9d, r9d             ; Message Filter Max

    mov dword [rsp + STACK_PARAM#4], PM_REMOVE    ; Remove message from the queue

    call PeekMessageA

    ; Queue is empty, back to the game!
    test eax, eax
    jz .done

    ; --- Translate & Dispatch the Message ---
    lea rcx, [msg_buffer]
    call TranslateMessage
    lea rcx, [msg_buffer]
    call DispatchMessageA    ; Ends up back in WindowProcedure

    jmp .loop    ; Process all the messages

.done:
    ; Release all the Shadow Space and additional stack parameters
    add rsp, SHADOW_SPACE + 8
    ret


;
; Returns boolean depending on whether Window should close.
;
;   @return  boolean "is Window should close"
;
; @convention  custom (Blanki)
; @features    x64
; @effects     reads
;
Window.shouldClose:
    ; Return eax as boolean
    movzx eax, byte [should_close]    ; Move with Zero-expansion
    ret


;
; Swaps buffers.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads, writes
;
Window.swapBuffers:
    ; Function doesn't take or return any values

    ; Reserve Shadow Space
    ; And align odd-8-aligned (post-call convention) stack to 16 bytes
    sub rsp, SHADOW_SPACE + 8

    mov rcx, [DC_handle]
    call SwapBuffers

    ; Release all the Shadow Space
    add rsp, SHADOW_SPACE + 8
    ret


;
; Destroy the Window.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads
;
Window.destroy:
    ; Function doesn't take or return any values

    ; Reserve Shadow Space
    ; And align odd-8-aligned (post-call convention) stack to 16 bytes
    sub rsp, SHADOW_SPACE + 8

    ; --- Detach GL Context ---
    xor rcx, rcx    ; DC handle -> Null
    mov rdx, rdx    ; GL Rendering Context handle -> Null

    call wglMakeCurrent    ; Detach context before deleting

    ; --- Delete GL Context ---
    mov rcx, [GL_RC_handle]
    call wglDeleteContext

    ; --- Release Device Context ---
    mov rcx, [window_handle]
    mov rdx, [DC_handle]

    call ReleaseDC

    ; --- Destroy the window ---
    mov rcx, [window_handle]
    call DestroyWindow

    ; Release all the Shadow Space
    add rsp, SHADOW_SPACE + 8
    ret
