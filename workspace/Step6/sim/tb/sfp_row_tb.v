// Testbench for sfp_row (Step6)
// Loads mac_out.txt, feeds sfp_row row-by-row (no SRAM; TB drives sfp_in directly).
// Golden: normalize each row: sum_abs = sum(|row|), divisor = sum_abs,
//         out[c] = (signed(row[c])<<out_shift) / divisor.
//         When sum_abs < SFP_THRESHOLD: output all zeros (sparsity gating).

`timescale 1ns/1ps

module sfp_row_tb;

  parameter ROWS = 8;
  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;   // 20 (matches sfp_row.v)
  parameter out_shift = 7;
  parameter bw_out = out_shift + 1'b1;
  parameter sfp_acc_lat = 1;
  `ifdef SFP_LONGDIV
    parameter sfp_div_lat = 8;  // div_longdiv: 1 input reg + 6 iter + 1
  `else
    parameter sfp_div_lat = 0;
  `endif

  // Sparsity threshold: rows with sum_abs < SFP_THRESHOLD output zeros.
  `ifndef SFP_THRESHOLD
    `define SFP_THRESHOLD 0
  `endif
  localparam integer SFP_THRESHOLD_TB = `SFP_THRESHOLD;

  integer mac_file, r, c, captured_data;
  integer mac_data [0:ROWS*col-1];
  integer estimated [0:ROWS*col-1];
  integer u0, u1, u2, u3, u4, u5, u6, u7;
  integer err_count, row_err;
  integer sum_abs, unsigned_val;
  reg [bw_psum-1:0] d0, d1, d2, d3, d4, d5, d6, d7;

  reg reset = 1;
  reg clk = 0;

  reg  [col*bw_psum-1:0] sfp_in_drive;
  wire [col*bw_psum-1:0] sfp_in = sfp_in_drive;

  reg acc = 0, div = 0;
  reg fifo_ext_rd = 0;
  wire [bw_psum+3:0] sum_in  = 0;
  wire [bw_psum+3:0] sum_out;

  wire [col*bw_out-1:0] sfp_out;
  wire sfp_out_valid;

  task read_int;
    input integer fd;
    output integer val;
    integer ret;
    begin
      ret = $fscanf(fd, "%d", val);
      if (ret != 1) val = 0;
    end
  endtask

  sfp_row #(
    .col(col),
    .bw(bw),
    .bw_psum(bw_psum),
    .out_shift(out_shift)
  ) u_sfp (
    .clk(clk),
    .reset(reset),
    .acc(acc),
    .div(div),
    .fifo_ext_rd(fifo_ext_rd),
    .sum_in(sum_in),
    .sum_out(sum_out),
    .sfp_in(sfp_in),
    .sfp_out(sfp_out),
    .sfp_out_valid(sfp_out_valid)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/waveform/sfp_row.vcd");
    $dumpvars(0, sfp_row_tb);

    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);

    $display("##### Loading mac_out.txt #####");
    mac_file = $fopen("sim/pattern/mac_out.txt", "r");
    if (mac_file == 0) begin
      $display("ERROR: cannot open sim/pattern/mac_out.txt");
      $finish;
    end
    for (r = 0; r < ROWS; r = r + 1) begin
      for (c = 0; c < col; c = c + 1) begin
        read_int(mac_file, captured_data);
        mac_data[r*col + c] = captured_data;
      end
    end
    $fclose(mac_file);

    // Golden: same as sfp_row (sum_abs = sum of |row|, out[c] = (|row[c]|<<out_shift)/sum_abs)
    // When sum_abs < SFP_THRESHOLD: output all zeros (sparsity gating)
    $display("##### Estimated normalization #####");
    for (r = 0; r < ROWS; r = r + 1) begin
      sum_abs = 0;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = mac_data[r*col + c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val-1'b1);
        sum_abs = sum_abs + unsigned_val;
      end
      if (sum_abs == 0) sum_abs = 1;

      if (sum_abs < SFP_THRESHOLD_TB) begin
        $display("[TB][Norm] row %0d: sum_abs=%0d < threshold=%0d -> estimated row forced to 0", r, sum_abs, SFP_THRESHOLD_TB);
        for (c = 0; c < col; c = c + 1)
          estimated[r*col + c] = 0;
      end else begin
        for (c = 0; c < col; c = c + 1) begin
          unsigned_val = mac_data[r*col + c];
          if (unsigned_val[bw_psum-1] == 1'b1)
            unsigned_val = ~(unsigned_val-1'b1);
          estimated[r*col + c] = {unsigned_val, {out_shift{1'b0}}} / sum_abs;
        end
      end
    end

    $display("");
    $display("##### sfp_row out vs estimated #####");
    $display("  [row]  RTL   :   col0   col1   col2   col3   col4   col5   col6   col7");
    $display("         golden:   ----   ----   ----   ----   ----   ----   ----   ----");
    err_count = 0;
    for (r = 0; r < ROWS; r = r + 1) begin
      d0 = mac_data[r*col+0];
      d1 = mac_data[r*col+1];
      d2 = mac_data[r*col+2];
      d3 = mac_data[r*col+3];
      d4 = mac_data[r*col+4];
      d5 = mac_data[r*col+5];
      d6 = mac_data[r*col+6];
      d7 = mac_data[r*col+7];
      sfp_in_drive = { d7, d6, d5, d4, d3, d2, d1, d0 };
      acc = 0;
      div = 0;
      repeat(2) @(posedge clk);  // sum8_2stage latency = 2 cycles for row energy
      acc = 1;
      @(posedge clk);
      acc = 0;
      @(posedge clk);
      repeat(sfp_acc_lat) @(posedge clk);
      div = 1;
      @(posedge clk);
      @(posedge clk);
      div = 0;
      @(posedge clk);
      repeat(sfp_div_lat) @(posedge clk);
      // Wait for sfp_out_valid before sampling
      while (!sfp_out_valid) @(posedge clk);
      u0 = $signed(sfp_out[bw_out*1-1 -: bw_out]);
      u1 = $signed(sfp_out[bw_out*2-1 -: bw_out]);
      u2 = $signed(sfp_out[bw_out*3-1 -: bw_out]);
      u3 = $signed(sfp_out[bw_out*4-1 -: bw_out]);
      u4 = $signed(sfp_out[bw_out*5-1 -: bw_out]);
      u5 = $signed(sfp_out[bw_out*6-1 -: bw_out]);
      u6 = $signed(sfp_out[bw_out*7-1 -: bw_out]);
      u7 = $signed(sfp_out[bw_out*8-1 -: bw_out]);
      $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", r, u0, u1, u2, u3, u4, u5, u6, u7);
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        estimated[r*col+0], estimated[r*col+1], estimated[r*col+2], estimated[r*col+3],
        estimated[r*col+4], estimated[r*col+5], estimated[r*col+6], estimated[r*col+7]);
      row_err = 0;
      if (u0 !== estimated[r*col+0]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col0 MISMATCH (RTL %d != golden %d)", u0, estimated[r*col+0]); end
      if (u1 !== estimated[r*col+1]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col1 MISMATCH (RTL %d != golden %d)", u1, estimated[r*col+1]); end
      if (u2 !== estimated[r*col+2]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col2 MISMATCH (RTL %d != golden %d)", u2, estimated[r*col+2]); end
      if (u3 !== estimated[r*col+3]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col3 MISMATCH (RTL %d != golden %d)", u3, estimated[r*col+3]); end
      if (u4 !== estimated[r*col+4]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col4 MISMATCH (RTL %d != golden %d)", u4, estimated[r*col+4]); end
      if (u5 !== estimated[r*col+5]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col5 MISMATCH (RTL %d != golden %d)", u5, estimated[r*col+5]); end
      if (u6 !== estimated[r*col+6]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col6 MISMATCH (RTL %d != golden %d)", u6, estimated[r*col+6]); end
      if (u7 !== estimated[r*col+7]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col7 MISMATCH (RTL %d != golden %d)", u7, estimated[r*col+7]); end
      $display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
      @(posedge clk);
    end

    $display("------------------------------------------------------------");
    if (err_count == 0) begin
      $display("  PASS  %0d rows x %0d cols  all match estimated result", ROWS, col);
      $display("------------------------------------------------------------");
    end else begin
      $display("  FAIL  %0d mismatches", err_count);
      $display("------------------------------------------------------------");
    end
    $display("");
    #100 $finish;
  end

endmodule
