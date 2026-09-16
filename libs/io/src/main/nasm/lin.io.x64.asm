[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; Linux backend for the "io" library (see "include/libs/io/io.inc").
; Owns every Linux system call in the project - same contract as win.io's Windows implementation.
;

%include "../definitions.inc"
%include "linapi.inc"


; I/O Library initialized data
    section .data
stdout_enabled:  db  true    ; If set to 'false', standard output prints are ignored
stderr_enabled:  db  true    ; If set to 'false', standard error output prints are ignored


; I/O Library functions implementation
    section .text

; List of exported functions
global print#out


;
; Prints the string of the specified length to the standard output.
;
;   @param string: *str  pointer to the message buffer to output
;   @param length: int   number of characters in the message buffer to print
;
;   @return  the number of bytes being written
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
print#out:
    ;
    ;   Calling convention:
    ; @param string  rsi (pointer, "source")
    ; @param length  ecx (u32 integer)
    ;
    ; @return rax
    ;
    ;   Side Effects:
    ; @change rax  the return value
    ;
    ; @destroyed rsi  the values is considered destroyed and potentially contain garbage
    ; @destroyed ecx  the values is considered destroyed and potentially contain garbage
    ;

    push rdi

    ; Check if the Standard Output is disabled
    cmp byte [stdout_enabled], false
    je .done

    ; Print the string to standard output
    mov rax, sys_write
    mov rdi, STD_OUTPUT_FILE
    mov rdx, rcx

    syscall

    ; Check for errors: if negative, something broke...
    test rax, rax
    jnl .done

    ; Disaster mitigation: Disable output entirely if something happens
    mov byte [stdout_enabled], false
    xor rax, rax    ; Return 0 bytes written

.done:
    pop rdi

    ret


stdout_failed:
    ; STDOUT failed mid-game... Welp, if so, we're screwed.
    ; Propagate the exit code from 'sys_write' and terminate everything.
