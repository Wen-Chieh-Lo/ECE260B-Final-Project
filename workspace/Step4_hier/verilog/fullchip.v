// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
//

module fullchip (clk0, clk1, mem_in0, mem_in1, inst0, inst1, reset0, reset1, out0, out1, fifo0_empty, fifo1_empty/*, sfp_sum_in_1_out*/);

parameter col      = 8;
parameter bw       = 8;
parameter bw_psum  = 2*bw+4;
parameter pr       = 16;
parameter half_pr  = 8;

input  clk0, clk1;
input  [half_pr*bw-1:0]         mem_in0, mem_in1;
input  [19:0]               inst0, inst1;
input                       reset0, reset1;

output [bw_psum*col-1:0] out0, out1;
output fifo0_empty, fifo1_empty;
//output [bw_psum+3:0] sfp_sum_in_1_out;

// raw combinational FIFO outputs
wire [bw_psum+3:0] sum_out_0_1;
wire [bw_psum+3:0] sum_out_1_0;

// registered sample-and-hold — fed to each core's sum_in
wire [bw_psum+3:0] sfp_sum_in_0;
wire [bw_psum+3:0] sfp_sum_in_1;

wire [bw_psum+3:0] ext_fifo_in_0;
wire [bw_psum+3:0] ext_fifo_in_1;
//wire [bw_psum*col-1:0] out_0;
//wire [bw_psum*col-1:0] out_1;

//wire [half_pr*bw-1:0] core0_mem_in, core1_mem_in;
//wire [19:0] inst0, inst1;

wire fifo_rd_core0, fifo_rd_core1;
wire fifo_wr_core0, fifo_wr_core1;

wire fifo_empty_1_0, fifo_empty_0_1;

// ── sample-and-hold registers (SYNCHRONOUS reset) ───────────────────────────
//
// Synchronous reset forces DC to synthesize a D-mux, guaranteeing the
// register resets to 0 on the first clock edge after reset is asserted.
// added for prevention of X propogation in GLS
//
// Enable condition: latch only when the source FIFO is non-empty, i.e.
// when valid data is present at the FIFO output.

reg [bw_psum+3:0] sfp_sum_in_0_r;
reg [bw_psum+3:0] sfp_sum_in_1_r;

// core1 reads from fifo_inst_ext_core0_1  (rd_clk = clk1)
// core0 reads from fifo_inst_ext_core1_0


always @(posedge clk0) begin
    if (reset0)
        sfp_sum_in_0_r <= {(bw_psum+4){1'b0}};
    else
        sfp_sum_in_0_r <= fifo_empty_1_0 ? sfp_sum_in_0_r : sum_out_1_0;
end

always @(posedge clk1) begin
    if (reset1)
        sfp_sum_in_1_r <= {(bw_psum+4){1'b0}};
    else
        sfp_sum_in_1_r <= fifo_empty_0_1 ? sfp_sum_in_1_r : sum_out_0_1;
end

assign sfp_sum_in_0 = sfp_sum_in_0_r;
assign sfp_sum_in_1 = sfp_sum_in_1_r;

//assign sfp_sum_in_1_out = sfp_sum_in_1;

// ── FIFO empty flags to top level ───────────────────────────────────────────
assign fifo0_empty = fifo_empty_0_1;
assign fifo1_empty = fifo_empty_1_0;

// ── address / instruction slicing ───────────────────────────────────────────
//assign core0_mem_in = mem_in[half_pr*bw-1:0];
//assign core1_mem_in = mem_in[pr*bw-1:half_pr*bw];

//assign inst0 = inst[19:0];
//assign inst1 = inst[39:20];

//assign out = {out_1, out_0};

// ── core instances ───────────────────────────────────────────────────────────
core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(half_pr)) core_instance_0 (
      .clk(clk0),
      .sum_in(sfp_sum_in_0),
      .mem_in(mem_in0),
      .out(out0),
      .inst(inst0),
      .reset(reset0),
      .ext_fifo_wr(fifo_wr_core0),
      .ext_fifo_in(ext_fifo_in_0),
      .ext_fifo_rd(fifo_rd_core0)
);

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(half_pr)) core_instance_1 (
      .clk(clk1),
      .sum_in(sfp_sum_in_1),
      .mem_in(mem_in1),
      .out(out1),
      .inst(inst1),
      .reset(reset1),
      .ext_fifo_wr(fifo_wr_core1),
      .ext_fifo_in(ext_fifo_in_1),
      .ext_fifo_rd(fifo_rd_core1)
);

// ── async FIFOs ──────────────────────────────────────────────────────────────
fifo_depth16_async #(.bw(bw_psum+4)) fifo_inst_ext_core0_1 (
     .rd_clk(clk1),
     .wr_clk(clk0),
     .in(ext_fifo_in_0),
     .out(sum_out_0_1),
     .rd(fifo_rd_core1),
     .wr(fifo_wr_core0),
     .reset(reset0),
     .o_empty(fifo_empty_0_1)
  );

fifo_depth16_async #(.bw(bw_psum+4)) fifo_inst_ext_core1_0 (
     .rd_clk(clk0),
     .wr_clk(clk1),
     .in(ext_fifo_in_1),
     .out(sum_out_1_0),
     .rd(fifo_rd_core0),
     .wr(fifo_wr_core1),
     .reset(reset1),
     .o_empty(fifo_empty_1_0)
  );

endmodule
