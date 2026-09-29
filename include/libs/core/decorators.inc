%ifndef __CORE_DECORATORS_INCLUDE__
%define __CORE_DECORATORS_INCLUDE__


%macro @section 1
    [section %1]
%endmacro


%macro @section.rodata 0
    @section .rodata
%endmacro


%macro @section.data 0
    @section .data
%endmacro


%macro @section.bss 0
    @section .bss
%endmacro


%macro @section.code 0
    @section .text
%endmacro


%macro @section.return 0
    __?SECT?__
%endmacro


%macro @const.u8 2
    @section.rodata
        %1:  db  %2
    @section.return
%endmacro


%macro @const.u16 2
    @section.rodata
        %1:  dw  %2
    @section.return
%endmacro


%macro @const.u32 2
    @section.rodata
        %1:  dd  %2
    @section.return
%endmacro


%macro @const.u64 2
    @section.rodata
        %1:  dq  %2
    @section.return
%endmacro


%macro @data.u8 2
    @section.data
        %1:  db  %2
    @section.return
%endmacro


%macro @data.u16 2
    @section.data
        %1:  dw  %2
    @section.return
%endmacro


%macro @data.u32 2
    @section.data
        %1:  dd  %2
    @section.return
%endmacro


%macro @data.u64 2
    @section.data
        %1:  dq  %2
    @section.return
%endmacro


%macro @string 2
    ; Strings are not supposed to be mutable
    ; so we save them into the Read-Only Section
    @section.rodata
        %1:  db  %2, 0x00         ; String + Zero-termination
        %1.length  equ  $ - %1    ; Length of the string + Zero-byte
    @section.return    ; Restore the section that was before
%endmacro


%nedif; __CORE_DECORATORS_INCLUDE__
