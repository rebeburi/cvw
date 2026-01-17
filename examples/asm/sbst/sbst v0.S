# ==============================================================================
# FPU VERIFICATION - "THE GRINDER" (Final SBST Version)
# Targets: Logic, Precision, Control, and Register File Coverage
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
    sd s2, 16(sp)   # Loop Counter
    addi s0, sp, 48

    # Initialize Pointers
    la s0, input_vectors      # Start of input data
    la s1, output_buffer      # Start of result area
    li s2, 13                 # LOOP COUNT: 13 Pairs (10 Standard + 3 High-Toggle)

    # ----------------------------------------------------
    # 2. The Loop
    # ----------------------------------------------------
process_next_pair:
    # --- A. Load Inputs (A and B) ---
    fld f0, 0(s0)             # Load A (Double)
    fld f1, 8(s0)             # Load B (Double)

    # ====================================================
    # PHASE 1: The Heavy Iron (Double Precision)
    # Target: Main Arithmetic Pipelines & FMA
    # ====================================================
    
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

    # --- Check for Exceptions ---
    frcsr t0
    sd t0, 48(s1)             # Store flags
    fscsr x0                  # Clear flags

    # ====================================================
    # PHASE 2: The Missing Links (PDF Configurable/Aux)
    # Target: Single Precision, Converters, Comparators
    # ====================================================

    # 7. Convert Double -> Single (Tests Unpack/Round logic)
    fcvt.s.d f10, f0          # A -> Single
    fcvt.s.d f11, f1          # B -> Single
    fsw f10, 56(s1)           # Store Single A (4 bytes)
    fsw f11, 60(s1)           # Store Single B (4 bytes)

    # 8. Single Precision Math (Tests "Multiple Precisions" logic)
    fadd.s f12, f10, f11      # Add Single
    fsw f12, 64(s1)
    
    fmul.s f13, f10, f11      # Mul Single
    fsw f13, 68(s1)

    # 9. Single Precision Iterative (Tests 32-bit loop termination)
    fdiv.s f14, f10, f11      # Div Single
    fsw f14, 72(s1)

    fsqrt.s f15, f10          # Sqrt Single
    fsw f15, 76(s1)

    # 10. Conversions & Integer Interface
    fcvt.w.d t1, f0           # Double -> Int32
    sw t1, 80(s1)

    # 11. Comparators & Classify
    feq.d t2, f0, f1          # A == B?
    sw t2, 84(s1)

    flt.d t3, f0, f1          # A < B?
    sw t3, 88(s1)

    fclass.d t4, f0           # Classify A (Inf/NaN/Norm)
    sw t4, 92(s1)

    # ====================================================
    # PHASE 3: Register File Saturation
    # Target: Toggle coverage for f16-f31 (Stuck-at Faults)
    # ====================================================
    
    # Fill the upper registers with data from previous steps
    fmv.d f16, f0    
    fmv.d f17, f1    
    fmv.d f18, f2    
    fmv.d f19, f3    
    fmv.d f20, f4    
    fmv.d f21, f5
    fmv.d f22, f6
    fmv.d f23, f7
    fmv.d f24, f10   # Note: Moving Single to Double reg is valid (NaN-boxed)
    fmv.d f25, f11
    fmv.d f26, f12
    fmv.d f27, f13
    fmv.d f28, f14
    fmv.d f29, f15
    
    # Use f30/f31 for inverted inputs (Logic toggle)
    fneg.d f30, f0
    fneg.d f31, f1

    # --- The Chain of Adds ---
    # We compress f16-f31 into two checksums (f8, f9) to save memory 
    # while ensuring every register output is "observed".
    
    fadd.d f8, f16, f17   # Start Accumulator 1
    fadd.d f9, f18, f19   # Start Accumulator 2

    fadd.d f8, f8, f20    # Chain...
    fadd.d f9, f9, f21
    
    fadd.d f8, f8, f22
    fadd.d f9, f9, f23
    
    fadd.d f8, f8, f24
    fadd.d f9, f9, f25
    
    fadd.d f8, f8, f26
    fadd.d f9, f9, f27
    
    fadd.d f8, f8, f28
    fadd.d f9, f9, f29
    
    fadd.d f8, f8, f30    # Finalize Accumulator 1
    fadd.d f9, f9, f31    # Finalize Accumulator 2

    # Store the Checksums
    fsd f8, 96(s1)
    fsd f9, 104(s1)

    # --- D. Advance Pointers & Loop Control ---
    addi s0, s0, 16           # Advance Input by 16 bytes (2 doubles)
    addi s1, s1, 112          # Advance Output (Matches total bytes stored per loop)
    
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
# DATA SECTION
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
    .long 0xFFFFFFFF, 0x7FEFFFFF    # Max Double

    # --- PAIR 4: Underflow Stimulus (Denorms) ---
    .long 0x00000001, 0x00000000    # Smallest Subnormal
    .double 2.0                     # Divide by 2

    # --- PAIR 5: The "Invalid" Trigger ---
    .long 0x00000000, 0x7FF00000    # +Infinity
    .double 0.0                     # Zero

    # --- PAIR 6: The "Divide by Zero" Trigger ---
    .double 1.0
    .double 0.0

    # --- PAIR 7: Mixed Signs (Negative Zero check) ---
    .double 1.0
    .long 0x00000000, 0x80000000    # -0.0

    # --- PAIR 8: NaN Propagation ---
    .long 0xFFFFFFFF, 0x7FFFFFFF    # QNaN
    .double 500.0                   

    # --- PAIR 9: Sqrt of Negative (Invalid) ---
    .double -4.0                    # Sqrt(-4) = NaN
    .double 1.0                     # Dummy

    # --- PAIR 10: Precision Edge (Mantissa limit) ---
    .long 0xFFFFFFFF, 0x3FDFFFFF    # 0.4999999...
    .long 0x00000000, 0x3FE00000    # 0.5

    # --- PAIR 11: The "Checkerboard" (Bridging Faults) ---
    .long 0x55555555, 0x55555555    # 0101...
    .long 0xAAAAAAAA, 0xAAAAAAAA    # 1010...

    # --- PAIR 12: The "Inverse" (Toggle Coverage) ---
    .long 0xAAAAAAAA, 0xAAAAAAAA    # 1010...
    .long 0x55555555, 0x55555555    # 0101...

    # --- PAIR 13: The "All-Ones" Saturation (Stuck-At) ---
    .long 0xFFFFFFFF, 0xFFFFFFFF    # All Ones
    .long 0x00000000, 0x00000000    # All Zeros

# Reserve huge space for output
output_buffer:
    .space 4096