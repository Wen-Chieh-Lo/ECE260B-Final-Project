// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module fullchip (clk0, clk1, mem_in, inst, reset, out);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter pr = 16;
parameter half_pr = 8;

input  clk0, clk1; 
input  [pr*bw-1:0] mem_in; 
input  [19:0] inst; //[18:0]
input  reset;

output [bw_psum*col*2-1:0] out;

wire [bw_psum+3:0] sfp_sum_in_0, sum_out_0_1;
wire [bw_psum+3:0] sfp_sum_in_1, sum_out_1_0;
wire [bw_psum+3:0] ext_fifo_in_0;
wire [bw_psum+3:0] ext_fifo_in_1;
wire [bw_psum*col-1:0] out_0;
wire [bw_psum*col-1:0] out_1;

wire [half_pr*bw-1:0] core0_mem_in, core1_mem_in;

wire fifo_rd_core0, fifo_rd_core1;
wire fifo_wr_core0, fifo_wr_core1;

wire fifo_empty_1_0, fifo_empty_0_1;

assign sfp_sum_in_0 = (!fifo_empty_1_0 && fifo_rd_core0) ? sum_out_1_0 : {(bw_psum+4){1'b0}};
assign sfp_sum_in_1 = (!fifo_empty_0_1 && fifo_rd_core1) ? sum_out_0_1 : {(bw_psum+4){1'b0}};

assign core0_mem_in = mem_in[half_pr*bw-1:0];
assign core1_mem_in = mem_in[pr*bw-1:half_pr*bw];

assign out = {out_1, out_0};

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(half_pr)) core_instance_0 (
      .clk(clk0),
      .sum_in(sfp_sum_in_0),
      .mem_in(core0_mem_in),
      .out(out_0),
      .inst(inst),
      .reset(reset),
      .ext_fifo_wr(fifo_wr_core0),
      .ext_fifo_in(ext_fifo_in_0),
      .ext_fifo_rd(fifo_rd_core0)
);

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(half_pr)) core_instance_1 (
      .clk(clk1),
      .sum_in(sfp_sum_in_1),
      .mem_in(core1_mem_in),
      .out(out_1),
      .inst(inst),
      .reset(reset),
      .ext_fifo_wr(fifo_wr_core1),
      .ext_fifo_in(ext_fifo_in_1),
      .ext_fifo_rd(fifo_rd_core1)
);

fifo_depth16_async #(.bw(bw_psum+4)) fifo_inst_ext_core0_1 (
     .rd_clk(clk1), 
     .wr_clk(clk0), 
     .in(ext_fifo_in_0),
     .out(sum_out_0_1), 
     .rd(fifo_rd_core1), 
     .wr(fifo_wr_core0), 
     .reset(reset),
     .o_empty(fifo_empty_0_1)
  );

fifo_depth16_async #(.bw(bw_psum+4)) fifo_inst_ext_core1_0 (
     .rd_clk(clk0), 
     .wr_clk(clk1), 
     .in(ext_fifo_in_1),
     .out(sum_out_1_0), 
     .rd(fifo_rd_core0), 
     .wr(fifo_wr_core1), 
     .reset(reset),
     .o_empty(fifo_empty_1_0)
  );






endmodule
