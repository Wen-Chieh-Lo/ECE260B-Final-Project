// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_w16 (CLK, D, Q, CEN, WEN, A);

  parameter sram_bit = 64;
  input  CLK;
  input  WEN;
  input  CEN;
  input  [sram_bit-1:0] D;
  input  [3:0] A;
  output reg [sram_bit-1:0] Q;

  reg [sram_bit-1:0] memory0;
  reg [sram_bit-1:0] memory1;
  reg [sram_bit-1:0] memory2;
  reg [sram_bit-1:0] memory3;
  reg [sram_bit-1:0] memory4;
  reg [sram_bit-1:0] memory5;
  reg [sram_bit-1:0] memory6;
  reg [sram_bit-1:0] memory7;
  reg [sram_bit-1:0] memory8;
  reg [sram_bit-1:0] memory9;
  reg [sram_bit-1:0] memory10;
  reg [sram_bit-1:0] memory11;
  reg [sram_bit-1:0] memory12;
  reg [sram_bit-1:0] memory13;
  reg [sram_bit-1:0] memory14;
  reg [sram_bit-1:0] memory15;

  reg [sram_bit-1:0] Q_nxt;
  reg [sram_bit-1:0] memory0_nxt, memory1_nxt, memory2_nxt, memory3_nxt;
  reg [sram_bit-1:0] memory4_nxt, memory5_nxt, memory6_nxt, memory7_nxt;
  reg [sram_bit-1:0] memory8_nxt, memory9_nxt, memory10_nxt, memory11_nxt;
  reg [sram_bit-1:0] memory12_nxt, memory13_nxt, memory14_nxt, memory15_nxt;

  // Combinational: compute next values
  always @(*) begin
    Q_nxt = Q;
    memory0_nxt  = memory0;
    memory1_nxt  = memory1;
    memory2_nxt  = memory2;
    memory3_nxt  = memory3;
    memory4_nxt  = memory4;
    memory5_nxt  = memory5;
    memory6_nxt  = memory6;
    memory7_nxt  = memory7;
    memory8_nxt  = memory8;
    memory9_nxt  = memory9;
    memory10_nxt = memory10;
    memory11_nxt = memory11;
    memory12_nxt = memory12;
    memory13_nxt = memory13;
    memory14_nxt = memory14;
    memory15_nxt = memory15;

    if (!CEN && WEN) begin // read
      case (A)
        4'b0000: Q_nxt = memory0;
        4'b0001: Q_nxt = memory1;
        4'b0010: Q_nxt = memory2;
        4'b0011: Q_nxt = memory3;
        4'b0100: Q_nxt = memory4;
        4'b0101: Q_nxt = memory5;
        4'b0110: Q_nxt = memory6;
        4'b0111: Q_nxt = memory7;
        4'b1000: Q_nxt = memory8;
        4'b1001: Q_nxt = memory9;
        4'b1010: Q_nxt = memory10;
        4'b1011: Q_nxt = memory11;
        4'b1100: Q_nxt = memory12;
        4'b1101: Q_nxt = memory13;
        4'b1110: Q_nxt = memory14;
        4'b1111: Q_nxt = memory15;
      endcase
    end
    else if (!CEN && !WEN) begin // write
      case (A)
        4'b0000: memory0_nxt  = D;
        4'b0001: memory1_nxt  = D;
        4'b0010: memory2_nxt  = D;
        4'b0011: memory3_nxt  = D;
        4'b0100: memory4_nxt  = D;
        4'b0101: memory5_nxt  = D;
        4'b0110: memory6_nxt  = D;
        4'b0111: memory7_nxt  = D;
        4'b1000: memory8_nxt  = D;
        4'b1001: memory9_nxt  = D;
        4'b1010: memory10_nxt = D;
        4'b1011: memory11_nxt = D;
        4'b1100: memory12_nxt = D;
        4'b1101: memory13_nxt = D;
        4'b1110: memory14_nxt = D;
        4'b1111: memory15_nxt = D;
      endcase
    end
  end

  // Sequential: only reg <= reg_nxt
  always @(posedge CLK) begin
    Q       <= Q_nxt;
    memory0 <= memory0_nxt;
    memory1 <= memory1_nxt;
    memory2 <= memory2_nxt;
    memory3 <= memory3_nxt;
    memory4 <= memory4_nxt;
    memory5 <= memory5_nxt;
    memory6 <= memory6_nxt;
    memory7 <= memory7_nxt;
    memory8 <= memory8_nxt;
    memory9 <= memory9_nxt;
    memory10 <= memory10_nxt;
    memory11 <= memory11_nxt;
    memory12 <= memory12_nxt;
    memory13 <= memory13_nxt;
    memory14 <= memory14_nxt;
    memory15 <= memory15_nxt;
  end

endmodule