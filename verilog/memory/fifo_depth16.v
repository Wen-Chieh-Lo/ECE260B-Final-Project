// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module fifo_depth16 (rd_clk, wr_clk, in, out, rd, wr, o_full, o_empty, reset);

  parameter bw = 4;
  parameter simd = 1;

  input  rd_clk;
  input  wr_clk;
  input  rd;
  input  wr;
  input  reset;
  output o_full;
  output o_empty;
  input  [simd*bw-1:0] in;
  output [simd*bw-1:0] out;

  wire full, empty;

  reg [4:0] rd_ptr = 5'b00000;
  reg [4:0] rd_ptr_nxt;
  reg [4:0] wr_ptr = 5'b00000;
  reg [4:0] wr_ptr_nxt;

  reg [simd*bw-1:0] q0,q0_nxt;
  reg [simd*bw-1:0] q1,q1_nxt;
  reg [simd*bw-1:0] q2,q2_nxt;
  reg [simd*bw-1:0] q3,q3_nxt;
  reg [simd*bw-1:0] q4,q4_nxt;
  reg [simd*bw-1:0] q5,q5_nxt;
  reg [simd*bw-1:0] q6,q6_nxt;
  reg [simd*bw-1:0] q7,q7_nxt;
  reg [simd*bw-1:0] q8,q8_nxt;
  reg [simd*bw-1:0] q9,q9_nxt;
  reg [simd*bw-1:0] q10,q10_nxt;
  reg [simd*bw-1:0] q11,q11_nxt;
  reg [simd*bw-1:0] q12,q12_nxt;
  reg [simd*bw-1:0] q13,q13_nxt;
  reg [simd*bw-1:0] q14,q14_nxt;
  reg [simd*bw-1:0] q15,q15_nxt;


 assign empty = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0 ;
 assign full  = ((wr_ptr[3:0] == rd_ptr[3:0]) && (wr_ptr[4] != rd_ptr[4])) ? 1'b1 : 1'b0;

 assign o_full  = full;
 assign o_empty = empty;


  fifo_mux_16_1 #(.bw(bw), .simd(simd)) fifo_mux_16_1a (.in0(q0), .in1(q1), .in2(q2), .in3(q3), .in4(q4), .in5(q5), .in6(q6), .in7(q7),
                                 .in8(q8), .in9(q9), .in10(q10), .in11(q11), .in12(q12), .in13(q13), .in14(q14), .in15(q15),
	                         .sel(rd_ptr[3:0]), .out(out));

always @ (*) begin
  if ((rd == 1) && (empty == 0)) begin
    rd_ptr_nxt = rd_ptr + 1;;
  end
  else begin
    rd_ptr_nxt = rd_ptr;
  end

  if ((wr == 1) && (full == 0)) begin
    wr_ptr_nxt = wr_ptr + 1;
  end
  else begin
    wr_ptr_nxt = wr_ptr;
  end

  q0_nxt = q0 ;
  q1_nxt = q1 ;
  q2_nxt = q2 ;
  q3_nxt = q3 ;
  q4_nxt = q4 ;
  q5_nxt = q5 ;
  q6_nxt = q6 ;
  q7_nxt = q7 ;
  q8_nxt = q8 ;
  q9_nxt = q9 ;
  q10_nxt = q10 ;
  q11_nxt = q11 ;
  q12_nxt = q12 ;
  q13_nxt = q13 ;
  q14_nxt = q14 ;
  q15_nxt = q15 ;
  
  if (wr == 1) begin
    case (wr_ptr[3:0])
      4'b0000   :    q0_nxt = in ;
      4'b0001   :    q1_nxt = in ;
      4'b0010   :    q2_nxt = in ;
      4'b0011   :    q3_nxt = in ;
      4'b0100   :    q4_nxt = in ;
      4'b0101   :    q5_nxt = in ;
      4'b0110   :    q6_nxt = in ;
      4'b0111   :    q7_nxt = in ;
      4'b1000   :    q8_nxt = in ;
      4'b1001   :    q9_nxt = in ;
      4'b1010   :    q10_nxt = in ;
      4'b1011   :    q11_nxt = in ;
      4'b1100   :    q12_nxt = in ;
      4'b1101   :    q13_nxt = in ;
      4'b1110   :    q14_nxt = in ;
      4'b1111   :    q15_nxt = in ;
    endcase
  end

end

always @ (posedge rd_clk) begin
  if (reset) begin
    rd_ptr <= 5'b00000;
  end
  else begin
    rd_ptr <= rd_ptr_nxt;
  end
end


always @ (posedge wr_clk) begin
  if (reset) begin
    wr_ptr <= 5'b00000;
    q0  <= 0;
    q1  <= 0;
    q2  <= 0;
    q3  <= 0;
    q4  <= 0;
    q5  <= 0;
    q6  <= 0;
    q7  <= 0;
    q8  <= 0;
    q9  <= 0;
    q10 <= 0;
    q11 <= 0;
    q12 <= 0;
    q13 <= 0;
    q14 <= 0;
    q15 <= 0;
  end
  else begin 
    wr_ptr <= wr_ptr_nxt;
    q0  <= q0_nxt ;
    q1  <= q1_nxt ;
    q2  <= q2_nxt ;
    q3  <= q3_nxt ;
    q4  <= q4_nxt ;
    q5  <= q5_nxt ;
    q6  <= q6_nxt ;
    q7  <= q7_nxt ;
    q8  <= q8_nxt ;
    q9  <= q9_nxt ;
    q10 <= q10_nxt ;
    q11 <= q11_nxt ;
    q12 <= q12_nxt ;
    q13 <= q13_nxt ;
    q14 <= q14_nxt ;
    q15 <= q15_nxt ;
  end

end


endmodule
