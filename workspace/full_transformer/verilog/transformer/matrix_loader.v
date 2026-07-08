// Converts scheduler matrix requests into the original fullchip external
// memory protocol: set mode, stream RHS into KMEM, stream LHS into QMEM, start.
module matrix_loader (
	clk,
	reset,
	req_valid,
	req_lhs_sel,
	req_rhs_sel,
	req_dst_sel,
	req_core_mode,
	req_ready,
	buf_row_addr,
	buf_lhs_row0,
	buf_lhs_row1,
	buf_rhs_row0,
	buf_rhs_row1,
	engine_start0,
	engine_start1,
	engine_set_mode0,
	engine_set_mode1,
	engine_mode_in0,
	engine_mode_in1,
	engine_mem_in0,
	engine_mem_in1,
	engine_inst_ext0,
	engine_inst_ext1,
	loader_busy,
	active_dst_sel
);

	parameter bw = 8;
	parameter half_pr = 8;
	parameter rows = 8;

	localparam row_width = half_pr*bw;

	input clk;
	input reset;
	input req_valid;
	input [3:0] req_lhs_sel;
	input [3:0] req_rhs_sel;
	input [3:0] req_dst_sel;
	input [2:0] req_core_mode;
	output req_ready;
	output [3:0] buf_row_addr;
	input [row_width-1:0] buf_lhs_row0;
	input [row_width-1:0] buf_lhs_row1;
	input [row_width-1:0] buf_rhs_row0;
	input [row_width-1:0] buf_rhs_row1;
	output reg engine_start0;
	output reg engine_start1;
	output reg engine_set_mode0;
	output reg engine_set_mode1;
	output reg [2:0] engine_mode_in0;
	output reg [2:0] engine_mode_in1;
	output reg [row_width-1:0] engine_mem_in0;
	output reg [row_width-1:0] engine_mem_in1;
	output reg [5:0] engine_inst_ext0;
	output reg [5:0] engine_inst_ext1;
	output loader_busy;
	output [3:0] active_dst_sel;

	localparam [2:0] S_IDLE     = 3'd0;
	localparam [2:0] S_SET_MODE = 3'd1;
	localparam [2:0] S_LOAD_RHS = 3'd2;
	localparam [2:0] S_LOAD_LHS = 3'd3;
	localparam [2:0] S_START    = 3'd4;

	localparam [1:0] EXT_CMD_NO_OP   = 2'b00;
	localparam [1:0] EXT_CMD_KMEM_WR = 2'b01;
	localparam [1:0] EXT_CMD_QMEM_WR = 2'b10;

	reg [2:0] state;
	reg [3:0] row_counter;
	reg [3:0] lhs_sel_r;
	reg [3:0] rhs_sel_r;
	reg [3:0] dst_sel_r;
	reg [2:0] core_mode_r;

	assign req_ready = (state == S_IDLE) && req_valid;
	assign loader_busy = (state != S_IDLE);
	assign active_dst_sel = dst_sel_r;
	assign buf_row_addr = row_counter;

	always @(posedge clk) begin
		if (reset) begin
			state <= S_IDLE;
			row_counter <= 4'd0;
			lhs_sel_r <= 4'd0;
			rhs_sel_r <= 4'd0;
			dst_sel_r <= 4'd0;
			core_mode_r <= 3'd0;
			engine_start0 <= 1'b0;
			engine_start1 <= 1'b0;
			engine_set_mode0 <= 1'b0;
			engine_set_mode1 <= 1'b0;
			engine_mode_in0 <= 3'd0;
			engine_mode_in1 <= 3'd0;
			engine_mem_in0 <= {row_width{1'b0}};
			engine_mem_in1 <= {row_width{1'b0}};
			engine_inst_ext0 <= 6'd0;
			engine_inst_ext1 <= 6'd0;
		end else begin
			engine_start0 <= 1'b0;
			engine_start1 <= 1'b0;
			engine_set_mode0 <= 1'b0;
			engine_set_mode1 <= 1'b0;
			engine_inst_ext0 <= {4'd0, EXT_CMD_NO_OP};
			engine_inst_ext1 <= {4'd0, EXT_CMD_NO_OP};

			case (state)
				S_IDLE: begin
					row_counter <= 4'd0;
					if (req_valid) begin
						lhs_sel_r <= req_lhs_sel;
						rhs_sel_r <= req_rhs_sel;
						dst_sel_r <= req_dst_sel;
						core_mode_r <= req_core_mode;
						engine_mode_in0 <= req_core_mode;
						engine_mode_in1 <= req_core_mode;
						state <= S_SET_MODE;
					end
				end

				S_SET_MODE: begin
					engine_set_mode0 <= 1'b1;
					engine_set_mode1 <= 1'b1;
					engine_mode_in0 <= core_mode_r;
					engine_mode_in1 <= core_mode_r;
					row_counter <= 4'd0;
					state <= S_LOAD_RHS;
				end

				S_LOAD_RHS: begin
					engine_mem_in0 <= buf_rhs_row0;
					engine_mem_in1 <= buf_rhs_row1;
					engine_inst_ext0 <= {row_counter, EXT_CMD_KMEM_WR};
					engine_inst_ext1 <= {row_counter, EXT_CMD_KMEM_WR};
					if (row_counter == rows-1) begin
						row_counter <= 4'd0;
						state <= S_LOAD_LHS;
					end else begin
						row_counter <= row_counter + 4'd1;
					end
				end

				S_LOAD_LHS: begin
					engine_mem_in0 <= buf_lhs_row0;
					engine_mem_in1 <= buf_lhs_row1;
					engine_inst_ext0 <= {row_counter, EXT_CMD_QMEM_WR};
					engine_inst_ext1 <= {row_counter, EXT_CMD_QMEM_WR};
					if (row_counter == rows-1) begin
						row_counter <= 4'd0;
						state <= S_START;
					end else begin
						row_counter <= row_counter + 4'd1;
					end
				end

				S_START: begin
					engine_start0 <= 1'b1;
					engine_start1 <= 1'b1;
					state <= S_IDLE;
				end

				default: begin
					state <= S_IDLE;
				end
			endcase
		end
	end

endmodule
