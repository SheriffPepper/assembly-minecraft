[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; Windows backend for the "io" library (see "include/libs/io/io.inc").
; Owns every Windows I/O call in the project - if you're hunting for a STDOUT
; anywhere else in the codebase, that's a bug.
;

%include "../definitions.inc"
%include "winapi.inc"


; Application uninitialized data
    section .bss
;
; Windows' Standard Handles. This memory must the written once, and only read afterwards.
; Effectively, making them singletons, or read-only constants if you ignore the initiation process.
;
align 8    ; Align the handles to 8-bytes
stdout_handle  resq  1    ; Console Standard Output Handle
stderr_handle  resq  1    ; Console Standard Error Handle

written  resd  1    ; (u32) Count of of data written to the console


; I/O Library functions implementation
    section .text

; List of imported functions
extern GetStdHandle
extern WriteFile
extern GetLastError
extern ExitProcess

; List of exported functions
global initializeHandles    ; Windows-specific function for handle values initialization
global print#out


;
; Prints the string of the specified length to the standard output.
;
;   @param string: *str  pointer to the message buffer to output
;   @param length: int   number of characters in the message buffer to print
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

    mov rax, qword [stdout_handle]    ; Check the handle

    ; Standard Output is null: ignore the output
    ; Basically equal to boolean flag to turn the output on and off
    test rax, rax
    jnz .print
    ret    ; Return early if the output is turned off

.print:
    ; Save volatile registers to match the protocol
    ; And align odd-8-aligned (post-call convention) stack to 16 bytes
    push rdx
    push r8
    push r9
    push r10
    push r11

    sub rsp, SHADOW_SPACE + 16    ; Reserve Shadow Space and space for stack parameter required by Windows ABI

    mov rdx, rsi                             ; Message to print
    mov r8d, ecx                             ; Message length to print
    mov rcx, rax                             ; Standard Output Handle
    lea r9, [written]                        ; Number of bytes that was written to the console
    mov qword [rsp + STACK_PARAM#4], null    ; Only used in asynchronous I/O

    call WriteFile

    ; If the function fails with Standard Output, that means something bad happened.
    ; We turn the output off and hope for the best.
    test eax, eax
    mov eax, dword [written]    ; 'Mov' doesn't change flags
    jnz .done    ; No errors occurred

    ; Disaster mitigation: Disable output entirely if something happens
    mov qword [stdout_handle], null
    xor eax, eax    ; Return 0 bytes written

.done:
    add rsp, SHADOW_SPACE + 16    ; Release reserved space

    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx

    ret


;
; Initializes all the standard handles and saves them to their corresponding memory spaces.
; If Windows returns Null for handle, it's still saves, so functions must check for Null-pointer before i/o operations.
;
; This function is expected to be called from OS-specific entry-point right away.
; This creates 16-byte aligned stack post-call for nice Windows API calls.
;
; [WARNING]: If the Windows returns INVALID_HANDLE, the function will terminate the program.
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
initializeHandles:
    ; Since stack is already 16-byte aligned post-call,
    ; we need only reserve the Shadow Space for Windows API calls

    sub rsp, SHADOW_SPACE    ; Reserve Shadow required by Windows ABI

    ; Getting standard output handle
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle

    ; Check for INVALID_HANDLE
    cmp rax, INVALID_HANDLE
    je api_failed    ; Something terrible happened...

    mov qword [stdout_handle], rax    ; Save the handle

    ; Getting standard error output handle
    mov ecx, STD_ERROR_HANDLE
    call GetStdHandle

    ; Check for INVALID_HANDLE
    cmp rax, INVALID_HANDLE
    je api_failed    ; Something terrible happened...

    mov qword [stderr_handle], rax    ; Save the handle

    add rsp, SHADOW_SPACE    ; Release reserved space
    ret

api_failed:    ; Called to terminate the process because Windows API failed
    call GetLastError
    ; Return the last error code as exit status
    mov rcx, rax
    call ExitProcess
