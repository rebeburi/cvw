# ==============================================================================
# FPU VERIFICATION - "THE GRINDER" (V3.0 - Industrial Paper Edition)
# Targets: Logic, Precision, Control, Hazards, Rounding, & Exception Masking
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
    li s2, 16                 # LOOP COUNT

    # ----------------------------------------------------
    # 2. The Loop
    # ----------------------------------------------------
process_next_pair:
    # --- A. Load Inputs (A and B) ---
    fld f0, 0(s0)             # Load A (Double)
    fld f1, 8(s0)             # Load B (Double)

    # ====================================================
    # PHASE 1: The Heavy Iron (Double Precision)
    # Target: Main Pipelines & Exception Flag Masking
    # ====================================================
    
    # 1. Addition
    fadd.d f2, f0, f1
    fsd f2, 0(s1)

    # 2. Subtraction
    fsub.d f3, f0, f1
    fsd f3, 8(s1)

    # 3. Multiplication
    fmul.d f4, f0, f1
    fsd f4, 16(s1)

    # 4. Division with Immediate Flag Check (Paper Recommendation)
    fdiv.d f5, f0, f1
    fsd f5, 24(s1)
    
    frcsr t0            # Read flags caused ONLY by Div
    sd t0, 32(s1)       # Store Div Flags
    fscsr x0            # Clear flags immediately

    # 5. Square Root with Immediate Flag Check
    fsqrt.d f6, f0
    fsd f6, 40(s1)

    frcsr t0            # Read flags caused ONLY by Sqrt
    sd t0, 48(s1)       # Store Sqrt Flags
    fscsr x0            # Clear flags

    # 6. FMA
    fmadd.d f7, f0, f1, f0
    fsd f7, 56(s1)

    # 7. Global Flag Check (Catch-all)
    frcsr t0
    sd t0, 64(s1)       
    fscsr x0            

    # ====================================================
    # PHASE 2: Auxiliary Units (Single & Converters)
    # Target: Format Logic, NaN Boxing, Comparators
    # ====================================================

    # 8. Convert Double -> Single 
    fcvt.s.d f10, f0          
    fcvt.s.d f11, f1          
    fsw f10, 72(s1)           # Store Single (4 bytes)
    fsw f11, 76(s1)           # Store Single (4 bytes)

    # 9. Single Precision Math 
    fadd.s f12, f10, f11      
    fsw f12, 80(s1)
    
    fmul.s f13, f10, f11      
    fsw f13, 84(s1)

    fdiv.s f14, f10, f11      
    fsw f14, 88(s1)

    fsqrt.s f15, f10          
    fsw f15, 92(s1)

    # 10. Conversions & Integer Interface
    fcvt.w.d t1, f0           # Double -> Int32
    sw t1, 96(s1)

    # 11. Comparators & Classify
    feq.d t2, f0, f1          
    sw t2, 100(s1)

    flt.d t3, f0, f1          
    sw t3, 104(s1)

    fclass.d t4, f0           
    sw t4, 108(s1)

    # 12. Extra Comparators (Min/Max)
    fmin.d f26, f0, f1
    fsd f26, 112(s1)     # Back to Double (8 bytes)
    
    fmax.d f27, f0, f1
    fsd f27, 120(s1)

    # 13. Round-Trip Conversion (Double->Int64->Double)
    # Replaces the "Half Precision" test from the paper
    fcvt.l.d t6, f0      # Double to Long
    fcvt.d.l f29, t6     # Long to Double
    fsd f29, 128(s1)     # Store result

    # ====================================================
    # PHASE 3: Register File Saturation
    # Target: Stuck-at Faults in f16-f31
    # ====================================================
    
    # Fill upper registers
    fmv.d f16, f0    
    fmv.d f17, f1    
    fmv.d f18, f2    
    fmv.d f19, f3    
    fmv.d f20, f4    
    fmv.d f21, f5
    fmv.d f22, f6
    fmv.d f23, f7
    fmv.d f24, f10   
    fmv.d f25, f11
    # f26, f27, f28, f29 used elsewhere
    
    fneg.d f30, f0
    fneg.d f31, f1

    # Checksum Compression
    fadd.d f8, f16, f17   
    fadd.d f9, f18, f19   
    fadd.d f8, f8, f20    
    fadd.d f9, f9, f21
    fadd.d f8, f8, f22
    fadd.d f9, f9, f23
    fadd.d f8, f8, f24
    fadd.d f9, f9, f25
    fadd.d f8, f8, f30    
    fadd.d f9, f9, f31    

    # Store Checksums
    fsd f8, 136(s1)
    fsd f9, 144(s1)

    # ====================================================
    # PHASE 4: Pipeline Hazards
    # Target: Forwarding Muxes
    # ====================================================
    
    fmv.d f28, f0             # Start with A (Use f28 to protect f1)
    fadd.d f28, f28, f1       # Step 1 
    fadd.d f28, f28, f28      # Step 2 (Hazard)
    fadd.d f28, f28, f28      # Step 3 (Hazard)
    
    fsd f28, 152(s1)          # Store Result

    # ====================================================
    # PHASE 5: Rounding Mode Thrashing
    # Target: Rounding Logic
    # ====================================================
    
    # RTZ
    li t5, 1
    fsrm t5                 
    fadd.d f10, f0, f1      
    fsd f10, 160(s1)        

    # RDN
    li t5, 2
    fsrm t5
    fadd.d f11, f0, f1      
    fsd f11, 168(s1)

    # RUP
    li t5, 3
    fsrm t5
    fadd.d f12, f0, f1      
    fsd f12, 176(s1)        # Last Store!

    # Restore RNE
    fsrm x0

    # --- D. Advance Pointers ---
    addi s0, s0, 16           # Input + 16 bytes
    addi s1, s1, 184          # Output + 184 bytes (176 offset + 8 size)
    
    addi s2, s2, -1           
    bnez s2, process_next_pair


    # ==============================================================================
