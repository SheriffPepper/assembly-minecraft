%ifndef __TEST_ASSERTIONS_INCLUDE__
%define __TEST_ASSERTIONS_INCLUDE__

%include "libs/testing/assertions/assertion_computed.inc"
%include "libs/testing/assertions/assertion_packed.inc"

;
; Assertion macros here represent debugging primitives used to enforce structural and
; algorithmic assumptions at test's runtime. Each macro evaluates a specific
; boolean condition or register state; if the condition evaluates to 'true', execution proceeds
; normally. If the condition evaluates to 'false', a critical developer bug is implied,
; and macro immediately halts the test's execution, and generates the Test Failure object
; for the test runner to inspect.
;
; [NOTE]: If the assertion holds, nothing observable changes (the only thing that is not preserved are flags).
;
; @author   Blanki
; @version  1.0
; @since    1.0
;


;
; Stops the assembly if the assertion is used outside of a Test Block.
;
;   @param who  name of the assertion that asks (used in the error messages)
;
%macro __t_assert_requirements 1
    %defstr %%who  %1
    %strcat %%no_module  %%who, ": First define the Test Module, and then we'll talk"
    %strcat %%no_test    %%who, ": Can't run 'ASSERT_*' directives outside the Test Block! Did you forget 'TEST'?"

    ; Assertions must work in Test Block only
    __t_require_module %%no_module
    __t_require_test   %%no_test

    %undef  %%who
    %undef  %%no_module
    %undef  %%no_test
%endmacro


;
; Fills the 'TestFailure' object and leaves the Test Block.
; The caller must have already written 'actual' & 'expected' values (if there are any).
;
; Clobbers 'rax' (only on the failure path, the test is over anyway).
;
;   @param kind  TEST_FAILURE_*
;   @param type  TEST_VALUE_TYPE_*
;   @param n     description of the value: string literal, or the label of a string
;
%macro __test_fail 3    ; <kind>, <type>, <name>
    ; If the name is string, we must save the string
    %ifstr %3
        @string %%value.name, %3
        lea rax, [%%value.name]
    %else
        lea rax, [%3]
    %endif

    mov qword [@fixture.failure + TestFailure.value.name], rax
    mov dword [@fixture.failure + TestFailure.value.type], %2
    mov dword [@fixture.failure + TestFailure.kind], %1

    lea rax, [@testcase.description]
    mov dword [@fixture.failure + TestFailure.case], %$__CASE_NUMBER__
    mov qword [@fixture.failure + TestFailure.case.description], rax

    ; Return the pointer to the Failure structure
    lea rax, [@fixture.failure]

    jmp @testblock.current%+#failed
%endmacro


