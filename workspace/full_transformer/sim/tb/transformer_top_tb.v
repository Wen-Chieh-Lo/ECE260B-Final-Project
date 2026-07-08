`timescale 1ns/1ps

module transformer_top_tb;

	localparam BW = 8;
	localparam BW_PSUM = 20;
	localparam COL = 8;
	localparam HALF_PR = 8;
	localparam PR = 16;
	localparam ROW_W = HALF_PR*BW;

	localparam [3:0] BUF_X  = 4'd0;
	localparam [3:0] BUF_WQ = 4'd1;
	localparam [3:0] BUF_WK = 4'd2;
	localparam [3:0] BUF_WV = 4'd3;
	localparam [3:0] BUF_Q  = 4'd4;
	localparam [3:0] BUF_K  = 4'd5;
	localparam [3:0] BUF_V  = 4'd6;

	localparam [4:0] PHASE_DONE = 5'd8;

	reg reset0;
	reg reset1;
	reg clk0;
	reg clk1;
	reg model_start;
	reg model_clear;
	reg enable_ffn;
	reg auto_loader_enable;

	reg host_wr_en;
	reg [3:0] host_wr_buf;
	reg host_wr_bank;
	reg [3:0] host_wr_addr;
	reg [ROW_W-1:0] host_wr_data;

	wire [BW_PSUM*COL-1:0] engine_out0;
	wire [BW_PSUM*COL-1:0] engine_out1;
	wire [BW_PSUM*COL-1:0] model_out0;
	wire [BW_PSUM*COL-1:0] model_out1;
	wire [3:0] status0;
	wire [3:0] status1;
	wire model_busy;
	wire model_done;
	wire model_out_valid;
	wire [4:0] model_phase;
	wire [7:0] layer_index;
	wire matrix_req_valid;
	wire [3:0] matrix_lhs_sel;
	wire [3:0] matrix_rhs_sel;
	wire [3:0] matrix_dst_sel;
	wire [2:0] matrix_core_mode;
	wire loader_busy;
	wire [3:0] active_dst_sel;
	wire result_writer_busy;

	integer timeout;
	integer row;

	always #0.5 clk0 = ~clk0;
	always #0.6 clk1 = ~clk1;

	transformer_top #(
		.bw(BW),
		.bw_psum(BW_PSUM),
		.col(COL),
		.pr(PR),
		.half_pr(HALF_PR),
		.num_layers(1)
	) dut (
		.reset0(reset0),
		.reset1(reset1),
		.clk0(clk0),
		.clk1(clk1),
		.model_start(model_start),
		.model_clear(model_clear),
		.enable_ffn(enable_ffn),
		.auto_loader_enable(auto_loader_enable),
		.host_wr_en(host_wr_en),
		.host_wr_buf(host_wr_buf),
		.host_wr_bank(host_wr_bank),
		.host_wr_addr(host_wr_addr),
		.host_wr_data(host_wr_data),
		.start0(1'b0),
		.start1(1'b0),
		.set_mode0(1'b0),
		.set_mode1(1'b0),
		.mode_in0(3'b000),
		.mode_in1(3'b000),
		.mem_in0({ROW_W{1'b0}}),
		.mem_in1({ROW_W{1'b0}}),
		.inst_ext0(6'd0),
		.inst_ext1(6'd0),
		.residual_in0({(BW_PSUM*COL){1'b0}}),
		.residual_in1({(BW_PSUM*COL){1'b0}}),
		.engine_out0(engine_out0),
		.engine_out1(engine_out1),
		.model_out0(model_out0),
		.model_out1(model_out1),
		.status0(status0),
		.status1(status1),
		.model_busy(model_busy),
		.model_done(model_done),
		.model_out_valid(model_out_valid),
		.model_phase(model_phase),
		.layer_index(layer_index),
		.matrix_req_valid(matrix_req_valid),
		.matrix_lhs_sel(matrix_lhs_sel),
		.matrix_rhs_sel(matrix_rhs_sel),
		.matrix_dst_sel(matrix_dst_sel),
		.matrix_core_mode(matrix_core_mode),
		.loader_busy(loader_busy),
		.active_dst_sel(active_dst_sel),
		.result_writer_busy(result_writer_busy)
	);

	initial begin
		$dumpfile("sim/waveform/transformer_top.vcd");
		$dumpvars(0, transformer_top_tb);

		clk0 = 1'b0;
		clk1 = 1'b0;
		reset0 = 1'b1;
		reset1 = 1'b1;
		model_start = 1'b0;
		model_clear = 1'b0;
		enable_ffn = 1'b1;
		auto_loader_enable = 1'b1;
		host_wr_en = 1'b0;
		host_wr_buf = 4'd0;
		host_wr_bank = 1'b0;
		host_wr_addr = 4'd0;
		host_wr_data = {ROW_W{1'b0}};

		repeat (4) @(posedge clk0);
		reset0 = 1'b0;
		reset1 = 1'b0;
		repeat (2) @(posedge clk0);

		preload_matrix_pair(BUF_X, 8'd1, 8'd1);
		preload_matrix_pair(BUF_WQ, 8'd1, 8'd2);
		preload_matrix_pair(BUF_WK, 8'd2, 8'd3);
		preload_matrix_pair(BUF_WV, 8'd3, 8'd4);

		// Seed intermediate buffers too. The readback path should overwrite
		// these as each matrix phase completes; the seeds keep later phases
		// deterministic even if a simulator is used for early control debug.
		preload_matrix_pair(BUF_Q, 8'd4, 8'd5);
		preload_matrix_pair(BUF_K, 8'd5, 8'd6);
		preload_matrix_pair(BUF_V, 8'd6, 8'd7);

		@(posedge clk0);
		model_start = 1'b1;
		@(posedge clk0);
		model_start = 1'b0;

		timeout = 0;
		while (!model_done && timeout < 5000) begin
			@(posedge clk0);
			timeout = timeout + 1;
		end

		if (!model_done) begin
			$display("FAIL: transformer_top did not complete before timeout");
			$finish;
		end

		if (model_phase !== PHASE_DONE) begin
			$display("FAIL: model_done asserted but phase is %0d", model_phase);
			$finish;
		end

		@(posedge clk0);
		if (!model_out_valid) begin
			$display("FAIL: expected model_out_valid after postproc");
			$finish;
		end

		$display("PASS: transformer_top auto-loader/readback control path completed");
		$finish;
	end

	always @(posedge clk0) begin
		if (!reset0) begin
			$display("t=%0t phase=%0d req=%0b lhs=%0d rhs=%0d dst=%0d loader=%0b writer=%0b busy=%0b done=%0b",
				$time, model_phase, matrix_req_valid, matrix_lhs_sel, matrix_rhs_sel,
				matrix_dst_sel, loader_busy, result_writer_busy, model_busy, model_done);
		end
	end

	task preload_matrix_pair;
		input [3:0] buf;
		input [7:0] base0;
		input [7:0] base1;
		begin
			for (row = 0; row < 8; row = row + 1) begin
				host_write_row(buf, 1'b0, row[3:0], make_row(base0 + row));
				host_write_row(buf, 1'b1, row[3:0], make_row(base1 + row));
			end
		end
	endtask

	task host_write_row;
		input [3:0] buf;
		input bank;
		input [3:0] addr;
		input [ROW_W-1:0] data;
		begin
			@(posedge clk0);
			host_wr_en = 1'b1;
			host_wr_buf = buf;
			host_wr_bank = bank;
			host_wr_addr = addr;
			host_wr_data = data;
			@(posedge clk0);
			host_wr_en = 1'b0;
			host_wr_data = {ROW_W{1'b0}};
		end
	endtask

	function [ROW_W-1:0] make_row;
		input [7:0] base;
		integer i;
		begin
			for (i = 0; i < HALF_PR; i = i + 1)
				make_row[i*BW +: BW] = base + i;
		end
	endfunction

endmodule
