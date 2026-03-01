// 8-input adder tree: sums 8 bw_psum-bit values with 4-bit zero-extension each.
// Output width: bw_psum + 4
module sum8 #(
  parameter bw_psum = 19
) (
  input  [bw_psum*8-1:0] in,
  output [bw_psum+3:0]   sum
);

  wire [bw_psum+3:0] ext0 = {4'b0, in[bw_psum*1-1 : bw_psum*0]};
  wire [bw_psum+3:0] ext1 = {4'b0, in[bw_psum*2-1 : bw_psum*1]};
  wire [bw_psum+3:0] ext2 = {4'b0, in[bw_psum*3-1 : bw_psum*2]};
  wire [bw_psum+3:0] ext3 = {4'b0, in[bw_psum*4-1 : bw_psum*3]};
  wire [bw_psum+3:0] ext4 = {4'b0, in[bw_psum*5-1 : bw_psum*4]};
  wire [bw_psum+3:0] ext5 = {4'b0, in[bw_psum*6-1 : bw_psum*5]};
  wire [bw_psum+3:0] ext6 = {4'b0, in[bw_psum*7-1 : bw_psum*6]};
  wire [bw_psum+3:0] ext7 = {4'b0, in[bw_psum*8-1 : bw_psum*7]};

  assign sum = ext0 + ext1 + ext2 + ext3 + ext4 + ext5 + ext6 + ext7;

endmodule

// 8-input adder tree, repipelined: 2 stages of registers to break critical path.
// Latency: 1 cycles. Output width: bw_psum + 4
module sum8_2stage #(
  parameter bw_psum = 19
) (
  input  clk,
  input  reset,
  input  [bw_psum*8-1:0] in,
  output [bw_psum+3:0]   sum
);

  wire [bw_psum+3:0] ext0 = {4'b0, in[bw_psum*1-1 : bw_psum*0]};
  wire [bw_psum+3:0] ext1 = {4'b0, in[bw_psum*2-1 : bw_psum*1]};
  wire [bw_psum+3:0] ext2 = {4'b0, in[bw_psum*3-1 : bw_psum*2]};
  wire [bw_psum+3:0] ext3 = {4'b0, in[bw_psum*4-1 : bw_psum*3]};
  wire [bw_psum+3:0] ext4 = {4'b0, in[bw_psum*5-1 : bw_psum*4]};
  wire [bw_psum+3:0] ext5 = {4'b0, in[bw_psum*6-1 : bw_psum*5]};
  wire [bw_psum+3:0] ext6 = {4'b0, in[bw_psum*7-1 : bw_psum*6]};
  wire [bw_psum+3:0] ext7 = {4'b0, in[bw_psum*8-1 : bw_psum*7]};

  // Stage 1: 4 pairs (registered)
  wire [bw_psum+3:0] s01 = ext0 + ext1;
  wire [bw_psum+3:0] s23 = ext2 + ext3;
  wire [bw_psum+3:0] s45 = ext4 + ext5;
  wire [bw_psum+3:0] s67 = ext6 + ext7;

  reg [bw_psum+3:0] s01_r, s23_r, s45_r, s67_r;

  always @(posedge clk) begin
    if (reset) begin
      s01_r <= 0;
      s23_r <= 0;
      s45_r <= 0;
      s67_r <= 0;
    end else begin
      s01_r <= s01;
      s23_r <= s23;
      s45_r <= s45;
      s67_r <= s67;
    end
  end

  // Stage 2 & 3: combinational
  assign sum = (s01_r + s23_r) + (s45_r + s67_r);

endmodule
