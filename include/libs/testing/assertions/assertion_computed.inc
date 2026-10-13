%ifndef __TESTING_ASSERTIONS_ALIGNED_INCLUDE__
%define __TESTING_ASSERTIONS_ALIGNED_INCLUDE__


;
; Computable assertions for values: the ones that have to do some math with them
; (alignment, comparison, boolean tests) on general-purpose registers and memory.
;
; @author   Blanki
; @version  1.0
; @since    1.0
;
; @see  assertions.inc
;


;
; Checks that the register is aligned to the given power of two: the lower bits of the value are zeroes.
; Failure holds the value in 'actual', and the same value aligned down in 'expected'.
;
;   @param reg          general-purpose register
;   @param alignment    power of two (it's validated when it's a plain number)
;   @param description  [optional] name of the value in the failure report (name of the register by default)
;
%macro ASSERT_ALIGNED_REGISTER 2-3
    ; Assertions must work in Test Block only
    __assert_requirements ASSERT_ALIGNED_REGISTER

    __t_operand_kind %%kind, %1
    %ifnidn %%kind, gpr
        %fatal "ASSERT_ALIGNED_REGISTER: expected a general-purpose register"
    %endif

    ; Alignment of '7' is certainly not what we wanted
    %ifnum %2
        %if ((%2) < 1) || (((%2) & ((%2) - 1)) != 0)
            %fatal "ASSERT_ALIGNED_REGISTER: alignment must be a power of two"
        %endif
    %endif

    __t_describe %%desc, %3, %1

    test %1, (%2) - 1
    jz %%passed    ; Register is aligned

    ; Register was not aligned:
    ; Construct the 'TestFailure' object
    mov [@failure.actual],   %1
    mov [@failure.expected], %1

    and @reg.size(%1) [@failure.expected], -(%2)

    ; Register was not aligned
    __test_fail TEST_FAILURE_ALIGNED, @reg.type(%1), %%desc

%%passed:
    %undef %%kind
    %undef %%desc
%endmacro


%macro ASSERT_ALIGNED_STACK 1
    ; Assertions must work in Test Block only
    __assert_requirements ASSERT_ALIGNED_STACK

    ASSERT_ALIGNED_REGISTER rsp, %1, "stack pointer"
%endmacro


;
; Writes the scalar operand into the 'TestFailure' slot (for the test runner to print).
; A memory operand goes through 'rax' of the right size, so it must be the LAST one to be written:
; the other operand could be 'rax' itself.
;
;   @param slot     memory operand of the slot
;   @param operand  what to save
;   @param kind     kind of the operand: gpr / mem / other (immediate)
;   @param size     size keyword: byte / word / dword / qword
;
%macro __t_fill_scalar 4
    %ifidn %3, gpr
        mov [%1], %2
    %elifidn %3, mem
        mov __t_gp_temp_%[%4], %2
        mov [%1], __t_gp_temp_%[%4]
    %else
        mov %4 [%1], %2
    %endif
%endmacro


;
; Writes both operands of the failed scalar assertion into the 'TestFailure' object.
;
%macro __t_fill_scalar_pair 5    ; <actual>, <kind of actual>, <expected>, <kind of expected>, <size>
    %ifidn %2, mem
        __t_fill_scalar @failure.expected, %3, %4, %5
        __t_fill_scalar @failure.actual,   %1, %2, %5
    %else
        __t_fill_scalar @failure.actual,   %1, %2, %5
        __t_fill_scalar @failure.expected, %3, %4, %5
    %endif
%endmacro


;
; Figures out the size of the compared values.
; Defines the single-line macro '%1' as: byte, word, dword, or qword.
;
;   @param out     name of the single-line macro to define
;   @param who     name of the assertion (for the error messages)
;   @param actual  the 'actual' operand
;   @param kind_a  its kind
;   @param other   the other operand
;   @param kind_b  its kind
;
%macro __t_scalar_size 6
    %ifidn %4, gpr
        %xdefine %1  @reg.size(%3)
    %elifidn %4, mem
        __t_mem_size %1, %3
        %ifidn %1, none
            ; The register on the other side knows the size
            %ifidn %6, gpr
                %xdefine %1  @reg.size(%5)
            %else
                %fatal "ASSERT_*: the size of the memory operand is unknown, write it explicitly: 'dword [value]'"
            %endif
        %endif
    %else
        %fatal "ASSERT_*: 'actual' value must be a general-purpose register or a memory operand"
    %endif

    ; Vector sizes are for the 'packed' assertions
    %if %isidn(%1, oword) | %isidn(%1, yword) | %isidn(%1, zword)
        %fatal "ASSERT_*: vector values are checked by the '*_PACKED' assertions"
    %endif
