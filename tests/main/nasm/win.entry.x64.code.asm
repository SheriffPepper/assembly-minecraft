[bits 64]

default rel    ; Using RIP-relative addressed by default

%include "libs/winapi.inc"


; Application code
    section .text

; Imported functions
extern initializeHandles    ; Windows-only I/O function
extern testAll    ; Testing program entry point
extern ExitProcess

; Exported OS-specific entry point
global win.entry


;
; Windows-specific entry point.
; Prepares the data and passes control to the main testing entry point,
; implementing our custom convention.
;
; @convention  Windows ABI
; @features    x64
; @effects     stack use
;
; @author   Blanki
; @version  Tests 1.0
; @since    Big Bang
;
win.entry:
    ; Initialize the handles for I/O to correctly work on Windows
    call initializeHandles    ; Kills the process if some errors occur
                              ; Use it if it ever turns against us in the future

    ; The stack pointer in Windows x64 is initialized to be 16-bytes aligned (pre-call)
    ; Making it odd-8-aligned after the call of the function (entry point) was executed.
    call testAll    ; Calling 'testAll' pushes the return address, aligning the stack to 16 bytes

    ; Failsafe for 'testAll' function return - cleanup and safe exit from the process
    ; It's the default behavior of the program:
    ; We need to return the value in `rax` as exit code
    sub rsp, SHADOW_SPACE + 8    ; Reserve Shadow Space required by Windows ABI
                                 ; And align stack to be 16-bytes pre-call aligned
    mov rcx, rax    ; Exit code
    call ExitProcess

; Hopefully, program never reaches this point
; Or we're totally screwed...
; Yeah, I know some add function epilogue even after the never-returning function,
; but I don't think that a dead code would be a good idea in this economy :P