# PHASE 6: REGISTER FILE THRASHING (Fixes 65k undetected faults)
# ==============================================================================
phase_6_registers:
    # 1. Load a pattern (e.g., All 1s) into an integer register
    li t0, -1               # Load 0xFFFFFFFFFFFFFFFF

    # 2. Move this pattern to EVERY Floating Point Register
    # This forces the "Write Enable" and "Decoder" logic to fire for all 32 regs
    fmv.d.x f0, t0
    fmv.d.x f1, t0
    fmv.d.x f2, t0
    fmv.d.x f3, t0
    fmv.d.x f4, t0
    fmv.d.x f5, t0
    fmv.d.x f6, t0
    fmv.d.x f7, t0
    fmv.d.x f8, t0
    fmv.d.x f9, t0
    fmv.d.x f10, t0
    # ... keep going for ALL 32 registers ...
    fmv.d.x f30, t0
    fmv.d.x f31, t0

    # 3. Verify by XORing them all together (Reading them back)
    # If any register is stuck at 0, the final checksum will be wrong.
    # We accumulate the result into fa0 (f10)
    fsgnj.d fa0, f0, f0     # Move f0 to accumulator
    xor t1, t0, t0          # Clear integer t1
    
    # Check f1
    fmv.x.d t1, f1          # Move f1 back to integer
    bne t1, t0, test_fail   # If f1 != 0xFF...FF, jump to fail

    # Check f31 (Do this for all of them ideally)
    fmv.x.d t1, f31
    bne t1, t0, test_fail

    # ==============================================================================
