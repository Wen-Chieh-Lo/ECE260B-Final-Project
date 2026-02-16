// Dual-core SFP testbench: verifies sum_in/sum_out for L1 norm across two cores.
//
// Protocol:
//   - Each core owns half of each row: core0 cols 0-3, core1 cols 4-7 (other half zero-padded).
//   - acc=1: each core writes sum of |sfp_in| into internal FIFO and exposes it on sum_out when read.
//   - fifo_ext_rd=1: read partial sum from sum_out (one cycle later capture).
//   - Cross-couple: sum_in0 = sum_out1, sum_in1 = sum_out0 so sum_2core = local + other = full row L1 sum.
//   - div=1 (two cycles): both divide by the same total; combine sfp_out col0-3 from each core for full row.

`timescale 1ns/1ps

module sfp_row_dualcore_tb;

  parameter ROWS = 8;
  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;  // 20
  parameter HALF = 4;

  integer mac_file, norm_file, r, c, scan_val, captured_data;
  integer mac_data [0:ROWS*col-1];
  integer golden  [0:ROWS*col-1];
  integer u0, u1, u2, u3, u4, u5, u6, u7;
  integer err_count;
  reg [bw_psum-1:0] d0, d1, d2, d3, d4, d5, d6, d7;

  reg reset = 1;
  reg clk = 0;

  // Per-row inputs: core0 = cols 0..3 (zero-pad 4..7), core1 = cols 4..7 (zero-pad 0..3)
  reg [col*bw_psum-1:0] sfp_in0 = 0;
  reg [col*bw_psum-1:0] sfp_in1 = 0;

  // Control
  reg acc = 0, div = 0;
  reg fifo_ext_rd0 = 0, fifo_ext_rd1 = 0;

  // sum_out from each core -> capture then feed to the other as sum_in
  wire [bw_psum+3:0] sum_out0, sum_out1;
  reg  [bw_psum+3:0] sum_in0 = 0, sum_in1 = 0;
  reg  [bw_psum+3:0] sum0_captured = 0, sum1_captured = 0;

  wire [col*bw_psum-1:0] sfp_out0, sfp_out1;

  task read_int;
    input integer fd;
    output integer val;
    integer ret;
    begin
      ret = $fscanf(fd, "%d", val);
      if (ret != 1) val = 0;
    end
  endtask

  sfp_row #(.col(col), .bw(bw)) u_sfp0 (
    .clk(clk),
    .reset(reset),
    .acc(acc),
    .div(div),
    .fifo_ext_rd(fifo_ext_rd0),
    .sum_in(sum_in0),
    .sum_out(sum_out0),
    .sfp_in(sfp_in0),
    .sfp_out(sfp_out0)
  );

  sfp_row #(.col(col), .bw(bw)) u_sfp1 (
    .clk(clk),
    .reset(reset),
    .acc(acc),
    .div(div),
    .fifo_ext_rd(fifo_ext_rd1),
    .sum_in(sum_in1),
    .sum_out(sum_out1),
    .sfp_in(sfp_in1),
    .sfp_out(sfp_out1)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("waveform/sfp_row_dualcore_tb.vcd");
    $dumpvars(0, sfp_row_dualcore_tb);

    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);

    // ----- Load mac_out.txt
    $display("##### Loading mac_out.txt #####");
    mac_file = $fopen("pattern/mac_out.txt", "r");
    if (mac_file == 0) begin
      $display("ERROR: cannot open mac_out.txt");
      $finish;
    end
    for (r = 0; r < ROWS; r = r + 1)
      for (c = 0; c < col; c = c + 1) begin
        read_int(mac_file, captured_data);
        mac_data[r*col + c] = captured_data;
      end
    $fclose(mac_file);

    // ----- Load golden norm_out_q20.txt
    $display("##### Loading norm_out_q20.txt #####");
    norm_file = $fopen("pattern/norm_out_q20.txt", "r");
    if (norm_file == 0) begin
      $display("ERROR: cannot open norm_out_q20.txt");
      $finish;
    end
    for (r = 0; r < ROWS; r = r + 1)
      for (c = 0; c < col; c = c + 1) begin
        read_int(norm_file, captured_data);
        golden[r*col + c] = captured_data;
      end
    $fclose(norm_file);

    // ----- Process each row: split -> acc -> exchange sum (fifo_ext_rd) -> sum_in cross -> div -> compare
    err_count = 0;
    for (r = 0; r < ROWS; r = r + 1) begin
      // Form sfp_in: core0 = row[0..3] in col0..3, zeros in col4..7; core1 = row[4..7] in col0..3, zeros in col4..7
      d0 = (mac_data[r*col+0] & ((1<<bw_psum)-1));
      d1 = (mac_data[r*col+1] & ((1<<bw_psum)-1));
      d2 = (mac_data[r*col+2] & ((1<<bw_psum)-1));
      d3 = (mac_data[r*col+3] & ((1<<bw_psum)-1));
      d4 = (mac_data[r*col+4] & ((1<<bw_psum)-1));
      d5 = (mac_data[r*col+5] & ((1<<bw_psum)-1));
      d6 = (mac_data[r*col+6] & ((1<<bw_psum)-1));
      d7 = (mac_data[r*col+7] & ((1<<bw_psum)-1));
      sfp_in0 = { 20'b0, 20'b0, 20'b0, 20'b0, d3, d2, d1, d0 };  // core0: col0-3 = row[0..3], col4-7 = 0
      sfp_in1 = { 20'b0, 20'b0, 20'b0, 20'b0, d7, d6, d5, d4 };  // core1: col0-3 = row[4..7], col4-7 = 0

      acc = 1;
      div = 0;
      fifo_ext_rd0 = 0;
      fifo_ext_rd1 = 0;
      sum_in0 = 0;
      sum_in1 = 0;
      @(posedge clk);

      acc = 0;
      @(posedge clk);

      // Read partial sums: capture sum_out in same cycle as fifo_ext_rd (before rd_ptr advances at posedge)
      fifo_ext_rd0 = 1;
      fifo_ext_rd1 = 1;
      sum0_captured = sum_out0;
      sum1_captured = sum_out1;
      @(posedge clk);
      fifo_ext_rd0 = 0;
      fifo_ext_rd1 = 0;
      @(posedge clk);

      // Exchange: each core divides by (own_partial + other_partial)
      sum_in0 = sum1_captured;
      sum_in1 = sum0_captured;

      // Two div cycles (same as single-core: first cycle div_q updates, second cycle sum_2core used for division)
      div = 1;
      @(posedge clk);
      @(posedge clk);
      div = 0;
      @(posedge clk);

      // Combine: core0 sfp_out col0..3 -> row[0..3], core1 sfp_out col0..3 -> row[4..7]
      u0 = sfp_out0[bw_psum*1-1 -: bw_psum] & ((1<<bw_psum)-1);
      u1 = sfp_out0[bw_psum*2-1 -: bw_psum] & ((1<<bw_psum)-1);
      u2 = sfp_out0[bw_psum*3-1 -: bw_psum] & ((1<<bw_psum)-1);
      u3 = sfp_out0[bw_psum*4-1 -: bw_psum] & ((1<<bw_psum)-1);
      u4 = sfp_out1[bw_psum*1-1 -: bw_psum] & ((1<<bw_psum)-1);
      u5 = sfp_out1[bw_psum*2-1 -: bw_psum] & ((1<<bw_psum)-1);
      u6 = sfp_out1[bw_psum*3-1 -: bw_psum] & ((1<<bw_psum)-1);
      u7 = sfp_out1[bw_psum*4-1 -: bw_psum] & ((1<<bw_psum)-1);

      if (u0 != golden[r*col+0] || u1 != golden[r*col+1] || u2 != golden[r*col+2] || u3 != golden[r*col+3] ||
          u4 != golden[r*col+4] || u5 != golden[r*col+5] || u6 != golden[r*col+6] || u7 != golden[r*col+7]) begin
        err_count = err_count + 1;
        $display("MISMATCH row %0d: got %0d %0d %0d %0d %0d %0d %0d %0d", r, u0,u1,u2,u3,u4,u5,u6,u7);
        $display("        golden %0d %0d %0d %0d %0d %0d %0d %0d",
          golden[r*col+0], golden[r*col+1], golden[r*col+2], golden[r*col+3],
          golden[r*col+4], golden[r*col+5], golden[r*col+6], golden[r*col+7]);
      end else
        $display("Row %0d OK (dual-core sum exchange)", r);

      @(posedge clk);
    end

    $display("##### sfp_row_dualcore_tb done: %0d rows OK, %0d errors #####", ROWS - err_count, err_count);
    if (err_count > 0) $display("*** FAIL ***");
    else               $display("*** PASS ***");
    #100 $finish;
  end

endmodule
