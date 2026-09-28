[bits 64]

default rel    ; Using RIP-relative addresses by default

%include "definitions.inc"
%include "testing/framework.inc"

test_module TEST#1

; Include the functions we're gonna test
%include "com/mojang/rubydung/phys/AABB.inc"


; Test module implementation code
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
; @requires    x64, AVX
; @effects     stack use
;
TEST AABB.new, "standard function", 1
    CASE "Common correct corners"
        ; Minimum Corner parameters
        movss xmm0, dword [@param(minX)]
        movss xmm1, dword [@param(minY)]
        movss xmm2, dword [@param(minZ)]

        ; Maximum Corner parameters
        movss xmm3, dword [@param(maxX)]
        movss xmm4, dword [@param(maxY)]
        movss xmm5, dword [@param(maxZ)]

        ; Place to save new structure to
        lea rdi, [@param(this)]

        ; Save some things to check later
        SAVE_STACK
        SAVE_REG rdi

        call AABB.new

        ASSERT_PRESERVED_STACK
        ASSERT_PRESERVED rdi, "this"

        ASSERT_EQUAL_PACKED.f32 xmm0, [@correct(minCorner)], "packed array of min corner"
        ASSERT_EQUAL_PACKED.f32 xmm3, [@correct(maxCorner)], "packed array of max corner"
        ; 'xmm1-2' & 'xmm4-5' are considered destroyed and don't need to be checked

        ; Since 'xmm0' and 'xmm3' are correct, we can use them for checks
        ASSERT_EQUAL_PACKED.f32 xmm0, [@check(this.minCorner)], "saved min corner"
        ASSERT_EQUAL_PACKED.f32 xmm3, [@check(this.maxCorner)], "saved max corner"

ENDTEST


; Test module initialized constant data
    section .rodata
    align 16
@testcase(AABB.new, 1).minCorner:
    @testcase(AABB.new, 1).minX:  dd  0.0
    @testcase(AABB.new, 1).minY:  dd  0.0
    @testcase(AABB.new, 1).minZ:  dd  0.0
                                  dd  0.0    ; Padding for the packed version
@testcase(AABB.new, 1).maxCorner:
    @testcase(AABB.new, 1).maxX:  dd  1.0
    @testcase(AABB.new, 1).maxY:  dd  1.0
    @testcase(AABB.new, 1).maxZ:  dd  1.0
                                  dd  0.0    ; Padding for the packed version

; Test module changeable data
    section .data
    align 16
@testcase(AABB.new, 1).this:
    @testcase(AABB.new, 1).this.minCorner:  dd  0xBAADF00D, 0xBAADF00D, 0xBAADF00D, 0xBAADF00D
    @testcase(AABB.new, 1).this.maxCorner:  dd  0xBAADF00D, 0xBAADF00D, 0xBAADF00D, 0xBAADF00D
