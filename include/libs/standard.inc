%ifndef __STANDARD_INCLUDE__
%define __STANDARD_INCLUDE__

;
; Cross-platform "standard" library interface.
;

%ifdef WINDOWS    ; Windows takes u32 as exit code, but we can ignore that fact...
    ; Register that is used for exit code
    %define EXIT_CODE  rcx

    ; Imports for standard functions
    extern ExitProcess
%elifdef LINUX
    ; Register that is used for exit code
    %define EXIT_CODE  rdi
%elifdef MACOS
    ; Register that is used for exit code
    %define EXIT_CODE  rdi
%else
    %error "Unsupported OS, try passing the definition '-D<OS>' to NASM"
%endif


; Helper macro
%macro _set_reg 2
  %ifnidni %1, %2
    mov %1, %2
  %endif
%endmacro


; ==================== Macros ====================


;
; Exits the program with the specified exit code.
;
; [NOTE]: Function never returns to your code
;
; @convention  macro
; @features    x64
; @effects     death
;
%macro macro@exit 0    ; Program executed successfully
    xor EXIT_CODE, EXIT_CODE

    %ifdef WINDOWS
        call ExitProcess
    %elifdef LINUX
        mov rax, 60
        syscall
    %elifdef MAC_OS
        mov rax, 0x2000001
        syscall
    %endif
%endmacro

;
; Exits the program with the specified exit code.
;
;   @param exit_code: u64  exit code
;
; [NOTE]: Function never returns to your code
;
; @convention  macro
; @features    x64
; @effects     death
;
%macro macro@exit 1    ; Program exits with some exit code
    _set_reg EXIT_CODE, %1

    %ifdef WINDOWS
        call ExitProcess
    %elifdef LINUX
        mov rax, 60
        syscall
    %elifdef MAC_OS
        mov rax, 0x2000001
        syscall
    %endif
%endmacro


%endif; __STANDARD_INCLUDE__
