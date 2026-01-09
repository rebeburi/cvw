# ==============================================================================
# FPU VERIFICATION - "SMART GRINDER" (Optimized for Speed)
# Strategy: 300 Loops + Flag Checking to capture Exception Logic faults.
# ==============================================================================

.section .text
.global test1
.type test1, @function

test1:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)   # Input Pointer
    sd s1, 40(sp)   # Output Pointer
    sd s2, 32(sp)   # Loop Counter
    sd s3, 24(sp)   # Random Seed (LFSR)

    # ----------------------------------------------------
    # 1. Setup
    # ----------------------------------------------------
    la s0, input_vectors      
    la s1, output_buffer      
    li s2, 100                # LOOP COUNT: 100 
    li s3, 0xACE1             # Seed for random generation

process_loop:
    # ----------------------------------------------------
    # 2. Input Generation (Hybrid)
    # ----------------------------------------------------
    # First 50 loops:  hardcoded vectors
    # Remaining 250 loops:  random numbers
    li t0, 50
    blt s2, t0, use_random

use_hardcoded:
    fld f0, 0(s0)
    fld f1, 8(s0)
    addi s0, s0, 16           # Advance input pointer
    j start_math

use_random:
    # LFSR for Input A
    srli t0, s3, 1
    xor  t1, s3, t0
    li   t2, 0x8000000000000000
    and  t2, t2, s3
    beqz t2, skip_tap1
    li   t4, 0xB400
    xor  t1, t1, t4
skip_tap1:
    mv   s3, t1
    fcvt.d.l f0, s3           # Random Double A

    # LFSR for Input B
    not  t1, s3               # Invert bits for variance
    fcvt.d.l f1, t1           # Random Double B

start_math:
    # ----------------------------------------------------
    # 3. The Gauntlet (Execute + Store + CHECK FLAGS)
    # ----------------------------------------------------
    
    # --- ADD ---
    fadd.d f2, f0, f1
    fsd    f2, 0(s1)          # Store Result
    frcsr  t5                 # READ FLAGS (Critical!)
    sd     t5, 8(s1)          # Store Flags
    
    # --- SUB ---
    fsub.d f3, f0, f1
    fsd    f3, 16(s1)
    frcsr  t5
    sd     t5, 24(s1)

    # --- MUL ---
    fmul.d f4, f0, f1
    fsd    f4, 32(s1)
    frcsr  t5
    sd     t5, 40(s1)

    # --- DIV ---
    # Add 1.0 to f1 to prevent Div-by-Zero hanging simulation
    li t6, 1
    fcvt.d.l f11, t6
    fadd.d f1, f1, f11        
    fdiv.d f5, f0, f1
    fsd    f5, 48(s1)
    frcsr  t5
    sd     t5, 56(s1)

    # --- SQRT ---
    fabs.d f0, f0             # Make positive
    fsqrt.d f6, f0
    fsd    f6, 64(s1)
    frcsr  t5
    sd     t5, 72(s1)

    # ----------------------------------------------------
    # 4. Loop Control
    # ----------------------------------------------------
    addi s1, s1, 80           # Advance Output Pointer
    addi s2, s2, -1           # Decrement Counter
    bnez s2, process_loop

    # Epilogue
    ld s3, 24(sp)
    ld s2, 32(sp)
    ld s1, 40(sp)
    ld s0, 48(sp)
    ld ra, 56(sp)
    addi sp, sp, 64
    ret



# ==============================================================================
# DATA SECTION 
# ==============================================================================
.section .data
.align 3

input_vectors:
    # --- Group 1: Standard & Edge Cases ---
    .double 3.14159, 2.71828        
    .double 1.23456789, 1.23456788  
    .long 0xFFFFFFFF, 0x7FEFFFFF, 0xFFFFFFFF, 0x7FEFFFFF # Max Double
    .long 0x00000001, 0x00000000, 0x00000000, 0x3FE00000 # Denorm & 0.5
    
    # --- Group 2: Special Values ---
    .long 0x00000000, 0x7FF00000, 0x00000000, 0x00000000 # +Inf & 0.0
    .long 0x00000000, 0xFFF00000, 0x00000000, 0x80000000 # -Inf & -0.0
    .long 0xFFFFFFFF, 0x7FFFFFFF, 0x00000000, 0x40000000 # NaN & 2.0
    .double -4.0, 1.0
    
    # --- Group 3: TDF Bit Toggles (Checkerboards) ---
    .long 0x55555555, 0x55555555, 0xAAAAAAAA, 0xAAAAAAAA 
    .long 0xAAAAAAAA, 0xAAAAAAAA, 0x55555555, 0x55555555
    
    # --- Group 4: Walking Ones (Targets Carry-Chain faults) ---
    .long 0x00000001, 0x00000000, 0xFFFFFFFE, 0xFFFFFFFF
    .long 0x00000002, 0x00000000, 0xFFFFFFFD, 0xFFFFFFFF
    .long 0x00000004, 0x00000000, 0xFFFFFFFB, 0xFFFFFFFF
    .long 0x00000008, 0x00000000, 0xFFFFFFF7, 0xFFFFFFFF
    .long 0x00000010, 0x00000000, 0xFFFFFFEF, 0xFFFFFFFF
    
    # --- Group 5: Mantissa Stress ---
    .long 0xAAAAAAAA, 0x3FEAAAAA, 0x55555555, 0x3FD55555
    .long 0x12345678, 0x400921FB, 0x87654321, 0xBFD00000
    .double 1e-15, 1e15
    .double 0.999999999999, 0.000000000001
    .double 6.022e23, 1.602e-19

        # --- Group 6: Exponent Extremes ---
    .double 1.0e308, 1.0e-308
    .double -1.0e308, -1.0e-308
    .double 2.2250738585072014e-308, 1.7976931348623157e308
    .double 4.0, 0.25
    .double -8.0, 0.125

    # --- Group 7: Cancellation & Precision Loss ---
    .double 1.000000000000001, 1.0
    .double 1.0000000000000002, 1.0
    .double 1.0e16, -1.0e16
    .double 1.0e16, 1.0
    .double 1.0e-16, 1.0

    # --- Group 8: Sign / Zero / Subnormal Stress ---
    .double -0.0, 0.0
    .double 0.0, -1.0
    .double -1.0, 0.0
    .long 0x00000001, 0x00000000, 0x00000002, 0x00000000  # tiny denorms
    .long 0x000FFFFF, 0x00000000, 0x00100000, 0x00000000

    # --- Group 9: Randomized Bit Patterns (Good for SAF/TDF) ---
    .long 0xDEADBEEF, 0x3FF12345, 0xCAFEBABE, 0x400ABCDE
    .long 0x0F0F0F0F, 0x4010F0F0, 0xF0F0F0F0, 0xBFF0F0F0
    .long 0xAAAAAAAA, 0x402AAAAA, 0x55555555, 0xC02AAAAA
    .long 0x11111111, 0x3FF11111, 0xEEEEEEEE, 0xBFF11111
    .long 0x13579BDF, 0x40013579, 0x2468ACE0, 0xC0013579

    # --- Group 10: Integer-Crossover Values (fcvt stress) ---
    .double 2147483647.0, -2147483648.0
    .double 2147483648.0, -2147483649.0
    .double 4294967295.0, 1.0
    .double -4294967296.0, -1.0
    .double 0.499999999999, 0.500000000001


# Reserve space for output
output_buffer:
    .space 32000