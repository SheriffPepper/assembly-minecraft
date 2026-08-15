[bits 64]

default rel    ; Using RIP-relative addresses by default

%define AABB_impl_    ; State that we're gonna implement the AABB module

%include "definitions.inc"
%include "com/mojang/rubydung/phys/AABB.inc"

;
; The Axis Aligned Bounding Box (AABB) represents a 3D rectangular cuboid, aligned with the coordinate axes.
; It serves as a primary data structure for 3D spatial collision detection,
; continuous movement clipping (swept collision response), any physical bounding volume transformations.
;
; [WARNING]: AABB structure must be 16-byte aligned in memory.
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;


; AABB functions implementation
    section .text

;
; Constructs a new AABB with explicit spatial bounds.
;
;   @param this: *AABB  pointer to the AABB structure to initialize
;
;   @param minX: f32  minimum X-coordinate
;   @param minY: f32  minimum Y-coordinate
;   @param minZ: f32  minimum Z-coordinate
;
;   @param maxX: f32  maximum X-coordinate
;   @param maxY: f32  maximum Y-coordinate
;   @param maxZ: f32  maximum Z-coordinate
;
; [NOTE]: Memory for the AABB structure must be allocated beforehand.
; [NOTE]: No checks for 'min#' being less than or equal to 'max#' coordinates is done.
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.new:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ;
    ; @param minX  xmm0 (as scalar f32)
    ; @param minY  xmm1 (as scalar f32)
    ; @param minZ  xmm2 (as scalar f32)
    ;
    ; @param maxX  xmm3 (as scalar f32)
    ; @param maxY  xmm4 (as scalar f32)
    ; @param maxZ  xmm5 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @destroyed xmm0  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm1  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm2  value is considered destroyed and potentially contain garbage
    ;
    ; @destroyed xmm3  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm4  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm5  value is considered destroyed and potentially contain garbage
    ;
    ret


;
; Stretches the bounding box along the trajectory vector, expanding the box boundaries
; to cover both the original position and the target displacement.
; Useful for volumetric movement to prevent tunneling during high-speed movement.
;
; If a 'delta#' value is negative, the corresponding 'min#' boundary is reduced by 'delta#'.
; If a 'delta#' value is positive, the corresponding 'max#' boundary is increased by 'delta#'.
;
;   @param this:  *AABB  pointer to the AABB structure to extend
;   @param other: *AABB  pointer to the AABB structure to save the extension to
;
;   @param deltaX: f32  displacement magnitude along the X-axis
;   @param deltaY: f32  displacement magnitude along the Y-axis
;   @param deltaZ: f32  displacement magnitude along the Z-axis
;
; [NOTE]: Memory for the AABB structure must be allocated beforehand.
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.expand:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this   rsi (pointer, "source")
    ; @param other  rdi (pointer, "destination")
    ;
    ; @param deltaX  xmm0 (as scalar f32)
    ; @param deltaY  xmm1 (as scalar f32)
    ; @param deltaZ  xmm2 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @destroyed xmm0  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm1  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm2  value is considered destroyed and potentially contain garbage
    ;
    ret


;
; Uniformly inflates or deflates the bounding box symmetrically across all dimensions.
;
; Subtracts 'amount#' from 'min#' fields and adds 'amount#' to max fields.
;
;   @param this:  *AABB  pointer to the AABB structure to grow
;   @param other: *AABB  pointer to the AABB structure to save the growth to
;
;   @param amountX: f32  distance to extend/shrink along X-axis in both positive and negative directions
;   @param amountY: f32  distance to extend/shrink along Y-axis in both positive and negative directions
;   @param amountZ: f32  distance to extend/shrink along Z-axis in both positive and negative directions
;
; [NOTE]: Memory for the AABB structure must be allocated beforehand.
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.grow:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this   rsi (pointer, "source")
    ; @param other  rdi (pointer, "destination")
    ;
    ; @param amountX  xmm0 (as scalar f32)
    ; @param amountY  xmm1 (as scalar f32)
    ; @param amountZ  xmm2 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @destroyed xmm0  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm1  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm2  value is considered destroyed and potentially contain garbage
    ;
    ret


