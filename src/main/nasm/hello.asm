[bits 64]

%include "definitions.inc"
%include "libs/winapi.inc"

; Import statements
extern GetStdHandle
extern WriteFile
extern ExitProcess

; Constants of the application
    section .data
message db "Hello, World!", 0x0d, 0x0a  ; Message to print
message_length equ ($ - message)        ; Message length to print

; Uninitialized statically allocated application variables
    section .bss
written resd 1  ; (u32) Count of data written to the console


; Code of the application
    section .text

; List of export functions
global main  ; Entry point


main:
    ; Prologue: by Windows x64 calling convention before calling any function there are should be
    ; allocated at least 32 bytes of "shadow space" on the stack, and the stack should always have
    ; 16-byte alignment (after `call` instruction execution) for instruction that use aligned
    ; address values, such as `movaps` (Move Aligned Packed Single-precision / float value),
    ; `movdqa` (Move Aligned Double Quadword / 128-bit value), etc.
    ; Otherwise, the process might be accidentally murdered by OS with "0xC0000005 access violation"

    ;           Caller stack after call
    ;         +––––––––––––––––––––––––––+  # Required!
    ; 0x0100 >| Return address to caller | rsp + 0
    ; 0x0108  | Param 1 (shadow) for rcx |       8  (not aligned)
    ; 0x0110  | Param 2 (shadow) for rdx |       16 (aligned)
    ; 0x0118  | Param 3 (shadow) for r8  |       24 (not aligned)
    ; 0x0120  | Param 4 (shadow) for r9  |       32 (aligned)
    ;         +––––––––––––––––––––––––––+  # Optional params, but alignment required!
    ; 0x0128  | Param 5 (if any)         | rsp + 40 (not aligned)
    ; 0x0130  | Param 6 (if any)         |       48 (aligned)
    ;         +––––––––––––––––––––––––––+
    ;
    ; By convension, the stack is aligned at the process start.

    ; Fulfilling the convension
    sub rsp, 0x30 - pointer@size  ; Before `call` instruction execution, 8-byte address is pushed
                                  ; on stack making it aligned, because this size was initially
                                  ; subtracted from an aligned offset.

    ; Getting output handle to print to the console
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov rbx, rax  ; Save handle to rbx

    ; Stack wasn't changed – no need to change `rsp` again

    ; Write data to the console synchronously
    mov rcx, rbx                ; Console output handle
    lea rdx, [rel message]      ; Message to print
    mov r8d, message_length     ; Message length to print
    lea r9, [rel written]       ; Number of bytes that was written to the console
    mov qword [rsp + 32], null  ; Only is used in asynchronous I/O (param #4 has the address of 4 * 8 bytes = 32)

    call WriteFile

    ; Exit with exit code `0` – executed successfully
    xor ecx, ecx  ; X ^ X = 0
    call ExitProcess

    ; Program never reaches this point
