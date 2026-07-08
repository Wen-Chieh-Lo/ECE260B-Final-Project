// Matrix-engine wrapper around the Alpha dual-core fullchip.
// The top-level scheduler decides which matrix operands should be loaded;
// this wrapper exposes the existing fullchip load/start ports as the shared
// matrix-compute fabric.
module matrix_engine_wrapper (
	reset0,
	reset1,
	clk0,
	clk1,
	start0,
	start1,
	set_mode0,
	set_mode1,
	mode_in0,
	mode_in1,
	mem_in0,
	mem_in1,
	inst_ext0,
	inst_ext1,
	out0,
	out1,
	status0,
	status1,
	engine_busy,
	engine_done
);

	parameter col = 8;
	parameter bw = 8;
	parameter bw_psum = 2*bw+4;
	parameter pr = 16;
	parameter half_pr = 8;

	input reset0;
	input reset1;
	input clk0;
	input clk1;
	input start0;
	input start1;
	input set_mode0;
	input set_mode1;
	input [2:0] mode_in0;
	input [2:0] mode_in1;
	input [half_pr*bw-1:0] mem_in0;
	input [half_pr*bw-1:0] mem_in1;
	input [5:0] inst_ext0;
	input [5:0] inst_ext1;
	output [bw_psum*col-1:0] out0;
	output [bw_psum*col-1:0] out1;
	output [3:0] status0;
	output [3:0] status1;
	output engine_busy;
	output engine_done;

	reg status1_busy_meta;
	reg status1_busy_sync;
	reg engine_busy_d;

	assign engine_busy = status0[3] | status1_busy_sync;
	assign engine_done = engine_busy_d & ~engine_busy;

	fullchip #(
		.col(col),
		.bw(bw),
		.bw_psum(bw_psum),
		.pr(pr),
		.half_pr(half_pr)
	) compute_engine (
		.reset0(reset0),
		.reset1(reset1),
		.clk0(clk0),
		.clk1(clk1),
		.start0(start0),
		.start1(start1),
		.set_mode0(set_mode0),
		.set_mode1(set_mode1),
		.mode_in0(mode_in0),
		.mode_in1(mode_in1),
		.mem_in0(mem_in0),
		.mem_in1(mem_in1),
		.inst_ext0(inst_ext0),
		.inst_ext1(inst_ext1),
		.out0(out0),
		.out1(out1),
		.status0(status0),
		.status1(status1)
	);

	always @(posedge clk0) begin
		if (reset0) begin
			status1_busy_meta <= 1'b0;
			status1_busy_sync <= 1'b0;
			engine_busy_d <= 1'b0;
		end else begin
			status1_busy_meta <= status1[3];
			status1_busy_sync <= status1_busy_meta;
			engine_busy_d <= engine_busy;
		end
	end

endmodule
