[bits 64]

default rel    ; Using RIP-relative addresses by default

%include "definitions.inc"
%include "tests/test.inc"
%include "com/mojang/rubydung/phys/AABB.inc"


; "AABB.new" testing implementation
    section .text

; List of imported functions

; List of exported functions
global test#1

;
; Tests the function "AABB.new", and returns '1' if the function failed.
; It prints all the errors to the terminal, so we know what happened.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64, AVX
; @effects     stack use
;
test#1:
    sub rsp, 8    ; 16-byte aligned stack

    log info.test.start

    xor eax, eax

    add rsp, 8    ; Release the borrowed space
    ret


; "AABB" testing data and messages
    section .data
info.test.start:  db  "[INFO] Testing function '", Color.classDefinition, "AABB", Color.clear, ".", Color.classMethod, "new", Color.clear, "'...", 0x0a, 0x00
info.test.start.size  equ  $ - info.test.start
