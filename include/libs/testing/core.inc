%ifndef __TESTING_CORE_INCLUDE__
%define __TESTING_CORE_INCLUDE__


;
; Establishes the current test module context and assigns the module name for logging.
; We can define the Test Module as many times as we like in one file,
; and even scatter them across different files.
; To open the Test Module namespace in a different file use "test_module_defined" macro.
;
%imacro test_module 1
    __create_module _TEST_, %1

    ; Create the Test Module name as a string you can use later
    %defstr %%namestr  %1
        @string @test_module.name, %%namestr
        global @test_module.name    ; Export the name for global use
    %undef  %%namestr
%endmacro


%define @testblock.current        @testblock(@module.name, __TEST_NAME__)
%define @testblock(test)          @testblock(@module.name, test)
%define @testblock(module, test)  module%+.%+test

%define @testcase.current              @testcase(@module.name, __TEST_NAME__, %$__CASE_NUMBER__)
%define @testcase(case)                @testcase(@module.name, __TEST_NAME__, case)
%define @testcase(test, case)          @testcase(@module.name, test, case)
%define @testcase(module, test, case)  @testblock(module, test)%+@case_%+case

%define @testblock.name         @testblock.current%+.name
%define @testblock.description  @testblock.current%+.description

%define @testcase.description  @testcase.current%+.description

%define __get_param0(name)  name
%define __get_param1(name)  @testcase.current%+.%+name

%define @check(name)    @param(name)
%define @correct(name)  @param(name)
%define @param(name)    __get_param%isctx(__test_block__)(name)


; TEST <TEST-NAME>, <TEST-DESCRIPTION>, <CASE-NUMBER>
%imacro TEST 3
    TEST %1, %2, %3, %1
%endmacro

; TEST <TEST-NAME>, <TEST-DESCRIPTION>, <CASE-NUMBER>, <FEATURE-NAME>
%imacro TEST 4
    ; There's no Testing Module defined yet
    %defstr %%__TEMP_MODULE_TYPE__  %[@module.type]
    %if %%__TEMP_MODULE_TYPE__ != "_TEST_"
        %fatal "Test Block is defined outside the Test Module! Did you forget 'test_module <module>'?"
    ; Test Block was already assigned
    %elifctx __test_block__
        %fatal "Test Blocks cannot nest! Did you forget 'ENDTEST'?"
    %endif
    %undef  %%__TEMP_MODULE_TYPE__

    ; Create Test Block on the context stack
    %push __test_block__

    ; Save Test Block data
    %define __TEST_NAME__  %1

    %assign %$__CASES_TOTAL__  %3
    %assign %$__CASE_NUMBER__  0

    ; Save strings for the logging purposes
    %defstr %$__TEMP_STRING_TEST_NAME__  %[__TEST_NAME__]
    %ifstr %2
        %define %$__TEMP_STRING_TEST_DESC__  %2
    %else
        %defstr %$__TEMP_STRING_TEST_DESC__  %2
    %endif

        @string @testblock.name,        %$__TEMP_STRING_TEST_NAME__
        @string @testblock.description, %$__TEMP_STRING_TEST_DESC__

    %undef  %$__TEMP_STRING_TEST_DESC__
    %undef  %$__TEMP_STRING_TEST_NAME__

    ; Per-Test-Block scratch: a TestFailure slot + saved-register area.
    [section .bss]
        alignb 32    ; 32-byte alignment for ymm-register fast saves
        @fixture.current:
            @fixture.failure:  resb  TestFailure_size     ; Fixture Test Failure structure
            alignb 32
            @fixture.regs:     resb  __REGS_TOTAL_SIZE    ; Fixture register saving space
            alignb 64
            @fixture.scratch:  resb  256                  ; Fixture 256-byte scratch space
    [section .text]    ;__?SECT?__

    ; Create the label for the Test Block
    @testblock.current:
%endmacro


%imacro CASE 1
    ; 'CASE' used without Test Block
    %ifnctx __test_block__
        %fatal "Test Block 'CASE' directive cannot be used outside the Test Block!"
    %endif

    ; Increment the local 'CASE_NUMBER' counter
    ; Now it's the current index of the Test Block 'CASE' directive
    %assign %$__CASE_NUMBER__  %$__CASE_NUMBER__ + 1

    ; Save the 'CASE' description for the logging purposes
    @string @testcase.description, %1

    ; Create the label for the Test Block case
    @testcase.current:
%endmacro


%imacro ENDTEST 0
    ; 'ENDTEST' is used without Test Block
    %ifnctx __test_block__
        %fatal "Orphaned 'ENDTEST' directive! Did you forget matching 'TEST'?"
    %elif %$__CASE_NUMBER__ != %$__CASES_TOTAL__
        %fatal "The total amount of cases for the Test Block is wrong!"
    %endif

    ; Test Block's epilogue
        xor eax, eax    ; 0 = every CASE passed

    @testblock.current%+@failed:
        ret    ; On the failure path the eax, is left holding the CASE number that failed

    ; Clean the Test Block data
    %undef __TEST_NAME__

    %undef %$__CASES_TOTAL__
    %undef %$__CASE_NUMBER__

    ; Close the Test Block
    %pop __test_block__
%endmacro


%endif; __TESTING_CORE_INCLUDE__
