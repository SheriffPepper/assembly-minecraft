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

%ifdef x64
    pointer@size equ 8  ; x64 -> 64-bits (8 bytes)
%else
    pointer@size equ 4  ; x86 -> 32-bits (4 bytes)
%endif
