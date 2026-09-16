%ifndef __TEST_INCLUDE__
%define __TEST_INCLUDE__

;
; Simple tests definitions for colorful output, some functions' macros, etc.
;

%include "libs/io/io.inc"

; Colored text preprocessor macros
%define ColoredText(&r,&g,&b)  0x1B, "[38;2;", r, ";", g, ";", b, "m"

%define Color.clear  0x1B, "[0m"

%define Color.classDefinition  ColoredText(188, 190, 196)
%define Color.classMethod      ColoredText( 86, 168, 245)
%define Color.unusedToken      ColoredText(111, 115, 122)


;
; Prints the string to the terminal the logging message using simple macro.
;
%macro log 1
    lea rsi, %1             ; Pointer to the message to print
    mov ecx, %1 %+ .size    ; The length of the message to print

    call print#out
%endmacro


%endif; __TEST_INCLUDE__