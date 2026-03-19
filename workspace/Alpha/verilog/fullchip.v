// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module fullchip (
	reset0, 	reset1,
	clk0, 		clk1,
	start0, 	start1,
	set_mode0, 	set_mode1,
	mode_in0, 	mode_in1,
	mem_in0, 	mem_in1,
	inst_ext0, 	inst_ext1,
	out0, 		out1,
	status0, 	status1
);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter pr = 16;
parameter half_pr  = 8;

// =========== 		Chip I/O 		===========
input 						reset0, 	reset1;
input 						clk0, 		clk1;
input 						start0, 	start1;
input 						set_mode0, 	set_mode1;
input 	[2:0] 				mode_in0, 	mode_in1;
input 	[half_pr*bw-1:0] 	mem_in0, 	mem_in1;
input 	[5:0] 				inst_ext0, 	inst_ext1;
output 	[bw_psum*col-1:0] 	out0, 		out1;
output  [3:0]				status0, 	status1;

// =========== 		Internal wires 		===========	
wire [bw_psum+3:0] 			sum_out0, 			sum_out1;
wire 						sum_out0_valid, 	sum_out1_valid;
wire [bw_psum+3:0] 			sum_in0, 			sum_in1;
wire 						sum_in0_valid, 		sum_in1_valid;
wire 						sum_in0_fifo_pop, 	sum_in1_fifo_pop;

wire 						core0_self_ext_fifo_empty, core1_self_ext_fifo_empty;


core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(half_pr)) core_instance0 (
	.reset(reset0),
	.clk(clk0),
	.set_mode(set_mode0),
	.mode_in(mode_in0),
	.mem_in(mem_in0),
	.inst_ext(inst_ext0),
	.sum_in(sum_in0),
	.sum_in_valid(sum_in0_valid),
	.sum_in_fifo_pop(sum_in0_fifo_pop), 
	.sum_out(sum_out0),			
	.sum_out_valid(sum_out0_valid),	
	.out(out0),
	.start(start0),
	.status(status0)
);

fifo_depth16_async #(.bw(bw_psum+4)) core0_self_ext_fifo (
	.reset(reset0),
	.wr_clk(clk0),
	.wr(sum_out0_valid),
	.in(sum_out0),
	.rd_clk(clk1),
	.rd(sum_in1_fifo_pop),
	.out(sum_in1),	
	.o_empty(core0_self_ext_fifo_empty)
); 
assign sum_in1_valid <= ~core0_self_ext_fifo_empty; 
assign sum_in0_valid <= ~core1_self_ext_fifo_empty;

fifo_depth16_async #(.bw(bw_psum+4)) core1_self_ext_fifo (
	.reset(reset1),
	.wr_clk(clk1),
	.wr(sum_out1_valid),
	.in(sum_out1),
	.rd_clk(clk0),
	.rd(sum_in0_fifo_pop),
	.out(sum_in0),	
	.o_empty(core1_self_ext_fifo_empty)
); 



core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(half_pr)) core_instance1 (
	.reset(reset1),
	.clk(clk1),
	.set_mode(set_mode1),
	.mode_in(mode_in1),
	.mem_in(mem_in1),
	.inst_ext(inst_ext1),
	.sum_in(sum_in1),
	.sum_in_valid(sum_in1_valid),
	.sum_in_fifo_pop(sum_in1_fifo_pop), 
	.sum_out(sum_out1),			
	.sum_out_valid(sum_out1_valid),	
	.out(out1),
	.start(start1),
	.status(status1)
);

endmodule
