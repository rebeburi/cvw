///////////////////////////////////////////
// wally-pipelinedsoc.sv
//
// Written: David_Harris@hmc.edu 6 November 2020
// Modified:
//
// Purpose: System on chip including pipelined processor and uncore memories/peripherals
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module wallypipelinedsoc import cvw::*; #(parameter cvw_t P)  (
  input  logic                clk,
  input  logic                reset_ext,        // external asynchronous reset pin
  output logic                reset,            // reset synchronized to clk to prevent races on release
  // AHB Interface
  input  logic [P.AHBW-1:0]   HRDATAEXT,
  input  logic                HREADYEXT, HRESPEXT,
  output logic                HSELEXT,
  // fpga debug signals
  input  logic                ExternalStall,
  // outputs to external memory, shared with uncore memory
  output logic                HCLK, HRESETn,
  output logic [P.PA_BITS-1:0]  HADDR,
  output logic [P.AHBW-1:0]     HWDATA,
  output logic [P.XLEN/8-1:0]   HWSTRB,
  output logic                HWRITE,
  output logic [2:0]          HSIZE,
  output logic [2:0]          HBURST,
  output logic [3:0]          HPROT,
  output logic [1:0]          HTRANS,
  output logic                HMASTLOCK,
  output logic                HREADY,
  // I/O Interface
  input  logic                TIMECLK,          // optional for CLINT MTIME counter
  input  logic [31:0]         GPIOIN,           // inputs from GPIO
  output logic [31:0]         GPIOOUT,          // output values for GPIO
  output logic [31:0]         GPIOEN,           // output enables for GPIO
  input  logic                UARTSin,          // UART serial data input
  output logic                UARTSout,         // UART serial data output
  input  logic                SPIIn,            // SPI pins in
  output logic                SPIOut,           // SPI pins out
  output logic [3:0]          SPICS,            // SPI chip select pins
  output logic                SPICLK,           // SPI clock
  input  logic                SDCIn,            // SDC DATA[0]     to     SPI DI
  output logic                SDCCmd,           // SDC CMD         from   SPI DO
  output logic [3:0]          SDCCS,            // SDC Card Detect from   SPI CS
  output logic                SDCCLK            // SDC Clock       from   SPI Clock
);

  // Uncore signals
  logic [P.AHBW-1:0]          HRDATA;           // from AHB mux in uncore
  logic                       HRESP;            // response from AHB
  logic                       MTimerInt, MSwInt;// timer and software interrupts from CLINT
  logic [63:0]                MTIME_CLINT;      // from CLINT to CSRs
  logic                       MExtInt,SExtInt;  // from PLIC

