#!/bin/bash

echo "--- Initializing Environment ---"
# Note: 'source' inside a script applies to the script's subshell
source setup.sh
source eda_tools_setup

echo "--- Updating Submodules ---"
git submodule update --init addins/verilog-ethernet/

echo "--- Building Derivatives ---"
make deriv

echo "--- Running Synthesis ---"
cd synthDC
./wallySynth_polito.py --tech nangate45 -t 50 -v fpu_test -c 16
cd ..

echo "--- Compiling Assembly ---"
cd examples/asm/sbst/
make
cd ../../..

echo "--- Running Gate-Level Simulation ---"
wsim --elf ./examples/asm/sbst/sbst.elf --gate --define "+define+GATE_LEVEL=1" --sim questa --tb testbench --vcd fpu_test

echo "--- Running Zoix Analysis ---"
cd zoix
./zoix_cvw.sh fpu_test questa

echo "--- Flow Completed Successfully ---"
