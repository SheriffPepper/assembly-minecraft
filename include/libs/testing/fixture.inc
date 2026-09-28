%ifndef __TESTING_FIXTURE_INCLUDE__
%define __TESTING_FIXTURE_INCLUDE__

%define @fixture.current        @fixture(@module.name, __TEST_NAME__)
%define @fixture(test)          @fixture(@module.name, test)
%define @fixture(module, test)  @testblock(module, test)%+@context

%define @fixture.failure  @fixture.current%+.failure
%define @fixture.regs     @fixture.current%+.regs
%define @fixture.scratch  @fixture.current%+.scratch

%define @reg(reg)       @fixture.regs + __regs.%+reg
;%define @reg.name(reg)  __REGISTER_%+reg%+@name

%assign __TEMP_COUNTER__  0
%macro __assign_gp_reg 1+
    %rep %0
        __regs.%1  equ  __TEMP_COUNTER__
        %rotate 1
    %endrep

    %assign __TEMP_COUNTER__  __TEMP_COUNTER__ + 8
%endmacro
%macro __assign_vec_reg 1+
    %rep %0
        __regs.%1  equ  __TEMP_COUNTER__
        %rotate 1
    %endrep

    %assign __TEMP_COUNTER__  __TEMP_COUNTER__ + 32
%endmacro

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

__assign_vec_reg xmm0,  ymm0
__assign_vec_reg xmm1,  ymm1
__assign_vec_reg xmm2,  ymm2
__assign_vec_reg xmm3,  ymm3
__assign_vec_reg xmm4,  ymm4
__assign_vec_reg xmm5,  ymm5
__assign_vec_reg xmm6,  ymm6
__assign_vec_reg xmm7,  ymm7
__assign_vec_reg xmm8,  ymm8
__assign_vec_reg xmm9,  ymm9
__assign_vec_reg xmm10, ymm10
__assign_vec_reg xmm11, ymm11
__assign_vec_reg xmm12, ymm12
__assign_vec_reg xmm13, ymm13
__assign_vec_reg xmm14, ymm14
__assign_vec_reg xmm15, ymm15

%assign __REGS_TOTAL_SIZE  __TEMP_COUNTER__
%undef __TEMP_COUNTER__


%endif; __TESTING_FIXTURE_INCLUDE__
