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
; @features    AVX
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
    ; @changed xmm0  packed array of min corner (as f32 array [X, Y, Z, 0])
    ; @changed xmm3  packed array of max corner (as f32 array [X, Y, Z, 0])
    ;
    ; @destroyed xmm1-2  values are considered destroyed and potentially contain garbage
    ; @destroyed xmm4-5  values are considered destroyed and potentially contain garbage
    ;

    ; Pack corners (alignment bytes are zeroed out to avoid uninitialized junk)
    pack_f32 xmm0, xmm1, xmm2    ; Lower boundary coordinates
    pack_f32 xmm3, xmm4, xmm5    ; Upper boundary coordinates

.packed:    ; Function variant with corners already packed
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

    ; Save the corners to the AABB structure
    ; [WARNING]: Pointer is expected to be 16-byte aligned
    vmovaps xmmword [rdi + AABB.minCorner], xmm0
    vmovaps xmmword [rdi + AABB.maxCorner], xmm3

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
; @features    AVX
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.expand#new:    ; Creates new object when called
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

    ; Copy the AABB structure to the new object 'other'
    AABB.copy rdi, rsi, xmm3, xmm4

AABB.expand#mutable:    ; Changes the object when called
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

    ; Pack the deltas into 'xmm0'
    pack_f32 xmm0, xmm1, xmm2    ; [deltaX, deltaY, deltaZ, 0.0]

.packed:    ; Function variant with deltas already packed
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

    ; Reusing registers for comparison masks
    vmovaps xmm1, xmm0
    vxorps  xmm2, xmm2, xmm2

    ; Save comparison masks (unordered -> NaN safely ignored)
    vcmpps xmm1, xmm1, xmm2, LT_OQ    ; delta < 0
    vcmpps xmm2, xmm0, xmm2, GT_OQ    ; delta > 0

    ; Calculate min & max deltas
    vandps xmm1, xmm1, xmm0    ; Min deltas will be added to 'min#' values of the structure
    vandps xmm2, xmm2, xmm0    ; Max deltas will be added to 'max#' values of the structure

.masks:    ; Function variant with deltas & masks precalculated
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaX, 0.0])
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

    ; Pack the structure to the temporal storage
    vmovaps xmm3, xmmword [rdi + AABB.minCorner]
    vmovaps xmm4, xmmword [rdi + AABB.maxCorner]

.loaded:    ; Function variant with all values precalculated & preloaded
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param this  rdi (pointer, "destination")
    ; @param deltas  xmm0 (as f32 array [deltaX, deltaY, deltaX, 0.0])
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

    ; Stretch the bounding box
    vaddps xmm3, xmm3, xmm1    ; Minimum Corner + Negative Deltas
    vaddps xmm4, xmm4, xmm2    ; Maximum Corner + Positive Deltas

    ; Save new values back to the structure
    vmovaps xmmword [rdi + AABB.minCorner], xmm3
    vmovaps xmmword [rdi + AABB.maxCorner], xmm4

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
; @features    AVX
; @effects     reads, computes, writes
;
; @author   Blanki
; @version  rd-132211
; @since    Minecraft Pre-Alpha
;
AABB.grow#new:
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
    ; @changed xmm3  (temporal storage) minimum corner of the original AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the original AABB structure
    ;

    ; Copy the AABB structure to the new object 'other'
    AABB.copy rdi, rsi, xmm3, xmm4

AABB.grow#mutable:
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

    ; Pack the amounts into 'xmm0'
    pack_f32 xmm0, xmm1, xmm2    ; [deltaX, deltaY, deltaZ, 0.0]

.packed:    ; Function variant with amounts already packed
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

    ; Save the structure to the temporal storage
    vmovaps xmm1, xmmword [rdi + AABB.minCorner]
    vmovaps xmm2, xmmword [rdi + AABB.maxCorner]

.loaded:    ; Function variant with amounts packed & corners preloaded
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

    ; Execute "grow" action with values
    vsubps xmm1, xmm1, xmm0    ; min# - amount#
    vaddps xmm2, xmm2, xmm0    ; max# + amount#

    ; Save new values to the structure
    vmovaps xmmword [rdi + AABB.minCorner], xmm1
    vmovaps xmmword [rdi + AABB.maxCorner], xmm2

    ret


