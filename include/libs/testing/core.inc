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
        @string @module.name%+.name, %%namestr
        global  @module.name%+.name    ; Export the name for global use
    %undef  %%namestr
%endmacro


%imacro test_module 1
    __create_module _TEST_, %1

    ; Create the Test Module name as a string you can use later
    %defstr %%namestr  %1
        @string %[@module.name]@name, %%namestr
        global  %[@module.name]@name    ; Export the name for global use
    %undef  %%namestr
%endmacro


%define @testblock.current        @testblock(__TEST_MODULE_NAME__, __TEST_NAME__)
%define @testblock(test)          @testblock(__TEST_MODULE_NAME__, test)
%define @testblock(module, test)  module%+.%+test

%define @testblock.name         @testblock.current%+.name
%define @testblock.description  @testblock.current%+.description
%define @testblock.cases        @testblock.current%+.cases


%define @testcase.current              @testcase(__TEST_MODULE_NAME__, __TEST_NAME__, %$__CASE_NUMBER__)
%define @testcase(case)                @testcase(__TEST_MODULE_NAME__, __TEST_NAME__, case)
%define @testcase(test, case)          @testcase(__TEST_MODULE_NAME__, test, case)
%define @testcase(module, test, case)  @testblock(module, test)%+@case_%+case

%define @testcase.description  @testcase.current%+.description

%define __get_param0(name)  name
%define __get_param1(name)  @testcase.current%+.%+name

%define @check(name)    @param(name)
%define @correct(name)  @param(name)
%define @param(name)    __get_param%isctx(__test_block__)(name)


%macro TEST 3
    TEST %1, %2, %3, %1
%endmacro


; TEST <TEST-NAME>, <TEST-DESCRIPTION>, <CASE-NUMBER>, <FEATURE-NAME>
%macro TEST 4
    ; There's no Testing Module defined yet
    %defstr %%__TEMP_MODULE_TYPE__  %[@module.type]
    %if %%__TEMP_MODULE_TYPE__ != "_TEST_"
        %fatal "Test Block is defined outside the Test Module! Did you forget 'test_module <MODULE>'?"
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

        @string  @testcase.description, "Test root"

        @string     @testblock.name,        %$__TEMP_STRING_TEST_NAME__
        @string     @testblock.description, %$__TEMP_STRING_TEST_DESC__
        @const.u32  @testblock.cases,       %$__CASES_TOTAL__

    %undef  %$__TEMP_STRING_TEST_NAME__
    %undef  %$__TEMP_STRING_TEST_DESC__

    ; Per-Test-Block scratch: a TestFailure slot + saved-register area
    @section.bss
        alignb 64    ; 64-byte alignment for zmm-register fast saves
        @fixture.current:
            alignb 64
            @fixture.regs:     resb  __regs.size
            alignb 64
            @fixture.failure:  resb  TestFailure_size
            alignb 64
            @fixture.scratch:  resb  FIXTURE_SCRATCH_SIZE
    @section.return

    ; Create the label for the Test Block
    @testblock.current:
%endmacro


%macro CASE 1
    ; 'CASE' is used without Test Block
    %ifnctx __test_block__
        %fatal "Test Block 'CASE' directive cannot be used outside the Test Block! Did you forget 'TEST'?"
    %endif

    ; Increment the local 'CASE_NUMBER' counter
    ; Now it's the current index of the Test Block 'CASE' directive
    %assign %$__CASE_NUMBER__  %$__CASE_NUMBER__ + 1

    ; Save the 'CASE' description for the logging purposes
    @string  @testcase.description, %1

    ; ; Create the label for the Test Block case
    ; @testcase.current:
    ; We actually never use the CASE label directly
    ; So, some could argue whether to add the label or not
%endmacro


%macro ENDTEST 0
    ; 'ENDTEST' is used without Test Block
    %ifnctx __test_block__
        %fatal "Orphaned 'ENDTEST' directive! Did you forget matching 'TEST'?"
    %elif %$__CASE_NUMBER__ != %$__CASES_TOTAL__
        %fatal "The total amount of cases for the Test Block is wrong!"
    %endif

    ; Test Block's epilogue
        xor eax, eax    ; 0 = every CASE passed

    @testblock.current%+#failed:
        ret    ; On the failure path the 'eax' is left holding the pointer to the TestFailure structure

    ; Clean Test Block data
    %undef __TEST_NAME__

    %undef %$__CASES_TOTAL__
    %undef %$__CASE_NUMBER__

    ; Close the Test Block
    %pop __test_block__
%endmacro


%macro PRESERVE_REGISTER 1
    ; Register preservation goes into test fixture
    %ifnctx __test_block__
        %fatal "There's no fixture found! Did you forget 'TEST' for Test Block?"
    %endif

    ; We might want to zero-extend the memory to preserve register values,
    ; But since we're gonna use the same size anyways, we may just wave the hand at it
    ; If you preserve 'xmm0' and then try and check the preservation of 'zmm0',
    ; It's logical error, please reconsider your life choices...
    %ifn @reg.is_vec(%1)
        ; General-purpose registers
        mov [@reg(%1)], %1
    %else
        ; Vector registers
        vmovaps [@reg(%1)], %1
    %endif
%endmacro


%macro PRESERVE_REGISTERS 1-*
    %rep %0
        PRESERVE_REGISTER %1
        %rotate 1
    %endrep
%endmacro


%macro PRESERVE_STACK 0
    PRESERVE_REGISTERS rsp, rbp
%endmacro


%endif; __TESTING_CORE_INCLUDE__