`ifdef GATE_LEVEL 
  // Uncore signals for Gate
  logic [P.AHBW-1:0]          HRDATA_gate;           // from AHB mux in uncore
  logic                       HRESP_gate;            // response from AHB
  logic                       MTimerInt_gate, MSwInt_gate;// timer and software interrupts from CLINT
  logic [63:0]                MTIME_CLINT_gate;      // from CLINT to CSRs
  logic                       MExtInt_gate,SExtInt_gate;  // from PLIC

  // we redefine the RTL signals for comparing with the gate
  // Uncore signals for RTL
  logic [P.AHBW-1:0]          HRDATA_RTL;           // from AHB mux in uncore
  logic                       HRESP_RTL;            // response from AHB
  logic                       MTimerInt_RTL, MSwInt_RTL;// timer and software interrupts from CLINT
  logic [63:0]                MTIME_CLINT_RTL;      // from CLINT to CSRs
  logic                       MExtInt_RTL,SExtInt_RTL;  // from PLIC

  // Duplicates I/Os
  logic [P.AHBW-1:0]     HRDATAEXT_RTL,HRDATAEXT_gate;
  logic                  HREADYEXT_RTL,HREADYEXT_gate, HRESPEXT_RTL,HRESPEXT_gate;
  logic                  HSELEXT_RTL,HSELEXT_gate;
  logic                  ExternalStall_RTL,ExternalStall_gate;
  logic                  HCLK_RTL,HCLK_gate, HRESETn_RTL,HRESETn_gate;
  logic [P.PA_BITS-1:0]  HADDR_RTL,HADDR_gate;
  logic [P.AHBW-1:0]     HWDATA_RTL,HWDATA_gate;
  logic [P.XLEN/8-1:0]   HWSTRB_RTL,HWSTRB_gate;
  logic                  HWRITE_RTL,HWRITE_gate;
  logic [2:0]            HSIZE_RTL,HSIZE_gate;
  logic [2:0]            HBURST_RTL,HBURST_gate;
  logic [3:0]            HPROT_RTL,HPROT_gate;
  logic [1:0]            HTRANS_RTL,HTRANS_gate;
  logic                  HMASTLOCK_RTL,HMASTLOCK_gate;
  logic                  HREADY_RTL,HREADY_gate;
  logic                  TIMECLK_RTL,TIMECLK_gate;
  logic [31:0]           GPIOIN_RTL,GPIOIN_gate;
  logic [31:0]           GPIOOUT_RTL,GPIOOUT_gate;
  logic [31:0]           GPIOEN_RTL,GPIOEN_gate;
  logic                  UARTSin_RTL,UARTSin_gate;
  logic                  UARTSout_RTL,UARTSout_gate;
  logic                  SPIIn_RTL,SPIIn_gate;
  logic                  SPIOut_RTL,SPIOut_gate;
  logic [3:0]            SPICS_RTL,SPICS_gate;
  logic                  SPICLK_RTL,SPICLK_gate;
  logic                  SDCIn_RTL,SDCIn_gate;
  logic                  SDCCmd_RTL,SDCCmd_gate;
  logic [3:0]            SDCCS_RTL,SDCCS_gate;
  logic                  SDCCLK_RTL,SDCCLK_gate;
  

`endif /*GATE_LEVEL*/
  // synchronize reset to SOC clock domain
  synchronizer resetsync(.clk(clk), .d(reset_ext), .q(reset));


`ifndef GATE_LEVEL 
  // instantiate processor and internal memories
  wallypipelinedcore #(P) core(.clk(clk), .reset(reset),
    .MTimerInt(MTimerInt), .MExtInt(MExtInt), .SExtInt(SExtInt), .MSwInt(MSwInt), .MTIME_CLINT,
    .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB,
    .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK, .ExternalStall
   );
`else 
// instantiate processor and internal memories
  wallypipelinedcore #(P) core(.clk(clk), .reset(reset),
    .MTimerInt(MTimerInt_RTL), .MExtInt(MExtInt_RTL), .SExtInt(SExtInt_RTL), .MSwInt(MSwInt_RTL), .MTIME_CLINT(MTIME_CLINT_RTL),
    .HRDATA(HRDATA_RTL), .HREADY(HREADY_RTL), .HRESP(HRESP_RTL), .HCLK(HCLK_RTL), .HRESETn(HRESETn_RTL), .HADDR(HADDR_RTL), .HWDATA(HWDATA_RTL), .HWSTRB(HWSTRB_RTL),
    .HWRITE(HWRITE_RTL), .HSIZE(HSIZE_RTL), .HBURST(HBURST_RTL), .HPROT(HPROT_RTL), .HTRANS(HTRANS_RTL), .HMASTLOCK(HMASTLOCK_RTL), .ExternalStall(ExternalStall_RTL)
   );
  /* in case there is the gate level top entity exports the signals to the top level, then we duplicate for the RTL */
   wallypipelinedcore_gate core_gate(.clk(clk), .reset(reset),
    .MTimerInt(MTimerInt_gate), .MExtInt(MExtInt_gate), .SExtInt(SExtInt_gate), .MSwInt(MSwInt_gate), .MTIME_CLINT(MTIME_CLINT_gate),
    .HRDATA(HRDATA_gate), .HREADY(HREADY_gate), .HRESP(HRESP_gate), .HCLK(HCLK_gate), .HRESETn(HRESETn_gate), .HADDR(HADDR_gate), .HWDATA(HWDATA_gate), .HWSTRB(HWSTRB_gate),
    .HWRITE(HWRITE_gate), .HSIZE(HSIZE_gate), .HBURST(HBURST_gate), .HPROT(HPROT_gate), .HTRANS(HTRANS_gate), .HMASTLOCK(HMASTLOCK_gate), .ExternalStall(ExternalStall_gate)
   );
