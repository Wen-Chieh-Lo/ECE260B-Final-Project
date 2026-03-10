// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

module sfp_row (clk, reset, acc, div, fifo_ext_rd, sum_in, sum_out, sfp_in, sfp_out, sfp_out_valid);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter out_shift = 7;

  localparam bw_out = out_shift + 1'b1;

 
  input  clk, reset, div, acc, fifo_ext_rd;
  input  [bw_psum+3:0] sum_in;
  input  [col*bw_psum-1:0] sfp_in;
  wire  [col*bw_psum-1:0] abs;
  reg    div_q;
  output reg sfp_out_valid;
  output [col*bw_out-1:0] sfp_out;
  output [bw_psum+3:0] sum_out;
  wire [bw_psum+3:0] sum_this_core;
  wire signed [bw_psum+3:0] sum_2core;
  wire [bw_psum+3:0] sum8_out;
  wire [out_shift-1:0] div_out0, div_out1, div_out2, div_out3;
  wire [out_shift-1:0] div_out4, div_out5, div_out6, div_out7;
  reg  div_start;
  reg  div_started;
  wire div_valid;
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

  // next-state registers
  reg        fifo_wr_nxt;
  reg        div_start_nxt;
  reg        acc_d1_nxt;
  reg        div_q_nxt;
  reg        div_started_nxt;
  reg [bw_psum+3:0] sum_q_nxt;
  reg [out_shift-1:0] div_out0_nxt;
  reg [out_shift-1:0] div_out1_nxt;
  reg [out_shift-1:0] div_out2_nxt;
  reg [out_shift-1:0] div_out3_nxt;
  reg [out_shift-1:0] div_out4_nxt;
  reg [out_shift-1:0] div_out5_nxt;
  reg [out_shift-1:0] div_out6_nxt;
  reg [out_shift-1:0] div_out7_nxt;
  

  reg [bw_psum+3:0] sum_q;
  reg fifo_wr;
  reg acc_d1;  // acc delayed 1 cycle: sum_q updates first, then fifo captures next cycle

  assign div_valid = div_started && div_done;

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


  // divider instances: use combinational div by default, enable long-division with +define+SFP_LONGDIV
