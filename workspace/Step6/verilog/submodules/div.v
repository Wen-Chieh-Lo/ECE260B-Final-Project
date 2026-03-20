// =============================================================================
// Divider modules for softmax: (in << out_shift) / divisor
// Three implementations: div (direct), div_mcp (MCP), div_longdiv (sequential)
// =============================================================================

// -----------------------------------------------------------------------------
// div: Direct division (combinational, uses / operator)
// Interface unified with div_longdiv: clk, reset, start (ignored for combinational)
// -----------------------------------------------------------------------------
module div #(
  parameter bw_psum   = 19,
  parameter out_shift = 7
) (
  input                         clk,
  input                         reset,
  input                         start,
  input      [bw_psum-1:0]      in,
  input      signed [bw_psum-1:0] divisor,
  output     [out_shift-1:0]    out,
  output                        done,
  output                        busy
);
  wire [bw_psum+out_shift-1:0] full_quotient;

  assign full_quotient = {in, {out_shift{1'b0}}} / divisor;
  assign out           = divisor == 0 ? 0 : full_quotient[out_shift-1:0];
  assign done = start;
  assign busy = start;

endmodule

// -----------------------------------------------------------------------------
// div_mcp: MCP-based divider (placeholder, same as div for now)
// Interface unified with div/div_longdiv: clk, reset, start (ignored for combinational)
// -----------------------------------------------------------------------------
module div_mcp #(
  parameter bw_psum   = 19,
  parameter out_shift = 7,
  parameter MCP_CYLCE = 5
) (
  input                         clk,
  input                         reset,
  input                         start,
  input      [bw_psum-1:0]      in,
  input      signed [bw_psum-1:0] divisor,
  output     [out_shift-1:0]    out,
  output                        done,
  output                        busy
);
  parameter IDLE       = 3'd0;
  parameter MCP_WAIT       = 3'd1;

  
  wire [bw_psum+out_shift-1:0] full_quotient;
  reg [2:0] MCP_cnt;
  reg done_q;
  reg state_q;
  reg [out_shift-1:0] div_out_q;

  assign full_quotient = {in, {out_shift{1'b0}}} / divisor;
  assign out           = div_out_q;
  assign done          = done_q;    // combinational: output always valid
  assign busy          = (MCP_cnt != 0) | start;
  
  always @ (posedge clk or posedge reset)begin
    if(reset)begin
      MCP_cnt <= 0;
      div_out_q <= 0;
      done_q <= 0;
      state_q <= IDLE;
    end
    else begin
      if(start)begin
        MCP_cnt <= MCP_cnt + 1;
        div_out_q <= div_out_q;
        done_q <= 0;
        state_q <= MCP_WAIT;
      end
      else if (MCP_cnt == MCP_CYLCE) begin
        MCP_cnt <= 0;
        div_out_q <= full_quotient[out_shift-1:0];
        done_q <= 1;
        state_q <= IDLE;
      end
      else if(state_q == MCP_WAIT)begin
        MCP_cnt <= MCP_cnt + 1;
        div_out_q <= div_out_q;
        done_q <= 0;
        state_q <= state_q;
      end
      else begin
        MCP_cnt <= 0;
        div_out_q <= 0;
        done_q <= 0;
        state_q <= state_q;
      end
    end
  end    // combinational: never busy
endmodule


// -----------------------------------------------------------------------------
// div: Multi-cycle restoring long division (1 quotient bit per cycle)
// -----------------------------------------------------------------------------
module div_longdiv #(
  parameter bw_psum   = 19,
  parameter out_shift = 7
) (
  input                         clk,
  input                         reset,
  input                         start,
  input      [bw_psum-1:0]      in,
  input      signed [bw_psum-1:0] divisor,
  output reg [out_shift-1:0]    out,
  output reg                    done,
  output wire                   busy
);
  localparam integer W_DIVIDEND   = bw_psum + out_shift;
  localparam integer W_DIVISOR    = bw_psum;
  localparam integer W_ITER       = W_DIVIDEND - (W_DIVISOR + 1);
  localparam integer W_CNT        = $clog2(W_ITER + 1);

  localparam S_IDLE = 1'b0;
  localparam S_DIV  = 1'b1;

  reg                  state, state_nxt;
  reg [W_DIVIDEND-1:0] quotient, quotient_nxt;
  reg [W_DIVISOR:0]    remainder, remainder_nxt;
  reg [W_CNT-1:0]      cntr, cntr_nxt;
  reg [W_DIVIDEND-1:0] dividend, dividend_nxt;
  reg [W_DIVISOR-1:0]  divisor_fix, divisor_fix_nxt;

  wire [W_DIVISOR:0]   remainder_shift;
  wire                 ge_divisor;

  reg [out_shift-1:0]  out_nxt;
  reg                  done_nxt;

  assign remainder_shift = {remainder[W_DIVISOR-1:0], quotient[W_DIVIDEND-1]};
  assign ge_divisor     = (remainder_shift >= {1'b0, divisor_fix});
  assign busy           = (state == S_DIV) || start;

  always @(*) begin
    quotient_nxt = quotient;
    remainder_nxt = remainder;
    cntr_nxt = cntr;
    state_nxt = state;
    done_nxt = 1'b0;
    out_nxt = out;
    dividend_nxt = dividend;
    divisor_fix_nxt = divisor_fix;

    if (state == S_IDLE) begin
      if (start) begin
        if (divisor == 0) begin
          out_nxt = 0;
          done_nxt = 1'b1;
        end else begin
          divisor_fix_nxt = divisor;
          dividend_nxt  = {in, {out_shift{1'b0}}};
          quotient_nxt  = {dividend_nxt[W_ITER-1:0], {(W_DIVIDEND-W_ITER){1'b0}}};
          remainder_nxt = dividend_nxt[W_DIVIDEND-1:W_ITER];
          cntr_nxt      = W_ITER;
          state_nxt     = S_DIV;
        end
      end
    end else begin
      quotient_nxt   = {quotient[W_DIVIDEND-2:0], ge_divisor};
      remainder_nxt  = ge_divisor ? (remainder_shift - {1'b0, divisor_fix}) : remainder_shift;
      cntr_nxt       = cntr - 1;
      if (cntr == 1) begin
        out_nxt        = quotient_nxt[out_shift-1:0];
        done_nxt      = 1'b1;
        state_nxt     = S_IDLE;
      end
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state    <= S_IDLE;
      out      <= {out_shift{1'b0}};
      done     <= 0;
      dividend <= 0;
      quotient <= 0;
      remainder<= 0;
      cntr     <= 0;
      divisor_fix <= 0;
    end else begin
      out      <= out_nxt;
      done     <= done_nxt;
      state    <= state_nxt;
      dividend <= dividend_nxt;
      quotient <= quotient_nxt;
      remainder<= remainder_nxt;
      cntr     <= cntr_nxt;
      divisor_fix <= divisor_fix_nxt;
    end
  end
endmodule