`endif /*GATE_LEVEL*/


`ifndef GATE_LEVEL 
// instantiate uncore if a bus interface exists
    if (P.BUS_SUPPORTED) begin : uncoregen // Hack to work around Verilator bug https://github.com/verilator/verilator/issues/4769
      uncore #(P) uncore(.HCLK, .HRESETn, .TIMECLK,
        .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK, .HRDATAEXT,
        .HREADYEXT, .HRESPEXT, .HRDATA, .HREADY, .HRESP, .HSELEXT,
        .MTimerInt, .MSwInt, .MExtInt, .SExtInt, .GPIOIN, .GPIOOUT, .GPIOEN, .UARTSin,
        .UARTSout, .MTIME_CLINT, .SPIIn, .SPIOut, .SPICS, .SPICLK, .SDCIn, .SDCCmd, .SDCCS, .SDCCLK);
    end else begin
      assign {HRDATA, HREADY, HRESP, HSELEXT, MTimerInt, MSwInt, MExtInt, SExtInt,
              MTIME_CLINT, GPIOOUT, GPIOEN, UARTSout, SPIOut, SPICS, SPICLK, SDCCmd, SDCCS, SDCCLK} = '0;
    end
`else
   if (P.BUS_SUPPORTED) begin : uncoregen // Hack to work around Verilator bug https://github.com/verilator/verilator/issues/4769
    uncore #(P) uncore(.HCLK(HCLK_RTL), .HRESETn(HRESETn_RTL), .TIMECLK(TIMECLK_RTL),
      .HADDR(HADDR_RTL), .HWDATA(HWDATA_RTL), .HWSTRB(HWSTRB_RTL), .HWRITE(HWRITE_RTL), .HSIZE(HSIZE_RTL), .HBURST(HBURST_RTL), .HPROT(HPROT_RTL), .HTRANS(HTRANS_RTL), .HMASTLOCK(HMASTLOCK_RTL), .HRDATAEXT(HRDATAEXT_RTL),
      .HREADYEXT(HREADYEXT_RTL), .HRESPEXT(HRESPEXT_RTL), .HRDATA(HRDATA_RTL), .HREADY(HREADY_RTL), .HRESP(HRESP_RTL), .HSELEXT(HSELEXT_RTL),
      .MTimerInt(MTimerInt_RTL), .MSwInt(MSwInt_RTL), .MExtInt(MExtInt_RTL), .SExtInt(SExtInt_RTL), .GPIOIN(GPIOIN_RTL), .GPIOOUT(GPIOOUT_RTL), .GPIOEN(GPIOEN_RTL), .UARTSin(UARTSin_RTL),
      .UARTSout(UARTSout_RTL), .MTIME_CLINT(MTIME_CLINT_RTL), .SPIIn(SPIIn_RTL), .SPIOut(SPIOut_RTL), .SPICS(SPICS_RTL), .SPICLK(SPICLK_RTL), .SDCIn(SDCIn_RTL), .SDCCmd(SDCCmd_RTL), .SDCCS(SDCCS_RTL), .SDCCLK(SDCCLK_RTL));
  end else begin
    assign {HRDATA_RTL, HREADY_RTL, HRESP_RTL, HSELEXT_RTL, MTimerInt_RTL, MSwInt_RTL, MExtInt_RTL, SExtInt_RTL,
            MTIME_CLINT_RTL, GPIOOUT_RTL, GPIOEN_RTL, UARTSout_RTL, SPIOut_RTL, SPICS_RTL, SPICLK_RTL, SDCCmd_RTL, SDCCS_RTL, SDCCLK_RTL} = '0;
  end

  if (P.BUS_SUPPORTED) begin : uncoregen_gate // Hack to work around Verilator bug https://github.com/verilator/verilator/issues/4769
    uncore #(P) uncore_gate (.HCLK(HCLK_gate), .HRESETn(HRESETn_gate), .TIMECLK(TIMECLK_gate),
      .HADDR(HADDR_gate), .HWDATA(HWDATA_gate), .HWSTRB(HWSTRB_gate), .HWRITE(HWRITE_gate), .HSIZE(HSIZE_gate), .HBURST(HBURST_gate), .HPROT(HPROT_gate), .HTRANS(HTRANS_gate), .HMASTLOCK(HMASTLOCK_gate), .HRDATAEXT(HRDATAEXT_gate),
      .HREADYEXT(HREADYEXT_gate), .HRESPEXT(HRESPEXT_gate), .HRDATA(HRDATA_gate), .HREADY(HREADY_gate), .HRESP(HRESP_gate), .HSELEXT(HSELEXT_gate),
      .MTimerInt(MTimerInt_gate), .MSwInt(MSwInt_gate), .MExtInt(MExtInt_gate), .SExtInt(SExtInt_gate), .GPIOIN(GPIOIN_gate), .GPIOOUT(GPIOOUT_gate), .GPIOEN(GPIOEN_gate), .UARTSin(UARTSin_gate),
      .UARTSout(UARTSout_gate), .MTIME_CLINT(MTIME_CLINT_gate), .SPIIn(SPIIn_gate), .SPIOut(SPIOut_gate), .SPICS(SPICS_gate), .SPICLK(SPICLK_gate), .SDCIn(SDCIn_gate), .SDCCmd(SDCCmd_gate), .SDCCS(SDCCS_gate), .SDCCLK(SDCCLK_gate));
  end else begin
    assign {HRDATA_gate, HREADY_gate, HRESP_gate, HSELEXT_gate, MTimerInt_gate, MSwInt_gate, MExtInt_gate, SExtInt_gate,
            MTIME_CLINT_gate, GPIOOUT_gate, GPIOEN_gate, UARTSout_gate, SPIOut_gate, SPICS_gate, SPICLK_gate, SDCCmd_gate, SDCCS_gate, SDCCLK_gate} = '0;
  end

  // Compare signals clock by clock between gate and rtl
  // IF gate is activate, we issue a warning but we select for the gate level signal
  // There is a very elegant way to do this, but we want to be verbose

  // Input signals
  assign HRDATAEXT_gate = HRDATAEXT;
  assign HRDATAEXT_RTL  = HRDATAEXT;
  
  assign HREADYEXT_gate = HREADYEXT;
  assign HREADYEXT_RTL  = HREADYEXT;
  
  assign HRESPEXT_gate = HRESPEXT;
  assign HRESPEXT_RTL  = HRESPEXT;
  
  assign TIMECLK_gate = TIMECLK;
  assign TIMECLK_RTL  = TIMECLK;
  
  assign GPIOIN_gate = GPIOIN;
  assign GPIOIN_RTL  = GPIOIN;

  assign UARTSin_gate = UARTSin;
  assign UARTSin_RTL  = UARTSin;

  assign SDCIn_gate = SDCIn;
  assign SDCIn_RTL  = SDCIn;

  assign ExternalStall_gate = ExternalStall;
  assign ExternalStall_RTL  = ExternalStall;

 
  always @(posedge clk)  begin 
  // Output signals  
  if (reset) begin // active low reset 
  HSELEXT <= HSELEXT_gate; 
  assert ( HSELEXT_gate === HSELEXT_RTL ) else $warning("HSELEXT mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HSELEXT_gate, HSELEXT_RTL);

  HCLK <= HCLK_gate; 
  assert ( HCLK_gate === HCLK_RTL ) else $warning("HCLK mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HCLK_gate, HCLK_RTL);

  
  HRESETn <= HRESETn_gate; 
  assert ( HRESETn_gate === HRESETn_RTL ) else $warning("HRESETn mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HRESETn_gate, HRESETn_RTL);

  
  HADDR <= HADDR_gate; 
  assert ( HADDR_gate === HADDR_RTL ) else $warning("HADDR mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HADDR_gate, HADDR_RTL);

  HWDATA <= HWDATA_gate; 
  assert ( HWDATA_gate === HWDATA_RTL ) else $warning("HWDATA mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HWDATA_gate, HWDATA_RTL);
  
  HWSTRB <= HWSTRB_gate; 
  assert ( HWSTRB_gate === HWSTRB_RTL ) else $warning("HWSTRB mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HWSTRB_gate, HWSTRB_RTL);

  HWRITE <= HWRITE_gate; 
  assert ( HWRITE_gate === HWRITE_RTL ) else $warning("HWRITE mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HWRITE_gate, HWRITE_RTL);

  HSIZE <= HSIZE_gate; 
  assert ( HSIZE_gate === HSIZE_RTL ) else $warning("HSIZE mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HSIZE_gate, HSIZE_RTL);

  HBURST <= HBURST_gate; 
  assert ( HBURST_gate === HBURST_RTL ) else $warning("HBURST mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HBURST_gate, HBURST_RTL);

  HPROT <= HPROT_gate; 
  assert ( HPROT_gate === HPROT_RTL ) else $warning("HPROT mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HPROT_gate, HPROT_RTL);
  
  HTRANS <= HTRANS_gate; 
  assert ( HTRANS_gate === HTRANS_RTL ) else $warning("HTRANS mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HTRANS_gate, HTRANS_RTL);

  HMASTLOCK <= HMASTLOCK_gate; 
  assert ( HMASTLOCK_gate === HMASTLOCK_RTL ) else $warning("HMASTLOCK mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HMASTLOCK_gate, HMASTLOCK_RTL);
  
  HREADY <= HREADY_gate; 
  assert ( HREADY_gate === HREADY_RTL ) else $warning("HREADY mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), HREADY_gate, HREADY_RTL);
  
  GPIOOUT <= GPIOOUT_gate; 
  assert ( GPIOOUT_gate === GPIOOUT_RTL ) else $warning("GPIOOUT mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), GPIOOUT_gate, GPIOOUT_RTL);
  
  GPIOEN <= GPIOEN_gate; 
  assert ( GPIOEN_gate === GPIOEN_RTL ) else $warning("GPIOEN mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), GPIOEN_gate, GPIOEN_RTL);

  UARTSout <= UARTSout_gate; 
  assert ( UARTSout_gate === UARTSout_RTL ) else $warning("UARTSout mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), UARTSout_gate, UARTSout_RTL);
  
  SPIOut <= SPIOut_gate; 
  assert ( SPIOut_gate === SPIOut_RTL ) else $warning("SPIOut mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), SPIOut_gate, SPIOut_RTL);
  
  SPICS <= SPICS_gate; 
  assert ( SPICS_gate === SPICS_RTL ) else $warning("SPICS mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), SPICS_gate, SPICS_RTL);

  SPICLK <= SPICLK_gate; 
  assert ( SPICLK_gate === SPICLK_RTL ) else $warning("SPICLK mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), SPICLK_gate, SPICLK_RTL);

  SDCCmd <= SDCCmd_gate; 
  assert ( SDCCmd_gate === SDCCmd_RTL ) else $warning("SDCCmd mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), SDCCmd_gate, SDCCmd_RTL);
  
  SDCCS <= SDCCS_gate; 
  assert ( SDCCS_gate === SDCCS_RTL ) else $warning("SDCCS mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), SDCCS_gate, SDCCS_RTL);
  
  SDCCLK <= SDCCLK_gate; 
  assert ( SDCCLK_gate === SDCCLK_RTL ) else $warning("SDCCLK mismatch @ %t ( Gate: 0x%h  --- RTL: 0x%h)", $time(), SDCCLK_gate, SDCCLK_RTL);
  end 
  end 
  `endif /*GATE_LEVEL*/
endmodule
