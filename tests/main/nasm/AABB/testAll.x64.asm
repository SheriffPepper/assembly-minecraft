[bits 64]

default rel    ; Using RIP-relative addresses by default


; "AABB" inter-testing data
    section .data
; The number of tests failed
testsFailed:  dd  0


; "AABB" all functions testing implementation
    section .text

; List of imported functions
extern test#1

; List of exported functions
global testAll


;
; Start tests for all the functions of the AABB class.
; (We all know it's not a class...)
; (it's hardly a structure with static functions, since it's Assembly)
; (But let's keep it simple, and call it according to the high-level analog)
;
testAll:
    call test#1    ; Returns '1' if test is failed
    add dword [testsFailed], eax

    mov eax, dword [testsFailed]
    ret    ; Exit with the number of tests failing being the exit code
