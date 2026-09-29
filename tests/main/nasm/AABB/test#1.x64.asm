[bits 64]

default rel    ; Using RIP-relative addresses by default

%include "definitions.inc"
%include "testing/framework.inc"

test_module TEST#AABB

; Include the functions we're gonna test
%include "com/mojang/rubydung/phys/AABB.inc"


; Test module implementation code
    section .text

; List of exported functions
global @testblock(AABB.new)


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
        movss xmm0, f32 [@param(minX)]
        movss xmm1, f32 [@param(minY)]
        movss xmm2, f32 [@param(minZ)]

        ; Maximum Corner parameters
        movss xmm3, f32 [@param(maxX)]
        movss xmm4, f32 [@param(maxY)]
        movss xmm5, f32 [@param(maxZ)]

        ; Space to save new structure to
        lea rdi, [@param(this)]

        ; Save some things to check later
        PRESERVE_STACK
        PRESERVE_REGISTER rdi

        call AABB.new

        ASSERT_PRESERVED_STACK
        ASSERT_PRESERVED_REGISTER rdi, "this"

        ASSERT_EQUAL_PACKED.f32 xmm0, [@correct(minCorner)], "packed array of min corner"
        ASSERT_EQUAL_PACKED.f32 xmm3, [@correct(maxCorner)], "packed array of max corner"
        ; 'xmm1-2' & 'xmm4-5' are considered destroyed and don't need to be checked

        ; Since 'xmm0' and 'xmm3' are correct, we can use them for checks
        ASSERT_EQUAL_PACKED.f32 xmm0, [@check(this.minCorner)], "saved min corner"
        ASSERT_EQUAL_PACKED.f32 xmm3, [@check(this.maxCorner)], "saved max corner"


        ; Case-specific data for testing
        @section.rodata
            align 16    ; Make sure the AABB structure is 16-byte aligned in memory
            @correct(minCorner):
                @param(minX):  dd  0.0
                @param(minX):  dd  0.0
                @param(minZ):  dd  0.0
                               dd  0.0    ; Padding for the packed version
            @correct(maxCorner):
                @param(maxX):  dd  1.0
                @param(maxY):  dd  1.0
                @param(maxZ):  dd  1.0
                               dd  0.0    ; Padding for the packed version
        @section.data
            align 16    ; Make sure the AABB structure is 16-byte aligned in memory
            @param(this):
                @check(this.minCorner):  dd  0xBAADF00D, 0xBAADF00D, 0xBAADF00D, 0xBAADF00D
                @check(this.maxCorner):  dd  0xBAADF00D, 0xBAADF00D, 0xBAADF00D, 0xBAADF00D
        @section.return

ENDTEST
