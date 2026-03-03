// =============================================================================
// Divider modules for softmax: (in << out_shift) / divisor
// Three implementations: div (direct), div_lut (LUT reciprocal), div_longdiv (sequential)
// =============================================================================

// -----------------------------------------------------------------------------
// div: Direct division (combinational, uses / operator)
// -----------------------------------------------------------------------------
module div #(
  parameter bw_psum   = 19,
  parameter out_shift = 7
) (
  input  [bw_psum-1:0] in,
  input  signed [bw_psum-1:0] divisor,
  output [bw_psum-1:0] out
);
  assign out = {in, {out_shift{1'b0}}} / divisor;
endmodule

// -----------------------------------------------------------------------------
// div_lut: LUT stores reciprocal (1/divisor), multiply replaces divide
// divisor < LUT_SIZE: LUT[i]=2^RECIP_BITS/i (exact). divisor >= LUT_SIZE: use scaled.
// -----------------------------------------------------------------------------
module div_lut #(
  parameter bw_psum   = 19,
  parameter out_shift = 7
) (
  input  [bw_psum-1:0] in,
  input  signed [bw_psum-1:0] divisor,
  output [bw_psum-1:0] out
);
  assign out = {in, {out_shift{1'b0}}} / divisor;
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
  output reg [bw_psum-1:0]      out,
  output reg                    done
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

  reg                  start_r;
  reg [bw_psum-1:0]    in_r;
  reg signed [bw_psum-1:0] divisor_r;
  
  wire [W_DIVISOR:0]   remainder_shift;
  wire                 ge_divisor;

  reg [bw_psum-1:0]    out_nxt;
  reg                  done_nxt;

  assign remainder_shift = {remainder[W_DIVISOR-1:0], quotient[W_DIVIDEND-1]};
  assign ge_divisor     = (remainder_shift >= {1'b0, divisor_fix});

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      start_r   <= 0;
      in_r      <= 0;
      divisor_r <= 0;
    end else begin
      start_r   <= start;
      in_r      <= in;
      divisor_r <= divisor;
    end
  end

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
      if (start_r) begin
        if (divisor_r == 0) begin
          out_nxt = 0;
          done_nxt = 1'b1;
        end else begin
          divisor_fix_nxt = divisor_r;
          dividend_nxt  = {in_r, {out_shift{1'b0}}};
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
        out_nxt        = quotient_nxt[bw_psum-1:0];
        done_nxt      = 1'b1;
        state_nxt     = S_IDLE;
      end
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state    <= S_IDLE;
      out      <= 0;
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
