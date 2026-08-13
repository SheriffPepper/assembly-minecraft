%ifndef __X11_INCLUDE__
%define __X11_INCLUDE__

;
; X11/GLX constants + the couple of struct offsets we actually touch.
; Offsets hand-derived from Xlib.h/Xutil.h field order + x86-64 struct
; padding rules - sanity-check against your system's headers before
; assembling, same disclaimer as the Win32 PIXEL_FORMAT_DESCRIPTOR
;

; XVisualInfo (glX gives us a pointer to one)
XVisualInfo.visual         equ  0x00
XVisualInfo.visualId       equ  0x08
XVisualInfo.screen         equ  0x10
XVisualInfo.depth          equ  0x14
XVisualInfo.class          equ  0x18
XVisualInfo.red_mask       equ  0x20
XVisualInfo.green_mask     equ  0x28
XVisualInfo.blue_mask      equ  0x30
XVisualInfo.colormap_size  equ  0x38
XVisualInfo.bits_per_rgb   equ  0x3c

; Window Attributes structure
XSetWindowAttributes.background_pixmap      equ  0x00
XSetWindowAttributes.background_pixel       equ  0x08
XSetWindowAttributes.border_pixmap          equ  0x10
XSetWindowAttributes.border_pixel           equ  0x18
XSetWindowAttributes.bit_gravity            equ  0x20
XSetWindowAttributes.win_gravity            equ  0x24
XSetWindowAttributes.backing_store          equ  0x28
XSetWindowAttributes.backing_planes         equ  0x30
XSetWindowAttributes.backing_pixel          equ  0x38
XSetWindowAttributes.save_under             equ  0x40
XSetWindowAttributes.event_mask             equ  0x48
XSetWindowAttributes.do_not_propagate_mask  equ  0x50
XSetWindowAttributes.override_redirect      equ  0x58
XSetWindowAttributes.colormap               equ  0x60
XSetWindowAttributes.cursor                 equ  0x68

XSetWindowAttributes_size  equ  0x70

; Event structure (union)
XEvent.type        equ  0x00
XEvent.serial      equ  0x08
XEvent.send_event  equ  0x10
XEvent.display     equ  0x18
XEvent.window      equ  0x20
XClientMessageEvent.message_type  equ  0x28
XClientMessageEvent.format        equ  0x30
XClientMessageEvent.data          equ  0x38

; Window attribute mask bits
CWBackPixmap        equ  1 << 0
CWBackPixel         equ  1 << 1
CWBorderPixmap      equ  1 << 2
CWBorderPixel       equ  1 << 3
CWBitGravity        equ  1 << 4
CWWinGravity        equ  1 << 5
CWBackingStore      equ  1 << 6
CWBackingPlanes     equ  1 << 7
CWBackingPixel      equ  1 << 8
CWOverrideRedirect  equ  1 << 9
CWSaveUnder         equ  1 << 10
CWEventMask         equ  1 << 11
CWDontPropagate     equ  1 << 12
CWColormap          equ  1 << 13
CWCursor            equ  1 << 14

; Event mask values
KeyPressMask         equ  0x00000001    ; Notify if there's a keyboard down event
ExposureMask         equ  0x00008000    ; Notify if the window is visible and ready (exposed)
StructureNotifyMask  equ  0x00020000    ; Notify if there are any changes in window

KeyPressEvent  equ  2
ExposeEvent    equ  12    ; XEvent.type value for
ClientMessage  equ  33    ; XEvent.type value for WM protocol messages (WM_DELETE_WINDOW)

GLX_RGBA           equ  4
GLX_DOUBLE_BUFFER  equ  5
GLX_STEREO         equ  6
GLX_AUX_BUFFERS    equ  7
GLX_RED_SIZE       equ  8
GLX_GREEN_SIZE     equ  9
GLX_BLUE_SIZE      equ  10
GLX_ALPHA_SIZE     equ  11
GLX_DEPTH_SIZE     equ  12
GLX_STENCIL_SIZE   equ  13


%endif; __X11_INCLUDE__
