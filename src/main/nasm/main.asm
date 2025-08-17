[bits 64]

default rel  ; Using RIP-relative address by default


%include "definitions.inc"
%include "libs/winapi.inc"

; Import statements
extern MessageBoxA
extern ExitProcess


; Constants of the application
    section .data
; Program strings
title db "Minecraft", 0x00                                 ; Title of the window
text  db "Hello from Minecraft Message Box window!", 0x00  ; Text inside the message box window


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

    ; Creating Message Box window
    xor rcx, rcx     ; Owner Window Handle (NULL -> no owner)
    lea rdx, [text]  ; Text in the window
    lea r8, [title]  ; Caption of the window
    xor r9, r9       ; Flags of the Message Box window (0x00000000 -> OK button without an icon)

    call MessageBoxA

    ; Exit with exit code `0` – executed successfully
    xor ecx, ecx  ; X ^ X = 0
    call ExitProcess

    ; Program never reaches this point
