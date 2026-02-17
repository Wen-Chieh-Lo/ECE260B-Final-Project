// Dual-core style TB: (1) after acc, assert fifo_ext_rd and check sum_out; (2) drive random sum_in, golden = divide by (sum_abs + sum_in).

`timescale 1ns/1ps

module sfp_row_dualcore_tb;

  parameter ROWS = 8;
  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+3;  // 20
  parameter out_shift = 7;
  parameter bw_out = out_shift + 1'b1;

  integer mac_file, r, c, captured_data;
  integer mac_data [0:ROWS*col-1];
  integer estimated [0:ROWS*col-1];   // divisor = sum_abs + sum_in
  integer sum_abs_golden [0:ROWS-1];  // sum(|row|) per row for sum_out check
  integer u0, u1, u2, u3, u4, u5, u6, u7;
  integer err_count, row_err, sum_err_count;
  integer sum_abs, divisor, unsigned_val;
  reg [bw_psum-1:0] d0, d1, d2, d3, d4, d5, d6, d7;

  reg reset = 1;
  reg clk = 0;

  reg  [col*bw_psum-1:0] sfp_in_drive;
  wire [col*bw_psum-1:0] sfp_in = sfp_in_drive;

  reg acc = 0, div = 0;
  reg fifo_ext_rd = 0;
  reg [bw_psum+3:0] sum_in_drive;     // TB drives sum_in (other core's sum)
  wire [bw_psum+3:0] sum_in = sum_in_drive;
  wire [bw_psum+3:0] sum_out;

  wire [col*bw_out-1:0] sfp_out;

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
    .sfp_out(sfp_out)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/waveform/sfp_row_dualcore.vcd");
    $dumpvars(0, sfp_row_dualcore_tb);

    // Random sum_in (other core's sum) so divisor = sum_this_core + sum_in
    sum_in_drive = ($urandom % 512) + 1;  // non-zero, 1..512
    $display("##### sum_in (other core) = %0d #####", sum_in_drive);

    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);

    // ----- Load mac_out.txt
    $display("##### Loading mac_out.txt #####");
    mac_file = $fopen("sim/pattern/mac_out.txt", "r");
    if (mac_file == 0) begin
      $display("ERROR: cannot open mac_out.txt");
      $finish;
    end
    for (r = 0; r < ROWS; r = r + 1) begin
      for (c = 0; c < col; c = c + 1) begin
        read_int(mac_file, captured_data);
        // $display("mac_data[%0d][%0d] = %0d", r, c, captured_data);
        mac_data[r*col + c] = captured_data;
      end
    end
    $fclose(mac_file);

    // ----- Golden: divisor = sum_abs + sum_in (RTL uses sum_2core = sum_this_core + sum_in)
    $display("##### Estimated: divisor = sum_abs + sum_in = %0d #####", sum_in_drive);
    for (r = 0; r < ROWS; r = r + 1) begin
      sum_abs = 0;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = mac_data[r*col + c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val-1'b1);
        sum_abs = sum_abs + unsigned_val;
      end
      if (sum_abs == 0) sum_abs = 1;
      sum_abs_golden[r] = sum_abs;
      divisor = sum_abs + sum_in_drive;
      if (divisor == 0) divisor = 1;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = mac_data[r*col + c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val-1'b1);
        estimated[r*col + c] = {unsigned_val, {out_shift{1'b0}}} / divisor;
      end
    end

    // ----- (1) After acc: fifo_ext_rd -> check sum_out == sum_abs_golden
    // ----- (2) div uses sum_2core = sum_this_core + sum_in -> sfp_out vs estimated
    $display("");
    $display("##### sum_out check (fifo_ext_rd after acc) #####");
    err_count = 0;
    sum_err_count = 0;
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
      $display("sfp_in_drive = %0d", sfp_in_drive);
      acc = 0;
      div = 0;
      fifo_ext_rd = 0;
      @(posedge clk);
      acc = 1;
      @(posedge clk);
      @(posedge clk);
      acc = 0;
      @(posedge clk);   // one cycle after acc so FIFO write has settled
      fifo_ext_rd = 1;
      @(posedge clk);
      #0.5;             // sample sum_out this cycle (FIFO out = current rd_ptr; rd_ptr advances at next posedge)
      if (sum_out !== sum_abs_golden[r]) begin
        $display("  [test1 sum_out] row %0d FAIL: fifo_ext_rd -> sum_out = %0d, expected sum_abs = %0d", r, sum_out, sum_abs_golden[r]);
        sum_err_count = sum_err_count + 1;
      end else
        $display("  [test1 sum_out] row %0d PASS: fifo_ext_rd -> sum_out = %0d (expected sum_abs)", r, sum_out);
      @(posedge clk);
      fifo_ext_rd = 0;
      @(posedge clk);
      div = 1;
      @(posedge clk);
      @(posedge clk);
      div = 0;
      @(posedge clk);
      @(posedge clk);  // sfp_out valid one cycle after div
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
      if (u0 != estimated[r*col+0]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col0 MISMATCH (RTL %d != golden %d)", u0, estimated[r*col+0]); end
      if (u1 != estimated[r*col+1]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col1 MISMATCH (RTL %d != golden %d)", u1, estimated[r*col+1]); end
      if (u2 != estimated[r*col+2]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col2 MISMATCH (RTL %d != golden %d)", u2, estimated[r*col+2]); end
      if (u3 != estimated[r*col+3]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col3 MISMATCH (RTL %d != golden %d)", u3, estimated[r*col+3]); end
      if (u4 != estimated[r*col+4]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col4 MISMATCH (RTL %d != golden %d)", u4, estimated[r*col+4]); end
      if (u5 != estimated[r*col+5]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col5 MISMATCH (RTL %d != golden %d)", u5, estimated[r*col+5]); end
      if (u6 != estimated[r*col+6]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col6 MISMATCH (RTL %d != golden %d)", u6, estimated[r*col+6]); end
      if (u7 != estimated[r*col+7]) begin row_err = row_err + 1; err_count = err_count + 1; $display("       >>> col7 MISMATCH (RTL %d != golden %d)", u7, estimated[r*col+7]); end
      $display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      @(posedge clk);
    end

    $display("");
    $display("##### error summary #####");
    $display("------------------------------------------------------------");
    
    if (err_count == 0 && sum_err_count == 0) begin
      $display("  PASS  sfp_out + sum_out  all match (divisor = sum_abs + sum_in)");
      $display("------------------------------------------------------------");
    end else begin
      $display("  FAIL  sfp_out %0d mismatches, sum_out %0d mismatches", err_count, sum_err_count);
      $display("------------------------------------------------------------");
    end
    $display("");
    #100 $finish;
  end

endmodule
