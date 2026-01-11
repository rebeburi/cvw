/* Copyright (c) 2019  ETH Zürich and University of Bologna
 * Modified for Bare Metal FPU Testing
 */

/* Entry point for bare metal programs */
.section .text.init
.global _start
.type _start, @function

_start:
    /* -------------------------------------- */
    /* 1. ENABLE FPU  */
    /* -------------------------------------- */
    li t0, 0x6000           # Set FS bits (13 and 14)
    csrs mstatus, t0        # Write to mstatus CSR

    /* -------------------------------------- */
    /* 2. Initialize Registers                */
    /* -------------------------------------- */
    li  x1, 0
    li  x2, 0
    li  x3, 0
    li  x4, 0
    li  x5, 0
    li  x6, 0
    li  x7, 0
    li  x8, 0
    li  x9, 0
    li  x10,0
    li  x11,0
    li  x12,0
    li  x13,0
    li  x14,0
    li  x15,0
    li  x16,0
    li  x17,0
    li  x18,0
    li  x19,0
    li  x20,0
    li  x21,0
    li  x22,0
    li  x23,0
    li  x24,0
    li  x25,0
    li  x26,0
    li  x27,0
    li  x28,0
    li  x29,0
    li  x30,0
    li  x31,0

    /* initialize global pointer */
.option push
.option norelax
    la gp, __global_pointer$
.option pop

    /* initialize stack pointer */
    la sp, _sp

    /* set vector table address and vectored mode */
    la a0, __vector_start
    ori a0, a0, 0x1
    csrw mtvec, a0

    /* -------------------------------------- */
    /* 3. Skip libc cleanup/init              */
    /* (Removed memset/atexit/libc calls)     */
    /* -------------------------------------- */

    /* call main */
    li a0, 0                        /* a0 = argc */
    li a1, 0                        /* a1 = argv */
    call main

  # Stop the simulator 
self_loop:
    j self_loop             # wait

.global _init
.type   _init, @function
.global _fini
.type   _fini, @function
_init:
_fini:
    ret
.size  _init, .-_init
.size _fini, .-_fini
