// Transformer encoder-layer scheduler.
// Reuses one matrix engine across projection, attention, and FFN phases.
module transformer_scheduler (
	clk,
	reset,
	start,
	clear,
	matrix_req_ready,
	engine_busy,
	engine_done,
	phase,
	layer_index,
	matrix_req_valid,
	matrix_lhs_sel,
	matrix_rhs_sel,
	matrix_dst_sel,
	matrix_core_mode,
	postproc_commit,
	done,
	busy
);

	input clk;
	input reset;
	input start;
	input clear;
	input matrix_req_ready;
	input engine_busy;
	input engine_done;
	output [4:0] phase;
	output [7:0] layer_index;
	output matrix_req_valid;
	output [3:0] matrix_lhs_sel;
	output [3:0] matrix_rhs_sel;
	output [3:0] matrix_dst_sel;
	output [2:0] matrix_core_mode;
	output postproc_commit;
	output done;
	output busy;

	parameter num_layers = 1;

	localparam [4:0] S_IDLE       = 5'd0;
	localparam [4:0] S_Q_PROJ     = 5'd1;
	localparam [4:0] S_K_PROJ     = 5'd2;
	localparam [4:0] S_V_PROJ     = 5'd3;
	localparam [4:0] S_ATTN_QK    = 5'd4;
	localparam [4:0] S_ATTN_NORM  = 5'd5;
	localparam [4:0] S_ATTN_V     = 5'd6;
	localparam [4:0] S_POSTPROC   = 5'd7;
	localparam [4:0] S_DONE       = 5'd8;

	localparam [3:0] BUF_X        = 4'd0;
	localparam [3:0] BUF_WQ       = 4'd1;
	localparam [3:0] BUF_WK       = 4'd2;
	localparam [3:0] BUF_WV       = 4'd3;
	localparam [3:0] BUF_Q        = 4'd4;
	localparam [3:0] BUF_K        = 4'd5;
	localparam [3:0] BUF_V        = 4'd6;
	localparam [3:0] BUF_SCORE    = 4'd7;
	localparam [3:0] BUF_NORM     = 4'd8;
	localparam [3:0] BUF_ATTN_OUT = 4'd9;
	localparam [3:0] BUF_W1       = 4'd10;
	localparam [3:0] BUF_FFN      = 4'd11;
	localparam [3:0] BUF_W2       = 4'd12;
	localparam [3:0] BUF_OUT      = 4'd13;

	localparam [2:0] CORE_MODE_MULT_SAVE_TO_PMEM               = 3'b100;
	localparam [2:0] CORE_MODE_MULT_NORM_SAVE_TO_PMEM_AND_KMEM = 3'b011;

	reg [4:0] state;
	reg [7:0] layer;
	reg req_active;
	reg done_r;
	reg [3:0] lhs_sel_r;
	reg [3:0] rhs_sel_r;
	reg [3:0] dst_sel_r;
	reg [2:0] core_mode_r;
	reg postproc_commit_r;

	assign phase = state;
	assign layer_index = layer;
	assign matrix_req_valid = req_active;
	assign matrix_lhs_sel = lhs_sel_r;
	assign matrix_rhs_sel = rhs_sel_r;
	assign matrix_dst_sel = dst_sel_r;
	assign matrix_core_mode = core_mode_r;
	assign postproc_commit = postproc_commit_r;
	assign done = done_r;
	assign busy = (state != S_IDLE) && (state != S_DONE);

	task set_matrix_op;
		input [3:0] lhs;
		input [3:0] rhs;
		input [3:0] dst;
		input [2:0] mode;
		begin
			lhs_sel_r <= lhs;
			rhs_sel_r <= rhs;
			dst_sel_r <= dst;
			core_mode_r <= mode;
			req_active <= 1'b1;
		end
	endtask

	always @(posedge clk) begin
		if (reset || clear) begin
			state <= S_IDLE;
			layer <= 8'd0;
			req_active <= 1'b0;
			done_r <= 1'b0;
			lhs_sel_r <= BUF_X;
			rhs_sel_r <= BUF_WQ;
			dst_sel_r <= BUF_Q;
			core_mode_r <= CORE_MODE_MULT_SAVE_TO_PMEM;
			postproc_commit_r <= 1'b0;
		end else begin
			postproc_commit_r <= 1'b0;

			case (state)
				S_IDLE: begin
					done_r <= 1'b0;
					req_active <= 1'b0;
					if (start) begin
						layer <= 8'd0;
						state <= S_Q_PROJ;
						set_matrix_op(BUF_X, BUF_WQ, BUF_Q, CORE_MODE_MULT_SAVE_TO_PMEM);
					end
				end

				S_Q_PROJ: begin
					if (matrix_req_ready) req_active <= 1'b0;
					if (engine_done) begin
						state <= S_K_PROJ;
						set_matrix_op(BUF_X, BUF_WK, BUF_K, CORE_MODE_MULT_SAVE_TO_PMEM);
					end
				end

				S_K_PROJ: begin
					if (matrix_req_ready) req_active <= 1'b0;
					if (engine_done) begin
						state <= S_V_PROJ;
						set_matrix_op(BUF_X, BUF_WV, BUF_V, CORE_MODE_MULT_SAVE_TO_PMEM);
					end
				end

				S_V_PROJ: begin
					if (matrix_req_ready) req_active <= 1'b0;
					if (engine_done) begin
						state <= S_ATTN_QK;
						set_matrix_op(BUF_Q, BUF_K, BUF_SCORE, CORE_MODE_MULT_SAVE_TO_PMEM);
					end
				end

				S_ATTN_QK: begin
					if (matrix_req_ready) req_active <= 1'b0;
					if (engine_done) begin
						state <= S_ATTN_NORM;
						set_matrix_op(BUF_SCORE, BUF_SCORE, BUF_NORM, CORE_MODE_MULT_NORM_SAVE_TO_PMEM_AND_KMEM);
					end
				end

				S_ATTN_NORM: begin
					if (matrix_req_ready) req_active <= 1'b0;
					if (engine_done) begin
						state <= S_ATTN_V;
						set_matrix_op(BUF_NORM, BUF_V, BUF_ATTN_OUT, CORE_MODE_MULT_SAVE_TO_PMEM);
					end
				end

				S_ATTN_V: begin
					if (matrix_req_ready) req_active <= 1'b0;
					if (engine_done) begin
						state <= S_POSTPROC;
						req_active <= 1'b0;
					end
				end

				S_POSTPROC: begin
					postproc_commit_r <= 1'b1;
					if (layer == (num_layers - 1)) begin
						state <= S_DONE;
						done_r <= 1'b1;
					end else begin
						layer <= layer + 8'd1;
						state <= S_Q_PROJ;
						set_matrix_op(BUF_OUT, BUF_WQ, BUF_Q, CORE_MODE_MULT_SAVE_TO_PMEM);
					end
				end

				S_DONE: begin
					req_active <= 1'b0;
					if (clear) begin
						state <= S_IDLE;
						done_r <= 1'b0;
					end
				end

				default: begin
					state <= S_IDLE;
					req_active <= 1'b0;
				end
			endcase
		end
	end

endmodule
