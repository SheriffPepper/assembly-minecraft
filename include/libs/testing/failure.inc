%ifndef __TESTING_FAILURE_INCLUDE__
%define __TESTING_FAILURE_INCLUDE__

%include "definitions.inc"


struc TestFailure
    align 64    ; Align for quick ZMM-register saves
    %define TestFailure.value  TestFailure.actual
    .actual:            resq  8    ; Raw bytes of the value that was produced
    .expected:          resq  8    ; Raw bytes of the value that was expected
    .value.name:        resq  1    ; Pointer to a human-readable name for the value
    .case.description:  resq  1    ; Description of the CASE that failed
    .value.type:        resd  1    ; TEST_VALUE_TYPE_* – how to interpret .actual/.expected
    .kind:              resd  1    ; TEST_FAIL_* – what kind of check failed
    .case:              resd  1    ; CASE number that failed
endstruc

%define @failure.actual    @fixture.failure + TestFailure.actual
%define @failure.expected  @fixture.failure + TestFailure.expected


TEST_FAILURE_ALIGNED    equ  0    ; Some pointer was not aligned properly
TEST_FAILURE_PRESERVED  equ  1    ; Some value was not preserved
TEST_FAILURE_BOOLEAN    equ  2    ; Value has wrong boolean value
TEST_FAILURE_EQUAL      equ  3    ; Value is not equal to another value
TEST_FAILURE_NOT_EQUAL  equ  4    ; Value is equal to something it shouldn't be


%define __gp_type(size)              size%+#bytes
%define __vec_type_u(size, element)  size%+#bytes + (element%+#bytes << u8.size#bits)
%define __vec_type_f(size, element)  size%+#bytes + ((element%+#bytes | (1 << 7)) << u8.size#bits)

TEST_VALUE_TYPE_GP.u8   equ  __gp_type( u8.size)    ; General-Purpose register,  8-bits (1 bytes)
TEST_VALUE_TYPE_GP.u16  equ  __gp_type(u16.size)    ; General-Purpose register, 16-bits (2 bytes)
TEST_VALUE_TYPE_GP.u32  equ  __gp_type(u32.size)    ; General-Purpose register, 32-bits (4 bytes)
TEST_VALUE_TYPE_GP.u64  equ  __gp_type(u64.size)    ; General-Purpose register, 64-bits (8 bytes)

TEST_VALUE_TYPE_VEC.v128  equ  __gp_type(v128.size)
TEST_VALUE_TYPE_VEC.v256  equ  __gp_type(v256.size)
TEST_VALUE_TYPE_VEC.v512  equ  __gp_type(v512.size)

TEST_VALUE_TYPE_VEC.v128.u8   equ  __vec_type_u(v128.size,  u8.size)
TEST_VALUE_TYPE_VEC.v128.u16  equ  __vec_type_u(v128.size, u16.size)
TEST_VALUE_TYPE_VEC.v128.u32  equ  __vec_type_u(v128.size, u32.size)
TEST_VALUE_TYPE_VEC.v128.u64  equ  __vec_type_u(v128.size, u64.size)

TEST_VALUE_TYPE_VEC.v128.f32  equ  __vec_type_f(v128.size, f32.size)
TEST_VALUE_TYPE_VEC.v128.f64  equ  __vec_type_f(v128.size, f64.size)

TEST_VALUE_TYPE_VEC.v256.u8   equ  __vec_type_u(v256.size,  u8.size)
TEST_VALUE_TYPE_VEC.v256.u16  equ  __vec_type_u(v256.size, u16.size)
TEST_VALUE_TYPE_VEC.v256.u32  equ  __vec_type_u(v256.size, u32.size)
TEST_VALUE_TYPE_VEC.v256.u64  equ  __vec_type_u(v256.size, u64.size)

TEST_VALUE_TYPE_VEC.v256.f32  equ  __vec_type_f(v256.size, f32.size)
TEST_VALUE_TYPE_VEC.v256.f64  equ  __vec_type_f(v256.size, f64.size)

TEST_VALUE_TYPE_VEC.v512.u8   equ  __vec_type_u(v512.size,  u8.size)
TEST_VALUE_TYPE_VEC.v512.u16  equ  __vec_type_u(v512.size, u16.size)
TEST_VALUE_TYPE_VEC.v512.u32  equ  __vec_type_u(v512.size, u32.size)
TEST_VALUE_TYPE_VEC.v512.u64  equ  __vec_type_u(v512.size, u64.size)

TEST_VALUE_TYPE_VEC.v512.f32  equ  __vec_type_f(v512.size, f32.size)
TEST_VALUE_TYPE_VEC.v512.f64  equ  __vec_type_f(v512.size, f64.size)

%define TEST_VALUE_TYPE.get_size(type)  (type & 0xFF)


%macro __get_types_u64 1-*
    %rep %0
        %define __get_type_%1  TEST_VALUE_TYPE_GP.u64
        %define __get_size_%1  qword

        %define __is_vec_%1  0
        %define __is_xmm_%1  0
        %define __is_ymm_%1  0
        %define __is_zmm_%1  0

        %rotate 1
    %endrep
%endmacro

%macro __get_types_u32 1-*
    %rep %0
        %define __get_type_%1  TEST_VALUE_TYPE_GP.u32
        %define __get_size_%1  dword

        %define __is_vec_%1  0
        %define __is_xmm_%1  0
        %define __is_ymm_%1  0
        %define __is_zmm_%1  0

        %rotate 1
    %endrep
