;
; Bare minimum OpenGL 1.x surface - immediate mode only,
; matches what RubyDung's fixed-function renderer actually needs so far.
;

GL_COLOR_BUFFER_BIT  equ  0x00004000
GL_TRIANGLES         equ  0x0004


;
; Sets RGBA values used to clear the color buffer.
;
;   @param red:   f32  red component of the color   clamped to [0..1]
;   @param green: f32  green component of the color clamped to [0..1]
;   @param blue:  f32  blue component of the color  clamped to [0..1]
;   @param alpha: f32  alpha component of the color clamped to [0..1]
;
; @convention  Windows ABI
; @features    x64
; @effects     stack use
;
extern glClearColor
    ;
    ;   Calling convention:
    ; @param red    xmm0 (as scalar f32 clamped to [0..1])
    ; @param green  xmm1 (as scalar f32 clamped to [0..1])
    ; @param blue   xmm2 (as scalar f32 clamped to [0..1])
    ; @param alpha  xmm3 (as scalar f32 clamped to [0..1])
    ;


;
; Clears present buffer bitplanes to designated values.
;
;   @param mask: u32  bitmask of the bitplane to clear
;
; @convention  Windows ABI
; @features    x64
; @effects     stack use
;
extern glClear
    ;
    ;   Calling convention:
    ; @param mask  ecx (u32 integer as bit mask)
    ;


;
; Sets the size and position of the drawing area mapping
; Normalized Device Coordinates (NDC) to window pixel.
;
;   @param x:      i32  the lower-left corner X-coordinate of the viewport rectangle in pixels
;   @param y:      i32  the lower-left corner Y-coordinate of the viewport rectangle in pixels
;   @param width:  i32  the width of the viewport rectangle in pixels
;   @param height: i32  the height of the viewport rectangle in pixels
;
; @convention  Windows ABI
; @features    x64
; @effects     stack use
;
extern glViewport
    ;
    ;   Calling convention:
    ; @param x       ecx (i32 integer)
    ; @param y       edx (i32 integer)
    ; @param width   r8d (i32 integer)
    ; @param height  r9d (i32 integer)
    ;


;
; Marks the start of a list of vertex data items that define a geometric shape.
;
;   @param mode: u32  primitive type to draw (as enum of GL_TRIANGLES, GL_LINES, and GL_POINTS)
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
extern glBegin
    ;
    ;   Calling convention:
    ; @param mode  ecx (u32 integer as enum)
    ;


;
; Marks the end of a vertex-drawing block.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
extern glEnd


;
; Sets the current RGB color values for drawing objects.
;
;   @param red:   f32  red component of the color   clamped to [0..1]
;   @param green: f32  green component of the color clamped to [0..1]
;   @param blue:  f32  blue component of the color  clamped to [0..1]
;
; @convention  Windows ABI
; @features    x64
; @effects     stack use
;
extern glColor3f
    ;
    ;   Calling convention:
    ; @param red    xmm0 (as scalar f32 clamped to [0..1])
    ; @param green  xmm1 (as scalar f32 clamped to [0..1])
    ; @param blue   xmm2 (as scalar f32 clamped to [0..1])
    ;


;
; Specifies a 3D-vertex using three floating-point coordinates.
;
;   @param x: f32  X-coordinate of the vertex
;   @param y: f32  Y-coordinate of the vertex
;   @param z: f32  Z-coordinate of the vertex
;
; @convention  Windows ABI
; @features    x64
; @effects     stack use
;
extern glVertex3f
    ;
    ;   Calling convention:
    ; @param x  xmm0 (as scalar f32)
    ; @param y  xmm1 (as scalar f32)
    ; @param z  xmm2 (as scalar f32)
    ;