# PHASE 6: REGISTER FILE THRASHING (The "Coverage Booster")
# Purpose: Write to ALL 32 registers to wake up the unused storage logic.
# ==============================================================================
    
    # 1. Load a pattern that triggers all bits (All 1s = 0xFFFFFFFFFFFFFFFF)
    li t0, -1               

    # 2. EXCITATION: Blast this pattern into EVERY Floating Point Register
    # This forces the "Address Decoder" and "Write Enable" for every single slot.
    fmv.d.x f0, t0
    fmv.d.x f1, t0
    fmv.d.x f2, t0
    fmv.d.x f3, t0
    fmv.d.x f4, t0
    fmv.d.x f5, t0
    fmv.d.x f6, t0
    fmv.d.x f7, t0
    fmv.d.x f8, t0
    fmv.d.x f9, t0
    fmv.d.x f10, t0
    fmv.d.x f11, t0
    fmv.d.x f12, t0
    fmv.d.x f13, t0
    fmv.d.x f14, t0
    fmv.d.x f15, t0
    fmv.d.x f16, t0
    fmv.d.x f17, t0
    fmv.d.x f18, t0
    fmv.d.x f19, t0
    fmv.d.x f20, t0
    fmv.d.x f21, t0
    fmv.d.x f22, t0
    fmv.d.x f23, t0
    fmv.d.x f24, t0
    fmv.d.x f25, t0
    fmv.d.x f26, t0
    fmv.d.x f27, t0
    fmv.d.x f28, t0
    fmv.d.x f29, t0
    fmv.d.x f30, t0
    fmv.d.x f31, t0

    # 3. PROPAGATION: Read them back and XOR them into a Checksum
    # If any register is broken (stuck at 0), the XOR sum will change.
    li t1, 0                # Clear Accumulator (t1)
    
    # Macro-like unwinding to keep it fast
    fmv.x.d t2, f0          # Move f0 back to integer
    xor t1, t1, t2          # XOR into checksum
    
    fmv.x.d t2, f1
    xor t1, t1, t2
    
    fmv.x.d t2, f2
    xor t1, t1, t2
    
    fmv.x.d t2, f3
    xor t1, t1, t2
    
    fmv.x.d t2, f4
    xor t1, t1, t2
    
    fmv.x.d t2, f5
    xor t1, t1, t2
    
    fmv.x.d t2, f6
    xor t1, t1, t2
    
    fmv.x.d t2, f7
    xor t1, t1, t2
    
    fmv.x.d t2, f8
    xor t1, t1, t2
    
    fmv.x.d t2, f9
    xor t1, t1, t2
    
    fmv.x.d t2, f10
    xor t1, t1, t2
    
    fmv.x.d t2, f11
    xor t1, t1, t2
    
    fmv.x.d t2, f12
    xor t1, t1, t2
    
    fmv.x.d t2, f13
    xor t1, t1, t2
    
    fmv.x.d t2, f14
    xor t1, t1, t2
    
    fmv.x.d t2, f15
    xor t1, t1, t2
    
    fmv.x.d t2, f16
    xor t1, t1, t2
    
    fmv.x.d t2, f17
    xor t1, t1, t2
    
    fmv.x.d t2, f18
    xor t1, t1, t2
    
    fmv.x.d t2, f19
    xor t1, t1, t2
    
    fmv.x.d t2, f20
    xor t1, t1, t2
    
    fmv.x.d t2, f21
    xor t1, t1, t2
    
    fmv.x.d t2, f22
    xor t1, t1, t2
    
    fmv.x.d t2, f23
    xor t1, t1, t2
    
    fmv.x.d t2, f24
    xor t1, t1, t2
    
    fmv.x.d t2, f25
    xor t1, t1, t2
    
    fmv.x.d t2, f26
    xor t1, t1, t2
    
    fmv.x.d t2, f27
    xor t1, t1, t2
    
    fmv.x.d t2, f28
    xor t1, t1, t2
    
    fmv.x.d t2, f29
    xor t1, t1, t2
    
    fmv.x.d t2, f30
    xor t1, t1, t2
    
    fmv.x.d t2, f31
    xor t1, t1, t2

    # 4. OBSERVATION: Store the final checksum to memory
    # Zoix will see this write. If t1 is wrong, the Fault is DETECTED.
    sd t1, 0(s1)            # Store 64-bit checksum
    addi s1, s1, 8          # Increment pointer just in case

# ==============================================================================
# END OF PHASE 6
# ==============================================================================
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
# DATA SECTION (MERGED & CLEANED)
# Total Pairs: 40 (16 Original + 24 Smart)
# ==============================================================================
.section .data
.align 3

input_vectors:
    # --- PART 1: The "Grinder" Manual Corners (16 Pairs) ---
    .double 3.14159, 2.71828        
    .double 1.23456789, 1.23456788  
    .long 0xFFFFFFFF, 0x7FEFFFFF    
    .long 0xFFFFFFFF, 0x7FEFFFFF    
    .long 0x00000001, 0x00000000    
    .double 2.0                     
    .long 0x00000000, 0x7FF00000    
    .double 0.0                     
    .double 1.0
    .double 0.0
    .double 1.0
    .long 0x00000000, 0x80000000    
    .long 0xFFFFFFFF, 0x7FFFFFFF    
    .double 500.0                    
    .double -4.0                    
    .double 1.0                     
    .long 0xFFFFFFFF, 0x3FDFFFFF    
    .long 0x00000000, 0x3FE00000    
    .long 0x55555555, 0x55555555    
    .long 0xAAAAAAAA, 0xAAAAAAAA    
    .long 0xAAAAAAAA, 0xAAAAAAAA    
    .long 0x55555555, 0x55555555    
    .long 0xFFFFFFFF, 0xFFFFFFFF    
    .long 0x00000000, 0x00000000    
    .long 0x00000001, 0x00000000    
    .double 1.0
    .double 0.0
    .double 3.14159
    .long 0x00000000, 0x7FF00000    
    .double 1.0

# Reserve Output Space
output_buffer:
    .space 4000