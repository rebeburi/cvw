.section .text
.global test1
.type test1, @function

test1:
    # ----------------------------------------------------
    # 1. ABI Prologue (64-bit Version)
    # ----------------------------------------------------
    addi sp, sp, -112      # Allocate 112 bytes
    sd ra, 104(sp)         
    sd s0, 96(sp)
    sd s1, 88(sp)
    sd s2, 80(sp)
    sd s3, 72(sp)
    sd s4, 64(sp)
    sd s5, 56(sp)
    sd s6, 48(sp)
    sd s7, 40(sp)
    sd s8, 32(sp)
    sd s9, 24(sp)
    sd s10, 16(sp)
    sd s11, 8(sp)
    addi s0, sp, 112

    # ----------------------------------------------------
    # 2. FPU Logic 
    # ----------------------------------------------------
    la s1, val_a           # Load address of A
    la s2, val_b           # Load address of B
    la s3, result_loc      # Load address of Result

    fld f0, 0(s1)          # Load Double (A)
    fld f1, 0(s2)          # Load Double (B)

    fadd.d f2, f0, f1      # Add
    fsub.d f3, f0, f1      # Sub
    fmul.d f4, f0, f1      # Mul
    fdiv.d f5, f0, f1      # Div

    fsd f2, 0(s3)          # Store results
    fsd f3, 8(s3)
    fsd f4, 16(s3)
    fsd f5, 24(s3)

    li a0, 0xCAFE          # Success Marker

    # ----------------------------------------------------
    # 3. ABI Epilogue (64-bit Version)
    # ----------------------------------------------------
    ld s11, 8(sp)          
    ld s10, 16(sp)
    ld s9, 24(sp)
    ld s8, 32(sp)
    ld s7, 40(sp)
    ld s6, 48(sp)
    ld s5, 56(sp)
    ld s4, 64(sp)
    ld s3, 72(sp)
    ld s2, 80(sp)
    ld s1, 88(sp)
    ld s0, 96(sp)
    ld ra, 104(sp)
    addi sp, sp, 112
    jr ra

# ----------------------------------------------------
# Data Section
# ----------------------------------------------------
.section .data
.align 3                   # Align to 8 bytes (Double)

val_a:      .double 3.14159265359
val_b:      .double 2.71828182846

result_loc: .double 0.0
            .double 0.0
            .double 0.0
            .double 0.0