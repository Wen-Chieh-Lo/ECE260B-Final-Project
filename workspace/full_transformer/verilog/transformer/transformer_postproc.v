// Post-attention transformer datapath: residual add + lightweight normalize +
// FFN approximation. This is intentionally compact so the first full-model
// prototype stays synthesizable and easy to extend.
module transformer_postproc (
	clk,
	reset,
	commit,
	enable_ffn,
	attention_out0,
	attention_out1,
	residual_in0,
	residual_in1,
	model_out0,
	model_out1,
	model_out_valid
);

	parameter col = 8;
	parameter bw_psum = 20;
	parameter ffn_shift = 1;

	input clk;
	input reset;
	input commit;
	input enable_ffn;
	input [bw_psum*col-1:0] attention_out0;
	input [bw_psum*col-1:0] attention_out1;
	input [bw_psum*col-1:0] residual_in0;
	input [bw_psum*col-1:0] residual_in1;
	output reg [bw_psum*col-1:0] model_out0;
	output reg [bw_psum*col-1:0] model_out1;
	output reg model_out_valid;

	integer i;
	reg signed [31:0] att0 [0:col-1];
	reg signed [31:0] att1 [0:col-1];
	reg signed [31:0] res0 [0:col-1];
	reg signed [31:0] res1 [0:col-1];
	reg signed [31:0] residual_sum0 [0:col-1];
	reg signed [31:0] residual_sum1 [0:col-1];
	reg signed [31:0] mean0;
	reg signed [31:0] mean1;
	reg signed [31:0] norm0;
	reg signed [31:0] norm1;
	reg signed [31:0] ffn0;
	reg signed [31:0] ffn1;
	reg signed [31:0] post0 [0:col-1];
	reg signed [31:0] post1 [0:col-1];

	function [bw_psum-1:0] sat_signed;
		input signed [31:0] value;
		reg signed [31:0] max_value;
		reg signed [31:0] min_value;
		begin
			max_value = (32'sd1 <<< (bw_psum-1)) - 32'sd1;
			min_value = -(32'sd1 <<< (bw_psum-1));
			if (value > max_value)
				sat_signed = max_value[bw_psum-1:0];
			else if (value < min_value)
				sat_signed = min_value[bw_psum-1:0];
			else
				sat_signed = value[bw_psum-1:0];
		end
	endfunction

	always @(*) begin
		mean0 = 32'sd0;
		mean1 = 32'sd0;
		for (i = 0; i < col; i = i + 1) begin
			att0[i] = $signed(attention_out0[i*bw_psum +: bw_psum]);
			att1[i] = $signed(attention_out1[i*bw_psum +: bw_psum]);
			res0[i] = $signed(residual_in0[i*bw_psum +: bw_psum]);
			res1[i] = $signed(residual_in1[i*bw_psum +: bw_psum]);
			residual_sum0[i] = att0[i] + res0[i];
			residual_sum1[i] = att1[i] + res1[i];
			mean0 = mean0 + residual_sum0[i];
			mean1 = mean1 + residual_sum1[i];
		end

		mean0 = mean0 / col;
		mean1 = mean1 / col;

		for (i = 0; i < col; i = i + 1) begin
			norm0 = residual_sum0[i] - mean0;
			norm1 = residual_sum1[i] - mean1;
			if (enable_ffn) begin
				ffn0 = (norm0 < 0) ? 32'sd0 : (norm0 + (norm0 >>> ffn_shift));
				ffn1 = (norm1 < 0) ? 32'sd0 : (norm1 + (norm1 >>> ffn_shift));
				post0[i] = residual_sum0[i] + ffn0;
				post1[i] = residual_sum1[i] + ffn1;
			end else begin
				post0[i] = residual_sum0[i];
				post1[i] = residual_sum1[i];
			end
		end
	end

	always @(posedge clk) begin
		if (reset) begin
			model_out0 <= {(bw_psum*col){1'b0}};
			model_out1 <= {(bw_psum*col){1'b0}};
			model_out_valid <= 1'b0;
		end else begin
			model_out_valid <= commit;
			if (commit) begin
				for (i = 0; i < col; i = i + 1) begin
					model_out0[i*bw_psum +: bw_psum] <= sat_signed(post0[i]);
					model_out1[i*bw_psum +: bw_psum] <= sat_signed(post1[i]);
				end
			end
		end
	end

endmodule