%endmacro


;
; Common implementation of the 'ASSERT_<CONDITION>' macros:
; compare 'actual' with 'expected', and if the condition doesn't hold - report the failure.
;
;   @param who         name of the assertion (for the error messages)
;   @param pass        condition code ('e', 'l', 'ae'...) of the jump to take when the assertion HOLDS
;   @param kind        TEST_FAILURE_*
;   @param actual      general-purpose register | memory
;   @param expected    general-purpose register | memory | immediate
;   @param description [optional] name of the value in the failure report
;
%macro __t_assert_scalar 5-6
    ; Assertions must work in Test Block only
    __t_assert_requirements %1

    __t_operand_kind %%kind_a, %4
    __t_operand_kind %%kind_b, %5

    ; Vector registers are not in our jurisdiction
    %if __t_is_vec_kind(%%kind_a) | __t_is_vec_kind(%%kind_b)
        %ifidn %1, ASSERT_EQUAL
            ASSERT_EQUAL_PACKED %{4:-1}
            %exitmacro    ; Stop the macro from unrolling
        %else
            %fatal "ASSERT_*: vector values are checked by the '*_PACKED' assertions"
        %endif
    %endif

    ; We can't compare two memory cells directly
    %if %isidn(%%kind_a, mem) & %isidn(%%kind_b, mem)
        %fatal "ASSERT_*: you can't compare two memory cells directly"
    %endif

    __t_scalar_size %%size, %1, %4, %%kind_a, %5, %%kind_b
    __t_describe %%desc, %6, %4

    cmp %4, %5
    j%2 %%passed    ; The condition holds

    ; Condition doesn't hold:
    ; Construct the 'TestFailure' object
    __t_fill_scalar_pair %4, %%kind_a, %5, %%kind_b, %%size

    ; Actual value doesn't satisfy the condition against the expected one
    __test_fail %3, __t_gp_type_%[%%size], %%desc

%%passed:
    %undef %%kind_a
    %undef %%kind_b
    %undef %%size
    %undef %%desc
%endmacro


%macro __t_assert_equal_gpr 3
    ; General-purpose register equality check
    cmp %1, %2
    je %%passed

    ; Wrong value:
    ; Construct the 'TestFailure' object
    mov [@failure.actual], %1
    mov %1, %2
    mov [@failure.expected], %1

    ; Actual register has different from expected value
    __test_fail TEST_FAILURE_EQUAL, @reg.type(%1), %3

%%passed:
%endmacro

%macro __t_assert_equal_mem 4
    ; Memory equality check
    cmp %1, %2
    je %%passed

    ; Wrong value:
    ; Construct the 'TestFailure' object
    mov %4, %1
    mov [@failure.actual], %4
    mov %4, %2
    mov [@failure.expected], %4

    ; Actual register has different from expected value
    __test_fail TEST_FAILURE_EQUAL, @reg.type(%4), %3

%%passed:
%endmacro


;
; Check that the values are equal / not equal.
; (vector registers are redirected to 'ASSERT_EQUAL_PACKED')
;
;   @param actual       general-purpose register | memory
;   @param expected     general-purpose register | memory | immediate
;   @param description  [optional] name of the value in the failure report
;
%macro ASSERT_EQUAL 2-3
    __t_assert_scalar ASSERT_EQUAL, e, TEST_FAILURE_EQUAL, %{1:-1}
%endmacro

%macro ASSERT_NOT_EQUAL 2-3
    __t_assert_scalar ASSERT_NOT_EQUAL, ne, TEST_FAILURE_NOT_EQUAL, %{1:-1}
%endmacro


; Signed comparison: 'actual' is less than / less than or equal to / greater than / greater than or equal to 'expected'

%macro ASSERT_LESS 2-3
    __t_assert_scalar ASSERT_LESS, l, TEST_FAILURE_LESS, %{1:-1}
