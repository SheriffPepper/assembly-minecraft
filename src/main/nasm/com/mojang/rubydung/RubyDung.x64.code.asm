[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; RubyDung entry point.
;
; @author  SheriffPepper
; @version now
; @since   forever
;

%include "definitions.inc"
%include "libs/standard.inc"
%include "libs/window/window.inc"
%include "libs/opengl/opengl.inc"


%define WIDTH   900
%define HEIGHT  600


; Some imports (RubyDung.data)
extern window_title
extern triangle_vertices
extern f32_one


; Application code
    section .text

; List of exported functions
global main    ; Entry point


;
; Main entry point.
;
; [NOTE]: Requires the stack to be 16-bytes aligned (post-call).
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, read, writes
;
; @author   Blanki
; @version  hello-triangle
; @since    Big Bang
;
main:
    ;
    ; This function requires the stack to be 16-bytes aligned inside of it (post-call).
    ; Values above the passed stack pointer is considered "unreachable" and should not
    ; be accessed (e.g. on Linux command-line arguments are passed via stack) as if it's
    ; located at the highest '0xfff...ff8' address and accessing it would trigger SegFault.
    ; Return value in `rax` register when returning from this function is considered
    ; the exit code of the application and must be provided with 16-bytes aligned stack
    ; register (pre-ret) even if it's not the same stack address.
    ;

    ; --- Create the Window ---
    mov ecx, WIDTH
    mov edx, HEIGHT
    lea r8, [window_title]

    call Window.create

    ; Couldn't create the Window - exit
    test eax, eax
    jz .exit

    ; One-time GL state - viewport has to match the window or you get letter boxing
    xor edi, edi
    xor esi, esi
    mov edx, WIDTH
    mov ecx, HEIGHT

    call OpenGL.Viewport

.loop:
    call Window.pollEvents
    call Window.shouldClose

    ; Window should close
    test eax, eax
    jnz .destroy

    call render

jmp .loop

.destroy:
    call Window.destroy

.exit:
    xor eax, eax    ; Exit code
    ret    ; Exit process


;
; Cleans the framebuffer and draws one red triangle, immediate-mode style.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads
;
; @author   Blanki
; @version  hello-triangle
; @since    Big Bang
;
render:
    ; Function doesn't take or return any values

    ; Align odd-8-aligned (post-call convention) stack to 16 bytes
    sub rsp, 8

    ; glClearColor(0, 0, 0, 1) - black background
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    movss xmm3, [f32_one]

    call OpenGL.ClearColor

    mov edi, GL_COLOR_BUFFER_BIT
    call OpenGL.Clear

    ; Triangle Drawing Block
    mov edi, GL_TRIANGLES
    call OpenGL.Begin

        ; glColor3f(1, 0, 0) - red, set once, all 3 vertices inherit it
        movss xmm0, [f32_one]
        xorps xmm1, xmm1
        xorps xmm2, xmm2

        call OpenGL.Color3f

        ; 3x glVertex3f, straight off triangle_vertices
        movss xmm0, [triangle_vertices + 0]
        movss xmm1, [triangle_vertices + 4]
        movss xmm2, [triangle_vertices + 8]

        call OpenGL.Vertex3f

        movss xmm0, [triangle_vertices + 12]
        movss xmm1, [triangle_vertices + 16]
        movss xmm2, [triangle_vertices + 20]

        call OpenGL.Vertex3f

        movss xmm0, [triangle_vertices + 24]
        movss xmm1, [triangle_vertices + 28]
        movss xmm2, [triangle_vertices + 32]

        call OpenGL.Vertex3f

    call OpenGL.End
    call Window.swapBuffers

    ; Release all the Shadow Space
    add rsp, 8
    ret
