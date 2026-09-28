%ifndef __TEST_ASSERTIONS_INCLUDE__
%define __TEST_ASSERTIONS_INCLUDE__

%include "tests/framework.inc"

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

%imacro ASSERT_PRESERVED_STACK 0

%endmacro


%imacro ASSERT_RESERVED_REG 1-2
%endmacro


%imacro ASSERT_EQUAL 2-3
%endmacro


%imacro ASSERT_EQUAL_PACKED 2-3
%endmacro


%endif; __TEST_ASSERTIONS_INCLUDE__
