; Win API include file

; =============== x64 Calling Convention ===============

; Caller of Windows-functions must allocate 32 bytes of space (four 64-bit values)
; as so-called "Shadow Space" or "Home Space" for first 4 function parameters
; even if function takes less. Stack must be 16-bytes aligned before every Win-call.
SHADOW_SPACE  equ  0x20
HOME_SPACE    equ  SHADOW_SPACE
; Stack params (Params #0-3 are passed via registers)
STACK_PARAM#4  equ SHADOW_SPACE + 0 * 8
STACK_PARAM#5  equ SHADOW_SPACE + 1 * 8
STACK_PARAM#6  equ SHADOW_SPACE + 2 * 8
STACK_PARAM#7  equ SHADOW_SPACE + 3 * 8
STACK_PARAM#8  equ SHADOW_SPACE + 4 * 8
STACK_PARAM#9  equ SHADOW_SPACE + 5 * 8
STACK_PARAM#10 equ SHADOW_SPACE + 6 * 8
STACK_PARAM#11 equ SHADOW_SPACE + 7 * 8

; =============== kernel32 ===============

; Standard handle types:
STD_INPUT_HANDLE  equ 0xfffffff6  ; (unsigned '-10') Handle of the standard input  (e.g., console input)
STD_OUTPUT_HANDLE equ 0xfffffff5  ; (unsigned '-11') Handle of the standard output (e.g., console output)
STD_ERROR_HANDLE  equ 0xfffffff4  ; (unsigned '-12') Handle of the standard error  (e.g., console output)

; =============== gdi32 ===============

; Pixel Format Descriptor flags
PFD_DOUBLE_BUFFER   equ  0x00000001    ; The buffer is double-buffered
PFD_DRAW_TO_WINDOW  equ  0x00000004    ; The buffer can draw to a window or device surface
PFD_SUPPORT_OPENGL  equ  0x00000020    ; The buffer supports OpenGL drawing

PFD_TYPE_RGBA  equ  0x00    ; RGBA pixels; each pixel has four components: (red, green, blue, alpha)

PFD_MAIN_PLANE  equ  0x00    ; Layer type (earlier implementations of OpenGL use this)

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
struc WindowClassEx
    .size:              resd  1    ; The size, in bytes, of this structure
    .style:             resd  1    ; The class style
    .window_procedure:  resq  1    ; A pointer to the window procedure
    .class_extra:       resd  1    ; The number of extra bytes to allocate following the window-class structure
    .window_extra:      resd  1    ; The number of extra bytes to allocate following the window instance
    .instance:          resq  1    ; A handle to the instance that contains the window procedure for the class
    .icon:              resq  1    ; A handle to the class icon
    .cursor:            resq  1    ; A handle to the class cursor
    .background:        resq  1    ; A handle to the class background brush
    .menu_name:         resq  1    ; A pointer to a string that specifies the resource name of the class menu
    .class_name:        resq  1    ; A pointer to a string of the class name
    .small_icon:        resq  1    ; A handle to a small icon that is associated with the window class
endstruc

; Window Class Styles
WindowClass.style@OWN_DC equ 0x00000020  ; Allocates a unique device context for each window in the class

; Window Styles
Window.style@BORDER       equ 0x00800000  ; The window has a thin-line border
Window.style@CAPTION      equ 0x00c00000  ; The window has a title bar (includes BORDER style)
Window.style@SYS_MENU     equ 0x00080000  ; The window has a window menu on its title bar (CAPTION style must also be specified)
Window.style@SIZE_BOX     equ 0x00040000  ; The window has a sizing border
Window.style@MINIMIZED    equ 0x20000000  ; The window initially minimized
Window.style@MAXIMIZED    equ 0x01000000  ; The window initially maximized
Window.style@MINIMIZE_BOX equ 0x00020000  ; The window has a minimize button (SYS_MENU style must also be specified)
Window.style@MAXIMIZE_BOX equ 0x00010000  ; The window has a maximize button (SYS_MENU style must also be specified)
Window.style@OVERLAPPED   equ 0x00000000  ; The window is an overlapped window (window will have a title bar and a border)
Window.style@VISIBLE      equ 0x10000000  ; The window is initially visible

Window.style@OVERLAPPED_WINDOW equ Window.style@OVERLAPPED | Window.style@CAPTION | Window.style@SYS_MENU | Window.style@SIZE_BOX | Window.style@MINIMIZE_BOX | Window.style@MAXIMIZE_BOX

CW_USE_DEFAULT equ 0x80000000    ; Default value for window position

SW_NORMAL equ 1    ; Activates and displays a window

PM_REMOVE equ 1    ; Peek Message removes the message

; Window Messages
WindowMessage.code@DESTROY equ 0x0002
WindowMessage.code@CLOSE   equ 0x0010

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
