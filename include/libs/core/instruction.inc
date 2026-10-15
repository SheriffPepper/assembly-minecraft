%ifndef __CORE_INSTRUCTION_INCLUDE__
%define __CORE_INSTRUCTION_INCLUDE__

;
; Everything about the instructions: what CPU they need, and what their operands are.
; Included by 'definitions.inc', so it's available to every include-file and every assembly file.
;


%macro __h_reg_define 6    ; <register>, <size>, <is vector>, <is xmm>, <is ymm>, <is zmm>
    %define __h_reg_size_%1   %2
    %define __h_reg_isvec_%1  %3
    %define __h_reg_isxmm_%1  %4
    %define __h_reg_isymm_%1  %5
    %define __h_reg_iszmm_%1  %6
%endmacro

%macro __h_gpr_define 4    ; <64-bit>, <32-bit>, <16-bit>, <8-bit>
    __h_gpr_define_part %1, 8, %1, %2, %3, %4
    __h_gpr_define_part %2, 4, %1, %2, %3, %4
    __h_gpr_define_part %3, 2, %1, %2, %3, %4
    __h_gpr_define_part %4, 1, %1, %2, %3, %4
%endmacro

%macro __h_gpr_define_part 6    ; <reg>, <size>, <64-bit>, <32-bit>, <16-bit>, <8-bit>
    __h_reg_define %1, %2, 0, 0, 0, 0

    %define __h_reg_to64_%1  %3
    %define __h_reg_to32_%1  %4
    %define __h_reg_to16_%1  %5
    %define __h_reg_to8_%1   %6

    ; General-purpose register can't be turned into the vector one
    %define __h_reg_toxmm_%1  %1
    %define __h_reg_toymm_%1  %1
    %define __h_reg_tozmm_%1  %1
%endmacro


%macro __h_vec_define 1    ; <register number>
    __h_reg_define xmm%1, 16, 1, 1, 0, 0
    __h_reg_define ymm%1, 32, 1, 0, 1, 0
    __h_reg_define zmm%1, 64, 1, 0, 0, 1

    __h_vec_define_part xmm%1, %1
    __h_vec_define_part ymm%1, %1
    __h_vec_define_part zmm%1, %1
%endmacro

%macro __h_vec_define_part 2    ; <reg>, <register number>
    ; Vector register can't be turned into the general-purpose one
    %define __h_reg_to64_%1  %1
    %define __h_reg_to32_%1  %1
    %define __h_reg_to16_%1  %1
    %define __h_reg_to8_%1   %1

    %define __h_reg_toxmm_%1  xmm%2
    %define __h_reg_toymm_%1  ymm%2
    %define __h_reg_tozmm_%1  zmm%2
%endmacro


__h_gpr_define rax, eax, ax, al
__h_gpr_define rbx, ebx, bx, bl
__h_gpr_define rcx, ecx, cx, cl
__h_gpr_define rdx, edx, dx, dl
__h_gpr_define rsi, esi, si, sil
__h_gpr_define rdi, edi, di, dil
__h_gpr_define rbp, ebp, bp, bpl
__h_gpr_define rsp, esp, sp, spl
__h_gpr_define r8,  r8d,  r8w,  r8b
__h_gpr_define r9,  r9d,  r9w,  r9b
__h_gpr_define r10, r10d, r10w, r10b
__h_gpr_define r11, r11d, r11w, r11b
__h_gpr_define r12, r12d, r12w, r12b
__h_gpr_define r13, r13d, r13w, r13b
__h_gpr_define r14, r14d, r14w, r14b
__h_gpr_define r15, r15d, r15w, r15b


%assign __i_vec_number  0
%rep 16
    __h_vec_define __i_vec_number
    %assign __i_vec_number  __i_vec_number + 1
%endrep
%undef  __i_vec_number


%define __h_reg_get(property, reg, fallback)  %cond(%isnum(__h_reg_size_%+reg), __h_reg_%+property%+_%+reg, fallback)

%define @reg.size(reg)  __h_reg_get(size, reg, -1)

%define @reg.is_vec(reg)  __h_reg_get(isvec, reg, 0)
%define @reg.is_xmm(reg)  __h_reg_get(isxmm, reg, 0)
%define @reg.is_ymm(reg)  __h_reg_get(isymm, reg, 0)
%define @reg.is_zmm(reg)  __h_reg_get(iszmm, reg, 0)

%define @reg.to_xmm(reg)  __h_reg_get(toxmm, reg, reg)
%define @reg.to_ymm(reg)  __h_reg_get(toymm, reg, reg)
%define @reg.to_zmm(reg)  __h_reg_get(tozmm, reg, reg)

%define @reg.to_512(reg)  @reg.to_zmm(reg)
%define @reg.to_256(reg)  @reg.to_ymm(reg)
%define @reg.to_128(reg)  @reg.to_xmm(reg)

%define @reg.to_64(reg)   __h_reg_get(to64, reg, reg)
%define @reg.to_32(reg)   __h_reg_get(to32, reg, reg)
%define @reg.to_16(reg)   __h_reg_get(to16, reg, reg)
%define @reg.to_8(reg)    __h_reg_get(to8,  reg, reg)


%define __h_mem_size(&mem)  %eval( \
       (%isidn(%substr(mem, 1, 4), "byte")  * 1) \
     + (%isidn(%substr(mem, 1, 4), "word")  * 2) \
     + (%isidn(%substr(mem, 1, 5), "dword") * 4) \
     + (%isidn(%substr(mem, 1, 5), "qword") * 8) \
     + (%isidn(%substr(mem, 1, 5), "oword") * 16) \
     + (%isidn(%substr(mem, 1, 5), "yword") * 32) \
     + (%isidn(%substr(mem, 1, 5), "zword") * 64))

%define @mem.size(mem)  %cond(@operand.is_mem(mem) & (__h_mem_size(mem) != 0), __h_mem_size(mem), -1)


%define @operand.is_reg(op)   %eval(@reg.size(op) != -1)
%define @operand.is_mem(&op)  %isidn(%substr(op, %strlen(op), 1), "]")
%define @operand.is_imm(op)   %eval(@operand.is_reg(op) == @operand.is_mem(op))


; Delete the definition macros to not trash the namespace
%undef __h_reg_define
%undef __h_reg_gpr_define
%undef __h_reg_gpr_define_part
%undef __h_vec_define
%undef __h_vec_define_part


%endif; __CORE_INSTRUCTION_INCLUDE__
