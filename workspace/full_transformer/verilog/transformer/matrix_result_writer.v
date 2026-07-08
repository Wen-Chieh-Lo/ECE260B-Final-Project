// Reads matrix-engine PMEM rows and writes quantized rows back into the
// transformer buffer bank selected by dst_sel.
module matrix_result_writer (
	clk,
	reset,
	start,
	dst_sel,
	engine_out0,
	engine_out1,
	engine_inst_ext0,
	engine_inst_ext1,
	result_wr_en,
	result_wr_buf,
	result_wr_addr,
	result_wr_data0,
	result_wr_data1,
	busy,
	done
);

	parameter bw = 8;
	parameter bw_psum = 20;
	parameter col = 8;
	parameter half_pr = 8;
	parameter rows = 8;

	localparam row_width = half_pr*bw;
	localparam [1:0] EXT_CMD_NO_OP = 2'b00;
	localparam [1:0] EXT_CMD_PMEM_RD = 2'b11;

	input clk;
	input reset;
	input start;
	input [3:0] dst_sel;
	input [bw_psum*col-1:0] engine_out0;
	input [bw_psum*col-1:0] engine_out1;
	output reg [5:0] engine_inst_ext0;
	output reg [5:0] engine_inst_ext1;
	output reg result_wr_en;
	output reg [3:0] result_wr_buf;
	output reg [3:0] result_wr_addr;
	output reg [row_width-1:0] result_wr_data0;
	output reg [row_width-1:0] result_wr_data1;
	output busy;
	output reg done;

	localparam [1:0] S_IDLE = 2'd0;
	localparam [1:0] S_ISSUE_READ = 2'd1;
	localparam [1:0] S_WAIT_DATA = 2'd2;
	localparam [1:0] S_CAPTURE = 2'd3;

	reg [1:0] state;
	reg [3:0] row_counter;
	reg [3:0] dst_sel_r;
	integer i;

	assign busy = (state != S_IDLE);

	always @(*) begin
		for (i = 0; i < half_pr; i = i + 1) begin
			result_wr_data0[i*bw +: bw] = engine_out0[i*bw_psum +: bw];
			result_wr_data1[i*bw +: bw] = engine_out1[i*bw_psum +: bw];
		end
	end

	always @(posedge clk) begin
		if (reset) begin
			state <= S_IDLE;
			row_counter <= 4'd0;
			dst_sel_r <= 4'd0;
			engine_inst_ext0 <= {4'd0, EXT_CMD_NO_OP};
			engine_inst_ext1 <= {4'd0, EXT_CMD_NO_OP};
			result_wr_en <= 1'b0;
			result_wr_buf <= 4'd0;
			result_wr_addr <= 4'd0;
			done <= 1'b0;
		end else begin
			engine_inst_ext0 <= {4'd0, EXT_CMD_NO_OP};
			engine_inst_ext1 <= {4'd0, EXT_CMD_NO_OP};
			result_wr_en <= 1'b0;
			done <= 1'b0;

			case (state)
				S_IDLE: begin
					row_counter <= 4'd0;
					if (start) begin
						dst_sel_r <= dst_sel;
						state <= S_ISSUE_READ;
					end
				end

				S_ISSUE_READ: begin
					engine_inst_ext0 <= {row_counter, EXT_CMD_PMEM_RD};
					engine_inst_ext1 <= {row_counter, EXT_CMD_PMEM_RD};
					state <= S_WAIT_DATA;
				end

				S_WAIT_DATA: begin
					engine_inst_ext0 <= {row_counter, EXT_CMD_PMEM_RD};
					engine_inst_ext1 <= {row_counter, EXT_CMD_PMEM_RD};
					state <= S_CAPTURE;
				end

				S_CAPTURE: begin
					result_wr_en <= 1'b1;
					result_wr_buf <= dst_sel_r;
					result_wr_addr <= row_counter;
					if (row_counter == rows-1) begin
						row_counter <= 4'd0;
						done <= 1'b1;
						state <= S_IDLE;
					end else begin
						row_counter <= row_counter + 4'd1;
						state <= S_ISSUE_READ;
					end
				end

				default: begin
					state <= S_IDLE;
				end
			endcase
		end
	end

endmodule