%endmacro

%macro __get_types_u16 1-*
    %rep %0
        %define __get_type_%1  TEST_VALUE_TYPE_GP.u16
        %define __get_size_%1  word

        %define __is_vec_%1  0
        %define __is_xmm_%1  0
        %define __is_ymm_%1  0
        %define __is_zmm_%1  0

        %rotate 1
    %endrep
%endmacro

%macro __get_types_u8 1-*
    %rep %0
        %define __get_type_%1  TEST_VALUE_TYPE_GP.u8
        %define __get_size_%1  byte

        %define __is_vec_%1  0
        %define __is_xmm_%1  0
        %define __is_ymm_%1  0
        %define __is_zmm_%1  0

        %rotate 1
    %endrep
%endmacro

%macro __get_types_vec 0
    %assign __VECTOR_REG_NUMBER__  0
    %rep 16
        %define __get_type_xmm%[__VECTOR_REG_NUMBER__]  TEST_VALUE_TYPE_VEC.v128
        %define __get_type_ymm%[__VECTOR_REG_NUMBER__]  TEST_VALUE_TYPE_VEC.v256
        %define __get_type_zmm%[__VECTOR_REG_NUMBER__]  TEST_VALUE_TYPE_VEC.v512

        %define __get_size_xmm%[__VECTOR_REG_NUMBER__]  oword
        %define __get_size_ymm%[__VECTOR_REG_NUMBER__]  yword
        %define __get_size_zmm%[__VECTOR_REG_NUMBER__]  zword

        %define __get_xmm_xmm%[__VECTOR_REG_NUMBER__]  xmm%[__VECTOR_REG_NUMBER__]
        %define __get_ymm_xmm%[__VECTOR_REG_NUMBER__]  ymm%[__VECTOR_REG_NUMBER__]
        %define __get_zmm_xmm%[__VECTOR_REG_NUMBER__]  zmm%[__VECTOR_REG_NUMBER__]

        %define __get_xmm_ymm%[__VECTOR_REG_NUMBER__]  xmm%[__VECTOR_REG_NUMBER__]
        %define __get_ymm_ymm%[__VECTOR_REG_NUMBER__]  ymm%[__VECTOR_REG_NUMBER__]
        %define __get_zmm_ymm%[__VECTOR_REG_NUMBER__]  zmm%[__VECTOR_REG_NUMBER__]

        %define __get_xmm_zmm%[__VECTOR_REG_NUMBER__]  xmm%[__VECTOR_REG_NUMBER__]
        %define __get_ymm_zmm%[__VECTOR_REG_NUMBER__]  ymm%[__VECTOR_REG_NUMBER__]
        %define __get_zmm_zmm%[__VECTOR_REG_NUMBER__]  zmm%[__VECTOR_REG_NUMBER__]

        %define __is_vec_xmm%[__VECTOR_REG_NUMBER__]  1
        %define __is_vec_ymm%[__VECTOR_REG_NUMBER__]  1
        %define __is_vec_zmm%[__VECTOR_REG_NUMBER__]  1

        %define __is_xmm_xmm%[__VECTOR_REG_NUMBER__]  1
        %define __is_xmm_ymm%[__VECTOR_REG_NUMBER__]  0
        %define __is_xmm_zmm%[__VECTOR_REG_NUMBER__]  0

        %define __is_ymm_xmm%[__VECTOR_REG_NUMBER__]  0
        %define __is_ymm_ymm%[__VECTOR_REG_NUMBER__]  1
        %define __is_ymm_zmm%[__VECTOR_REG_NUMBER__]  0

        %define __is_zmm_xmm%[__VECTOR_REG_NUMBER__]  0
        %define __is_zmm_ymm%[__VECTOR_REG_NUMBER__]  0
        %define __is_zmm_zmm%[__VECTOR_REG_NUMBER__]  1

        %assign __VECTOR_REG_NUMBER__  __VECTOR_REG_NUMBER__ + 1
    %endrep
    %undef  __VECTOR_REG_NUMBER__
%endmacro


__get_types_u64 rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp,  r8,  r9,  r10,  r11,  r12,  r13,  r14,  r15
__get_types_u32 eax, ebx, ecx, edx, esi, edi, ebp, esp, r8d, r9d, r10d, r11d, r12d, r13d, r14d, r15d
__get_types_u16  ax,  bx,  cx,  dx,  si,  di,  bp,  sp, r8w, r9w, r10w, r11w, r12w, r13w, r14w, r15w
__get_types_u8   al,  bl,  cl,  dl, sil, dil,           r8b, r9b, r10b, r11b, r12b, r13b, r14b, r15b

__get_types_vec


%define @reg.type(reg)  __get_type_%+reg
%define @reg.size(reg)  __get_size_%+reg

%define @reg.is_vec(reg)  __is_vec_%+reg
%define @reg.is_xmm(reg)  __is_xmm_%+reg
%define @reg.is_ymm(reg)  __is_ymm_%+reg
%define @reg.is_zmm(reg)  __is_zmm_%+reg

%define @reg.get_xmm(reg)  __get_xmm_%+reg
%define @reg.get_ymm(reg)  __get_ymm_%+reg
%define @reg.get_zmm(reg)  __get_zmm_%+reg


%endif; __TESTING_FAILURE_INCLUDE__
