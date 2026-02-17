// Mac verification top: fullchip interface (clk, mem_in, inst, reset).
// out = ofifo output for TB to compare with estimated result. No pmem (TB only samples out).

module mac_array_top (clk, mem_in, inst, reset, out);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter pr = 8;

  input  clk;
  input  [pr*bw-1:0] mem_in;
  input  [18:0] inst;
  input  reset;
  output [bw_psum*col-1:0] out;

  wire  [pr*bw-1:0] mac_in;
  wire  [pr*bw-1:0] kmem_out;
  wire  [pr*bw-1:0] qmem_out;
  wire  [bw_psum*col-1:0] fifo_out;
  wire  [bw_psum*col-1:0] array_out;
  wire  [col-1:0] fifo_wr;
  wire  ofifo_rd;
  wire  [3:0] qkmem_add;
  wire  qmem_rd, qmem_wr, kmem_rd, kmem_wr;
  wire  fifo_valid;

  assign ofifo_rd = inst[16];
  assign qkmem_add = inst[15:12];
  assign qmem_rd = inst[5];
  assign qmem_wr = inst[4];
  assign kmem_rd = inst[3];
  assign kmem_wr = inst[2];
  assign mac_in = inst[6] ? kmem_out : qmem_out;
  assign out = fifo_out;

  mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
    .in(mac_in),
    .clk(clk),
    .reset(reset),
    .inst(inst[7:6]),
    .fifo_wr(fifo_wr),
    .out(array_out)
  );

  ofifo #(.bw(bw_psum), .col(col)) ofifo_inst (
    .reset(reset),
    .clk(clk),
    .in(array_out),
    .wr(fifo_wr),
    .rd(ofifo_rd),
    .o_valid(fifo_valid),
    .out(fifo_out)
  );

  sram_w16 #(.sram_bit(pr*bw)) qmem_instance (
    .CLK(clk),
    .D(mem_in),
    .Q(qmem_out),
    .CEN(!(qmem_rd||qmem_wr)),
    .WEN(!qmem_wr),
    .A(qkmem_add)
  );

  sram_w16 #(.sram_bit(pr*bw)) kmem_instance (
    .CLK(clk),
    .D(mem_in),
    .Q(kmem_out),
    .CEN(!(kmem_rd||kmem_wr)),
    .WEN(!kmem_wr),
    .A(qkmem_add)
  );

endmodule
