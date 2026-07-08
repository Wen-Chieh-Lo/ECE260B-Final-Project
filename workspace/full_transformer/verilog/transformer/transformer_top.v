// Full transformer encoder-layer top built from the Alpha dual-core attention
// engine. The scheduler sequences Q/K/V projection, attention, and FFN phases
// over one reusable matrix fabric.
module transformer_top (
	reset0,
	reset1,
	clk0,
	clk1,
	model_start,
	model_clear,
	enable_ffn,
	auto_loader_enable,
	host_wr_en,
	host_wr_buf,
	host_wr_bank,
	host_wr_addr,
	host_wr_data,
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
	residual_in0,
	residual_in1,
	engine_out0,
	engine_out1,
	model_out0,
	model_out1,
	status0,
	status1,
	model_busy,
	model_done,
	model_out_valid,
	model_phase,
	layer_index,
	matrix_req_valid,
	matrix_lhs_sel,
	matrix_rhs_sel,
	matrix_dst_sel,
	matrix_core_mode,
	loader_busy,
	active_dst_sel,
	result_writer_busy
);

	parameter col = 8;
	parameter bw = 8;
	parameter bw_psum = 2*bw+4;
	parameter pr = 16;
	parameter half_pr = 8;
	parameter num_layers = 1;

	input reset0;
	input reset1;
	input clk0;
	input clk1;
	input model_start;
	input model_clear;
	input enable_ffn;
	input auto_loader_enable;
	input host_wr_en;
	input [3:0] host_wr_buf;
	input host_wr_bank;
	input [3:0] host_wr_addr;
	input [half_pr*bw-1:0] host_wr_data;
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
	input [bw_psum*col-1:0] residual_in0;
	input [bw_psum*col-1:0] residual_in1;
	output [bw_psum*col-1:0] engine_out0;
	output [bw_psum*col-1:0] engine_out1;
	output [bw_psum*col-1:0] model_out0;
	output [bw_psum*col-1:0] model_out1;
	output [3:0] status0;
	output [3:0] status1;
	output model_busy;
	output model_done;
	output model_out_valid;
	output [4:0] model_phase;
	output [7:0] layer_index;
	output matrix_req_valid;
	output [3:0] matrix_lhs_sel;
	output [3:0] matrix_rhs_sel;
	output [3:0] matrix_dst_sel;
	output [2:0] matrix_core_mode;
	output loader_busy;
	output [3:0] active_dst_sel;
	output result_writer_busy;

	wire engine_busy;
	wire engine_done;
	wire raw_engine_done;
	wire postproc_commit;
	wire matrix_req_ready;
	wire loader_req_ready;
	wire loader_start0;
	wire loader_start1;
	wire loader_set_mode0;
	wire loader_set_mode1;
	wire [2:0] loader_mode_in0;
	wire [2:0] loader_mode_in1;
	wire [half_pr*bw-1:0] loader_mem_in0;
	wire [half_pr*bw-1:0] loader_mem_in1;
	wire [5:0] loader_inst_ext0;
	wire [5:0] loader_inst_ext1;
	wire [5:0] result_inst_ext0;
	wire [5:0] result_inst_ext1;
	wire result_writer_done;
	wire result_wr_en;
	wire [3:0] result_wr_buf;
	wire [3:0] result_wr_addr;
	wire [half_pr*bw-1:0] result_wr_data0;
	wire [half_pr*bw-1:0] result_wr_data1;
	wire [3:0] buf_row_addr;
	wire [half_pr*bw-1:0] buf_lhs_row0;
	wire [half_pr*bw-1:0] buf_lhs_row1;
	wire [half_pr*bw-1:0] buf_rhs_row0;
	wire [half_pr*bw-1:0] buf_rhs_row1;
	wire engine_start0;
	wire engine_start1;
	wire engine_set_mode0;
	wire engine_set_mode1;
	wire [2:0] engine_mode_in0;
	wire [2:0] engine_mode_in1;
	wire [half_pr*bw-1:0] engine_mem_in0;
	wire [half_pr*bw-1:0] engine_mem_in1;
	wire [5:0] engine_inst_ext0;
	wire [5:0] engine_inst_ext1;

	assign engine_done = auto_loader_enable ? result_writer_done : raw_engine_done;
	assign matrix_req_ready = auto_loader_enable ? loader_req_ready : matrix_req_valid;
	assign engine_start0 = auto_loader_enable ? loader_start0 : start0;
	assign engine_start1 = auto_loader_enable ? loader_start1 : start1;
	assign engine_set_mode0 = auto_loader_enable ? loader_set_mode0 : set_mode0;
	assign engine_set_mode1 = auto_loader_enable ? loader_set_mode1 : set_mode1;
	assign engine_mode_in0 = auto_loader_enable ? loader_mode_in0 : mode_in0;
	assign engine_mode_in1 = auto_loader_enable ? loader_mode_in1 : mode_in1;
	assign engine_mem_in0 = auto_loader_enable ? loader_mem_in0 : mem_in0;
	assign engine_mem_in1 = auto_loader_enable ? loader_mem_in1 : mem_in1;
	assign engine_inst_ext0 = auto_loader_enable ? (result_writer_busy ? result_inst_ext0 : loader_inst_ext0) : inst_ext0;
	assign engine_inst_ext1 = auto_loader_enable ? (result_writer_busy ? result_inst_ext1 : loader_inst_ext1) : inst_ext1;

	transformer_scheduler #(
		.num_layers(num_layers)
	) scheduler (
		.clk(clk0),
		.reset(reset0),
		.start(model_start),
		.clear(model_clear),
		.matrix_req_ready(matrix_req_ready),
		.engine_busy(engine_busy),
		.engine_done(engine_done),
		.phase(model_phase),
		.layer_index(layer_index),
		.matrix_req_valid(matrix_req_valid),
		.matrix_lhs_sel(matrix_lhs_sel),
		.matrix_rhs_sel(matrix_rhs_sel),
		.matrix_dst_sel(matrix_dst_sel),
		.matrix_core_mode(matrix_core_mode),
		.postproc_commit(postproc_commit),
		.done(model_done),
		.busy(model_busy)
	);

	transformer_buffer_bank #(
		.bw(bw),
		.half_pr(half_pr)
	) buffer_bank (
		.clk(clk0),
		.reset(reset0),
		.host_wr_en(host_wr_en),
		.host_wr_buf(host_wr_buf),
		.host_wr_bank(host_wr_bank),
		.host_wr_addr(host_wr_addr),
		.host_wr_data(host_wr_data),
		.result_wr_en(result_wr_en),
		.result_wr_buf(result_wr_buf),
		.result_wr_addr(result_wr_addr),
		.result_wr_data0(result_wr_data0),
		.result_wr_data1(result_wr_data1),
		.lhs_sel(matrix_lhs_sel),
		.rhs_sel(matrix_rhs_sel),
		.row_addr(buf_row_addr),
		.lhs_row0(buf_lhs_row0),
		.lhs_row1(buf_lhs_row1),
		.rhs_row0(buf_rhs_row0),
		.rhs_row1(buf_rhs_row1)
	);

	matrix_loader #(
		.bw(bw),
		.half_pr(half_pr)
	) loader (
		.clk(clk0),
		.reset(reset0),
		.req_valid(matrix_req_valid & auto_loader_enable),
		.req_lhs_sel(matrix_lhs_sel),
		.req_rhs_sel(matrix_rhs_sel),
		.req_dst_sel(matrix_dst_sel),
		.req_core_mode(matrix_core_mode),
		.req_ready(loader_req_ready),
		.buf_row_addr(buf_row_addr),
		.buf_lhs_row0(buf_lhs_row0),
		.buf_lhs_row1(buf_lhs_row1),
		.buf_rhs_row0(buf_rhs_row0),
		.buf_rhs_row1(buf_rhs_row1),
		.engine_start0(loader_start0),
		.engine_start1(loader_start1),
		.engine_set_mode0(loader_set_mode0),
		.engine_set_mode1(loader_set_mode1),
		.engine_mode_in0(loader_mode_in0),
		.engine_mode_in1(loader_mode_in1),
		.engine_mem_in0(loader_mem_in0),
		.engine_mem_in1(loader_mem_in1),
		.engine_inst_ext0(loader_inst_ext0),
		.engine_inst_ext1(loader_inst_ext1),
		.loader_busy(loader_busy),
		.active_dst_sel(active_dst_sel)
	);

	matrix_result_writer #(
		.bw(bw),
		.bw_psum(bw_psum),
		.col(col),
		.half_pr(half_pr)
	) result_writer (
		.clk(clk0),
		.reset(reset0),
		.start(auto_loader_enable & raw_engine_done),
		.dst_sel(active_dst_sel),
		.engine_out0(engine_out0),
		.engine_out1(engine_out1),
		.engine_inst_ext0(result_inst_ext0),
		.engine_inst_ext1(result_inst_ext1),
		.result_wr_en(result_wr_en),
		.result_wr_buf(result_wr_buf),
		.result_wr_addr(result_wr_addr),
		.result_wr_data0(result_wr_data0),
		.result_wr_data1(result_wr_data1),
		.busy(result_writer_busy),
		.done(result_writer_done)
	);

	matrix_engine_wrapper #(
		.col(col),
		.bw(bw),
		.bw_psum(bw_psum),
		.pr(pr),
		.half_pr(half_pr)
	) matrix_engine (
		.reset0(reset0),
		.reset1(reset1),
		.clk0(clk0),
		.clk1(clk1),
		.start0(engine_start0),
		.start1(engine_start1),
		.set_mode0(engine_set_mode0),
		.set_mode1(engine_set_mode1),
		.mode_in0(engine_mode_in0),
		.mode_in1(engine_mode_in1),
		.mem_in0(engine_mem_in0),
		.mem_in1(engine_mem_in1),
		.inst_ext0(engine_inst_ext0),
		.inst_ext1(engine_inst_ext1),
		.out0(engine_out0),
		.out1(engine_out1),
		.status0(status0),
		.status1(status1),
		.engine_busy(engine_busy),
		.engine_done(raw_engine_done)
	);

	transformer_postproc #(
		.col(col),
		.bw_psum(bw_psum)
	) postproc (
		.clk(clk0),
		.reset(reset0),
		.commit(postproc_commit),
		.enable_ffn(enable_ffn),
		.attention_out0(engine_out0),
		.attention_out1(engine_out1),
		.residual_in0(residual_in0),
		.residual_in1(residual_in1),
		.model_out0(model_out0),
		.model_out1(model_out1),
		.model_out_valid(model_out_valid)
	);

endmodule
