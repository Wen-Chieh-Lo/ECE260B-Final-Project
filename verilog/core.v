// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module core (clk, sum_in, sum_out, mem_in, out, inst, reset);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+3;
parameter sfp_out_shift = 8;
parameter pr = 8;

input  [bw_psum+3:0] sum_in;
output [bw_psum+3:0] sum_out;
output [bw_psum*col-1:0] out;
wire   [bw_psum*col-1:0] pmem_out;
input  [pr*bw-1:0] mem_in;
input  clk;
// input  [16:0] inst; 
input  [18:0] inst;
input  reset;

wire  [pr*bw-1:0] mac_in;
wire  [pr*bw-1:0] kmem_out;
wire  [pr*bw-1:0] qmem_out;
wire  [bw_psum*col-1:0] pmem_in;
wire  [bw_psum*col-1:0] fifo_out;
wire  [bw_psum*col-1:0] sfp_out;
wire  [bw_psum*col-1:0] array_out;
wire  [col-1:0] fifo_wr;
wire  ofifo_rd;
wire [3:0] qkmem_add;
wire [3:0] pmem_add;
wire [1:0] mac_inst;

wire vproduct_mode;

wire  qmem_rd;
wire  qmem_wr; 
wire  kmem_rd;
wire  kmem_wr; 
wire  pmem_rd;
wire  pmem_wr; 


wire sfp_acc;                         // SFP accumulating for normalization
wire sfp_div;                         // SFP dividing for normalization
wire sfp_fifo_ext_rd;                 // SFP start to output FIFO -> sfp_sum_out -> other core, not used in single core
wire [bw_psum+3:0] sfp_sum_in;        // SFP sum input, is always 0 in single port
wire [bw_psum+3:0] sfp_sum_out;       // SFP sum output, float in single core

assign sfp_fifo_ext_rd = 1'b0;    // unused in single core
assign sfp_sum_in = {bw_psum+4{1'b0}}; // unused in single core

assign vprod_mode = inst[19];
assign sfp_div  = inst[18];            // set as controlled by primary input, may changed to internal FSM
assign sfp_acc  = inst[17];            // set as controlled by primary input, may changed to internal FSM
assign ofifo_rd = inst[16];
assign qkmem_add= inst[15:12];
assign pmem_add = inst[11:8];

assign mac_inst = inst[7:6];
assign qmem_rd  = inst[5];
assign qmem_wr  = inst[4];
assign kmem_rd  = inst[3];
assign kmem_wr  = inst[2];
assign pmem_rd  = inst[1];
assign pmem_wr  = inst[0];

assign mac_in  = mac_inst[1] ? kmem_out : qmem_out;

// assign pmem_in = fifo_out;
assign out = pmem_out;

assign pmem_in = fifo_out; 

mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
        .in(mac_in), 
        .clk(clk), 
        .reset(reset), 
        .inst(mac_inst),     
        .fifo_wr(fifo_wr),     
	.out(array_out)
);

ofifo #(.bw(bw_psum), .col(col))  ofifo_inst (
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

sram_w16 #(.sram_bit(col*bw_psum)) psum_mem_instance (
        .CLK(clk),
        .D(pmem_in),
        .Q(pmem_out),
        .CEN(!(pmem_rd||pmem_wr)),
        .WEN(!pmem_wr), 
        .A(pmem_add)
);


sfp_row #(.col(col), .bw(bw), .bw_psum(bw_psum), .out_shift(sfp_out_shift)) sfp_instance (
	.clk(clk),
	.reset(reset),
	.acc(sfp_acc),
	.div(sfp_div),
	.fifo_ext_rd(sfp_fifo_ext_rd),
	.sum_in(sfp_sum_in),
	.sum_out(sfp_sum_out),
	.sfp_in(pmem_out),
	.sfp_out(sfp_out)
);



//   //////////// For printing purpose ////////////
//   always @(posedge clk) begin
//       if(pmem_wr)
//          $display("Memory write to PSUM mem add %x %x ", pmem_add, pmem_in); 
//   end



endmodule
