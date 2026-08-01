; All the exported values
global window_title
global triangle_vertices
global f32_one


; RubyDung module data
    section .data
window_title  db  "RubyDung", 0x00

; Normalized Device Coordinates (NDC) - no projection/modelview matrix touched,
; so these map straight to clip space. Fine for one triangle;
; Player/Level's actual geometry will need real matrices once Frustum comes into play.
triangle_vertices:
    dd  0.0,  0.5, 0.0    ; Top
    dd -0.5, -0.5, 0.0    ; Bottom-Left
    dd  0.5, -0.5, 0.0    ; Bottom-Right


; RubyDung module constants
    section .rodata
f32_one:  dd  1.0
