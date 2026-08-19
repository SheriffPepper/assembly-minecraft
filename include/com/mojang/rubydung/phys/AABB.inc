%ifndef __AABB_INCLUDE__
%define __AABB_INCLUDE__

%include "definitions.inc"
%include "simd.inc"

%define MODULE_NAME  AABB

;
; The Axis Aligned Bounding Box (AABB) represents a 3D rectangular cuboid, aligned with the coordinate axes.
; It serves as a primary data structure for 3D spatial collision detection,
; continuous movement clipping (swept collision response), any physical bounding volume transformations.
;
; [WARNING]: AABB structure must be 16-byte aligned in memory.
;
; @author  Blanki
; @version rd-132211
; @since   Minecraft Pre-Alpha
;
struc AABB
    ; Lower boundary coordinates
    ; [NOTE]: 16-byte aligned
    .minCorner:
        .minX:  resd  1    ; Lower boundary coordinate on the X-axis
        .minY:  resd  1    ; Lower boundary coordinate on the Y-axis
        .minZ:  resd  1    ; Lower boundary coordinate on the Z-axis
    alignb 16    ; Padding must assigned to zero

    ; Upper boundary coordinates
    ; [NOTE]: 16-byte aligned
    .maxCorner:
        .maxX:  resd  1    ; Upper boundary coordinate on the X-axis
        .maxY:  resd  1    ; Upper boundary coordinate on the Y-axis
        .maxZ:  resd  1    ; Upper boundary coordinate on the Z-axis
    alignb 16    ; Padding must be assigned to zero
endstruc


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
; @features    AVX
; @effects     writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.new
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
    ; @changed xmm0  packed array of min corner (as f32 array [X, Y, Z, 0])
    ; @changed xmm3  packed array of max corner (as f32 array [X, Y, Z, 0])
    ;
    ; @destroyed xmm1-2  values are considered destroyed and potentially contain garbage
    ; @destroyed xmm4-5  values are considered destroyed and potentially contain garbage
    ;
