%ifndef __SIMD_INCLUDE__
%define __SIMD_INCLUDE__

;
; Standard definitions for Single-Instruction Multiple-Data (SIMD) code.
; That includes size constants, and some helpful macros.
;

; Define the aliases for word-sizes:
%define xmmword  oword
%define ymmword  yword
%define zmmword  zword


; Index of the f32 value in xmm-registers
vec.x  equ  0
vec.y  equ  1
vec.z  equ  2
vec.w  equ  3

; Comparison values
   EQ_OQ  equ  0         ; Equal (ordered and quiet)
   EQ_OS  equ  16        ; Equal (ordered and signaling)
   EQ_UQ  equ  8         ; Equal (unordered and quiet)
   EQ_US  equ  24        ; Equal (unordered and signaling)
  NEQ_OQ  equ  12        ; Not Equal (ordered and quiet)
  NEQ_OS  equ  28        ; Not Equal (ordered and signaling)
  NEQ_UQ  equ  4         ; Not Equal (unordered and quiet)
  NEQ_US  equ  20        ; Not Equal (unordered and signaling)

   LT_OQ  equ  17        ; Less than (ordered and quiet)
   LT_OS  equ  1         ; Less than (ordered and signaling)
   LT_UQ  equ  NGE_UQ    ; Less than (unordered and quiet)
   LT_US  equ  NGE_US    ; Less than (unordered and signaling)
  NLT_OQ  equ   GE_OQ    ; Not Less than (ordered and quiet)
  NLT_OS  equ   GE_OS    ; Not Less than (ordered and signaling)
  NLT_UQ  equ  21        ; Not Less than (unordered and quiet)
  NLT_US  equ  5         ; Not Less than (unordered and signaling)

   LE_OQ  equ  18        ; Less than or Equal (ordered and quiet)
   LE_OS  equ  2         ; Less than or Equal (ordered and signaling)
   LE_UQ  equ  NGT_UQ    ; Less than or Equal (unordered and quiet)
   LE_US  equ  NGT_US    ; Less than or Equal (unordered and signaling)
  NLE_OQ  equ   GT_OQ    ; Not Less than or Equal (ordered and quiet)
  NLE_OS  equ   GT_OS    ; Not Less than or Equal (ordered and signaling)
  NLE_UQ  equ  22        ; Not Less than or Equal (unordered and quiet)
  NLE_US  equ  6         ; Not Less than or Equal (unordered and signaling)

   GT_OQ  equ  30        ; Greater than (ordered and quiet)
   GT_OS  equ  14        ; Greater than (ordered and signaling)
   GT_UQ  equ  NLE_UQ    ; Greater than (unordered and quiet)
   GT_US  equ  NLE_US    ; Greater than (unordered and signaling)
  NGT_OQ  equ   LE_OQ    ; Not Greater than (ordered and quiet)
  NGT_OS  equ   LE_OS    ; Not Greater than (ordered and signaling)
  NGT_UQ  equ  26        ; Not Greater than (unordered and quiet)
  NGT_US  equ  10        ; Not Greater than (unordered and signaling)

   GE_OQ  equ  29        ; Greater than or Equal (ordered and quiet)
   GE_OS  equ  13        ; Greater than or Equal (ordered and signaling)
   GE_UQ  equ  NLT_UQ    ; Greater than or Equal (unordered and quiet)
   GE_US  equ  NLT_US    ; Greater than or Equal (unordered and signaling)
  NGE_OQ  equ   LT_OQ    ; Not Greater than or Equal (ordered and quiet)
  NGE_OS  equ   LT_OS    ; Not Greater than or Equal (ordered and signaling)
  NGE_UQ  equ  25        ; Not Greater than or Equal (unordered and quiet)
  NGE_US  equ  9         ; Not Greater than or Equal (unordered and signaling)

  ORD_Q   equ  7         ; Is Ordered (quiet)
  ORD_S   equ  23        ; Is Ordered (signaling)
UNORD_Q   equ  3         ; Is Unordered (quiet)
UNORD_S   equ  19        ; Is Unordered (signaling)

 TRUE_UQ  equ  15        ; Always True (quiet)
 TRUE_US  equ  31        ; Always True (signaling)
FALSE_OQ  equ  11        ; Always False (quiet)
FALSE_OS  equ  27        ; Always False (signaling)


;
; Packs two 'xmm#' registers into the the destination register, and zero out all the other values.
;
; @features  AVX
; @effects   computes
;
; @author   Blanki
; @version  1.0
; @since    Big Bang
;
%macro pack_f32 2
    ;
    ;   Side Effects:
    ; @changed destination  packed values of both registers (as f32 array [X, Y, 0, 0])
    ;
    vinsertps %1, %1, %2, 0b00011100    ; $1 = [X, Y, 0, 0]
%endmacro

;
; Pack three 'xmm#' registers into the destination register, and zero out all the other values.
;
; @features  AVX
; @effects   computes
;
; @author   Blanki
; @version  1.0
; @since    Big Bang
;
%macro pack_f32 3
    ;
    ;   Side Effects:
    ; @changed destination  packed values of both registers (as f32 array [X, Y, Z, 0])
    ;
    vinsertps %1, %1, %2, 0b00011100    ; $1 = [X, Y, 0, 0]
    vinsertps %1, %1, %3, 0b00101000    ; $1 = [X, Y, Z, 0]
%endmacro

;
; Pack four 'xmm#' registers into the destination register.
;
; @features  AVX
; @effects   computes
;
; @author   Blanki
; @version  1.0
; @since    Big Bang
;
%macro pack_f32 4
    ;
    ;   Side Effects:
    ; @changed destination  packed values of both registers (as f32 array [X, Y, Z, W])
    ;
    vinsertps %1, %1, %2, 0b00011100    ; $1 = [X, Y, 0, 0]
    vinsertps %1, %1, %3, 0b00101000    ; $1 = [X, Y, Z, 0]
    vinsertps %1, %1, %4, 0b00110000    ; $1 = [X, Y, Z, W]
%endmacro


;
; Extract one single precision floating-point value (f32)
; from the source register by index, and save it as scalar value in the destination.
;
; @features  AVX
; @effects   computes
;
; @author   Blanki
; @version  1.0
; @since    Big Bang
;
%macro extract_f32 3
    ;
    ;   Side Effects:
    ; @changed destination  picked scalar value (as scalar f32 [value, 0.0, 0.0, 0.0])
    ;
    vinsertps %1, %1, %2, 0b1110 | ((%3 & 0b11) << 6)
%endmacro


%endif; __SIMD_INCLUDE__