;
; Calculates the maximum distance an external bounding box 'other'
; can move along the X-axis before colliding with 'this' bounding box.
;
; If no projection Y or Z axes overlap exists, 'movementX' is returned unclipped.
; If there's a possibility of colliding on X-axis, returns the minimal of
; the distance to the 'other' bounding box and 'movementX'.
;
;   @param this:  *AABB  pointer to the AABB structure to check the collision with
;   @param other: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementX: f32  desired motion offset along the X-axis for 'other'
;
;   @return  the allowed movement amount along the X-axis, clipped to prevent penetration into 'this' box
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.clipXCollide:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this   rsi (pointer)
    ; @param other  rdi (pointer)
    ;
    ; @param movementX  xmm0 (as scalar f32)
    ;
    ; @return  xmm0 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed xmm0  return value
    ;
    ret


;
; Calculates the maximum distance an external bounding box 'other'
; can move along the Y-axis before colliding with 'this' bounding box.
;
; If no projection X or Z axes overlap exists, 'movementY' is returned unclipped.
; If there's a possibility of colliding on Y-axis, returns the minimal of
; the distance to the 'other' bounding box and 'movementY'.
;
;   @param this:  *AABB  pointer to the AABB structure to check the collision with
;   @param other: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementY: f32  desired motion offset along the Y-axis for 'other'
;
;   @return  the allowed movement amount along the Y-axis, clipped to prevent penetration into 'this' box
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.clipYCollide:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this   rsi (pointer)
    ; @param other  rdi (pointer)
    ;
    ; @param movementY  xmm0 (as scalar f32)
    ;
    ; @return  xmm0 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed xmm0  return value
    ;
    ret


;
; Calculates the maximum distance an external bounding box 'other'
; can move along the Y-axis before colliding with 'this' bounding box.
;
; If no projection X or Z axes overlap exists, 'movementY' is returned unclipped.
; If there's a possibility of colliding on Z-axis, returns the minimal of
; the distance to the 'other' bounding box and 'movementZ'.
;
;   @param this:  *AABB  pointer to the AABB structure to check the collision with
;   @param other: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementY: f32  desired motion offset along the Z-axis for 'other'
;
;   @return  the allowed movement amount along the Z-axis, clipped to prevent penetration into 'this' box
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.clipYCollide:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this   rsi (pointer)
    ; @param other  rdi (pointer)
    ;
    ; @param movementZ  xmm0 (as scalar f32)
    ;
    ; @return  xmm0 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed xmm0  return value
    ;
    ret


;
; Determines whether 'this' bounding box overlaps with another bounding box in 3D space.
;
;   @param this:  *AABB  pointer to the AABB structure to test for intersection
;   @param other: *AABB  pointer to the AABB structure to test for intersection
;
;   @return  'true' if boxes overlap on all three axes simultaneously; 'false' otherwise
;
; [NOTE]: Employs strict inequalities. Boxes that share touching faces or edges are not considered intersecting.
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.intersects:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this   rsi (pointer)
    ; @param other  rdi (pointer)
    ;
    ; @return  rax (as zero-extended boolean)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed rax  return value
    ;
    ret


;
; Translates the bounding box in-place by applying offset increments to all boundaries.
;
;   @param this: *AABB  pointer to the AABB structure to move
;
;   @param deltaX: f32  translation distance along the X-axis
;   @param deltaY: f32  translation distance along the Y-axis
;   @param deltaZ: f32  translation distance along the Z-axis
;
; @convention  custom (Blanki)
; @features    SSE
; @effects     reads, computes, writes
;
AABB.move:
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer)
    ;
    ; @param deltaX  xmm0 (as scalar f32)
    ; @param deltaY  xmm1 (as scalar f32)
    ; @param deltaZ  xmm2 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @destroyed xmm0  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm1  value is considered destroyed and potentially contain garbage
    ; @destroyed xmm2  value is considered destroyed and potentially contain garbage
    ;
    ret
