import struct

def float_to_hex(f):
    return hex(struct.unpack('<Q', struct.pack('<d', f))[0])

def generate_smart_vectors():
    print("# GENERATED 'SMART' VECTORS: ~36 PAIRS")
    print(".section .data")
    print(".align 3")
    print("input_vectors:")
    
    # 1. The "Paper" Patterns (Checkerboards)
    # Toggles all adjacent bits (0101 vs 1010)
    print("    .long 0x55555555, 0x55555555 # 0101... (A)")
    print("    .long 0x55555555, 0x55555555 # 0101... (B)")
    
    print("    .long 0xAAAAAAAA, 0xAAAAAAAA # 1010... (A)")
    print("    .long 0xAAAAAAAA, 0xAAAAAAAA # 1010... (B)")

    # 2. All Zeros and All Ones (Stuck-At Basics)
    print("    .long 0x00000000, 0x00000000")
    print("    .long 0x00000000, 0x00000000")
    
    print("    .long 0xFFFFFFFF, 0xFFFFFFFF")
    print("    .long 0xFFFFFFFF, 0xFFFFFFFF")

    # 3. Walking '1' (The "Stuck-At" Killer)
    # Moves a single 1 through critical positions to check for shorts.
    # We walk a '1' through the Mantissa and Exponent fields.
    shifts = [0, 1, 23, 30, 51, 62, 63] # Critical bit positions
    for i in shifts:
        val_a = 1 << i
        val_b = 1 << ((i + 1) % 64) # Offset by 1 to create difference
        
        # Convert to hex string for assembly
        hex_a_hi = (val_a >> 32) & 0xFFFFFFFF
        hex_a_lo = val_a & 0xFFFFFFFF
        hex_b_hi = (val_b >> 32) & 0xFFFFFFFF
        hex_b_lo = val_b & 0xFFFFFFFF
        
        print(f"    .long 0x{hex_a_lo:08X}, 0x{hex_a_hi:08X} # Walking 1 at bit {i}")
        print(f"    .long 0x{hex_b_lo:08X}, 0x{hex_b_hi:08X} # Walking 1 offset")

    # 4. Critical Math Corners (Reusing your Grinder logic)
    corners = [
        (1.0, 1.0),           # Simple Math
        (1.0, -1.0),          # Cancellation
        (float('inf'), 1.0),  # Infinity Logic
        (float('nan'), 1.0),  # NaN Logic
        (1e-308, 1e-308),     # Subnormal Logic
        (1.79e308, 1.79e308)  # Overflow Logic
    ]
    for a, b in corners:
        print(f"    .double {a}, {b}")

    # 5. Inverse Operations (Walking '0')
    # Start with all 1s, walk a 0.
    for i in shifts:
        val_a = ~(1 << i) & 0xFFFFFFFFFFFFFFFF
        val_b = ~(1 << ((i + 1) % 64)) & 0xFFFFFFFFFFFFFFFF
        
        hex_a_hi = (val_a >> 32) & 0xFFFFFFFF
        hex_a_lo = val_a & 0xFFFFFFFF
        hex_b_hi = (val_b >> 32) & 0xFFFFFFFF
        hex_b_lo = val_b & 0xFFFFFFFF
        
        print(f"    .long 0x{hex_a_lo:08X}, 0x{hex_a_hi:08X} # Walking 0")
        print(f"    .long 0x{hex_b_lo:08X}, 0x{hex_b_hi:08X}")

    print("\n# End of vectors")

generate_smart_vectors()