;
; Precalculates useful data for clip#Collide functions SIMD style.
;
;   @param box0: *AABB  pointer to the AABB structure to check the collision with
;   @param box1: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movements: Array<f32>  desired motion offset along axes for 'box1'
;
; @features  AVX
; @effects   reads, computes
;
; @author   Blanki
; @version  1.0
; @since    Big Bang
;
%macro clipCollide 9
    ;
    ;   Calling convention:
    ;
    ; [WARNING]: AABB structure is considered 16-byte aligned in memory
    ;
    ; @param box0  %1, general-purpose (pointer)
    ; @param box1  %2, general-purpose (pointer)
    ;
    ; @param movements  %3, xmm-register (as f32 array [movementX, movementY, movementZ, 0.0])
    ;
    ; @param temps  %4-9, xmm-registers
    ;
    ;   Side Effects:
    ; @preserved %1  pointer is never changed, and can be reused
    ; @preserved %2  pointer is never changed, and can be reused
    ; @preserved %3  movements was never changed, and can be reused
    ;
    ; @changed %4  array of comparison masks (box0.min# >= box1.max#, no possible intersection)
    ; @changed %5  array of comparison masks (box0.max# <= box1.min#, no possible intersection)
    ; @changed %6  array of calculated movement values for each axis without considering intersections on other axes
    ;
    ; @destroyed %7-9  values are considered destroyed and potentially contain garbage
    ;

    ; Save the 'box0' AABB structure to the temporal storage
    vmovaps %4, xmmword [%1 + AABB.minCorner]
    vmovaps %5, xmmword [%1 + AABB.maxCorner]

    ; Save the 'box1' AABB structure to the temporal storage
    vmovaps %6, xmmword [%2 + AABB.minCorner]
    vmovaps %7, xmmword [%2 + AABB.maxCorner]

    ; Calculate both answers to avoid branching
    vsubps %8, %4, %7    ; box0.min# - box1.max#
    vsubps %9, %5, %6    ; box0.max# - box1.min#

    vminps %8, %8, %3    ; Clipping the positive distance
    vmaxps %9, %9, %3    ; Clipping the negative distance

    ; Conditions of the boxes being in specific positions
    vcmpps %4, %4, %7, GE_OQ    ; box0.min# >= box1.max#
    vcmpps %5, %5, %6, LE_OQ    ; box0.max# <= box1.min#

    vxorps %7, %7, %7    ; Zero out for comparisons

    vcmpps %6, %3, %7, GT_OQ    ; movement > 0 (Greater than, ordered, quiet)
    vcmpps %7, %3, %7, LT_OQ    ; movement < 0 (Less than, ordered, quiet)

    ; Calculate the full condition "box1 moving into box0"
    vandps %6, %4, %6    ; box1 is behind box0 and is moving in a positive direction
    vandps %7, %5, %7    ; box1 is after box0 and is moving in a negative direction

    ; Zero out the answer lanes that are not fell under the conditions
    vandps %8, %8, %6
    vandps %9, %9, %7

    ; Merge positives and negatives
    vorps %7, %6, %7    ; Conditions
    vorps %6, %8, %9    ; Clipped Distances

    ; Prepare the default values for merging with the answer
    vandnps %7, %7, %3

    ; Merge default values with conditional lanes
    vorps %6, %6, %7
%endmacro


;
; Calculates the maximum distance an external bounding box 'other'
; can move along the X-axis before colliding with 'this' bounding box.
;
; If no projection Y or Z axes overlap exists, 'movementX' is returned unclipped.
; If there's a possibility of colliding on X-axis, returns the minimal of
; the distance to the 'other' bounding box and 'movementX'.
;
;   @param box0: *AABB  pointer to the AABB structure to check the collision with
;   @param box1: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementX: f32  desired motion offset along the X-axis for 'other'
;
;   @return  the allowed movement amount along the X-axis, clipped to prevent penetration into 'this' box
;
; @convention  custom (Blanki)
; @features    AVX
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

    ; ; Move the movement value to the X-lane
    ; vinsertps xmm0, xmm0, xmm0, 0b00001110    ; No need, already there

    ; Calculate the values via macro you forget how works in three seconds
    clipCollide rsi, rdi, xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6

    ; Calculate the X-lane mask for no collision in YZ-plane detected
    vorps xmm2, xmm2, xmm1
    vinsertps xmm1, xmm1, xmm2, 0b01001110    ; Copy Y to X
    vinsertps xmm2, xmm2, xmm2, 0b10001110    ; Copy Z to X
    vorps xmm1, xmm1, xmm2

    ; Use mask to merge the result vector
    vandps  xmm0, xmm1, xmm0
    vandnps xmm3, xmm1, xmm3

    ; Merge the vectors getting the result in X-lane
    vorps xmm0, xmm0, xmm3

    ; Extract X-lane to return scalar f32
    extract_f32 xmm0, xmm0, vec.x
    ret


;
; Calculates the maximum distance an external bounding box 'other'
; can move along the Y-axis before colliding with 'this' bounding box.
;
; If no projection X or Z axes overlap exists, 'movementY' is returned unclipped.
; If there's a possibility of colliding on Y-axis, returns the minimal of
; the distance to the 'other' bounding box and 'movementY'.
;
;   @param box0: *AABB  pointer to the AABB structure to check the collision with
;   @param box1: *AABB  pointer to the AABB structure of the moving bounding box being checked against the static box
;
;   @param movementY: f32  desired motion offset along the Y-axis for 'other'
;
;   @return  the allowed movement amount along the Y-axis, clipped to prevent penetration into 'this' box
;
; @convention  custom (Blanki)
; @features    AVX
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

    ; Move the movement value to the Y-lane
    vinsertps xmm0, xmm0, xmm0, 0b00011101

    ; Calculate the values via macro you forget how works in three seconds
    clipCollide rsi, rdi, xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6

    ; Calculate the Y-lane mask for no collision in XZ-plane detected
    vorps xmm2, xmm2, xmm1
    vinsertps xmm1, xmm1, xmm2, 0b00011101    ; Copy X to Y
    vinsertps xmm2, xmm2, xmm2, 0b10011101    ; Copy Z to Y
    vorps xmm1, xmm1, xmm2

    ; Use mask to merge the result vector
    vandps  xmm0, xmm1, xmm0
    vandnps xmm3, xmm1, xmm3

    ; Merge the vectors getting the result in Y-lane
    vorps xmm0, xmm0, xmm3

    ; Extract Y-lane to return scalar f32
    extract_f32 xmm0, xmm0, vec.y
    ret


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
AABB.clipZCollide:
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

    ; Move the movement value to the Z-lane
    vinsertps xmm0, xmm0, xmm0, 0b00101011

    ; Calculate the values via macro you forget how works in three seconds
    clipCollide rsi, rdi, xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6

    ; Calculate the Z-lane mask for no collision in XY-plane detected
    vorps xmm2, xmm2, xmm1
    vinsertps xmm1, xmm1, xmm2, 0b00101011    ; Copy X to Z
    vinsertps xmm2, xmm2, xmm2, 0b01101011    ; Copy Y to Z
    vorps xmm1, xmm1, xmm2

    ; Use mask to merge the result vector
    vandps  xmm0, xmm1, xmm0
    vandnps xmm3, xmm1, xmm3

    ; Merge the vectors getting the result in Z-lane
    vorps xmm0, xmm0, xmm3

    ; Extract Z-lane to return scalar f32
    extract_f32 xmm0, xmm0, vec.z
    ret


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
AABB.intersects:
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
    ; @changed xmm0  array of comparison masks (box0.min# < box1.max#)
    ; @changed xmm1  array of comparison masks (box0.max# > box1.min#)
    ;
    ; @destroyed xmm2-3  values are considered destroyed and potentially contain garbage
    ;

    ; Save the 'box0' AABB structure to the temporal storage
    vmovaps xmm0, xmmword [rsi + AABB.minCorner]
    vmovaps xmm1, xmmword [rsi + AABB.maxCorner]

    ; Save the 'box1' AABB structure to the temporal storage
    vmovaps xmm2, xmmword [rdi + AABB.minCorner]
    vmovaps xmm3, xmmword [rdi + AABB.maxCorner]

    vcmpps xmm0, xmm0, xmm3, LT_OQ    ; box0.min# < box1.max#
    vcmpps xmm1, xmm1, xmm2, GT_OQ    ; box0.max# > box1.min#

    ; Load the comparison mask into the return register
    vandps xmm2, xmm0, xmm1
    vmovmskps rax, xmm2

    ; Check if the mask is what we need
    cmp rax, 0b0111    ; All conditions are met
    sete al

    ; Zero-extend 'al' into the full 'rax' register
    movzx eax, al
    ret


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
AABB.move#new:    ; Creates new object when called
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
    ; @changed xmm3  (temporal storage) minimum corner of the original AABB structure
    ; @changed xmm4  (temporal storage) maximum corner of the original AABB structure
    ;

    ; Copy the AABB structure to the new object 'other'
    AABB.copy rdi, rsi, xmm3, xmm4

AABB.move#mutable:
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

    ; Pack all the deltas into 'xmm0'
    pack_f32 xmm0, xmm1, xmm2    ; [deltaX, deltaY, deltaZ, 0.0]

.packed:
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

    ; Save the structure to the temporal storage
    vmovaps xmm1, xmmword [rdi + AABB.minCorner]
    vmovaps xmm2, xmmword [rdi + AABB.maxCorner]

.loaded:
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

    ; Move the values by the delta amount
    vaddps xmm1, xmm1, xmm0    ; min# + delta#
    vaddps xmm2, xmm2, xmm0    ; max# + delta#

    ; Save new values to the structure
    vmovaps xmmword [rdi + AABB.minCorner], xmm1
    vmovaps xmmword [rdi + AABB.maxCorner], xmm2

    ret
