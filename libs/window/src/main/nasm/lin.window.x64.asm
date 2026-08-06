[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; Linux/X11+GLX backend for the "window" library (see 'include/libs/window/window.inc').
; Owns every Xlib/GLX call in the project - same contract as win.window's Win32 file,
; so RubyDung.asm never notices which one got linked in.
;

%include "../definitions.inc"
%include "x11.inc"


; Application constants
    section .data
align 4
; GLX visual attribute list: RGBA, double-buffered, 24-bit depth, terminated by 0.
; glXChooseVisual reads this as a flat array - flags with no value just appear
; once, flags that take a value are followed immediately by it.
glx_attribs:
    dd GLX_RGBA
    dd GLX_DOUBLE_BUFFER
    dd GLX_RED_SIZE,   8
    dd GLX_GREEN_SIZE, 8
    dd GLX_BLUE_SIZE,  8
    dd GLX_ALPHA_SIZE, 8
    dd GLX_DEPTH_SIZE, 24
    dd 0

atom_name  db  "WM_DELETE_WINDOW", 0x00

align 8
; Window's XSetWindowAttributes structure
win_attrs:
    .background_pixmap:  dq  null     ; Value is ignored because of mask
    .background_pixel:   dq  null     ; Value is ignored because of mask
    .border_pixmap:      dq  null     ; Value is ignored because of mask
    .border_pixel:       dq  null     ; value is ignored because of mask
    .bit_gravity:        dd  null     ; Value is ignored because of mask
    .win_gravity:        dd  null     ; Value is ignored because of mask
    .backing_store:      dd  null     ; Value is ignored because of mask
                         dd  0x00     ; 4-byte padding
    .backing_planes:     dq  null     ; Value is ignored because of mask
    .backing_pixel:      dq  null     ; Value is ignored because of mask
    .save_under:         dd  false    ; Value is ignored because of mask
                         dd  0x00     ; 4-byte padding
    .event_mask:         dq  ExposureMask | KeyPressMask | StructureNotifyMask
    .do_not_propagate:   dq  null     ; Value is ignored because of mask
    .override_redirect:  dd  false    ; Value is ignored because of mask
                         dd  0x00     ; 4-byte padding
    .colormap:           dq  null     ; Value is ignored because of mask
    .cursor:             dq  null     ; Value is ignored because of mask


; Application uninitialized data
    section .bss
align 8
display       resq  1      ; Display*
window        resq  1      ; Window (XID, but 64-bit slot for alignment)
glx_context   resq  1      ; GLXContext
wm_delete     resq  1      ; Atom for WM_DELETE_WINDOW
event_buffer  resb  256    ; XEvent is a union, comfortably under 256B on x64
should_close  resb  1      ; boolean


; Application code
    section .text

; List of imported functions
extern XOpenDisplay
extern XCloseDisplay
extern XDefaultScreen
extern XRootWindow
extern glXChooseVisual
extern glXCreateContext
extern glXMakeCurrent
extern glXDestroyContext
extern glXSwapBuffers
extern XCreateColormap
extern XCreateWindow
extern XDestroyWindow
extern XMapWindow
extern XInternAtom
extern XSetWMProtocols
extern XStoreName
extern XPending
extern XNextEvent

; List of exported functions
global Window.create
global Window.destroy
global Window.pollEvents
global Window.shouldClose
global Window.swapBuffers


;
; Creates Window singleton with given size and title.
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
    ; @return  eax (boolean)
    ;

    push rbx
    push r12
    push r13
    push r14
    push r15
    ; 5 pushes = odd, +8 below fixes parity back to 16-byte aligned

    mov r12d, ecx    ; width
    mov r13d, edx    ; height
    mov r14, r8      ; title pointer

    ; --- 1. Open Display ---
    xor edi, edi    ; NULL display name -> use $DISPLAY env var
    call XOpenDisplay

    ; Something went wrong: Couldn't open display
    test rax, rax
    jz .fail

    mov [display], rax
    mov r15, rax          ; r15 = display

    ; --- 2. Get Default Screen ---
    mov rdi, r15
    call XDefaultScreen

    mov ebx, eax    ; ebx = screen index

    ; --- 3. Choose GLX Visual ---
    mov rdi, r15    ; Display
    mov esi, ebx    ; Screen index
    lea rdx, [glx_attribs]

    call glXChooseVisual

    ; Something went wrong: Couldn't choose GLX Visual
    test rax, rax
    jz .fail

    ; --- 4. Get Root Window & Colormap ---
    mov rdi, r15    ; Display
    mov esi, ebx    ; Screen index

    mov rbx, rax    ; rbx = Visual info (save to rbx, since it's its last usage as screen index)

    call XRootWindow

    mov rbp, rax    ; rbp = root window

    ; Create colormap
    mov rdi, r15                           ; Display
    mov rsi, rbp                           ; Root Window
    mov rdx, [rbx + XVisualInfo.visual]    ; Visual pointer
    xor ecx, ecx                           ; AllocNone

    call XCreateColormap

    mov r8, rax    ; r8 = colormap

    ; --- 5. Prepare Window Attributes Block ---
    mov qword [win_attrs.colormap], r8    ; Use generated colormap

    ; --- 6. Create X Window (XCreateWindow) ---
    sub rsp, qword@size * 6    ; Allocate space for 6 stack arguments

        mov rdi, r15     ; Arg 1: display
        mov rsi, rbp     ; Arg 2: parent window (root)
        xor edx, edx     ; Arg 3: X = 0
        xor ecx, ecx     ; Arg 4: Y = 0
        mov r8d, r12d    ; Arg 5: Window Width
        mov r9d, r13d    ; Arg 6: Window Height

        ; Stack params
        mov qword [rsp + qword@size * 0], 0                           ; Arg 7: border width
        mov eax, [rbx + XVisualInfo.depth]
        mov qword [rsp + qword@size * 1], rax                         ; Arg 8: window's depth
        mov qword [rsp + qword@size * 2], 1                           ; Arg 9: window's class (InputOutput)
        mov rax, [rbx + XVisualInfo.visual]
        mov qword [rsp + qword@size * 3], rax                         ; Arg 10: visual type
        mov qword [rsp + qword@size * 4], CWColormap | CWEventMask    ; Arg 11: value mask
        lea rax, [win_attrs]
        mov qword [rsp + qword@size * 5], rax                         ; Arg 12: attributes

        call XCreateWindow

    add rsp, qword@size * 6    ; Free argument stack space

    ; Something went wrong: window is the door out.
    test rax, rax
    jz .fail

    mov [window], rax
    mov r12, rax    ; r12 = window

    ; --- 7. Set Window Title ---
    mov rdi, r15    ; Display
    mov rsi, r12    ; Window
    mov rdx, r14    ; Title

    call XStoreName

    ; --- 8. Setup WM_DELETE_WINDOW protocol (Catch close button) ---
    mov rdi, r15            ; Display
    lea rsi, [atom_name]    ; Atom name
    xor edx, edx            ; OnlyIfExists = false

    call XInternAtom

    ; Something went wrong: could not create an atom
    test rax, rax
    jz .fail

    mov [wm_delete], rax

    mov rdi, r15            ; Display
    mov rsi, r12            ; Window
    lea rdx, [wm_delete]    ; WM_DELETE_WINDOW atom array pointer
    mov ecx, 1              ; Number of protocols in the list

    call XSetWMProtocols

    ; --- 9. Map (Show) Window ---

    mov rdi, r15    ; Display
    mov rsi, r12    ; Window

    call XMapWindow

    ; --- 10. Create GLX Context & Make Current ---
    mov rdi, r15    ; Display
    mov rsi, rbx    ; Visual info
    xor edx, edx    ; Render through X server

    call glXCreateContext

    ; Something went wrong: Couldn't create OpenGL context
    test rax, rax
    jz .fail

    mov [glx_context], rax

    ; Make Current
    mov rdi, r15    ; Display
    mov rsi, r12    ; Window
    mov rdx, rax    ; GL context

    call glXMakeCurrent

    mov byte [should_close], false
    mov eax, true    ; Everything is fine (return value)

    jmp .exit

.fail:
    xor eax, eax
    mov byte [should_close], true

.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

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
    ; Functions doesn't take or return any values
    sub rsp, 8

        mov rdi, [display]    ; Window display
        test rdi, rdi
        jz .exit    ; There's no display

        ; Unbind GL context (bind to a zero-window/context)
        xor esi, esi    ; No Drawable
        xor edx, edx    ; No GL Context

        call glXMakeCurrent

        ; Destroy GL context
        mov rdi, [display]        ; Window display
        mov rsi, [glx_context]    ; GL context

        call glXDestroyContext

        ; Destroy Window
        mov rdi, [display]    ; Window display
        mov rsi, [window]     ; Window

        call XDestroyWindow

        ; Close Display
        mov rdi, [display]
        call XCloseDisplay

        ; Destroy display to not segfault if called twice
        mov qword [display], null
.exit:
    add rsp, 8
    ret


;
; Processes all the events sent.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads, writes
;
Window.pollEvents:
    ; Functions doesn't take or return any values
    sub rsp, 8

    mov rdi, [display]
    test rdi, rdi
    jz .done    ; There's no display

.loop:

    ; Get a number of event structures waiting in queue
    mov rdi, [display]
    call XPending

    ; No events left
    test eax, eax
    jz .done

    ; Get the next Event to the buffer
    mov rdi, [display]
    lea rsi, [event_buffer]

    call XNextEvent

    ; We only subscribed to one protocol message (WM_DELETE_WINDOW),
    ; so any ClientMessage at all means "close" - no need to compare atoms.
    cmp dword [event_buffer + XEvent.type], ClientMessage
    jne .loop  ; continue (not a Client Message)

    ; WM_DELETE_WINDOW was clicked
    mov rax, [event_buffer + XClientMessageEvent.data]
    cmp rax, [wm_delete]
    ; je .close
    jne .loop  ; continue (not a WM_DELETE_WINDOW)

.close:
    mov byte [should_close], true

    jmp .loop    ; Continue the event loop 'till the end

.done:
    add rsp, 8
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
    ;
    ;   Calling convention:
    ; @return  eax (boolean)
    ;
    movzx eax, byte [should_close]
    ret


;
; Swaps buffers.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads
;
Window.swapBuffers:
    ; Functions doesn't take or return any values
    sub rsp, 8

        mov rdi, [display]
        mov rsi, [window]

        call glXSwapBuffers

    add rsp, 8
    ret
