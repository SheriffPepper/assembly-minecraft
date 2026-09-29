[bits 64]

default rel    ; Using RIP-relative addresses by default


%include "definitions.inc"
%include "libs/testing/framework.inc"

test_module TEST#AABB, "AABB class testing module"


; "AABB" all functions testing implementation
    section .text

; List of imported functions
extern @testblock(AABB.new)

; List of exported functions
global testAll


;
; Start tests for all the functions of the AABB class.
; (We all know it's not a class...)
; (it's hardly a structure with static functions, since it's Assembly)
; (But let's keep it simple, and call it according to the high-level analog)
;
testAll:
    ; This test will return 0 in 'rax' if all the cases passed,
    ; And the pointer to the failure structure, if something went wrong
    call @testblock(AABB.new)

    test eax, eax
    jz .exit

    ; Something went wrong: fix the 'eax' to be an exit code
    mov eax, 1

.exit:
    ret
