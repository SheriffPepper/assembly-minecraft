[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; Linux/X11+GLX backend for the "window" library - Not Implemented yet
; Placeholder so the project structure (and the build) already accounts for this slot.
;
; @TODO  implement this thing
;

%include "../definitions.inc"

; Application code
    section .text

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

    xor eax, eax    ; Always "fails" - nothing to create yet
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
    ret    ; Stub


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
    ret    ; Stub


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
    mov eax, true    ; Report closed immediately rather than looping forever
    ret              ; Even though we should've been exited a lo-o-ong time ago...


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
    ret    ; Stub