`ifndef SFP_LONGDIV
  // combinational division: use direct div, treat divider as always-done
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div0 (
    .in({4'b0, abs[bw_psum*1-1 : bw_psum*0]}),
    .divisor(sum_2core), .out(div_out0), .done(div_done)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div1 (
    .in({4'b0, abs[bw_psum*2-1 : bw_psum*1]}),
    .divisor(sum_2core), .out(div_out1)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div2 (
    .in({4'b0, abs[bw_psum*3-1 : bw_psum*2]}),
    .divisor(sum_2core), .out(div_out2)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div3 (
    .in({4'b0, abs[bw_psum*4-1 : bw_psum*3]}),
    .divisor(sum_2core), .out(div_out3)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div4 (
    .in({4'b0, abs[bw_psum*5-1 : bw_psum*4]}),
    .divisor(sum_2core), .out(div_out4)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div5 (
    .in({4'b0, abs[bw_psum*6-1 : bw_psum*5]}),
    .divisor(sum_2core), .out(div_out5)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div6 (
    .in({4'b0, abs[bw_psum*7-1 : bw_psum*6]}),
    .divisor(sum_2core), .out(div_out6)
  );
  div #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div7 (
    .in({4'b0, abs[bw_psum*8-1 : bw_psum*7]}),
    .divisor(sum_2core), .out(div_out7)
  );
`else
  // multi-cycle long division (uses div_longdiv)
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div0 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*1-1 : bw_psum*0]}),
    .divisor(sum_2core), .out(div_out0), .done(div_done)
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div1 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*2-1 : bw_psum*1]}),
    .divisor(sum_2core), .out(div_out1), .done()
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div2 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*3-1 : bw_psum*2]}),
    .divisor(sum_2core), .out(div_out2), .done()
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div3 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*4-1 : bw_psum*3]}),
    .divisor(sum_2core), .out(div_out3), .done()
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div4 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*5-1 : bw_psum*4]}),
    .divisor(sum_2core), .out(div_out4), .done()
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div5 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*6-1 : bw_psum*5]}),
    .divisor(sum_2core), .out(div_out5), .done()
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div6 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*7-1 : bw_psum*6]}),
    .divisor(sum_2core), .out(div_out6), .done()
  );
  div_longdiv #(.bw_psum(bw_psum+4), .out_shift(out_shift)) div7 (
    .clk(clk), .reset(reset), .start(div_start), .in({4'b0, abs[bw_psum*8-1 : bw_psum*7]}),
    .divisor(sum_2core), .out(div_out7), .done()
  );
`endif
  // next-state combinational logic
  always @(*) begin
    fifo_wr_nxt   = fifo_wr;
    div_start_nxt = div_start;
    acc_d1_nxt    = acc_d1;
    sum_q_nxt     = sum_q;
    div_q_nxt     = div_q;

    // hold divider outputs by default
    div_out0_nxt  = div_out0;
    div_out1_nxt  = div_out1;
    div_out2_nxt  = div_out2;
    div_out3_nxt  = div_out3;
    div_out4_nxt  = div_out4;
    div_out5_nxt  = div_out5;
    div_out6_nxt  = div_out6;
    div_out7_nxt  = div_out7;

    div_q_nxt   = div;
    acc_d1_nxt  = acc;

    if (acc) begin
      sum_q_nxt = sum8_out;
    end

    fifo_wr_nxt = acc_d1;

    if (!acc) begin
      if (div) begin
        div_start_nxt = 1'b1;
      end else begin
        div_start_nxt = 1'b0;
      end

      if (div_done) begin
        div_out0_nxt = div_out0;
        div_out1_nxt = div_out1;
        div_out2_nxt = div_out2;
        div_out3_nxt = div_out3;
        div_out4_nxt = div_out4;
        div_out5_nxt = div_out5;
        div_out6_nxt = div_out6;
        div_out7_nxt = div_out7;
      end
    end

    if(!div_started)begin
      if(div_start)begin
        div_started_nxt = 1'b1;
      end
      else begin
        div_started_nxt = 1'b0;
      end
    end
    else begin
      if(div_done)begin
        div_started_nxt = 1'b0;
      end
      else begin
        div_started_nxt = div_started;
      end
    end
  end

  // sequential updates
  always @ (posedge clk) begin
    if (reset) begin
      fifo_wr       <= 1'b0;
      div_start     <= 1'b0;
      acc_d1        <= 1'b0;
      sum_q         <= {(bw_psum+4){1'b0}};
      div_q         <= 1'b0;
      div_started   <= 1'b0;
      sfp_out_sign0 <= {bw_psum{1'b0}};
      sfp_out_sign1 <= {bw_psum{1'b0}};
      sfp_out_sign2 <= {bw_psum{1'b0}};
      sfp_out_sign3 <= {bw_psum{1'b0}};
      sfp_out_sign4 <= {bw_psum{1'b0}};
      sfp_out_sign5 <= {bw_psum{1'b0}};
      sfp_out_sign6 <= {bw_psum{1'b0}};
      sfp_out_sign7 <= {bw_psum{1'b0}};
      sfp_out_valid <= 1'b0;
    end
    else begin
      fifo_wr       <= fifo_wr_nxt;
      div_start     <= div_start_nxt;
      acc_d1        <= acc_d1_nxt;
      sum_q         <= sum_q_nxt;
      div_q         <= div_q_nxt;
      div_started   <= div_started_nxt;
      sfp_out_sign0 <= {{(bw_psum-out_shift){1'b0}}, div_out0_nxt};
      sfp_out_sign1 <= {{(bw_psum-out_shift){1'b0}}, div_out1_nxt};
      sfp_out_sign2 <= {{(bw_psum-out_shift){1'b0}}, div_out2_nxt};
      sfp_out_sign3 <= {{(bw_psum-out_shift){1'b0}}, div_out3_nxt};
      sfp_out_sign4 <= {{(bw_psum-out_shift){1'b0}}, div_out4_nxt};
      sfp_out_sign5 <= {{(bw_psum-out_shift){1'b0}}, div_out5_nxt};
      sfp_out_sign6 <= {{(bw_psum-out_shift){1'b0}}, div_out6_nxt};
      sfp_out_sign7 <= {{(bw_psum-out_shift){1'b0}}, div_out7_nxt};
      sfp_out_valid <= div_valid;  //the latency after division is 1 cyc. So we explicitly delay 1 cyc here.
    end
  end


endmodule

