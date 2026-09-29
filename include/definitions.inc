%ifndef __DEFINITIONS_INCLUDE__
%define __DEFINITIONS_INCLUDE__

%ifdef LIBRARY
    %include "core/module.inc"
%else
    %include "libs/core/module.inc"
%endif

; Standard definitions include file

null  equ 0
false equ 0
true  equ 1

; Sizes (in bytes)
%define u8   byte
%define u16  word
%define u32  dword
%define u64  qword

%define f32  dword
%define f64  qword

%define v128  oword
%define v256  yword
%define v512  zword

%define xmmword  oword
%define ymmword  yword
%define zmmword  zword


 u8.size#bytes  equ  1
u16.size#bytes  equ  2
u32.size#bytes  equ  4
u64.size#bytes  equ  8

f32.size#bytes  equ  4
f64.size#bytes  equ  8

v128.size#bytes  equ  16
v256.size#bytes  equ  32
v512.size#bytes  equ  64


 u8.size#bits  equ   u8.size#bytes << 3
u16.size#bits  equ  u16.size#bytes << 3
u32.size#bits  equ  u32.size#bytes << 3
u64.size#bits  equ  u64.size#bytes << 3

f32.size#bits  equ  f32.size#bytes << 3
f64.size#bits  equ  f64.size#bytes << 3

v128.size#bits  equ  v128.size#bytes << 3
v256.size#bits  equ  v256.size#bytes << 3
v512.size#bits  equ  v512.size#bytes << 3

 byte.size equ 1
 word.size equ 2
dword.size equ 4
qword.size equ 8

float.size  equ 4
double.size equ 8

pointer.size equ 8  ; x64 -> 64-bits (8 bytes)

; Max buffer sizes for number representations
 u8.MAX_BUFFER_SIZE#hex  equ  2
u16.MAX_BUFFER_SIZE#hex  equ  4
u32.MAX_BUFFER_SIZE#hex  equ  8
u64.MAX_BUFFER_SIZE#hex  equ  16

; Architecture is officially not 'x64'
%ifndef x64
    %error "This code supports only 'x64' architecture, please use different files to compile the project, or pass the '-Dx64' definition to NASM"
%endif


%endif; __DEFINITIONS_INCLUDE__
