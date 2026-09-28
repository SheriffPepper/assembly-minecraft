%ifndef __DEFINITIONS_INCLUDE__
%define __DEFINITIONS_INCLUDE__

%include "libs/core/module.inc"

; Standard definitions include file

null  equ 0
false equ 0
true  equ 1

; Sizes (in bytes)
 u8.size  equ  1
u16.size  equ  2
u32.size  equ  4
u64.size  equ  8

f32.size  equ  4
f64.size  equ  8

v128.size  equ  16
v256.size  equ  32
v512.size  equ  64

 u8.size#bytes  equ  u8.size
u16.size#bytes  equ  u16.size
u32.size#bytes  equ  u32.size
u64.size#bytes  equ  u64.size

f32.size#bytes  equ  f32.size
f64.size#bytes  equ  f64.size

v128.size#bytes  equ  v128.size
v256.size#bytes  equ  v256.size

 u8.size#bits  equ   u8.size#bytes << 3
u16.size#bits  equ  u16.size#bytes << 3
u32.size#bits  equ  u32.size#bytes << 3
u64.size#bits  equ  u64.size#bytes << 3

f32.size#bits  equ  f32.size#bytes << 3
f64.size#bits  equ  f64.size#bytes << 3

v128.size#bits  equ  v128.size#bytes << 3
v256.size#bits  equ  v256.size#bytes << 3


 byte@size equ 1
 word@size equ 2
dword@size equ 4
qword@size equ 8

float@size  equ 4
double@size equ 8

pointer@size equ 8  ; x64 -> 64-bits (8 bytes)

; Max buffer sizes for number representations
 u8.MAX_BUFFER_SIZE#hex  equ  2
u16.MAX_BUFFER_SIZE#hex  equ  4
u32.MAX_BUFFER_SIZE#hex  equ  8
u64.MAX_BUFFER_SIZE#hex  equ  16

; Architecture is officially not 'x64'
%ifndef x64
    %error "This code supports only 'x64' architecture, please use different files to compile the project, or pass the '-Dx64' definition to NASM"
%endif


;
; Defines the name of the current Module
;
%imacro module 1
    __create_module _, %1
%endmacro


%endif; __DEFINITIONS_INCLUDE__
