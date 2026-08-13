%ifndef DEFINITIONS_INCLUDE
%define DEFINITIONS_INCLUDE

; Standard definitions include file

null  equ 0
false equ 0
true  equ 1

; Sizes (in bytes)
 byte@size equ 1
 word@size equ 2
dword@size equ 4
qword@size equ 8

float@size  equ 4
double@size equ 8

pointer@size equ 8  ; x64 -> 64-bits (8 bytes)

; Architecture is officially not 'x64'
%ifndef x64
    %error "This code supports only 'x64' architecture, please use different files to compile the project, or pass the '-Dx64' definition to NASM"
%endif

; Include-files logic

;
; Defines the name of the current Module
;
%macro module 1
    %define MODULE_NAME %1
%endmacro

;
; Defines the label as "external" if the "implementation identifier" wasn't present,
; and as "global" exported one if the "implementation identifier" was present.
;
%macro define 1
    %ifdef %[MODULE_NAME]_impl_
        global %1    ; Global label for implementation code
    %else
        extern %1    ; External label for consumer code
    %endif
%endmacro


%endif; DEFINITIONS_INCLUDE
