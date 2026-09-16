%ifndef __IO_INCLUDE__
%define __IO_INCLUDE__

;
; Simple Input/Output functions to use with no overcomplicating.
;


;
; Prints the string of the specified length to the standard output.
;
;   @param string: *str  pointer to the message buffer to output
;   @param length: int   number of characters in the message buffer to print
;
;   @return  the number of bytes written to the standard output
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
extern print#out
    ;
    ;   Calling convention:
    ; @param string  rsi (pointer, "source")
    ; @param length  ecx (u32 integer)
    ;
    ; @return rax
    ;
    ;   Side Effects:
    ; @change rax  the return value
    ;
    ; @destroyed rsi  the values is considered destroyed and potentially contain garbage
    ; @destroyed ecx  the values is considered destroyed and potentially contain garbage
    ;


%endif; __IO_INCLUDE__
