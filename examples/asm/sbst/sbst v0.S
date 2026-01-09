# ==============================================================================
# FPU VERIFICATION - "THE GRINDER" (Table-Driven Loop)
# ==============================================================================

.section .text
.global test1
.type test1, @function

test1:
    # ----------------------------------------------------
    # 1. Setup
    # ----------------------------------------------------
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)   # Input Pointer
    sd s1, 24(sp)   # Output Pointer
    sd s2, 16(sp)   # Counter
    addi s0, sp, 48

    # Initialize Pointers
    la s0, input_vectors      # Start of input data
    la s1, output_buffer      # Start of result area
    li s2, 10                 # LOOP COUNT: Process 10 pairs (adjust as needed)

    # ----------------------------------------------------
    # 2. The Loop
    # ----------------------------------------------------
process_next_pair:
    # A. Load Inputs (A and B)
    fld f0, 0(s0)             # Load A
    fld f1, 8(s0)             # Load B

    # B. Execute FPU Operations (The Gauntlet)
    
    # 1. Addition (A + B)
    fadd.d f2, f0, f1
    fsd f2, 0(s1)

    # 2. Subtraction (A - B)
    fsub.d f3, f0, f1
    fsd f3, 8(s1)

    # 3. Multiplication (A * B)
    fmul.d f4, f0, f1
    fsd f4, 16(s1)

    # 4. Division (A / B)
    fdiv.d f5, f0, f1
    fsd f5, 24(s1)

    # 5. Square Root (Sqrt A)
    fsqrt.d f6, f0
    fsd f6, 32(s1)

    # 6. Fused Multiply-Add (A * B + A)
    fmadd.d f7, f0, f1, f0
    fsd f7, 40(s1)

    # C. Check for Exceptions (Optional but recommended)
    # We read the flags, store them, and CLEAR them for the next loop
    frcsr t0
    sd t0, 48(s1)             # Store flags for this specific pair
    fscsr x0                  # Clear flags (reset to 0)

    # D. Advance Pointers & Loop Control
    addi s0, s0, 16           # Advance Input by 16 bytes (2 doubles)
    addi s1, s1, 56           # Advance Output by 56 bytes (6 doubles + 1 long)
    
    addi s2, s2, -1           # Decrement counter
    bnez s2, process_next_pair

    # ----------------------------------------------------
    # 3. Finish
    # ----------------------------------------------------
    ld s2, 16(sp)
    ld s1, 24(sp)
    ld s0, 32(sp)
    ld ra, 40(sp)
    addi sp, sp, 48
    jr ra

# ==============================================================================
# DATA SECTION - THE VECTORS
# ==============================================================================
.section .data
.align 3

input_vectors:
    # --- PAIR 1: Standard Math ---
    .double 3.14159, 2.71828        # Pi, e

    # --- PAIR 2: Cancellation (Similar numbers) ---
    .double 1.23456789, 1.23456788  # Result should be tiny

    # --- PAIR 3: Overflow Stimulus ---
    .long 0xFFFFFFFF, 0x7FEFFFFF    # Max Double
    .long 0xFFFFFFFF, 0x7FEFFFFF    # Max Double (Add = Inf, Mul = Inf)

    # --- PAIR 4: Underflow Stimulus (Denorms) ---
    .long 0x00000001, 0x00000000    # Smallest Subnormal
    .double 2.0                     # Divide by 2 (Result gets smaller)

    # --- PAIR 5: The "Invalid" Trigger ---
    .long 0x00000000, 0x7FF00000    # +Infinity
    .double 0.0                     # Zero (Inf * 0 = NaN)

    # --- PAIR 6: The "Divide by Zero" Trigger ---
    .double 1.0
    .double 0.0

    # --- PAIR 7: Mixed Signs (Negative Zero check) ---
    .double 1.0
    .long 0x00000000, 0x80000000    # -0.0 (Negative Zero)

    # --- PAIR 8: NaN Propagation ---
    .long 0xFFFFFFFF, 0x7FFFFFFF    # QNaN
    .double 500.0                   

    # --- PAIR 9: Sqrt of Negative (Invalid) ---
    .double -4.0                    # Sqrt(-4) = NaN
    .double 1.0                     # Dummy

    # --- PAIR 10: Precision Edge (Mantissa limit) ---
    .long 0xFFFFFFFF, 0x3FDFFFFF    # 0.4999999...
    .long 0x00000000, 0x3FE00000    # 0.5

# Reserve huge space for output
output_buffer:
    .space 4096