;
; Defines the description of the checked value:
; the one the user has given, or (if there's none) the text of the operand itself.
;
;   @param out      name of the single-line macro to define
;   @param given    description given by the user (may be empty)
;   @param operand  operand to take the name from
;
%macro __t_describe 3
    %ifempty %2
        %defstr %1  %3
    %else
        %xdefine %1  %2
    %endif
%endmacro


;
; Finds out the size keyword written in front of the memory operand ('dword [x]', 'f32 [x]', 'v128 [x]', etc.),
; Defines the single-line macro '%1' as: 'byte', 'word', 'dword', 'qword', 'oword', 'yword', 'zword', or 'none'.
;
;   @param out      name of the single-line macro to define
;   @param operand  memory operand
;
%macro __t_mem_size 2
    %defstr %%text   %[%2]           ; Expand the aliases ('f32' -> 'dword')
    %substr %%word5  %%text  1, 5
    %substr %%word4  %%text  1, 4

    %ifidni %%word5, "dword"
        %xdefine %1  dword
    %elifidni %%word5, "qword"
        %xdefine %1  qword
    %elifidni %%word5, "oword"
        %xdefine %1  oword
    %elifidni %%word5, "yword"
        %xdefine %1  yword
    %elifidni %%word5, "zword"
        %xdefine %1  zword
    %elifidni %%word4, "word"
        %xdefine %1  word
    %elifidni %%word4, "byte"
        %xdefine %1  byte
    %else
        %xdefine %%%1  none
    %endif

    %undef  %%text
    %undef  %%word5
    %undef  %%word4
%endmacro


%macro __t_assert_gp_preserved 2
    ; General-purpose register check
    cmp %1, [@reg(%1)]
    je %%passed    ; Register was preserved

    ; Register was not preserved:
    ; Construct the 'TestFailure' object
    mov [@failure.actual], %1
    mov %1, [@reg(%1)]
    mov [@failure.expected], %1

    ; Preserved register was not saved during testing
    __test_fail TEST_FAILURE_PRESERVED, @reg.type(%1), %2

%%passed:
%endmacro


%macro __t_assert_xymm_preserved 2
    ; Vector 'xmm / ymm' register check
    ; Save the whole register (128-bit instructions below its upper half) to a temporal storage
    vmovaps [@failure.actual], @reg.get_full(%1)

    ; Check the register value
    vxorps %1, %1, [@reg(%1)]    ; If values are equal, 'xmm / ymm' register will become all zeroes
    vptest %1, %1                ; Test the result against itself
    jz %%passed    ; Value was preserved

    ; Register was not preserved:
    ; Construct the 'TestFailure' object
    vmovaps %1, [@reg(%1)]
    vmovaps [@failure.expected], %1

    ; Preserved register was not saved during testing
    __test_fail TEST_FAILURE_PRESERVED, @reg.type(%1), %2

%%passed:
    ; Restore the value of the register
    vmovaps @reg.get_full(%1), [@failure.actual]
%endmacro


%macro __t_assert_zmm_preserved 2
    ; Vector 'zmm' register check
    vpcmpeqq k0, %1, [@reg(%1)]    ; Safely overwrite k0 mask register
    kortestw k0, k0                ; Test the 'k0' against itself
    jc %%passed    ; Value was preserved

    ; Register was not preserved:
    ; Construct the 'TestFailure' object
    vmovaps [@failed.actual], %1
    vmovaps %1, [@reg(%1)]
    vmovaps [@failed.expected], %1

    ; Preserved register was not saved during testing
    __test_fail TEST_FAILURE_PRESERVED, @reg.type(%1), %2

%%passed:
    ; We don't need to restore anything,
    ; Since we've overwrote only the 'k0'
%endmacro


%macro ASSERT_PRESERVED_REGISTER 2
    ; Assertions must work in Test Block only
    __t_assert_requirements ASSERT_PRESERVED_REGISTER

    __t_operand_kind %%kind, %1
    __t_describe %%desc, %2, %1

    ; Choose the implementation based on the register type
    %ifidn %%kind, gpr
        ; General-purpose registers implementation
        __t_assert_gp_preserved %1, %%desc
    %elifidn %%kind, xmm
        ; AVX-compatible vector registers implementation
        __t_require_AVX ASSERT_PRESERVED_REGISTER
        __t_assert_xymm_preserved %1, %%desc
    %elifidn %%kind, ymm
        ; AVX-compatible vector registers implementation
        __t_require_AVX ASSERT_PRESERVED_REGISTER
        __t_assert_xymm_preserved %1, %%desc
    %elifidn %%kind, zmm
        ; AVX-512f is the baseline for ZMM-register preservation check
        __t_require_AVX512f ASSERT_PRESERVED_REGISTER
        __t_assert_zmm_preserved %1, %%desc
    %else
        %fatal "ASSERT_PRESERVED_REGISTER: expected a general-purpose or a vector register"
    %endif

    %undef %%kind
    %undef %%desc
%endmacro


;
; Checks that the stack pointer and the frame base are the same as they were when 'PRESERVE_STACK' was called.
;
%macro ASSERT_PRESERVED_STACK 0
    ; Assertions must work in Test Block only
    __t_assert_requirements ASSERT_PRESERVED_STACK

    ASSERT_PRESERVED_REGISTER rsp, "stack pointer"
    ASSERT_PRESERVED_REGISTER rbp, "stack frame pointer"
%endmacro


%include "libs/testing/assertions/assertion_computed.inc"
%include "libs/testing/assertions/assertion_packed.inc"


%macro __ASSERT_EQUAL_PACKED 4
    ; Assertions must work in Test Block only
    %ifnctx __test_block__
        %fatal "Can't run 'ASSERT_*' directives outside the Test Block! Did you forget 'TEST'?"
    %endif

    ; First parameter is register
    %ifnidn {%substr(%1, 1, 1)}, {'['}
        ; Check if register is vector
        %ifn @reg.is_vec(%1)
            %fatal "*_PACKED assertions operate only on vector registers!"
        %endif

        %define %%__REGISTER__  %1
    %endif

    ; Second parameter is register
    %ifnidn {%substr(%2, 1, 1)}, {'['}
        ; Check if register is vector
        %ifn @reg.is_vec(%2)
            %fatal "*_PACKED assertions operate only on vector registers!"
        %endif

        ; First parameter is already a register
        %ifdef %%__REGISTER__
            ; If registers don't match in size
            %ifn (@reg.is_xmm(%1) & @reg.is_xmm(%2)) | (@reg.is_ymm(%1) & @reg.is_ymm(%2)) | (@reg.is_zmm(%1) & @reg.is_zmm(%2))
                %fatal "Registers have not matching sizes!"
            %endif
        %endif

        %define %%__REGISTER__  %2
    %endif

    ; If none of the parameters are registers
    %ifndef %%__REGISTER__
        %fatal "Can't compare two values in memory with unknown size!"
    %endif


    ; XMM-register comparison
    %if @reg.is_xmm(%%__REGISTER__)
        __ASSERT_EQUAL_PACKED.v128 %1, %2, %3, %4
    ; YMM-register comparison
    %elif @reg.is_ymm(%%__REGISTER__)
        __ASSERT_EQUAL_PACKED.v256 %1, %2, %3, %4
    ; ZMM-register comparison
    %elif @reg.is_zmm(%__REGISTER__)
        __ASSERT_EQUAL_PACKED.v512 %1, %2, %3, %4
    %else
        %fatal "Unknown vector type...what did you do? ._."
    %endif

    %undef %%__REGISTER__
%endmacro


%macro __ASSERT_EQUAL_PACKED.v128 4
    ; Preserve the 'xmm6' & 'xmm7' registers to not clobber them with comparison masks
    movaps [@fixture.scratch +  0], xmm6
    movaps [@fixture.scratch + 16], xmm7
    movaps xmm6, %1
    %ifidn {%2}, {xmm6}
        ; Use saved register value if the value uses 'xmm6' register
        ; So, we're not in the situation, where we're comparing 'xmm7' & 'xmm6'
        ; In that case 'xmm6' will turn into 'xmm7', and 'xmm7' will stay the same,
        ; Creating logical error, where 'xmm7 == xmm7' in any case
        movaps xmm7, [@fixture.scratch]
    %else
        movaps xmm7, %2
    %endif

    ; Save the 'rax' register to not clobber it with mask
    mov [@fixture.scratch + 32], rax

    ; Save the values to some temporal storage
    ; If the comparison fails, we already have a few values initialized
    movaps [@failure.actual],   xmm6
    movaps [@failure.expected], xmm7

    vpcmpeqb xmm6, xmm7    ; Get the comparison mask
    vpmovmskb eax, xmm6    ; Load the mask into 'eax' to check the equality
    cmp eax, 0xFFFF        ; If the full mask, values are equal -> registers are equal
    je %%passed    ; 128-bit values are not equal

    ; 128-bit values are not equal
    __test_fail TEST_FAILURE_EQUAL, TEST_VALUE_TYPE_VEC.v128%4, %3

%%passed:
    ; Restore the values in 'xmm6', 'xmm7' & 'rax'
    movaps xmm6, [@fixture.scratch]
    movaps xmm7, [@fixture.scratch + 16]
    mov rax, [@fixture.scratch + 32]
%endmacro


%macro __ASSERT_EQUAL_PACKED.v256 4
    %fatal "TODO: implement the ZMM-register equality check"
%endmacro


%macro __ASSERT_EQUAL_PACKED.v512 4
    %fatal "TODO: implement the ZMM-register equality check"
%endmacro


%macro ASSERT_EQUAL_PACKED.f32 3
    __ASSERT_EQUAL_PACKED %1, %2, %3, .f32
%endmacro


%endif; __TEST_ASSERTIONS_INCLUDE__
