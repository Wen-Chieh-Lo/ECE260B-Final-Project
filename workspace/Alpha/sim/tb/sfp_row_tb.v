// Alpha sfp_row testbench - ST1~ST4 per sfp_row.design
// Data: random by TB, print before execute. Golden: truncate((|sfp_in[c]|<<out_shift)/(Si+sum_in))
// sum_in: valid next cycle after div_start, random 0..2^(bw_psum+3)-1

`timescale 1ns/1ps

module sfp_row_tb;

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter out_shift = 7;
  parameter bw_out = out_shift + 1'b1;
  parameter acc_latency = 3;
  parameter div_latency = 6;

  integer r, cc, err_count, test_pass, divisor, seed;
  integer golden [0:col-1];
  integer u0, u1, u2, u3, u4, u5, u6, u7;

  reg reset = 1;
  reg clk = 0;
  reg acc_start = 0;
  reg div_start = 0;

  reg  [col*bw_psum-1:0] sfp_in_drive;
  wire [col*bw_psum-1:0] sfp_in = sfp_in_drive;

  reg [bw_psum+3:0] sum_in_drive;
  wire [bw_psum+3:0] sum_in = sum_in_drive;

  wire acc_done, div_done, div_busy;
  wire [bw_psum+3:0] sum_out;
  wire [col*bw_out-1:0] sfp_div_out;

  sfp_row #(
    .col(col),
    .bw(bw),
    .bw_psum(bw_psum),
    .out_shift(out_shift)
  ) u_sfp (
    .clk(clk),
    .reset(reset),
    .acc_start(acc_start),
    .div_start(div_start),
    .acc_done(acc_done),
    .div_done(div_done),
    .div_busy(div_busy),
    .sum_in(sum_in),
    .sum_out(sum_out),
    .sfp_in(sfp_in),
    .sfp_div_out(sfp_div_out)
  );

  always #5 clk = ~clk;

  task compute_golden;
    input [col*bw_psum-1:0] row;
    input [bw_psum+3:0] sum_in_val;
    output integer si;
    integer abs_c, numer;
    begin
      si = 0;
      for (cc = 0; cc < col; cc = cc + 1) begin
        abs_c = $signed(row[bw_psum*(cc+1)-1 -: bw_psum]);
        if (abs_c < 0) abs_c = -abs_c;
        si = si + abs_c;
      end
      divisor = si + sum_in_val;
      for (cc = 0; cc < col; cc = cc + 1) begin
        abs_c = $signed(row[bw_psum*(cc+1)-1 -: bw_psum]);
        if (abs_c < 0) abs_c = -abs_c;
        numer = abs_c << out_shift;
        golden[cc] = (divisor == 0) ? 0 : (numer / divisor);
      end
    end
  endtask

  task random_row;
    output [col*bw_psum-1:0] row;
    integer v, s, cc;
    begin
      row = 0;
      for (cc = 0; cc < col; cc = cc + 1) begin
        v = $random(seed) & ((1 << bw_psum) - 1);
        s = $random(seed);
        if (s[0]) v = -v;
        row = row | (($unsigned(v) & ((1 << bw_psum) - 1)) << (cc * bw_psum));
      end
    end
  endtask

  task get_random_sum_in;
    output [bw_psum+3:0] outval;
    integer v;
    begin
      v = $random(seed);
      if (v < 0) v = -v;
      outval = v % (1 << (bw_psum + 3));
    end
  endtask

  task do_acc_div;
    input [col*bw_psum-1:0] row_data;
    input [bw_psum+3:0] sum_in_val;
    begin
      sfp_in_drive = row_data;
      sum_in_drive = 0;
      acc_start = 1; div_start = 0;
      @(posedge clk);
      acc_start = 0;
      repeat(acc_latency) @(posedge clk);
      while (div_busy) @(posedge clk);
      sfp_in_drive = row_data;
      div_start = 1;
      sum_in_drive = sum_in_val;   // sum_in valid same cycle as div_start
      @(posedge clk);
      div_start = 0;
      sum_in_drive = 0;
      while (!div_done) @(posedge clk);
    end
  endtask

  task check_output;
    integer row_err;
    begin
      u0 = $signed(sfp_div_out[bw_out*1-1 -: bw_out]);
      u1 = $signed(sfp_div_out[bw_out*2-1 -: bw_out]);
      u2 = $signed(sfp_div_out[bw_out*3-1 -: bw_out]);
      u3 = $signed(sfp_div_out[bw_out*4-1 -: bw_out]);
      u4 = $signed(sfp_div_out[bw_out*5-1 -: bw_out]);
      u5 = $signed(sfp_div_out[bw_out*6-1 -: bw_out]);
      u6 = $signed(sfp_div_out[bw_out*7-1 -: bw_out]);
      u7 = $signed(sfp_div_out[bw_out*8-1 -: bw_out]);
      $display("   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", u0, u1, u2, u3, u4, u5, u6, u7);
      $display("   golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        golden[0], golden[1], golden[2], golden[3], golden[4], golden[5], golden[6], golden[7]);
      row_err = 0;
      if (u0 != golden[0]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col0 MISMATCH (RTL %d != golden %d)", u0, golden[0]); end
      if (u1 != golden[1]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col1 MISMATCH (RTL %d != golden %d)", u1, golden[1]); end
      if (u2 != golden[2]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col2 MISMATCH (RTL %d != golden %d)", u2, golden[2]); end
      if (u3 != golden[3]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col3 MISMATCH (RTL %d != golden %d)", u3, golden[3]); end
      if (u4 != golden[4]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col4 MISMATCH (RTL %d != golden %d)", u4, golden[4]); end
      if (u5 != golden[5]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col5 MISMATCH (RTL %d != golden %d)", u5, golden[5]); end
      if (u6 != golden[6]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col6 MISMATCH (RTL %d != golden %d)", u6, golden[6]); end
      if (u7 != golden[7]) begin row_err = row_err + 1; err_count = err_count + 1; $display("   >>> col7 MISMATCH (RTL %d != golden %d)", u7, golden[7]); end
      $display("   %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      if (row_err == 0) test_pass = test_pass + 1;
    end
  endtask

  initial begin
    $dumpfile("sim/waveform/sfp_row.vcd");
    $dumpvars(0, sfp_row_tb);

    seed = 12345;
    err_count = 0;
    test_pass = 0;

    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);

    // ----- ST1: Normal (1 acc + 1 div)
    $display("##### ST1: Normal (1 acc + 1 div) #####");
    begin
      reg [col*bw_psum-1:0] row;
      reg [bw_psum+3:0] s_in;
      integer si;
      random_row(row);
      get_random_sum_in(s_in);
      compute_golden(row, s_in, si);
      $display("  [print before execute] sum_abs=%0d sum_in=%0d divisor=%0d", si, s_in, si+s_in);
      $display("  golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        golden[0], golden[1], golden[2], golden[3], golden[4], golden[5], golden[6], golden[7]);
      do_acc_div(row, s_in);
      check_output;
    end

    $display("");
    // ----- ST2: Batch (8 acc + 8 div)
    $display("##### ST2: Batch (8 acc + 8 div) #####");
    begin
      reg [col*bw_psum-1:0] rows [0:7];
      reg [bw_psum+3:0] sum_ins [0:7];
      integer si;
      for (r = 0; r < 8; r = r + 1) begin
        random_row(rows[r]);
        get_random_sum_in(sum_ins[r]);
      end
      $display("  [print before execute] 8 rows acc");
      for (r = 0; r < 8; r = r + 1) begin
        sfp_in_drive = rows[r];
        acc_start = 1; div_start = 0;
        @(posedge clk);
        acc_start = 0;
      end
      repeat(acc_latency) @(posedge clk);
      for (r = 0; r < 8; r = r + 1) begin
        compute_golden(rows[r], sum_ins[r], si);
        $display("  [row %0d] golden: %7d %7d %7d %7d %7d %7d %7d %7d",
          r, golden[0], golden[1], golden[2], golden[3], golden[4], golden[5], golden[6], golden[7]);
        while (div_busy) @(posedge clk);
        sfp_in_drive = rows[r];
        sum_in_drive = 0;
        div_start = 1;
        @(posedge clk);
        div_start = 0;
        sum_in_drive = sum_ins[r];
        @(posedge clk);
        sum_in_drive = 0;
        while (!div_done) @(posedge clk);
        check_output;
      end
    end

    $display("");
    // ----- ST3: Interleaved (acc row0->div row0->acc row1->div row1...)
    $display("##### ST3: Interleaved (acc row0->div row0->acc row1->div row1...) #####");
    begin
      reg [col*bw_psum-1:0] rows [0:3];
      reg [bw_psum+3:0] sum_ins [0:3];
      integer si;
      for (r = 0; r < 4; r = r + 1) begin
        random_row(rows[r]);
        get_random_sum_in(sum_ins[r]);
      end
      for (r = 0; r < 4; r = r + 1) begin
        compute_golden(rows[r], sum_ins[r], si);
        $display("  [row %0d] golden: %7d %7d %7d %7d %7d %7d %7d %7d",
          r, golden[0], golden[1], golden[2], golden[3], golden[4], golden[5], golden[6], golden[7]);
        sfp_in_drive = rows[r];
        sum_in_drive = 0;
        acc_start = 1; div_start = 0;
        @(posedge clk);
        acc_start = 0;
        repeat(acc_latency) @(posedge clk);
        while (div_busy) @(posedge clk);
        sfp_in_drive = rows[r];
        div_start = 1;
        @(posedge clk);
        div_start = 0;
        sum_in_drive = sum_ins[r];
        @(posedge clk);
        sum_in_drive = 0;
        while (!div_done) @(posedge clk);
        check_output;
      end
    end

    $display("");
    // ----- ST4: 0 row (sfp_in all zeros)
    $display("##### ST4: 0 row (sfp_in all zeros) #####");
    begin
      reg [col*bw_psum-1:0] zero_row;
      reg [bw_psum+3:0] s_in;
      integer si;
      zero_row = 0;
      get_random_sum_in(s_in);
      compute_golden(zero_row, s_in, si);
      $display("  golden (all 0): %7d %7d %7d %7d %7d %7d %7d %7d",
        golden[0], golden[1], golden[2], golden[3], golden[4], golden[5], golden[6], golden[7]);
      do_acc_div(zero_row, s_in);
      check_output;
    end

    $display("");
    $display("##### error summary #####");
    $display("------------------------------------------------------------");
    if (err_count == 0) begin
      $display("  PASS  sfp_div_out all match (ST1-ST4)");
      $display("------------------------------------------------------------");
    end else begin
      $display("  FAIL  sfp_div_out %0d mismatches", err_count);
      $display("------------------------------------------------------------");
    end
    $display("");
    #100 $finish;
  end

  initial begin
    #500000;
    $display("ERROR: Simulation timeout");
    $finish(1);
  end

endmodule
