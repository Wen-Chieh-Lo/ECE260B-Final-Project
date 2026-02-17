// Testbench: load mac_out.txt into pmem, feed sfp_row row-by-row.
// Estimated = normalize each row: sum_abs = sum(|row|), divisor = sum_abs>>7, out[c] = signed(row[c])/divisor.
// Scoreboard same as mac_array_tb: RTL vs estimated, [OK]/[MISMATCH], PASS block.

`timescale 1ns/1ps

module sfp_row_tb;

  parameter ROWS = 8;
  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;  // 20

  integer mac_file, r, c, captured_data;
  integer mac_data [0:ROWS*col-1];   // row-major: row*col + c
  integer estimated [0:ROWS*col-1];   // computed from mac_data (same formula as sfp_row)
  integer u0, u1, u2, u3, u4, u5, u6, u7;
  integer err_count, row_err;
  integer sum_abs, divisor, signed_val;
  reg [bw_psum-1:0] d0, d1, d2, d3, d4, d5, d6, d7;

  reg reset = 1;
  reg clk = 0;

  // pmem: 16 x 160-bit (one row = 8 x 20-bit per address)
  reg  pmem_rd = 0, pmem_wr = 0;
  reg  [3:0] pmem_add = 0;
  wire [col*bw_psum-1:0] pmem_out;
  reg  [col*bw_psum-1:0] pmem_in = 0;

  // sfp_row control (ignore sum_in / sum_out)
  reg acc = 0, div = 0;
  reg fifo_ext_rd = 0;
  wire [bw_psum+3:0] sum_in  = 0;
  wire [bw_psum+3:0] sum_out;

  // sfp_row: sfp_in from pmem, sfp_out to compare
  wire [col*bw_psum-1:0] sfp_in;
  wire [col*bw_psum-1:0] sfp_out;

  assign sfp_in = pmem_out;

  task read_int;
    input integer fd;
    output integer val;
    integer ret;
    begin
      ret = $fscanf(fd, "%d", val);
      if (ret != 1) val = 0;
    end
  endtask

  sram_w16 #(.sram_bit(col*bw_psum)) pmem (
    .CLK(clk),
    .D(pmem_in),
    .Q(pmem_out),
    .CEN(!(pmem_rd || pmem_wr)),
    .WEN(!pmem_wr),
    .A(pmem_add)
  );

  sfp_row #(.col(col), .bw(bw)) u_sfp (
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
    $dumpfile("sim/waveform/sfp_row.vcd");
    $dumpvars(0, sfp_row_tb);

    // Clock a few cycles, then release reset
    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);

    // ----- Load mac_out.txt (8 rows x 8 cols, tab/space separated)
    $display("##### Loading mac_out.txt into pmem #####");
    mac_file = $fopen("sim/pattern/mac_out.txt", "r");
    if (mac_file == 0) begin
      $display("ERROR: cannot open mac_out.txt");
      $finish;
    end
    for (r = 0; r < ROWS; r = r + 1) begin
      for (c = 0; c < col; c = c + 1) begin
        read_int(mac_file, captured_data);
        mac_data[r*col + c] = captured_data;
      end
    end
    $fclose(mac_file);

    // Write each row to pmem (one 160-bit word per row; each element 20-bit 2's complement)
    for (r = 0; r < ROWS; r = r + 1) begin
      pmem_add = r[3:0];
      d0 = (mac_data[r*col+0] & ((1<<bw_psum)-1));
      d1 = (mac_data[r*col+1] & ((1<<bw_psum)-1));
      d2 = (mac_data[r*col+2] & ((1<<bw_psum)-1));
      d3 = (mac_data[r*col+3] & ((1<<bw_psum)-1));
      d4 = (mac_data[r*col+4] & ((1<<bw_psum)-1));
      d5 = (mac_data[r*col+5] & ((1<<bw_psum)-1));
      d6 = (mac_data[r*col+6] & ((1<<bw_psum)-1));
      d7 = (mac_data[r*col+7] & ((1<<bw_psum)-1));
      pmem_in  = { d7, d6, d5, d4, d3, d2, d1, d0 };
      pmem_wr = 1;
      pmem_rd = 0;
      @(posedge clk);
      pmem_wr = 0;
      @(posedge clk);
    end

    // ----- Estimated: same as sfp_row (sum_abs = sum of |row|, divisor = sum_abs>>7, out[c] = signed(row[c])/divisor)
    $display("##### Estimated normalization (sum_abs>>7, then signed divide) #####");
    for (r = 0; r < ROWS; r = r + 1) begin
      sum_abs = 0;
      for (c = 0; c < col; c = c + 1) begin
        signed_val = mac_data[r*col + c] & ((1<<bw_psum)-1);
        if (signed_val >= (1<<(bw_psum-1)))
          signed_val = signed_val - (1<<bw_psum);
        if (signed_val < 0)
          sum_abs = sum_abs + (-signed_val);
        else
          sum_abs = sum_abs + signed_val;
      end
      divisor = sum_abs >> 7;
      if (divisor == 0) divisor = 1;
      for (c = 0; c < col; c = c + 1) begin
        signed_val = mac_data[r*col + c] & ((1<<bw_psum)-1);
        if (signed_val >= (1<<(bw_psum-1)))
          signed_val = signed_val - (1<<bw_psum);
        estimated[r*col + c] = signed_val / divisor;
      end
    end

    // ----- Process each row: read from pmem -> acc -> div (2 cycles) -> compare with estimated
    $display("");
    $display("##### sfp_row out vs estimated #####");
    $display("  [row]  RTL   :   col0   col1   col2   col3   col4   col5   col6   col7");
    $display("         golden:   ----   ----   ----   ----   ----   ----   ----   ----");
    err_count = 0;
    for (r = 0; r < ROWS; r = r + 1) begin
      pmem_rd = 1;
      pmem_wr = 0;
      pmem_add = r[3:0];
      acc = 0;
      div = 0;
      @(posedge clk);
      acc = 1;
      @(posedge clk);
      acc = 0;
      @(posedge clk);
      div = 1;
      @(posedge clk);
      @(posedge clk);
      div = 0;
      @(posedge clk);
      @(posedge clk);  // sfp_out valid one cycle after div
      u0 = $signed(sfp_out[bw_psum*1-1 -: bw_psum]);
      u1 = $signed(sfp_out[bw_psum*2-1 -: bw_psum]);
      u2 = $signed(sfp_out[bw_psum*3-1 -: bw_psum]);
      u3 = $signed(sfp_out[bw_psum*4-1 -: bw_psum]);
      u4 = $signed(sfp_out[bw_psum*5-1 -: bw_psum]);
      u5 = $signed(sfp_out[bw_psum*6-1 -: bw_psum]);
      u6 = $signed(sfp_out[bw_psum*7-1 -: bw_psum]);
      u7 = $signed(sfp_out[bw_psum*8-1 -: bw_psum]);
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
      $display("");
      @(posedge clk);
    end

    pmem_rd = 0;
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
