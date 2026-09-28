%ifndef __CORE_DECORATORS_INCLUDE__
%define __CORE_DECORATORS_INCLUDE__


%macro @string 2
    ; Strings are not supposed to be mutable,
    ; so we save them into the Read-Only Section
    [section .rodata]
        %1:  db  %2, 0x00         ; String + Zero-termination
        %1.length  equ  $ - %1    ; Length of the string + Zero-byte
    __?SECT?__    ; Restore the section that was before
%endmacro


%nedif; __CORE_DECORATORS_INCLUDE__
