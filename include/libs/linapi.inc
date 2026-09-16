%ifndef __LINAPI_INCLUDE__
%define __LINAPI_INCLUDE__

; Linux API include file

; Standard file descriptors:
STD_INPUT_FILE   equ  0    ; File descriptor of the standard input  (e.g., terminal input)
STD_OUTPUT_FILE  equ  1    ; File descriptor of the standard output (e.g., terminal output)
STD_ERROR_FILE   equ  2    ; File descriptor of the standard error  (e.g., terminal output)


; System calls table (only what is used by the program)
sys_write  equ  1     ; Write to a file descriptor
sys_exit   equ  60    ; Terminate the calling process


%endif; __LINAPI_INCLUDE__
