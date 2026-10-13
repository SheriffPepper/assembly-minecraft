%ifndef __TESTING_ASSERTIONS_PACKED_INCLUDE__
%define __TESTING_ASSERTIONS_PACKED_INCLUDE__


;
; Equality assertions for packed (vector) values.
; Public API is one macro per element type, and nothing else to remember:
;
;   ASSERT_EQUAL_PACKED.f32  xmm0, [expected], "min corner"
;   ASSERT_EQUAL_PACKED.u8   ymm1, ymm2,       "mask"
;   ASSERT_EQUAL_PACKED.f32  [a],  [b],        "two arrays", v128
;
; The register kind (xmm / ymm) and the operand shapes (reg-reg, reg-mem, mem-reg, mem-mem)
; are detected by macros. The element type only decides how the test runner prints the values.
;
; The comparison is BITWISE: '-0.0' is not equal to '+0.0', and two NaNs are equal only if their bits are equal.
;
; [NOTE]: Every vector register (including the upper halves) and every flag but ZF is preserved when assertion holds
;
; @author   Blanki
; @version  1.0
; @since    1.0
;


; Registers we're allowed to borrow (all of them are saved & restored)
%define __t_vec1  xmm15
%define __t_vec2  xmm14
%define __t_vec3  xmm13


; Widths of the vectors:  w128 (xmm), w256 (ymm), w512 (zmm)
; ('v128' & co are macros in 'definitions.inc': 'oword' & co, so we use our own names)
%define __t_width_xmm    w128
%define __t_width_ymm    w256
%define __t_width_zmm    w512

%define __t_width_oword  w128
%define __t_width_yword  w256
%define __t_width_zword  w512

%define __t_width_none   unknown    ; Memory without a size

; Scalar operands, immediates and memory of scalar sizes can't be the vectors
%define __t_width_gpr    bad
%define __t_width_other  bad
%define __t_width_byte   bad
%define __t_width_word   bad
%define __t_width_dword  bad
%define __t_width_qword  bad

%define __t_chunks_w128  1    ; How many 128-bit chunks the vector consists of
%define __t_chunks_w256  2
%define __t_chunks_w512  4

%define __t_tmp_w128  xmm15    ; Borrowed register of the same width as the vector
%define __t_tmp_w256  ymm15
%define __t_tmp_w512  zmm15