define AABB.new.packed    ; Function variant with corners already packed
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ;
    ; @param minCorner  xmm0 (as f32 array [minX, minY, minZ, 0.0])
    ; @param maxCorner  xmm3 (as f32 array [maxX, maxY, maxZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @preserved xmm0  packed array of min corner (as f32 array [X, Y, Z, 0])
    ; @preserved xmm3  packed array of max corner (as f32 array [X, Y, Z, 0])
    ;
    ; @destroyed xmm1-2  values are considered destroyed and potentially contain garbage
    ; @destroyed xmm4-5  values are considered destroyed and potentially contain garbage
    ;


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
; @features    AVX
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.expand#new        ; Creates new object when called
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
    ; @changed xmm0  packed array of deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @changed xmm1  packed array of all negative deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @changed xmm2  packed array of all positive deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @changed xmm3  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.expand#mutable    ; Changes the object when called
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ;
    ; @param deltaX  xmm0 (as scalar f32)
    ; @param deltaY  xmm1 (as scalar f32)
    ; @param deltaZ  xmm2 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed xmm0  packed array of all deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @changed xmm1  packed array of all negative deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @changed xmm2  packed array of all positive deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @changed xmm3  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.expand#mutable.packed    ; Function variant with deltas already packed
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this    rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  deltas array is never changes, and can be reused
    ;
    ; @changed xmm1  packed array of all negative deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @changed xmm2  packed array of all positive deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @changed xmm3  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.expand#mutable.masks     ; Function variant with deltas & masks precalculated
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this    rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @param negativeDeltas  xmm1 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @param positiveDeltas  xmm2 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  deltas array is never changed, and can be reused
    ;
    ; @preserved xmm1  value is never changed, and can be reused
    ; @preserved xmm2  value is never changed, and can be reused
    ;
    ; @changed xmm3  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.expand#mutable.loaded    ; Function variant with all values precalculated & preloaded
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this    rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @param negativeDeltas  xmm1 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ; @param positiveDeltas  xmm2 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @param minCorner  xmm3 (as f32 array [minX, minY, minZ, 0.0])
    ; @param maxCorner  xmm4 (as f32 array [maxX, maxY, maxZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  deltas array is never changed, and can be reused
    ;
    ; @preserved xmm1  value is never changed, and can be reused
    ; @preserved xmm2  value is never changed, and can be reused
    ;
    ; @changed xmm3  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the resulted AABB structure
    ;


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
; @features    AVX
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.grow#new        ; Creates new object when called
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
    ; @changed xmm0  packed array of amounts (as f32 array [amountX, amountY, amountZ, 0.0])
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.grow#mutable    ; Changes the object when called
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ;
    ; @param amountX  xmm0 (as scalar f32)
    ; @param amountY  xmm1 (as scalar f32)
    ; @param amountZ  xmm2 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ;
    ; @changed xmm0  packed array of amounts (as f32 array [amountX, amountY, amountZ, 0.0])
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.grow#mutable.packed    ; Function variant with amounts already packed
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this     rdi (pointer, "destination")
    ; @param amounts  xmm0 (as f32 array [amountX, amountY, amountZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  amounts array is never changed, and can be reused
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.grow#mutable.loaded    ; Function variant with amounts packed & corners preloaded
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this     rdi (pointer, "destination")
    ; @param amounts  xmm0 (as f32 array [amountX, amountY, amountZ, 0.0])
    ;
    ; @param minCorner  xmm1 (as f32 array [minX, minY, minZ, 0.0])
    ; @param maxCorner  xmm2 (as f32 array [maxX, maxY, maxZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  amounts array is never changed, and can be reused
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;


;
; Calculates the maximum distance an external bounding box 'box1'
; can move along the X-axis before colliding with 'box0' bounding box.
;
; If no projection Y or Z axes overlap exists, 'movementX' is returned unclipped.
; If there's a possibility of colliding on X-axis, returns the minimal of
; the distance to the 'box1' bounding box and 'movementX'.
;
;   @param box0: *AABB  pointer to the AABB structure to check the collision with
;   @param box1: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementX: f32  desired motion offset along the X-axis for 'box1'
;
;   @return  the allowed movement amount along the X-axis, clipped to prevent penetration into 'box0' box
;
; @convention  custom (Blanki)
; @features    AVX
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.clipXCollide
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param box0  rsi (pointer)
    ; @param box1  rdi (pointer)
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
    ; @destroyed xmm1-6  values are considered destroyed and potentially contain garbage
    ;


;
; Calculates the maximum distance an external bounding box 'box1'
; can move along the Y-axis before colliding with 'box0' bounding box.
;
; If no projection X or Z axes overlap exists, 'movementY' is returned unclipped.
; If there's a possibility of colliding on Y-axis, returns the minimal of
; the distance to the 'box1' bounding box and 'movementY'.
;
;   @param box0: *AABB  pointer to the AABB structure to check the collision with
;   @param box1: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementY: f32  desired motion offset along the Y-axis for 'box1'
;
;   @return  the allowed movement amount along the Y-axis, clipped to prevent penetration into 'box0' box
;
; @convention  custom (Blanki)
; @features    AVX
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.clipYCollide
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param box0  rsi (pointer)
    ; @param box1  rdi (pointer)
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
    ; @destroyed xmm1-6  values are considered destroyed and potentially contain garbage
    ;


;
; Calculates the maximum distance an external bounding box 'box1'
; can move along the Z-axis before colliding with 'box0' bounding box.
;
; If no projection X or Y axes overlap exists, 'movementZ' is returned unclipped.
; If there's a possibility of colliding on Z-axis, returns the minimal of
; the distance to the 'box1' bounding box and 'movementZ'.
;
;   @param box0: *AABB  pointer to the AABB structure to check the collision with
;   @param box1: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementZ: f32  desired motion offset along the Z-axis for 'box1'
;
;   @return  the allowed movement amount along the Z-axis, clipped to prevent penetration into 'box0' box
;
; @convention  custom (Blanki)
; @features    AVX
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.clipZCollide
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param box0  rsi (pointer)
    ; @param box1  rdi (pointer)
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
    ; @destroyed xmm1-6  values are considered destroyed and potentially contain garbage
    ;


;
; Determines whether 'box0' bounding box overlaps with another bounding box 'box1' in 3D space.
;
;   @param box0: *AABB  pointer to the AABB structure to test for intersection
;   @param box1: *AABB  pointer to the AABB structure to test for intersection
;
;   @return  'true' if boxes overlap on all three axes simultaneously; 'false' otherwise
;
; [NOTE]: Employs strict inequalities. Boxes that share touching faces or edges are not considered intersecting.
;
; @convention  custom (Blanki)
; @features    x64, AVX
; @effects     reads, computes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.intersects
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param box0  rsi (pointer)
    ; @param box1  rdi (pointer)
    ;
    ; @return  rax (as zero-extended boolean)
    ;
    ;   Side Effects:
    ; @preserved rsi  pointer is never changed, and can be reused
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed rax  return value
    ;


;
; Translates the bounding box in-place by applying offset increments to all boundaries.
;
;   @param this:  *AABB  pointer to the AABB structure to move
;   @param other: *AABB  pointer to the AABB structure to save the movement to
;
;   @param deltaX: f32  translation distance along the X-axis
;   @param deltaY: f32  translation distance along the Y-axis
;   @param deltaZ: f32  translation distance along the Z-axis
;
; @convention  custom (Blanki)
; @features    AVX
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
define AABB.move#new
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
    ; @changed xmm0  packed array of deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.move#mutable
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ;
    ; @param deltaX  xmm0 (as scalar f32)
    ; @param deltaY  xmm1 (as scalar f32)
    ; @param deltaZ  xmm2 (as scalar f32)
    ;
    ;   Side Effects:
    ; @preserved rdi  pointer is never changed, and can be reused
    ;
    ; @changed xmm0  packed array of deltas (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.move#mutable.packed
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this    rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  deltas array is never changed, and can be reused
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;
define AABB.move#mutable.loaded
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this    rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaZ, 0.0])
    ;
    ; @param minCorner  xmm1 (as f32 array [minX, minY, minZ, 0.0])
    ; @param maxCorner  xmm2 (as f32 array [maxX, maxY, maxZ, 0.0])
    ;
    ;   Side Effects:
    ; @preserved rdi   pointer is never changed, and can be reused
    ; @preserved xmm0  deltas array is never changed, and can be reused
    ;
    ; @changed xmm1  (temporal storage) minimum corner of the resulted AABB structure
    ; @changed xmm2  (temporal storage) maximum corner of the resulted AABB structure
    ;


; AABB macros

;
; Copies AABB structure from the source to the destination, via one temporal 'ymm#' register.
;
; [WARNING]: AABB pointers must be 16-byte aligned.
;
; @features  AVX
; @effects   reads, writes
;
; @author   Blanki
; @version  1.0
; @since    Big Bang
;
%macro AABB.copy 4
    ;
    ;   Side Effects:
    ; @changed minTemporal  (temporal storage) copy of the min corner of the AABB structure
    ; @changed maxTemporal  (temporal storage) copy of the max corner of the AABB structure
    ;

    ;
    ; For everybody wondering why we didn't just used one 'ymm' register.
    ; We can't. 32-byte long registers ('ymm' exactly) require 32-byte alignment.
    ; Since the alignment for AABB structure is 16 bytes, we can't use aligned moves directly.
    ;
    ; For standard 64-byte CPU cache line, with 16-byte alignment,
    ; a 32-byte ymm-move has a 25% probability of splitting across cache line boundary,
    ; incurring 4-12 cycle penalty of stitching two cache lines together.
    ; 16-byte aligned moves on the other hand can't never physically cross the boundary,
    ; making loads and stores hit a single cache line for each load/store with 100% certainty.
    ;
    ; Will be more effective with 32-byte alignment.
    ; Consider altering AABB-alignment contract.
    ;

    ; Save AABB structure to the temporal register
    vmovaps %3, xmmword [%2 + AABB.minCorner]
    vmovaps %4, xmmword [%2 + AABB.maxCorner]

    ; Write AABB structure to the destination
    vmovaps xmmword [%1 + AABB.minCorner], %3
    vmovaps xmmword [%1 + AABB.maxCorner], %4
%endmacro


%endif; __AABB_INCLUDE__