%endmacro

%macro ASSERT_LESS_OR_EQUAL 2-3
    __t_assert_scalar ASSERT_LESS_OR_EQUAL, le, TEST_FAILURE_LESS_OR_EQUAL, %{1:-1}
%endmacro

%macro ASSERT_GREATER 2-3
    __t_assert_scalar ASSERT_GREATER, g, TEST_FAILURE_GREATER, %{1:-1}
%endmacro

%macro ASSERT_GREATER_OR_EQUAL 2-3
    __t_assert_scalar ASSERT_GREATER_OR_EQUAL, ge, TEST_FAILURE_GREATER_OR_EQUAL, %{1:-1}
%endmacro


; Unsigned comparison: 'actual' is below / below or equal to / above / above or equal to 'expected'

%macro ASSERT_BELOW 2-3
    __t_assert_scalar ASSERT_BELOW, b, TEST_FAILURE_BELOW, %{1:-1}
%endmacro

%macro ASSERT_BELOW_OR_EQUAL 2-3
    __t_assert_scalar ASSERT_BELOW_OR_EQUAL, be, TEST_FAILURE_BELOW_OR_EQUAL, %{1:-1}
%endmacro

%macro ASSERT_ABOVE 2-3
    __t_assert_scalar ASSERT_ABOVE, a, TEST_FAILURE_ABOVE, %{1:-1}
%endmacro

%macro ASSERT_ABOVE_OR_EQUAL 2-3
    __t_assert_scalar ASSERT_ABOVE_OR_EQUAL, ae, TEST_FAILURE_ABOVE_OR_EQUAL, %{1:-1}
%endmacro


;
; Common implementation of 'ASSERT_TRUE' & 'ASSERT_FALSE'.
; Failure holds the value in 'actual', and '1' (true) or '0' (false) in 'expected'.
;
;   @param who          name of the assertion (for the error messages)
;   @param pass         condition code of the jump to take when the assertion HOLDS: 'nz' for true, 'z' for false
;   @param expected     1 or 0
;   @param actual       general-purpose register | memory
;   @param description  [optional] name of the value in the failure report
;
%macro __t_assert_boolean 4-5
    ; Assertions must work in Test Block only
    __t_assert_requirements %1

    __t_operand_kind %%kind, %4

    %ifidn %%kind, gpr
        %xdefine %%size  @reg.size(%4)
    %elifidn %%kind, mem
        __t_mem_size %%size, %4
        %ifidn %%size, none
            %fatal "ASSERT_TRUE / ASSERT_FALSE: the size of the memory operand is unknown, write it explicitly: 'dword [value]'"
        %endif
    %else
        %fatal "ASSERT_TRUE / ASSERT_FALSE: expected a general-purpose register or a memory operand (vector values are not supported)"
    %endif

    %if %isidn(%%size, oword) | %isidn(%%size, yword) | %isidn(%%size, zword)
        %fatal "ASSERT_TRUE / ASSERT_FALSE: vector values are not supported"
    %endif

    __t_describe %%desc, %5, %4

    %ifidn %%kind, gpr
        test %4, %4
    %else
        cmp %4, 0
    %endif
    j%2 %%passed    ; The value is what it should be

    ; Value has a wrong boolean value:
    ; Construct the 'TestFailure' object
    mov qword [@failure.expected], %3
    __t_fill_scalar @failure.actual, %4, %%kind, %%size

    __test_fail TEST_FAILURE_BOOLEAN, __t_gp_type_%[%%size], %%desc

%%passed:
    %undef %%kind
    %undef %%size
    %undef %%desc
%endmacro


;
; Checks that the value is not zero.
;
;   @param actual       general-purpose register | memory
;   @param description  [optional] name of the value in the failure report
;
%macro ASSERT_TRUE 1-2
    __t_assert_boolean ASSERT_TRUE, nz, 1, %{1:-1}
%endmacro


;
; Checks that the value is zero.
;
;   @param actual       general-purpose register | memory
;   @param description  [optional] name of the value in the failure report
;
%macro ASSERT_FALSE 1-2
    __t_assert_boolean ASSERT_FALSE, z, 0, %{1:-1}
%endmacro


%endif; __TESTING_ASSERTIONS_ALIGNED_INCLUDE__
