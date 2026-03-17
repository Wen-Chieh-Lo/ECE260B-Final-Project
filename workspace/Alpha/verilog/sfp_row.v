// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
// Alpha interface: acc_start/div_start (pulse), acc_done/div_done, div_busy
// sum_in valid next cycle after div_start. No fifo_ext_rd.
// Pipeline: shifter for acc/div done.

module sfp_row(clk, reset, acc_start, div_start, acc_done, div_done, div_busy, sum_in, sum_out, sfp_in, sfp_div_out);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter out_shift = 7;

  localparam bw_out = out_shift + 1'b1;

  input  clk, reset;
  input  acc_start, div_start;
  input  [bw_psum+3:0] sum_in;
  input  [col*bw_psum-1:0] sfp_in;
  output wire acc_done;
  output wire div_done;
  output wire div_busy;
  output wire [bw_psum+3:0] sum_out;
  output [col*bw_out-1:0] sfp_div_out;

  wire  [col*bw_psum-1:0] abs;
  wire  [bw_psum+3:0] sum8_out;
  wire  [bw_psum+3:0] sum_this_core;
  wire  signed [bw_psum+3:0] sum_2core;
  wire  [out_shift-1:0] div_out [0:col-1];
  wire  div_done_w [0:col-1];
  wire  div_busy_w [0:col-1];

  reg   [bw_psum+3:0] sum_this_core_r;
  reg   [bw_psum+3:0] sum_in_r;
  reg   [col*bw_psum-1:0] abs_div;  // latch abs when div_start (sfp_in only valid that cycle)
  reg   div_start_D1;
  reg   [out_shift-1:0] div_out_r [0:col-1];
  reg   div_done_r;   // latch to align with sfp_div_out (valid same cycle)

  wire  fifo_rd;
  wire  fifo_wr;
  wire  sum8_valid;
  wire  div_start_internal;
  genvar c;

  assign fifo_rd = div_start;
  assign fifo_wr = sum8_valid;   // when sum8_out valid
  assign sum_2core = sum_this_core_r + sum_in_r;

  // abs: combinational from sfp_in
  assign abs[bw_psum*1-1 : bw_psum*0] = (sfp_in[bw_psum*1-1]) ? (~sfp_in[bw_psum*1-1 : bw_psum*0] + 1) : sfp_in[bw_psum*1-1 : bw_psum*0];
  assign abs[bw_psum*2-1 : bw_psum*1] = (sfp_in[bw_psum*2-1]) ? (~sfp_in[bw_psum*2-1 : bw_psum*1] + 1) : sfp_in[bw_psum*2-1 : bw_psum*1];
  assign abs[bw_psum*3-1 : bw_psum*2] = (sfp_in[bw_psum*3-1]) ? (~sfp_in[bw_psum*3-1 : bw_psum*2] + 1) : sfp_in[bw_psum*3-1 : bw_psum*2];
  assign abs[bw_psum*4-1 : bw_psum*3] = (sfp_in[bw_psum*4-1]) ? (~sfp_in[bw_psum*4-1 : bw_psum*3] + 1) : sfp_in[bw_psum*4-1 : bw_psum*3];
  assign abs[bw_psum*5-1 : bw_psum*4] = (sfp_in[bw_psum*5-1]) ? (~sfp_in[bw_psum*5-1 : bw_psum*4] + 1) : sfp_in[bw_psum*5-1 : bw_psum*4];
  assign abs[bw_psum*6-1 : bw_psum*5] = (sfp_in[bw_psum*6-1]) ? (~sfp_in[bw_psum*6-1 : bw_psum*5] + 1) : sfp_in[bw_psum*6-1 : bw_psum*5];
  assign abs[bw_psum*7-1 : bw_psum*6] = (sfp_in[bw_psum*7-1]) ? (~sfp_in[bw_psum*7-1 : bw_psum*6] + 1) : sfp_in[bw_psum*7-1 : bw_psum*6];
  assign abs[bw_psum*8-1 : bw_psum*7] = (sfp_in[bw_psum*8-1]) ? (~sfp_in[bw_psum*8-1 : bw_psum*7] + 1) : sfp_in[bw_psum*8-1 : bw_psum*7];

  sum8_2stage #(.bw_psum(bw_psum)) sum8_inst (
    .clk(clk),
    .reset(reset),
    .start(acc_start),
    .in(abs),
    .valid(sum8_valid),
    .sum(sum8_out)
  );

  fifo_depth16 #(.bw(bw_psum+4)) fifo_inst (
    .rd_clk(clk),
    .wr_clk(clk),
    .in(sum8_out),
    .out(sum_this_core),
    .rd(fifo_rd),
    .wr(fifo_wr),
    .o_full(),
    .o_empty(),
    .reset(reset)
  );

  assign acc_done = sum8_valid;

  // sum_out: when fifo_rd (div_start), output sum_this_core; else 0
  assign sum_out = fifo_rd ? sum_this_core : {(bw_psum+4){1'b0}};

  // div pipeline: div_start -> D1 (sum_in valid) -> divisor ready, start div
  always @ (posedge clk) begin
    if (reset) begin
      div_start_D1 <= 1'b0;
      sum_this_core_r <= {(bw_psum+4){1'b0}};
      sum_in_r <= {(bw_psum+4){1'b0}};
      abs_div <= {(col*bw_psum){1'b0}};
    end else begin
      div_start_D1 <= div_start;
      if (div_start) begin
        sum_this_core_r <= sum_this_core;
        sum_in_r <= sum_in;   // sum_in valid same cycle as div_start
        abs_div <= abs;
      end else begin
        sum_this_core_r <= sum_this_core_r;
        sum_in_r <= sum_in_r;
        abs_div <= abs_div;
      end
    end
  end

  assign div_start_internal = div_start_D1;

  // divider: +define+SFP_LONGDIV -> div_longdiv, +define+SFP_MCP -> div_mcp, else div
  `ifdef SFP_LONGDIV
    `define SFP_DIV_MODULE div_longdiv
  `elsif SFP_MCP
    `define SFP_DIV_MODULE div_mcp
  `else
    `define SFP_DIV_MODULE div
  `endif

  generate
    for (c = 0; c < col; c = c + 1) begin : gen_div
      `SFP_DIV_MODULE #(.bw_psum(bw_psum+4), .out_shift(out_shift)) u_div (
        .clk(clk), .reset(reset), .start(div_start_internal),
        .in({4'b0, abs_div[bw_psum*(c+1)-1 : bw_psum*c]}),
        .divisor(sum_2core), .out(div_out[c]), .done(div_done_w[c]), .busy(div_busy_w[c])
      );
    end
  endgenerate

  // div_done latched to align with sfp_div_out: both valid same cycle
  integer i;
  always @ (posedge clk) begin
    if (reset) begin
      div_done_r <= 1'b0;
      for (i = 0; i < col; i = i + 1)
        div_out_r[i] <= {out_shift{1'b0}};
    end else begin
      div_done_r <= div_done_w[0];
      if (div_done_w[0]) begin
        for (i = 0; i < col; i = i + 1)
          div_out_r[i] <= div_out[i];
      end else begin
        for (i = 0; i < col; i = i + 1)
          div_out_r[i] <= div_out_r[i];
      end
    end
  end
  assign div_done = div_done_r;
  assign div_busy = div_busy_w[0];

  generate
    for (c = 0; c < col; c = c + 1) begin : gen_out
      assign sfp_div_out[bw_out*(c+1)-1 : bw_out*c] = {1'b0, div_out_r[c]};
    end
  endgenerate

endmodule
