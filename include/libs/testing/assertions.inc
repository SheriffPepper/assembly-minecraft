%ifndef __TEST_ASSERTIONS_INCLUDE__
%define __TEST_ASSERTIONS_INCLUDE__


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


%macro ASSERT_ALIGNED_REGISTER 2
    %defstr %%__TEMP_REG_STRING__  %1
    ASSERT_ALIGNED_REGISTER %1, %2, %%__TEMP_REG_STRING__
    %undef  %%__TEMP_REG_STRING__
%endmacro


%macro ASSERT_ALIGNED_REGISTER 3
    ; Assertions must work in Test Block only
    %ifnctx __test_block__
        %fatal "Can't run 'ASSERT_*' directives outside the Test Block! Did you forget 'TEST'?"
    %endif

    test %1, %2 - 1
    jz %%passed    ; Register is aligned

    ; Register was not aligned:
    ; Construct the TestFailure object
    mov [@failure.actual], %1
    mov [@failure.expected], %1
    and @reg.size(%1) [@failure.expected], -%2

    ; Register was not aligned
    __test_fail TEST_FAILURE_ALIGNED, @reg.type(%1), %3

%%passed:
%endmacro


%macro ASSERT_ALIGNED_STACK 1
    ASSERT_ALIGNED_REGISTER rsp, %1, "stack pointer"
%endmacro


%macro ASSERT_PRESERVED_REGISTER 2
    ; Assertions must work in Test Block only
    %ifnctx __test_block__
        %fatal "Can't run 'ASSERT_*' directives outside the Test Block! Did you forget 'TEST'?"
    %endif

    %ifn @reg.is_vec(%1)
        ; General-purpose register check
        cmp %1, [@reg(%1)]
        je %%passed    ; Register was preserved

        ; Register was not preserved:
        ; Construct the TestFailure object
        mov [@failure.actual], %1
        mov %1, [@reg(%1)]
        mov [@failure.expected], %1
    %elif @reg.is_xmm(%1)
        ; Vector 'xmm' register check
        movaps [@fixture.scratch], xmm7    ; Save the 'xmm7' to scratch space to use as temp-storage
        movaps xmm7, %1    ; Move the register value to the 'xmm7' to not clobber the register with comparison mask

        ; Save the 'rax' register to not clobber it with mask
        mov [@fixture.scratch + 16], rax

        vpcmpeqb xmm7, [@reg(%1)]    ; Get the comparison mask
        vpmovmskb eax, xmm7          ; Load the mask into 'eax' to check the equality
        cmp eax, 0xFFFF              ; If the full mask, values are equal -> register was preserved

        ; Restore the values in 'xmm7' & 'rax'
        movaps xmm7, [@fixture.scratch]
        mov rax, [@fixture.scratch + 16]
        je %%passed    ; Register was preserved

        ; Register was not preserved:
        ; Construct the TestFailure object
        movaps [@failure.actual], %1
        movaps %1, [@reg(%1)]
        movaps [@failure.expected], %1
    %elif @reg.is_ymm(%1)
        ; Vector 'ymm' register check
        movaps [@fixture.scratch], ymm7    ; Save the 'ymm7' to scractch space to use as temp-storage
        movaps xmm7, @reg.get_xmm(%1)      ; Move the low 128-bit register value to the 'xmm7' to not clobber the register with comparison mask

        ; Save the 'rax' register to not clobber it with mask
        mov [@fixture.scratch + 32], rax

        ; Check the low 128-bit register value
        vpcmpeqb xmm7, [@reg(%1)]    ; Get the comparison mask
        vpmovmskb eax, xmm7          ; Load the mask into 'eax' to check the equality
        cmp eax, 0xFFFF              ; If the full mask, values are equal -> low 128-bit register value was preserved

        jne %%failed    ; Register was not preserved

        ; Check the high 128-bit register value
        vextractf128 xmm7, %1, 1     ; Extract high 128-bit register value

        vpcmpeqb xmm7, [@reg(%1) + 16]    ; Get the comparison mask
        vpmovmskb eax, xmm7               ; Load the mask into 'eax' to check the equality
        cmp eax, 0xFFFF                   ; If the full mask, values are equal -> high 128-bit register value was preserved

        ; Restore the values in 'ymm7' & 'rax'
        movaps ymm7, [@fixture.scratch]
        mov rax, [@fixture.scratch + 32]
        je %%passed
    %%failed:
        ; Register was not preserved:
        ; Construct the TestFailure object
        movaps [@failure.actual], %1
        movaps %1, [@reg(%1)]
        movaps [@failure.expected], %1
    %elif @reg.is_zmm(%1)
        %fatal "TODO: implement the ZMM-register preservation check"
    %endif

    ; Preserved register was not saved during testing
    __test_fail TEST_FAILURE_PRESERVED, @reg.type(%1), %2

    %%passed:
%endmacro


%macro ASSERT_PRESERVED_STACK 0
    ASSERT_PRESERVED_REGISTER rsp, "stack pointer"
    ASSERT_PRESERVED_REGISTER rbp, "stack frame pointer"
%endmacro


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
