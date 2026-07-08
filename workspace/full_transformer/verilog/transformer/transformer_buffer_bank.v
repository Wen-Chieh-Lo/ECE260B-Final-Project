// Small on-chip matrix buffer bank for the first full-transformer prototype.
// Each logical buffer has two physical banks so the dual-core matrix engine can
// receive separate core0/core1 RHS tiles while sharing LHS rows when desired.
module transformer_buffer_bank (
	clk,
	reset,
	host_wr_en,
	host_wr_buf,
	host_wr_bank,
	host_wr_addr,
	host_wr_data,
	result_wr_en,
	result_wr_buf,
	result_wr_addr,
	result_wr_data0,
	result_wr_data1,
	lhs_sel,
	rhs_sel,
	row_addr,
	lhs_row0,
	lhs_row1,
	rhs_row0,
	rhs_row1
);

	parameter bw = 8;
	parameter half_pr = 8;
	parameter rows = 8;
	parameter num_bufs = 16;

	localparam row_width = half_pr*bw;
	localparam addr_width = 7;

	input clk;
	input reset;
	input host_wr_en;
	input [3:0] host_wr_buf;
	input host_wr_bank;
	input [3:0] host_wr_addr;
	input [row_width-1:0] host_wr_data;
	input result_wr_en;
	input [3:0] result_wr_buf;
	input [3:0] result_wr_addr;
	input [row_width-1:0] result_wr_data0;
	input [row_width-1:0] result_wr_data1;
	input [3:0] lhs_sel;
	input [3:0] rhs_sel;
	input [3:0] row_addr;
	output [row_width-1:0] lhs_row0;
	output [row_width-1:0] lhs_row1;
	output [row_width-1:0] rhs_row0;
	output [row_width-1:0] rhs_row1;

	reg [row_width-1:0] bank0 [0:num_bufs*rows-1];
	reg [row_width-1:0] bank1 [0:num_bufs*rows-1];

	wire [addr_width-1:0] host_index;
	wire [addr_width-1:0] result_index;
	wire [addr_width-1:0] lhs_index;
	wire [addr_width-1:0] rhs_index;

	assign host_index = {host_wr_buf, host_wr_addr[2:0]};
	assign result_index = {result_wr_buf, result_wr_addr[2:0]};
	assign lhs_index = {lhs_sel, row_addr[2:0]};
	assign rhs_index = {rhs_sel, row_addr[2:0]};

	assign lhs_row0 = bank0[lhs_index];
	assign lhs_row1 = bank0[lhs_index];
	assign rhs_row0 = bank0[rhs_index];
	assign rhs_row1 = bank1[rhs_index];

	integer i;
	always @(posedge clk) begin
		if (reset) begin
			for (i = 0; i < num_bufs*rows; i = i + 1) begin
				bank0[i] <= {row_width{1'b0}};
				bank1[i] <= {row_width{1'b0}};
			end
		end else if (result_wr_en) begin
			bank0[result_index] <= result_wr_data0;
			bank1[result_index] <= result_wr_data1;
		end else if (host_wr_en) begin
			if (host_wr_bank)
				bank1[host_index] <= host_wr_data;
			else
				bank0[host_index] <= host_wr_data;
		end
	end

endmodule
