// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

module sfp_row (clk, reset, acc, div, fifo_ext_rd, sum_in, sum_out, sfp_in, sfp_out);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+3;
  parameter out_shift = 7;

  localparam bw_out = out_shift + 1'b1;

 
  input  clk, reset, div, acc, fifo_ext_rd;
  input  [bw_psum+3:0] sum_in;
  input  [col*bw_psum-1:0] sfp_in;
  wire  [col*bw_psum-1:0] abs;
  reg    div_q;
  output [col*bw_out-1:0] sfp_out;
  output [bw_psum+3:0] sum_out;
  wire [bw_psum+3:0] sum_this_core;
  wire signed [bw_psum-1:0] sum_2core;
  wire [bw_psum+3:0] sum8_out;
  wire [bw_psum-1:0] div_out0, div_out1, div_out2, div_out3;
  wire [bw_psum-1:0] div_out4, div_out5, div_out6, div_out7;
  reg  div_start;
  wire div_done;
  wire signed [bw_psum-1:0] sfp_in_sign0;
  wire signed [bw_psum-1:0] sfp_in_sign1;
  wire signed [bw_psum-1:0] sfp_in_sign2;
  wire signed [bw_psum-1:0] sfp_in_sign3;
  wire signed [bw_psum-1:0] sfp_in_sign4;
  wire signed [bw_psum-1:0] sfp_in_sign5;
  wire signed [bw_psum-1:0] sfp_in_sign6;
  wire signed [bw_psum-1:0] sfp_in_sign7;


  reg  [bw_psum-1:0] sfp_out_sign0;
  reg  [bw_psum-1:0] sfp_out_sign1;
  reg  [bw_psum-1:0] sfp_out_sign2;
  reg  [bw_psum-1:0] sfp_out_sign3;
  reg  [bw_psum-1:0] sfp_out_sign4;
  reg  [bw_psum-1:0] sfp_out_sign5;
  reg  [bw_psum-1:0] sfp_out_sign6;
  reg  [bw_psum-1:0] sfp_out_sign7;

  reg [bw_psum+3:0] sum_q;
  reg fifo_wr;
  reg acc_d1;  // acc delayed 1 cycle: sum_q updates first, then fifo captures next cycle

  assign sfp_in_sign0 =  sfp_in[bw_psum*1-1 : bw_psum*0];
  assign sfp_in_sign1 =  sfp_in[bw_psum*2-1 : bw_psum*1];
  assign sfp_in_sign2 =  sfp_in[bw_psum*3-1 : bw_psum*2];
  assign sfp_in_sign3 =  sfp_in[bw_psum*4-1 : bw_psum*3];
  assign sfp_in_sign4 =  sfp_in[bw_psum*5-1 : bw_psum*4];
  assign sfp_in_sign5 =  sfp_in[bw_psum*6-1 : bw_psum*5];
  assign sfp_in_sign6 =  sfp_in[bw_psum*7-1 : bw_psum*6];
  assign sfp_in_sign7 =  sfp_in[bw_psum*8-1 : bw_psum*7];


  assign sfp_out[bw_out*1-1 : bw_out*0] = {1'b0, sfp_out_sign0};
  assign sfp_out[bw_out*2-1 : bw_out*1] = {1'b0, sfp_out_sign1};
  assign sfp_out[bw_out*3-1 : bw_out*2] = {1'b0, sfp_out_sign2};
  assign sfp_out[bw_out*4-1 : bw_out*3] = {1'b0, sfp_out_sign3};
  assign sfp_out[bw_out*5-1 : bw_out*4] = {1'b0, sfp_out_sign4};
  assign sfp_out[bw_out*6-1 : bw_out*5] = {1'b0, sfp_out_sign5};
  assign sfp_out[bw_out*7-1 : bw_out*6] = {1'b0, sfp_out_sign6};
  assign sfp_out[bw_out*8-1 : bw_out*7] = {1'b0, sfp_out_sign7};

  assign sum_2core = sum_this_core[bw_psum+3:0] + sum_in[bw_psum+3:0];

  assign abs[bw_psum*1-1 : bw_psum*0] = (sfp_in[bw_psum*1-1]) ?  (~sfp_in[bw_psum*1-1 : bw_psum*0] + 1)  :  sfp_in[bw_psum*1-1 : bw_psum*0];
  assign abs[bw_psum*2-1 : bw_psum*1] = (sfp_in[bw_psum*2-1]) ?  (~sfp_in[bw_psum*2-1 : bw_psum*1] + 1)  :  sfp_in[bw_psum*2-1 : bw_psum*1];
  assign abs[bw_psum*3-1 : bw_psum*2] = (sfp_in[bw_psum*3-1]) ?  (~sfp_in[bw_psum*3-1 : bw_psum*2] + 1)  :  sfp_in[bw_psum*3-1 : bw_psum*2];
  assign abs[bw_psum*4-1 : bw_psum*3] = (sfp_in[bw_psum*4-1]) ?  (~sfp_in[bw_psum*4-1 : bw_psum*3] + 1)  :  sfp_in[bw_psum*4-1 : bw_psum*3];
  assign abs[bw_psum*5-1 : bw_psum*4] = (sfp_in[bw_psum*5-1]) ?  (~sfp_in[bw_psum*5-1 : bw_psum*4] + 1)  :  sfp_in[bw_psum*5-1 : bw_psum*4];
  assign abs[bw_psum*6-1 : bw_psum*5] = (sfp_in[bw_psum*6-1]) ?  (~sfp_in[bw_psum*6-1 : bw_psum*5] + 1)  :  sfp_in[bw_psum*6-1 : bw_psum*5];
  assign abs[bw_psum*7-1 : bw_psum*6] = (sfp_in[bw_psum*7-1]) ?  (~sfp_in[bw_psum*7-1 : bw_psum*6] + 1)  :  sfp_in[bw_psum*7-1 : bw_psum*6];
  assign abs[bw_psum*8-1 : bw_psum*7] = (sfp_in[bw_psum*8-1]) ?  (~sfp_in[bw_psum*8-1 : bw_psum*7] + 1)  :  sfp_in[bw_psum*8-1 : bw_psum*7];

  fifo_depth16 #(.bw(bw_psum+4)) fifo_inst_int (
     .rd_clk(clk), 
     .wr_clk(clk), 
     .in(sum_q),
     .out(sum_this_core), 
     .rd(div_q), 
     .wr(fifo_wr), 
     .reset(reset)
  );

  fifo_depth16 #(.bw(bw_psum+4)) fifo_inst_ext (
     .rd_clk(clk), 
     .wr_clk(clk), 
     .in(sum_q),
     .out(sum_out), 
     .rd(fifo_ext_rd), 
     .wr(fifo_wr), 
     .reset(reset)
  );

  sum8_2stage #(.bw_psum(bw_psum)) sum8_inst (
    .clk(clk),
    .reset(reset),
    .in(abs),
    .sum(sum8_out)
  );


  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div0 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*1-1 : bw_psum*0]),
    .divisor(sum_2core), .out(div_out0), .done(div_done)
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div1 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*2-1 : bw_psum*1]),
    .divisor(sum_2core), .out(div_out1), .done()
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div2 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*3-1 : bw_psum*2]),
    .divisor(sum_2core), .out(div_out2), .done()
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div3 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*4-1 : bw_psum*3]),
    .divisor(sum_2core), .out(div_out3), .done()
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div4 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*5-1 : bw_psum*4]),
    .divisor(sum_2core), .out(div_out4), .done()
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div5 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*6-1 : bw_psum*5]),
    .divisor(sum_2core), .out(div_out5), .done()
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div6 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*7-1 : bw_psum*6]),
    .divisor(sum_2core), .out(div_out6), .done()
  );
  div_longdiv #(.bw_psum(bw_psum), .out_shift(out_shift)) div7 (
    .clk(clk), .reset(reset), .start(div_start), .in(abs[bw_psum*8-1 : bw_psum*7]),
    .divisor(sum_2core), .out(div_out7), .done()
  );
  

  always @ (posedge clk) begin
    if (reset) begin
      fifo_wr <= 0;
      div_start <= 0;
      acc_d1 <= 0;
    end
    else begin
       div_q <= div ;
       acc_d1 <= acc;
      //  $display("acc = %0d", acc);
       if (acc) begin
         sum_q <= sum8_out;
       end
       fifo_wr <= acc_d1;  // write 1 cycle after sum_q updates (aligns sum8/sum8_2stage)
       if (!acc) begin
   
         if (div) begin
           div_start     <= 1'b1;
         end else begin
           div_start     <= 1'b0;
         end

         if (div_done) begin
           sfp_out_sign0 <= div_out0;
           sfp_out_sign1 <= div_out1;
           sfp_out_sign2 <= div_out2;
           sfp_out_sign3 <= div_out3;
           sfp_out_sign4 <= div_out4;
           sfp_out_sign5 <= div_out5;
           sfp_out_sign6 <= div_out6;
           sfp_out_sign7 <= div_out7;
         end

       end
   end
 end


endmodule

