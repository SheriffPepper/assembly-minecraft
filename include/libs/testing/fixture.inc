%ifndef __TESTING_FIXTURE_INCLUDE__
%define __TESTING_FIXTURE_INCLUDE__


%define @fixture.current        @fixture(__TEST_MODULE_NAME__, __TEST_NAME__)
%define @fixture(test)          @fixture(__TEST_MODULE_NAME__, test)
%define @fixture(module, test)  @testblock(module, test)%+@context

%define @fixture.failure  @fixture.current%+.failure
%define @fixture.regs     @fixture.current%+.regs
%define @fixture.scratch  @fixture.current%+.scratch

FIXTURE_SCRATCH_SIZE  equ  256

%define @reg(reg)  @fixture.regs + __regs.%+reg


%macro __assign_gp_reg 1-*
    %rep %0
        __regs.%1  equ  %[__TEMP_REG_COUNTER__]
        %rotate 1
    %endrep

    %assign __TEMP_REG_COUNTER__  __TEMP_REG_COUNTER__ + 8
%endmacro

%assign __TEMP_REG_COUNTER__  0

%assign __TEMP_REG_NUMBER__  0
%rep 16
    __regs.zmm%[__TEMP_REG_NUMBER__]  equ  __TEMP_REG_COUNTER__
    __regs.ymm%[__TEMP_REG_NUMBER__]  equ  __TEMP_REG_COUNTER__
    __regs.xmm%[__TEMP_REG_NUMBER__]  equ  __TEMP_REG_COUNTER__

    %assign __TEMP_REG_COUNTER__  __TEMP_REG_COUNTER__ + 64
    %assign __TEMP_REG_NUMBER__   __TEMP_REG_NUMBER__  + 1
%endrep
%undef  __TEMP_REG_NUMBER__

__assign_gp_reg rax, eax, ax, al
__assign_gp_reg rbx, ebx, bx, bl
__assign_gp_reg rcx, ecx, cx, cl
__assign_gp_reg rdx, edx, dx, dl
__assign_gp_reg rsi, esi, si, sil
__assign_gp_reg rdi, edi, di, dil
__assign_gp_reg rbp, ebp, bp
__assign_gp_reg rsp, esp, sp
__assign_gp_reg r8,  r8d,  r8w,  r8b
__assign_gp_reg r9,  r9d,  r9w,  r9b
__assign_gp_reg r10, r10d, r10w, r10b
__assign_gp_reg r11, r11d, r11w, r11b
__assign_gp_reg r12, r12d, r12w, r12b
__assign_gp_reg r13, r13d, r13w, r13b
__assign_gp_reg r14, r14d, r14w, r14b
__assign_gp_reg r15, r15d, r15w, r15b

%assign __regs.size  __TEMP_REG_COUNTER__


%endif; __TESTING_FIXTURE_INCLUDE__
