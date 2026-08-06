[bits 64]

default rel    ; Using RIP-relative addresses by default

;
; Windows backend for the "opengl" library (see "include/libs/opengl/opengl.inc").
; Contains custom OpenGL interface for interacting with GL functions.
;

%include "winapi.inc"


; OpenGL interface code
    section .text

; List of imported functions
extern glClearColor
extern glClear
extern glViewport
extern glBegin, glEnd
extern glColor3f
extern glVertex3f

; List of exported functions
global OpenGL.ClearColor
global OpenGL.Clear
global OpenGL.Viewport
global OpenGL.Begin, OpenGL.End
global OpenGL.Color3f
global OpenGL.Vertex3f


;
; Sets RGBA values used to clear the color buffer.
;
;   @param red:   f32  red component of the color   clamped to [0..1]
;   @param green: f32  green component of the color clamped to [0..1]
;   @param blue:  f32  blue component of the color  clamped to [0..1]
;   @param alpha: f32  alpha component of the color clamped to [0..1]
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.ClearColor:
    ;
    ;   Calling convention:
    ; @param red    xmm0 (as scalar f32 clamped to [0..1])
    ; @param green  xmm1 (as scalar f32 clamped to [0..1])
    ; @param blue   xmm2 (as scalar f32 clamped to [0..1])
    ; @param alpha  xmm3 (as scalar f32 clamped to [0..1])
    ;

    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        ; Since Windows' function take the same set of arguments,
        ; We can have a free ride
        call glClearColor

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret


;
; Clears present buffer bitplanes to designated values.
;
;   @param mask: u32  bitmask of the bitplane to clear
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.Clear:
    ;
    ;   Calling convention:
    ; @param mask  edi (u32 integer as bit mask)
    ;

    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        ; Move arguments to the Windows-specific registers
        mov ecx, edi    ; Mask
        call glClear

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret


;
; Sets the size and position of the drawing area mapping
; Normalized Device Coordinates (NDC) to window pixel.
;
;   @param x:      i32  the lower-left corner X-coordinate of the viewport rectangle in pixels
;   @param y:      i32  the lower-left corner Y-coordinate of the viewport rectangle in pixels
;   @param width:  i32  the width of the viewport rectangle in pixels
;   @param height: i32  the height of the viewport rectangle in pixels
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.Viewport:
    ;
    ;   Calling convention:
    ; @param x       edi (i32 integer)
    ; @param y       esi (i32 integer)
    ; @param width   edx (i32 integer)
    ; @param height  ecx (i32 integer)
    ;

    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        ; Move arguments to the Windows-specific registers
        mov r8d, edx    ; Width
        mov r9d, ecx    ; Height
        mov ecx, edi    ; X
        mov edx, esi    ; Y
        call glViewport

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret


;
; Marks the start of a list of vertex data items that define a geometric shape.
;
;   @param mode: u32  primitive type to draw (as enum of GL_TRIANGLES, GL_LINES, and GL_POINTS)
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.Begin:
    ;
    ;   Calling convention:
    ; @param mode  edi (u32 integer as enum)
    ;

    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        ; Move arguments to the Windows-specific registers
        mov ecx, edi    ; Mode
        call glBegin

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret


;
; Marks the end of a vertex-drawing block.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.End:
    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        call glEnd

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret


;
; Sets the current RGB color values for drawing objects.
;
;   @param red:   f32  red component of the color   clamped to [0..1]
;   @param green: f32  green component of the color clamped to [0..1]
;   @param blue:  f32  blue component of the color  clamped to [0..1]
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.Color3f:
    ;
    ;   Calling convention:
    ; @param red    xmm0 (as scalar f32 clamped to [0..1])
    ; @param green  xmm1 (as scalar f32 clamped to [0..1])
    ; @param blue   xmm2 (as scalar f32 clamped to [0..1])
    ;

    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        ; Since Windows' function take the same set of arguments,
        ; We can have a free ride
        call glColor3f

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret


;
; Specifies a 3D-vertex using three floating-point coordinates.
;
;   @param x: f32  X-coordinate of the vertex
;   @param y: f32  Y-coordinate of the vertex
;   @param z: f32  Z-coordinate of the vertex
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
OpenGL.Vertex3f:
    ;
    ;   Calling convention:
    ; @param x  xmm0 (as scalar f32)
    ; @param y  xmm1 (as scalar f32)
    ; @param z  xmm2 (as scalar f32)
    ;

    ; Windows ABI requires stack to be 16-bytes aligned (pre-call)
    ; And contain space for at least 4 Shadow Arguments (Shadow Space / Home Space)
    ; If we don't allocate Shadow Space for a function, it will suppose it did,
    ; And could use values higher in stack, destroying saves values.
    sub rsp, SHADOW_SPACE + 8    ; Allocate & align space on the stack

        ; Since Windows' function take the same set of arguments,
        ; We can have a free ride
        call glVertex3f

    add rsp, SHADOW_SPACE + 8    ; Return stack to its previous state
    ret
