.section .text
.global fpu_stress_test

fpu_stress_test:
    # --- Initialization ---
    li      t0, 0xACE1          # LFSR Seed
    li      t1, 500            # Loop counter (Increase for higher coverage)
    li      a0, 0               # Master Checksum (Observability)
    li      t3, 0xEDB88320      # Polynomial Taps
    
    # Load 1.0 into f10 as a starting accumulator value
    li      t2, 0x3F800000
    fmv.w.x f10, t2

fpu_loop:
    # --- 1. LFSR Logic (Generate random bits in t0) ---
    srli    t4, t0, 1
    andi    t5, t0, 1
    beqz    t5, skip_xor
    xor     t4, t4, t3
skip_xor:
    mv      t0, t4              
    
    # --- 2. Controllability (Input to FPU) ---
    fmv.w.x f1, t0              # Operand A: Random pattern from LFSR
    fadd.s  f2, f1, f1          # Operand B: Derived from A

    # --- 3. The New Stress Instructions ---
    # These target the 0.04% coverage areas you saw in your report
    fdiv.s  f11, f1, f2         # Stresses the Divider
    fsqrt.s f12, f1             # Stresses the Square Root
    fmadd.s f10, f1, f2, f10    # Stresses the FMA (Multiply-Add)

    # --- 4. Observability (Propagation to a0) ---
    # We XOR every result into a0. If a fault changes even 1 bit 
    # in any of these units, a0 will be corrupted at the strobe point.
    
    fmv.x.w t6, f11             # Observe Divider
    xor     a0, a0, t6          
    
    fmv.x.w t6, f12             # Observe Square Root
    xor     a0, a0, t6          
    
    fmv.x.w t6, f10             # Observe FMA
    xor     a0, a0, t6          
    
    # --- Loop Control ---
    addi    t1, t1, -1
    bnez    t1, fpu_loop

    ret                         # Final a0 is the result for main.c
