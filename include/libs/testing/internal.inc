%ifndef __TESTING_INTERNAL_INCLUDE__
%define __TESTING_INTERNAL_INCLUDE__


;
; Internal helpers shared by every public testing macro.
; Nothing in this file is meant to be called from test code directly.
;
; The idea: public macros stay tiny (guard -> classify -> dispatch), and every
; "what am I looking at?" question is answered by exactly one macro in this file.
;
; @author   Blanki
; @version  1.0
; @since    1.0
;


;
; Stops the assembly if we're not inside of a Test Module.
;
;   @param message  message for macro's error
;
%macro __t_require_module 1
    %defstr %%type  %[@module.type]
    %ifn %%type == "_TEST_"
        %fatal %1
    %endif
    %undef  %%type
%endmacro


;
; Stops the assembly if we're not inside of a Test Block.
;
;   @param message  message for macro's error
;
%macro __t_require_test 1
    %ifnctx __test_block__
        %fatal %1
    %endif
%endmacro


;
; Classifies an operand and defines the single-line macro '%1' with the result:
; 'xmm', 'ymm', 'zmm' (vector registers), 'gpr' (general-purpose register),
; 'mem' (ends with ']'), or 'other' (immediate, label, anything else).
;
%macro __t_operand_kind 2
    %defstr %%text  %2
    %strlen %%size  %%text
    %substr %%last  %%text  %%size

    %ifidn %%last, "]"
        %xdefine %1  mem
    %elifdef __is_vec_%2
        %if __is_xmm_%2
            %xdefine %1  xmm
        %elif __is_ymm_%2
            %xdefine %1  ymm
        %elif __is_zmm_%2
            %xdefine %1  zmm
        %else
            %xdefine %1  gpr
        %endif
    %else
        %xdefine %1  other
    %endif

    %undef %%text
    %undef %%size
    %undef %%last
%endmacro


; Tells if the operand kind (see '__t_operand_kind') is a vector register
%define __t_is_vec_kind(kind)  (%isidn(kind, xmm) | %isidn(kind, ymm) | %isidn(kind, zmm))


; Register 'rax' of the same size
; (The only general-purpose register assertions are allowed to clobber, on the failure path)
%define __t_gp_temp_byte   al
%define __t_gp_temp_word   ax
%define __t_gp_temp_dword  eax
%define __t_gp_temp_qword  rax


;
; Stops the assembly if a CPU feature required by the macro was not passed to NASM.
; One macro per feature: the feature name can't be passed as a parameter, because NASM would expand
; '-DAVX' (which is 'AVX = 1') before the '%ifndef' could look at the name.
;
;   @param who  name of the macro that asks (used in the error message)
;

%macro __t_require_SSE 1
    %ifndef SSE
        %fatal %1: requires SSE, but -DSSE was not passed to NASM
    %endif
%endmacro

%macro __t_require_SSE2 1
    %ifndef SSE2
        %fatal %1: requires SSE2, but -DSSE2 was not passed to NASM
    %endif
%endmacro

%macro __t_require_SSE3 1
    %ifndef SSE3
        %fatal %1: requires SSE3, but -DSSE3 was not passed to NASM
    %endif
%endmacro

%macro __t_require_SSSE3 1
    %ifndef SSSE3
        %fatal %1: requires SSSE3, but -DSSSE3 was not passed to NASM
    %endif
%endmacro

%macro __t_require_SSE4_1 1
    %ifndef SSE4_1
        %fatal %1: requires SSE4.1, but -DSSE4_1 was not passed to NASM
    %endif
%endmacro

%macro __t_require_SSE4_2 1
    %ifndef SSE4_2
        %fatal %1: requires SSE4.2, but -DSSE4_2 was not passed to NASM
    %endif
%endmacro

%macro __t_require_AVX 1
    %ifndef AVX
        %fatal %1: requires AVX, but -DAVX was not passed to NASM
    %endif
%endmacro

%macro __t_require_AVX2 1
    %ifndef AVX2
        %fatal %1: requires AVX2, but -DAVX was not passed to NASM
    %endif
%endmacro

%macro __t_require_AVX512f 1
    %ifndef AVX512f
        %fatal %1: requires AVX-512f, but -DAVX was not passed to NASM
    %endif
%endmacro


%endif; __TESTING_INTERNAL_INCLUDE__