;
; Types of the lanes.
;
;   @param type   id of the type: 't_' and the name ('u32' is a macro in 'definitions.inc', so it can't be used as is)
;   @param size   size keyword of the lane
;   @param isfx   suffix of the integer instructions ('vpcmpeq?'): b / w / d / q
;   @param class  sint (signed integer), uint (unsigned integer), float
;   @param desc   what the type is called in 'TEST_VALUE_TYPE_*' as a string (they don't tell signed from unsigned)
;   @param fsfx   suffix of the floating-point instructions ('vcmp?'): ps / pd
;
%macro __t_def_lane 6    ; <type>, <size>, <isfx>, <class>, <desc>, <fsfx>
    %define __t_lane_size_%1   %2
    %define __t_lane_isfx_%1   %3
    %define __t_lane_class_%1  %4
    %define __t_lane_desc_%1   %5
    %define __t_lane_fsfx_%1   %6
%endmacro

__t_def_lane  t_u8,  byte,  b, uint,  "u8",  -
__t_def_lane  t_u16, word,  w, uint,  "u16", -
__t_def_lane  t_u32, dword, d, uint,  "u32", -
__t_def_lane  t_u64, qword, q, uint,  "u64", -
__t_def_lane  t_i8,  byte,  b, sint,  "u8",  -
__t_def_lane  t_i16, word,  w, sint,  "u16", -
__t_def_lane  t_i32, dword, d, sint,  "u32", -
__t_def_lane  t_i64, qword, q, sint,  "u64", -
__t_def_lane  t_f32, dword, d, float, "f32", ps
__t_def_lane  t_f64, qword, q, float, "f64", pd

; Type of the unsigned lane of a given size (for 'ASSERT_ONE_OF_PACKED' without a type)
%define __t_type_of_size_byte   t_u8
%define __t_type_of_size_word   t_u16
%define __t_type_of_size_dword  t_u32
%define __t_type_of_size_qword  t_u64


; Conditions: relation they check, and what kind of lanes they are for
%define __t_cond_rel_EQUAL             EQ
%define __t_cond_rel_NOT_EQUAL         NE
%define __t_cond_rel_LESS              LT
%define __t_cond_rel_LESS_OR_EQUAL     LE
%define __t_cond_rel_GREATER           GT
%define __t_cond_rel_GREATER_OR_EQUAL  GE
%define __t_cond_rel_BELOW             LT
%define __t_cond_rel_BELOW_OR_EQUAL    LE
%define __t_cond_rel_ABOVE             GT
%define __t_cond_rel_ABOVE_OR_EQUAL    GE

%define __t_cond_domain_EQUAL             any
%define __t_cond_domain_NOT_EQUAL         any
%define __t_cond_domain_LESS              signed
%define __t_cond_domain_LESS_OR_EQUAL     signed
%define __t_cond_domain_GREATER           signed
%define __t_cond_domain_GREATER_OR_EQUAL  signed
%define __t_cond_domain_BELOW             unsigned
%define __t_cond_domain_BELOW_OR_EQUAL    unsigned
%define __t_cond_domain_ABOVE             unsigned
%define __t_cond_domain_ABOVE_OR_EQUAL    unsigned

; Opposite relations of the integers
%define __t_not_LT  GE
%define __t_not_LE  GT
%define __t_not_GT  LE
%define __t_not_GE  LT


;  ================================================================================================
;   Operands
;  ================================================================================================


;
; Defines '%1' as the width of the vector operand: w128 / w256 / w512 / unknown (memory without a size) / bad.
;
%macro __t_operand_width 3    ; <out>, <operand>, <kind>
    %ifidn %3, mem
        __t_mem_size %%size, %2
        %xdefine %1  __t_width_%[%%size]
        %undef %%size
    %else
        %xdefine %1  __t_width_%[%3]
    %endif
%endmacro


;
; Defines '%1' as the width of the compared vectors, and stops the assembly if the operands don't make sense.
;
%macro __t_vec_width 4    ; <out>, <who>, <actual>, <expected>
    __t_operand_kind %%kind_a, %3
    __t_operand_kind %%kind_b, %4
    __t_operand_width %%width_a, %3, %%kind_a
    __t_operand_width %%width_b, %4, %%kind_b

    %if %isidn(%%width_a, bad) | %isidn(%%width_b, bad)
        %fatal "ASSERT_*_PACKED: operands must be vector registers or memory (for the general-purpose values use ASSERT_EQUAL, ASSERT_LESS...)"
    %endif

    %ifidn %%width_a, unknown
        %ifidn %%width_b, unknown
            %fatal "ASSERT_*_PACKED: can't compare two memory values of unknown size! Write the size in front of one of them: 'v128 [mem]'"
        %endif
        %xdefine %1  %%width_b
    %elifidn %%width_b, unknown
        %xdefine %1  %%width_a
    %elifidn %%width_a, %%width_b
        %xdefine %1  %%width_a
    %else
        %fatal "ASSERT_*_PACKED: operands have different sizes"
    %endif

    %undef %%kind_a
    %undef %%kind_b
    %undef %%width_a
    %undef %%width_b
%endmacro


;
; Copies the vector operands to the 'actual' & 'expected' fields of the 'TestFailure' object.
; Memory operands are copied through the borrowed register: so they go last, after the registers were saved.
;
%macro __t_spill 5    ; <width>, <actual>, <kind of actual>, <expected>, <kind of expected>
    %if __t_is_vec_kind(%3)
        vmovups [@failure.actual], %2
    %endif
    %if __t_is_vec_kind(%5)
        vmovups [@failure.expected], %4
    %endif
    %ifidn %3, mem
        vmovups __t_tmp_%[%1], %2
        vmovups [@failure.actual], __t_tmp_%[%1]
    %endif
    %ifidn %5, mem
        vmovups __t_tmp_%[%1], %4
        vmovups [@failure.expected], __t_tmp_%[%1]
    %endif
%endmacro


;
; Saves / restores the borrowed registers (and MXCSR when we're about to use floating-point instructions)
;
%macro __t_save_borrowed 1    ; <uses MXCSR: 0 | 1>
    %if %1
        vstmxcsr [@scratch.slot(3)]
    %endif
    vmovups [@scratch.slot(0)], __t_vec_full(__t_vec1)
    vmovups [@scratch.slot(1)], __t_vec_full(__t_vec2)
    vmovups [@scratch.slot(2)], __t_vec_full(__t_vec3)
%endmacro

%macro __t_restore_borrowed 1    ; <uses MXCSR: 0 | 1>
    vmovups __t_vec_full(__t_vec1), [@scratch.slot(0)]
    vmovups __t_vec_full(__t_vec2), [@scratch.slot(1)]
    vmovups __t_vec_full(__t_vec3), [@scratch.slot(2)]
    %if %1
        vldmxcsr [@scratch.slot(3)]
    %endif
%endmacro


;
; Defines '%1' as the 'TEST_VALUE_TYPE_VEC.*' constant of the vector.
;
%macro __t_vec_value_type 3    ; <out>, <width>, <lane type id | none>
    %defstr %%width  %2
    %substr %%bits   %%width 2, 3    ; 'w128' -> '128'
    %ifidn %3, none
        %strcat %%name  "TEST_VALUE_TYPE_VEC.v", %%bits
    %else
        %strcat %%name  "TEST_VALUE_TYPE_VEC.v", %%bits, ".", __t_lane_desc_%[%3]
    %endif
    %deftok %1  %%name
%endmacro


;  ================================================================================================
;   Lane masks
;  ================================================================================================
;
; Every mask macro works with a 128-bit chunk of the vectors: '__t_vec1' = actual, '__t_vec2' = expected.
; The result (all-ones in the lanes where the relation holds, otherwise zeroes) is left in '__t_vec1'.
; '__t_vec3' is a scratch register.
;
; Names of the masks:
;   SAME             the lane of 'actual' is bitwise equal to the lane of 'expected'
;   DIFF             the lanes are different (it's not a lane mask, but it's not zero if at least one bit is different)
;   LT LE GT GE      actual < expected, actual <= expected, actual > expected, actual >= expected
;   NLT NLE NGT NGE  floats only: "not less", "not less or equal"... (they are true for NaNs as well)
;


;
; Signed integer lanes
;
%macro __t_mask_sint 2    ; <mask>, <lane suffix: b | w | d | q>
    %ifidn %1, GT
        vpcmpgt%2  __t_vec1, __t_vec1, __t_vec2
    %elifidn %1, LT
        vpcmpgt%2  __t_vec1, __t_vec2, __t_vec1
    %elifidn %1, GE
        vpcmpgt%2  __t_vec3, __t_vec1, __t_vec2    ; Greater...
        vpcmpeq%2  __t_vec1, __t_vec1, __t_vec2    ; ...or equal
        vpor       __t_vec1, __t_vec1, __t_vec3
    %elifidn %1, LE
        vpcmpgt%2  __t_vec3, __t_vec2, __t_vec1    ; Less...
        vpcmpeq%2  __t_vec1, __t_vec1, __t_vec2    ; ...or equal
        vpor       __t_vec1, __t_vec1, __t_vec3
    %else
        %fatal "Unknown signed lane mask: " %1
    %endif
%endmacro


;
; Sets the sign bit in every lane of the register
;
%macro __t_sign_bits 2    ; <register>, <lane suffix: b | w | d | q>
    vpcmpeqd %1, %1, %1        ; All ones
    %ifidn %2, b
        vpabsb  %1, %1         ; 0x01 in every byte
        vpsllw  %1, %1, 7      ; 0x0101 << 7 = 0x8080
    %elifidn %2, w
        vpsllw  %1, %1, 15
    %elifidn %2, d
        vpslld  %1, %1, 31
    %else
        vpsllq  %1, %1, 63
    %endif
%endmacro


;
; Unsigned integer lanes: flip the sign bits of both values, and the unsigned order turns into the signed one
;
%macro __t_mask_uint 2    ; <mask>, <lane suffix: b | w | d | q>
    __t_sign_bits __t_vec3, %2
    vpxor __t_vec1, __t_vec1, __t_vec3
    vpxor __t_vec2, __t_vec2, __t_vec3
    __t_mask_sint %1, %2
%endmacro


;
; Floating-point lanes: 'vcmpps' / 'vcmppd' with the predicate in the last operand
; (0x11 = LT_OQ, 0x12 = LE_OQ, 0x1E = GT_OQ, 0x1D = GE_OQ: false for NaNs;
;  0x15 = NLT_UQ, 0x16 = NLE_UQ, 0x1A = NGT_UQ, 0x19 = NGE_UQ: true for NaNs; 'Q' = no exception for quiet NaNs)
;
%macro __t_mask_float 2    ; <mask>, <lane suffix: ps | pd>
    %ifidn %1, LT
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x11
    %elifidn %1, LE
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x12
    %elifidn %1, GT
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x1E
    %elifidn %1, GE
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x1D
    %elifidn %1, NLT
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x15
    %elifidn %1, NLE
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x16
    %elifidn %1, NGT
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x1A
    %elifidn %1, NGE
        vcmp%2  __t_vec1, __t_vec1, __t_vec2, 0x19
    %else
        %fatal "Unknown floating-point lane mask: " %1
    %endif
%endmacro


;
; Chooses the mask for the check: what makes the 'vptest' say "decided"?
;   ANY: some lane satisfies the condition             -> the mask of the condition
;   ALL: some lane does NOT satisfy the condition      -> the mask of the opposite condition
;
%macro __t_pick_mask 4    ; <out>, <quantifier: ALL | ANY>, <lane class>, <relation: EQ | NE | LT | LE | GT | GE>
    %ifidn %4, EQ
        %ifidn %2, ANY
            %xdefine %1  SAME
        %else
            %xdefine %1  DIFF
        %endif
    %elifidn %4, NE
        %ifidn %2, ANY
            %xdefine %1  DIFF
        %else
            %xdefine %1  SAME
        %endif
    %elifidn %2, ANY
        %xdefine %1  %4
    %elifidn %3, float
        %xdefine %1  N%+%4    ; LT -> NLT
    %else
        %xdefine %1  __t_not_%[%4]
    %endif
%endmacro


;
; Calculates the mask in '__t_vec1' for the current chunk
;
%macro __t_mask_compute 2    ; <mask>, <lane type | none>
    %ifidn %1, DIFF
        vpxor __t_vec1, __t_vec1, __t_vec2
    %elifidn %2, none
        %fatal "ASSERT_*_PACKED: this assertion needs the type of the lanes: write it after the name, like 'ASSERT_LESS_PACKED.i32'"
    %elifidn %1, SAME
        vpcmpeq%[__t_lane_isfx_%[%2]]  __t_vec1, __t_vec1, __t_vec2
    %elifidn __t_lane_class_%[%2], float
        __t_mask_float %1, __t_lane_fsfx_%[%2]
    %elifidn __t_lane_class_%[%2], sint
        __t_mask_sint %1, __t_lane_isfx_%[%2]
    %else
        __t_mask_uint %1, __t_lane_isfx_%[%2]
    %endif
%endmacro


;
; Goes through all the chunks of the vectors, and jumps to the label if the mask of any of them is not zero
;
%macro __t_chunk_loop 4    ; <mask>, <lane type | none>, <width>, <label>
    %assign %%chunk 0
    %rep __t_chunks_%[%3]
        vmovups __t_vec1, [@failure.actual   + %%chunk * 16]
        vmovups __t_vec2, [@failure.expected + %%chunk * 16]
        __t_mask_compute %1, %2
        vptest __t_vec1, __t_vec1
        jnz %4
        %assign %%chunk %%chunk + 1
    %endrep
%endmacro


;  ================================================================================================
;   ASSERT_<CONDITION>_PACKED[_ALL | _ANY][.<type>]
;  ================================================================================================


;
; Common implementation of every '<CONDITION>_PACKED' macro (see the tables and the "how it works" above).
;
;   @param who          name of the macro the user has called (for the error messages)
;   @param condition    EQUAL, NOT_EQUAL, LESS, LESS_OR_EQUAL, GREATER, GREATER_OR_EQUAL, BELOW, ...
;   @param quantifier   ALL | ANY
;   @param type         type of the lanes, or 'none'
;   @param actual       vector register | memory
;   @param expected     vector register | memory
;   @param description  [optional] name of the value in the failure report
;
%macro __t_packed_assert 6-7
    ; Assertions must work in Test Block only
    __t_assert_requirements %1
    __t_require_AVX %1

    ; Which lanes, which relation?
    %xdefine %%rel  __t_cond_rel_%[%2]
    %ifidn %4, none
        %xdefine %%class  none
    %else
        %ifndef __t_lane_class_%[%4]
            %fatal "ASSERT_*_PACKED: unknown type of the lanes"
        %endif
        %xdefine %%class  __t_lane_class_%[%4]

        ; 'LESS' is signed (or floats), 'BELOW' is unsigned
        %ifidn __t_cond_domain_%[%2], signed
            %if %isidn(%%class, uint)
                %fatal "ASSERT_*_PACKED: 'LESS' & 'GREATER' compare signed integers and floats, use 'BELOW' & 'ABOVE' for the unsigned ones"
            %endif
        %elifidn __t_cond_domain_%[%2], unsigned
            %ifnidn %%class, uint
                %fatal "ASSERT_*_PACKED: 'BELOW' & 'ABOVE' compare unsigned integers, use 'LESS' & 'GREATER' for the signed ones and floats"
            %endif
        %endif
    %endif
    __t_pick_mask %%mask, %3, %%class, %%rel

    ; Size of the vectors
    __t_vec_width %%width, %1, %5, %6
    %ifidn %%width, w512
        __t_require_AVX512f %1
    %endif

    ; Only the floating-point comparison can touch the MXCSR
    %if %isidn(%%class, float) & !(%isidn(%%mask, SAME) | %isidn(%%mask, DIFF))
        %assign %%fp  1
    %else
        %assign %%fp  0
    %endif

    ; What to tell the test runner
    __t_describe %%desc, %7, %5
    __t_vec_value_type %%vtype, %%width, %4
    %ifidn %3, ANY
        %xdefine %%kind  TEST_FAILURE_%[%2] | TEST_FAILURE_FLAG_ANY
    %else
        %xdefine %%kind  TEST_FAILURE_%[%2]
    %endif

    __t_operand_kind %%kind_a, %5
    __t_operand_kind %%kind_b, %6

    ; 1. Borrow the registers, 2. Copy the operands to the 'TestFailure' object
    __t_save_borrowed %%fp
    __t_spill %%width, %5, %%kind_a, %6, %%kind_b

    ; 3. Check the lanes
    %ifidn %3, ALL
        ; Violation of the condition by any lane fails the assertion
        __t_chunk_loop %%mask, %4, %%width, %%failed
        jmp %%passed
    %%failed:
        __test_fail %%kind, %%vtype, %%desc
    %else
        ; Any lane satisfying the condition is enough
        __t_chunk_loop %%mask, %4, %%width, %%passed
        __test_fail %%kind, %%vtype, %%desc
    %endif

%%passed:
    ; 4. Give the registers back
    __t_restore_borrowed %%fp
%endmacro


;  ================================================================================================
;   ASSERT_ONE_OF_PACKED[.<type>]
;  ================================================================================================


;
; Fills the register with copies of the scalar. 'vec2' is used as a zero.
;
%macro __t_broadcast 3    ; <register>, <scalar memory operand>, <size: byte | word | dword | qword>
    %ifidn %3, byte
        vpxor    %1, %1, %1
        vpinsrb  %1, %1, %2, 0
        vpxor    __t_vec2, __t_vec2, __t_vec2
        vpshufb  %1, %1, __t_vec2    ; Zero control byte = the first byte to every place
    %elifidn %3, word
        vpxor    %1, %1, %1
        vpinsrw  %1, %1, %2, 0
        vpshuflw %1, %1, 0           ; First word to the lower 4 words
        vpshufd  %1, %1, 0           ; First dword to all dwords
    %elifidn %3, dword
        vbroadcastss %1, %2
    %else
        vmovddup %1, %2
    %endif
%endmacro


;
; Checks that the scalar value is one of the lanes of the vector.
;
;   @param who          name of the macro the user has called (for the error messages)
;   @param type         type of the lanes, or 'none': then it's the unsigned type of the scalar's size
;   @param actual       general-purpose register | memory
;   @param expected     vector register | memory
;   @param description  [optional] name of the value in the failure report
;
%macro __t_one_of_assert 4-5
    ; Assertions must work in Test Block only
    __t_assert_requirements %1
    __t_require_AVX %1

    __t_operand_kind %%kind_a, %3
    __t_operand_kind %%kind_b, %4

    ; Scalar
    %ifidn %%kind_a, gpr
        %xdefine %%scalar_size  @reg.size(%3)
    %elifidn %%kind_a, mem
        __t_mem_size %%scalar_size, %3
    %else
        %fatal "ASSERT_ONE_OF_PACKED: 'actual' must be a general-purpose register or memory (a scalar value)"
    %endif

    ; Type of the lanes
    %ifidn %2, none
        %ifidn %%scalar_size, none
            %fatal "ASSERT_ONE_OF_PACKED: can't tell the size of the memory value, write the type ('ASSERT_ONE_OF_PACKED.u32') or the size ('dword [value]')"
        %endif
        %xdefine %%type  __t_type_of_size_%[%%scalar_size]
    %else
        %ifndef __t_lane_class_%[%2]
            %fatal "ASSERT_ONE_OF_PACKED: unknown type of the lanes"
        %endif
        %xdefine %%type  %2
        %ifnidn %%scalar_size, none
            %ifnidn %%scalar_size, __t_lane_size_%[%%type]
                %fatal "ASSERT_ONE_OF_PACKED: size of the value doesn't match the type of the lanes"
            %endif
        %endif
    %endif
    %xdefine %%size  __t_lane_size_%[%%type]

    ; Vector
    __t_operand_width %%width, %4, %%kind_b
    %if %isidn(%%width, bad) | %isidn(%%width, unknown)
        %fatal "ASSERT_ONE_OF_PACKED: 'expected' must be a vector register, or memory with a size: 'v128 [mem]'"
    %endif
    %ifidn %%width, w512
        __t_require_AVX512f %1
    %endif

    __t_describe %%desc, %5, %3
    __t_vec_value_type %%vtype, %%width, %%type

    ; 1. Borrow the registers
    __t_save_borrowed 0

    ; 2. Copy the operands to the 'TestFailure' object: the vector goes there, and the scalar is read from where it is
    ;    (a register is copied to the 'TestFailure' as well, since there's no way to read it from a register)
    %ifidn %%kind_a, gpr
        mov [@failure.actual], %3
        %xdefine %%source  [@failure.actual]
    %else
        %xdefine %%source  %3
    %endif
    %if __t_is_vec_kind(%%kind_b)
        vmovups [@failure.expected], %4
    %else
        vmovups __t_tmp_%[%%width], %4
        vmovups [@failure.expected], __t_tmp_%[%%width]
    %endif

    ; 3. Compare the scalar with every lane
    __t_broadcast __t_vec3, %%source, %%size
    %assign %%chunk 0
    %rep __t_chunks_%[%%width]
        vmovups __t_vec1, [@failure.expected + %%chunk * 16]
        vpcmpeq%[__t_lane_isfx_%[%%type]]  __t_vec1, __t_vec1, __t_vec3
        vptest __t_vec1, __t_vec1
        jnz %%passed    ; One of the lanes is the same
        %assign %%chunk %%chunk + 1
    %endrep

    ; None of the lanes is the same as the value:
    ; Construct the 'TestFailure' object ('expected' is already there)
    %ifidn %%kind_a, mem
        __t_fill_scalar @failure.actual, %3, mem, %%size
    %endif
    __test_fail TEST_FAILURE_ONE_OF, %%vtype, %%desc

%%passed:
    ; 4. Give the registers back
    __t_restore_borrowed 0
%endmacro


;  ================================================================================================
;   Public macros
;  ================================================================================================
;
; There're lots of them (the condition, the quantifier, the type), and they are all the same: so let's generate them.
; Every generated macro is a three-liner: it calls '__t_packed_assert' (or '__t_one_of_assert'),
; adding the constants it was generated with.
;


;
; Generates one macro.
;
;   @param name       name of the new macro
;   @param condition  EQUAL, LESS...
;   @param quantifier ALL | ANY
;   @param type       type of the lanes, or 'none'
;
%macro __t_generate 4
    ; The macro has to know its own name to find the constants: '%?' is the name of the macro being expanded
    %define __t_generated.%1  __t_packed_assert %1, %2, %3, %4,

    %macro %1 2-3
        __t_generated.%? %{1:-1}
    %endmacro
%endmacro


; All the types the lanes can have. (strings: 'u32' & 'f32' are macros, they would turn into 'dword')
%define __t_generate_typed(prefix, condition, quantifier)  __t_generate_types prefix, condition, quantifier, "u8", "u16", "u32", "u64", "i8", "i16", "i32", "i64", "f32", "f64"

;
; Generates the macros '<prefix>.<type>' for each of the types
;
%macro __t_generate_types 4-*    ; <prefix>, <condition>, <quantifier>, <type as a string>...
    %defstr %%prefix  %1
    %xdefine %%cond   %2
    %xdefine %%quant  %3
    %rotate 3
    %rep %0 - 3
        %strcat %%name  %%prefix, ".", %1
        %strcat %%id    "t_", %1
        %deftok %%name_token  %%name
        %deftok %%id_token    %%id
        __t_generate %[%%name_token], %%cond, %%quant, %[%%id_token]
        %rotate 1
    %endrep
%endmacro


%macro __t_generate_condition 1
    __t_generate_typed(ASSERT_%1_PACKED_ALL, %1, ALL)
    __t_generate_typed(ASSERT_%1_PACKED_ANY, %1, ANY)
    __t_generate_typed(ASSERT_%1_PACKED,     %1, ALL)
%endmacro

__t_generate_condition EQUAL
__t_generate_condition NOT_EQUAL
__t_generate_condition LESS
__t_generate_condition LESS_OR_EQUAL
__t_generate_condition GREATER
__t_generate_condition GREATER_OR_EQUAL
__t_generate_condition BELOW
__t_generate_condition BELOW_OR_EQUAL
__t_generate_condition ABOVE
__t_generate_condition ABOVE_OR_EQUAL


; The ones that make sense without the type: they're the bitwise comparison of the whole vectors
__t_generate ASSERT_EQUAL_PACKED_ALL,    EQUAL,     ALL, none
__t_generate ASSERT_EQUAL_PACKED,        EQUAL,     ALL, none
__t_generate ASSERT_NOT_EQUAL_PACKED_ANY, NOT_EQUAL, ANY, none


;
; Generates the 'ASSERT_ONE_OF_PACKED[.<type>]'
;
%macro __t_generate_one_of 2    ; <name>, <type | none>
    %define __t_generated.%1  __t_one_of_assert %1, %2,

    %macro %1 2-3
        __t_generated.%? %{1:-1}
    %endmacro
%endmacro

%macro __t_generate_one_of_typed 1    ; <type as a string>
    %strcat %%name  "ASSERT_ONE_OF_PACKED.", %1
    %strcat %%id    "t_", %1
    %deftok %%name_token  %%name
    %deftok %%id_token    %%id
    __t_generate_one_of %[%%name_token], %[%%id_token]
%endmacro

__t_generate_one_of ASSERT_ONE_OF_PACKED, none
__t_generate_one_of_typed "u8"
__t_generate_one_of_typed "u16"
__t_generate_one_of_typed "u32"
__t_generate_one_of_typed "u64"
__t_generate_one_of_typed "i8"
__t_generate_one_of_typed "i16"
__t_generate_one_of_typed "i32"
__t_generate_one_of_typed "i64"
__t_generate_one_of_typed "f32"
__t_generate_one_of_typed "f64"


%endif; __TESTING_ASSERTIONS_PACKED_INCLUDE__
