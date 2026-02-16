// Testbench: load mac_out.txt into pmem, feed sfp_row row-by-row, compare with norm_out_q20.txt
// sum_in / sum_out are tied off (not used).

`timescale 1ns/1ps

module sfp_row_tb;

  parameter ROWS = 8;
  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;  // 20

  integer mac_file, norm_file, r, c, scan_val, captured_data;
  integer mac_data [0:ROWS*col-1];   // row-major: row*col + c
  integer golden  [0:ROWS*col-1];
  integer u0, u1, u2, u3, u4, u5, u6, u7;
  integer err_count;
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

    // ----- Load golden norm_out_q20.txt (unsigned 0..2^20-1)
    $display("##### Loading norm_out_q20.txt #####");
    norm_file = $fopen("sim/pattern/norm_out_q20.txt", "r");
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

    // ----- Process each row: read from pmem -> acc -> div (2 cycles) -> compare
    err_count = 0;
    for (r = 0; r < ROWS; r = r + 1) begin
      pmem_rd = 1;
      pmem_wr = 0;
      pmem_add = r[3:0];
      acc = 0;
      div = 0;
      @(posedge clk);
      // Cycle 1: pmem_out valid, assert acc
      acc = 1;
      @(posedge clk);
      acc = 0;
      @(posedge clk);
      // Two div cycles so fifo output is used for sum_2core
      div = 1;
      @(posedge clk);
      @(posedge clk);
      div = 0;
      @(posedge clk);
      // sfp_out is now valid (registered on div cycle)
      begin
        u0 = sfp_out[bw_psum*1-1 -: bw_psum] & ((1<<bw_psum)-1);
        u1 = sfp_out[bw_psum*2-1 -: bw_psum] & ((1<<bw_psum)-1);
        u2 = sfp_out[bw_psum*3-1 -: bw_psum] & ((1<<bw_psum)-1);
        u3 = sfp_out[bw_psum*4-1 -: bw_psum] & ((1<<bw_psum)-1);
        u4 = sfp_out[bw_psum*5-1 -: bw_psum] & ((1<<bw_psum)-1);
        u5 = sfp_out[bw_psum*6-1 -: bw_psum] & ((1<<bw_psum)-1);
        u6 = sfp_out[bw_psum*7-1 -: bw_psum] & ((1<<bw_psum)-1);
        u7 = sfp_out[bw_psum*8-1 -: bw_psum] & ((1<<bw_psum)-1);
        if (u0 != golden[r*col+0] || u1 != golden[r*col+1] || u2 != golden[r*col+2] || u3 != golden[r*col+3] ||
            u4 != golden[r*col+4] || u5 != golden[r*col+5] || u6 != golden[r*col+6] || u7 != golden[r*col+7]) begin
          err_count = err_count + 1;
          $display("MISMATCH row %0d: got %0d %0d %0d %0d %0d %0d %0d %0d", r, u0,u1,u2,u3,u4,u5,u6,u7);
          $display("        golden %0d %0d %0d %0d %0d %0d %0d %0d",
            golden[r*col+0], golden[r*col+1], golden[r*col+2], golden[r*col+3],
            golden[r*col+4], golden[r*col+5], golden[r*col+6], golden[r*col+7]);
        end else
          $display("Row %0d OK", r);
      end
      @(posedge clk);
    end

    pmem_rd = 0;
    $display("##### sfp_row_tb done: %0d rows OK, %0d errors #####", ROWS - err_count, err_count);
    if (err_count > 0) $display("*** FAIL ***");
    else               $display("*** PASS ***");
    #100 $finish;
  end

endmodule
