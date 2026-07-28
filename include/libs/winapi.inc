; Win API include file

; =============== kernel32 ===============

; Standard handle types:
STD_INPUT_HANDLE  equ 0xfffffff6  ; (unsigned '-10') Handle of the standard input  (e.g., console input)
STD_OUTPUT_HANDLE equ 0xfffffff5  ; (unsigned '-11') Handle of the standard output (e.g., console output)
STD_ERROR_HANDLE  equ 0xfffffff4  ; (unsigned '-12') Handle of the standard error  (e.g., console output)

; =============== user32 ===============

;
; Contains window class information.
; It is used with the RegisterClassEx and GetClassInfoEx functions.
;
; The WindowClassEx structure is similar to the WindowClass structure.
; There are two differences. WindowClassEx includes the 'size' member,
; which specifies the size of the structure, and the 'icon' member,
; which contains a handle to a small icon associated with the window class.
;

; Icons of the Message Box window
MessageBox.icon@EXCLAMATION equ 0x00000030  ; An exclamation-point icon
MessageBox.icon@WARNING     equ 0x00000030
MessageBox.icon@INFORMATION equ 0x00000040  ; An icon consisting of lowercase letter i in a circle
MessageBox.icon@ASTERISK    equ 0x00000040
MessageBox.icon@QUESTION    equ 0x00000020  ; A question-mark icon
MessageBox.icon@STOP        equ 0x00000010  ; A stop-sign icon
MessageBox.icon@ERROR       equ 0x00000010
MessageBox.icon@HAND        equ 0x00000010

; Push buttons in Message Box window
MessageBox.buttons@ABORT_RETRY_IGNORE  equ 0x00000002
MessageBox.buttons@CANCEL_TRY_CONTINUE equ 0x00000006
MessageBox.buttons@HELP                equ 0x00004000
MessageBox.buttons@OK                  equ 0x00000000
MessageBox.buttons@OK_CANCEL           equ 0x00000001
MessageBox.buttons@RETRY_CANCEL        equ 0x00000005
MessageBox.buttons@YES_NO              equ 0x00000004
MessageBox.buttons@YES_NO_CANCEL       equ 0x00000003

; Default buttons in Message Box window
MessageBox.defaultButton@1 equ 0x00000000  ; First button is the default button
MessageBox.defaultButton@2 equ 0x00000100  ; Second button is the default button
MessageBox.defaultButton@3 equ 0x00000200  ; Third button is the default button
MessageBox.defaultButton@4 equ 0x00000300  ; Fourth button is the default button

; Modality of the Message Box window
MessageBox.modality@APPLICATION equ 0x00000000  ; Message Box window stops execution of the owner window
MessageBox.modality@SYSTEM      equ 0x00001000  ; Same as APPLICATION modality, but with TOPMOST style
MessageBox.modality@TASK        equ 0x00002000  ; Same as APPLICATION modality, but all thread windows are disabled if window handle is `NULL`

; Other Message Box window flags
MessageBox.flags@DEFAULT_DESKTOP_ONLY equ 0x00020000  ; Same as desktop of the interactive window station
MessageBox.flags@RIGHT                equ 0x00080000  ; The text is right-justified
MessageBox.flags@RTL_READING          equ 0x00100000  ; Displays message and caption text using right-to-left reading order on Hebrew and Arabic systems
MessageBox.flags@SET_FOREGROUND       equ 0x00010000  ; The Message Box becomes the foreground window
MessageBox.flags@TOPMOST              equ 0x00040000  ; The Message Box is created with the TOPMOST window style
MessageBox.flags@SERVICE_NOTIFICATION equ 0x00200000  ; The caller is a service notifying the user of an event

; Message Box window's selected value
MessageBox@ABORT     equ 3
MessageBox@CANCEL    equ 2
MessageBox@CONTINUE  equ 11
MessageBox@IGNORE    equ 5
MessageBox@NO        equ 7
MessageBox@OK        equ 1
MessageBox@RETRY     equ 4
MessageBox@TRY_AGAIN equ 10
MessageBox@YES       equ 6
