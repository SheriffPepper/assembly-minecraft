%ifndef __TESTING_FAILURE_INCLUDE__
%define __TESTING_FAILURE_INCLUDE__

%include "definitions.inc"


struc TestFailure
    align 32
    %define TestFailure.value  TestFailure.actual
    .actual:            resq  4    ; Raw bytes of the value that was produced
    .expected:          resq  4    ; Raw bytes of the value that was expected
    .value.name:        resq  1    ; Pointer to a human-readable name for the value
    .value.type:        resq  1    ; TEST_VALUE_TYPE_* – how to interpret .actual/.expected
    .case.description:  resq  1    ; Description of the CASE that failed
    .kind:              resd  1    ; TEST_FAIL_* – what kind of check failed
    .case:              resd  1    ; CASE number that failed
endstruc


%define __gp_type(type)              type%+.size#bytes
%define __vec_type_u(type, element)  type%+.size#bytes + (element%+.size#bytes << u8.size#bits)
%define __vec_type_f(type, element)  type%+.size#bytes + (((1 << 7) | element%+.size#bytes) << u8.size#bits)

TEST_VALUE_TYPE_GP.u64  equ  __gp_type(u64)    ; General-purpose register, 64-bits (8 bytes)
TEST_VALUE_TYPE_GP.u32  equ  __gp_type(u32)    ; General-purpose register, 32-bits (4 bytes)
TEST_VALUE_TYPE_GP.u16  equ  __gp_type(u16)    ; General-purpose register, 16-bits (2 bytes)
TEST_VALUE_TYPE_GP.u8   equ  __gp_type( u8)    ; General-purpose register,  8-bits (1 bytes)

TEST_VALUE_TYPE_VECTOR.v128.u64  equ  __vec_type_u(v128, u64)
TEST_VALUE_TYPE_VECTOR.v128.u32  equ  __vec_type_u(v128, u32)
TEST_VALUE_TYPE_VECTOR.v128.u16  equ  __vec_type_u(v128, u16)
TEST_VALUE_TYPE_VECTOR.v128.u8   equ  __vec_type_u(v128, u8)
TEST_VALUE_TYPE_VECTOR.v128.f32  equ  __vec_type_u(v128, f32)
TEST_VALUE_TYPE_VECTOR.v128.f64  equ  __vec_type_f(v128, f64)

TEST_VALUE_TYPE_VECTOR.v256.u64  equ  __vec_type_u(v256, u64)
TEST_VALUE_TYPE_VECTOR.v256.u32  equ  __vec_type_u(v256, u32)
TEST_VALUE_TYPE_VECTOR.v256.u16  equ  __vec_type_u(v256, u16)
TEST_VALUE_TYPE_VECTOR.v256.u8   equ  __vec_type_u(v256, u8)
TEST_VALUE_TYPE_VECTOR.v256.f32  equ  __vec_type_f(v256, f32)
TEST_VALUE_TYPE_VECTOR.v256.f64  equ  __vec_type_f(v256, f64)

TEST_VALUE_TYPE_VECTOR.v512.u64  equ  __vec_type_u(v512, u64)
TEST_VALUE_TYPE_VECTOR.v512.u32  equ  __vec_type_u(v512, u32)
TEST_VALUE_TYPE_VECTOR.v512.u16  equ  __vec_type_u(v512, u16)
TEST_VALUE_TYPE_VECTOR.v512.u8   equ  __vec_type_u(v512, u8)
TEST_VALUE_TYPE_VECTOR.v512.f32  equ  __vec_type_f(v512, f32)
TEST_VALUE_TYPE_VECTOR.v512.f64  equ  __vec_type_f(v512, f64)


%define __get_reg_type_rax  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_eax  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_ax   TEST_VALUE_TYPE_GP.u16
%define __get_reg_type_al   TEST_VALUE_TYPE_GP.u8

%define __get_reg_type_rbx  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_ebx  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_bx   TEST_VALUE_TYPE_GP.u16
%define __get_reg_type_bl   TEST_VALUE_TYPE_GP.u8

%define __get_reg_type_rcx  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_ecx  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_cx   TEST_VALUE_TYPE_GP.u16
%define __get_reg_type_cl   TEST_VALUE_TYPE_GP.u8

%define __get_reg_type_rdx  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_edx  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_dx   TEST_VALUE_TYPE_GP.u16
%define __get_reg_type_dl   TEST_VALUE_TYPE_GP.u8

%define __get_reg_type_rsi  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_esi  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_si   TEST_VALUE_TYPE_GP.u16
%define __get_reg_type_sil  TEST_VALUE_TYPE_GP.u8

%define __get_reg_type_rdi  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_edi  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_di   TEST_VALUE_TYPE_GP.u16
%define __get_reg_type_dil  TEST_VALUE_TYPE_GP.u8

%define __get_reg_type_rbp  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_ebp  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_bp   TEST_VALUE_TYPE_GP.u16

%define __get_reg_type_rsp  TEST_VALUE_TYPE_GP.u64
%define __get_reg_type_esp  TEST_VALUE_TYPE_GP.u32
%define __get_reg_type_sp   TEST_VALUE_TYPE_GP.u16

%assign __GP_REG_NUMBER__  8
%rep 8
    %define __get_reg_type_r%[__VECTOR_REG_NUMBER__]   TEST_VALUE_TYPE_GP.u64
    %define __get_reg_type_r%[__VECTOR_REG_NUMBER__]d  TEST_VALUE_TYPE_GP.u32
    %define __get_reg_type_r%[__VECTOR_REG_NUMBER__]w  TEST_VALUE_TYPE_GP.u16
    %define __get_reg_type_r%[__VECTOR_REG_NUMBER__]b  TEST_VALUE_TYPE_GP.u8

    %assign __GP_REG_NUMBER__  __GP_REG_NUMBER__ + 1
%endrep
%undef  __GP_REG_NUMBER__

%assign __VECTOR_REG_NUMBER__  0
%rep 15
    %define __get_reg_type_xmm%[__VECTOR_REG_NUMBER__]  TEST_VALUE_TYPE_VECTOR.v128
    %define __get_reg_type_ymm%[__VECTOR_REG_NUMBER__]  TEST_VALUE_TYPE_VECTOR.v256
    %define __get_reg_type_zmm%[__VECTOR_REG_NUMBER__]  TEST_VALUE_TYPE_VECTOR.v512

    %assign __VECTOR_REG_NUMBER__  __VECTOR_REG_NUMBER__ + 1
%endrep
%undef  __VECTOR_REG_NUMBER__

%define @reg.type(reg)  __get_reg_type%+reg


%endif; __TESTING_FAILURE_INCLUDE__
