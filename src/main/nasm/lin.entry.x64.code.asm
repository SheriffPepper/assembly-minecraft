[bits 64]

default rel    ; Using RIP-relative addresses by default


; Application code
    section .text

; Imported functions
extern main    ; Main program entry point

; Exported OS-specific entry point
global lin.entry


;
; Linux-specific entry point.
; Prepares the data and passes control to the main entry point,
; implementing our custom convention.
;
; @convention  Linux ABI
; @features    x64
; @effects     stack use
;
; @author   Blanki
; @version  hello-triangle
; @since    Big Bang
;
lin.entry:
    ; The stack pointer in Linux x64 is initialized to be 16-bytes aligned (post-jump)
    ; Making our call to 'main' misalign the stack to odd-8-aligned in that function.
    sub rsp, 8    ; Align the stack back to 16 bytes after the call
    call main     ; Calling 'main' pushes the return address, making it nice and clean alignment

    ; Failsafe for 'main' function return - cleanup and safe exit from the process
    ; It's the default behavior of the program:
    ; We need to return the value in `rax` as exit code
    mov rdi, rax    ; Exit code
    mov rax, 60     ; Syscall number 60 in sys_exit

    syscall    ; Exit Process

; Hopefully, program never reaches this point
; Or we're totally screwed...
