;
; Bare minimum OpenGL 1.x surface - immediate mode only,
; matches what RubyDung's fixed-function renderer actually needs so far.
;

%ifdef LINUX
    extern glClearColor
    extern glClear
    extern glViewport
    extern glBegin, glEnd
    extern glColor3f
    extern glVertex3f
%endif

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
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
%ifdef WINDOWS
    extern OpenGL.ClearColor
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.ClearColor  glClearColor wrt ..plt
%endif
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
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
%ifdef WINDOWS
    extern OpenGL.Clear
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.Clear  glClear wrt ..plt
%endif
    ;
    ;   Calling convention:
    ; @param mask  edi (u32 integer as bit mask)
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
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
%ifdef WINDOWS
    extern OpenGL.Viewport
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.Viewport  glViewport wrt ..plt
%endif
    ;
    ;   Calling convention:
    ; @param x       edi (i32 integer)
    ; @param y       esi (i32 integer)
    ; @param width   edx (i32 integer)
    ; @param height  ecx (i32 integer)
    ;


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
%ifdef WINDOWS
    extern OpenGL.Begin
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.Begin  glBegin wrt ..plt
%endif
    ;
    ;   Calling convention:
    ; @param mode  edi (u32 integer as enum)
    ;


;
; Marks the end of a vertex-drawing block.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
%ifdef WINDOWS
    extern OpenGL.End
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.End  glEnd wrt ..plt
%endif


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
%ifdef WINDOWS
    extern OpenGL.Color3f
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.Color3f  glColor3f wrt ..plt
%endif
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
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use
;
%ifdef WINDOWS
    extern OpenGL.Vertex3f
%elifdef LINUX
    ; Since functions' custom Calling Convention are basically the same as
    ; Linux's Calling Convention, we can just assign an alias
    %define OpenGL.Vertex3f  glVertex3f wrt ..plt
%endif
    ;
    ;   Calling convention:
    ; @param x  xmm0 (as scalar f32)
    ; @param y  xmm1 (as scalar f32)
    ; @param z  xmm2 (as scalar f32)
    ;
