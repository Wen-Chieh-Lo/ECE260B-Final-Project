// =============================================================================
// Simulation Parameters - shared across testbenches
// =============================================================================

// ----- Timing ----- (override with -DCYCLE=2 -DH_CYCLE=1 etc.)
`ifndef CYCLE
  `define CYCLE      1
`endif
`ifndef H_CYCLE
  `define H_CYCLE    0.5
`endif
`define TIME_OUT   100000

// ----- Output (override with -DOUTPUT_DIR="sim/myout") -----
`ifndef OUTPUT_DIR
  `define OUTPUT_DIR "sim/waveform"
`endif

// ----- Core architecture -----
`define TOTAL_CYCLE    8
`define BW             8
`define BW_PSUM        (2*`BW+4)
`define PR             8
`define COL            8
`define SFP_OUT_SHIFT  7
`define SFP_ACC_LAT    1


// ----- Pattern folder (for Q/K/V_T) -----
`define PATTERN_PATH "sim/pattern"

// ----- External memory commands (inst_ext[1:0]) -----
`define EXT_CMD_NO_OP   2'b00
`define EXT_CMD_KMEM_WR 2'b01
`define EXT_CMD_QMEM_WR 2'b10
`define EXT_CMD_PMEM_RD 2'b11

// ----- stdin for interactive sim (iverilog: 32'h8000_0000) -----
`define STDIN 32'h80000000

// ----- Core mode setting -----
`define CORE_MODE_MULT_save_to_PMEM                3'b100
`define CORE_MODE_MULT_NORM_save_to_PMEM           3'b001
`define CORE_MODE_MULT_NORM_save_to_KMEM           3'b010
`define CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM  3'b011
