// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module fullchip (clk_0, clk_1, mem_in_0, mem_in_1, inst, reset);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter pr = 16;

input  clk; 
input  [pr*bw-1:0] mem_in_0; 
input  [pr*bw-1:0] mem_in_1; 
input  [18:0] inst; 
input  reset;

wire [18:0] inst_0;
wire [18:0] inst_1;
wire [bw_psum+3:0] sfp_sum_in_0;
wire [bw_psum+3:0] sfp_sum_in_1;
wire [bw_psum+3:0] sfp_sum_out_0;
wire [bw_psum+3:0] sfp_sum_out_1;
wire [bw_psum*col-1:0] out_0;
wire [bw_psum*col-1:0] out_1;

assign inst_0 = inst;
assign inst_1 = inst;
assign sfp_sum_in_0 = sfp_sum_out_1_sync;
assign sfp_sum_in_1 = sfp_sum_out_0_sync;

assign out = {out_1, out_0};

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core_instance_0 (
      .reset(reset), 
      .clk(clk_0), 
      .mem_in(mem_in_0), 
      .inst(inst_0),
      .sfp_sum_in(sfp_sum_in_0),
      .sfp_sum_out(sfp_sum_out_0),
      .out(out_0)
);

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core_instance_1 (
      .reset(reset), 
      .clk(clk_1), 
      .mem_in(mem_in_1), 
      .inst(inst_1),
      .sfp_sum_in(sfp_sum_in_1),
      .sfp_sum_out(sfp_sum_out_1),
      .out(out_1)
);

sync sync_instance_0 (
      .clk(clk_1), 
      .in(sfp_sum_out_0),
      .out(sfp_sum_out_0_sync)
);
sync sync_instance_1 (
      .clk(clk_0), 
      .in(sfp_sum_out_1),
      .out(sfp_sum_out_1_sync)
);


endmodule
