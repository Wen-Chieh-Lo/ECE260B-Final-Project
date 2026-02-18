// Mac verification: TB + DUT (mac_array_top) in one file.
// Flow: Q/K files -> qmem/kmem write -> K load -> execute -> sample ofifo out, compare to golden.

`timescale 1ns/1ps

module core_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+3;
  parameter pr = 8;
  parameter col = 8;

  integer qkvn_file, qkvn_scan_file, captured_data;
  integer weight [col*pr-1:0];
  integer K [col-1:0][pr-1:0];
  integer Q [total_cycle-1:0][pr-1:0];
  integer N [col-1:0][pr-1:0]; 
  integer V_T[total_cycle-1:0][pr-1:0];
  integer result [total_cycle-1:0][col-1:0];
  integer sum [total_cycle-1:0];
  integer i, j, k, t, p, q, s, u, m;

  reg reset = 1;
  reg clk = 0;
  reg [pr*bw-1:0] mem_in;
  reg sfp_processing = 0;
  reg sfp_div, sfp_acc;
  reg VN_mode = 0;
  // wire [18:0] inst;
  wire [19:0] inst;
  reg qmem_rd = 0, qmem_wr = 0, kmem_rd = 0, kmem_wr = 0;
  reg execute = 0, load = 0;
  reg [3:0] qkmem_add = 0;

  reg [bw_psum-1:0] temp5b;
  reg [bw_psum+3:0] temp_sum;
  reg [bw_psum*col-1:0] temp16b;

  wire [bw_psum*col-1:0] pmem_out;
  integer err, row_err, row, c;
  integer golden_col [0:7];  // RTL col c -> golden result[t][golden_col[c]] (chain mapping)

  assign inst [19] = VN_mode;
  assign inst[18] = sfp_div;            // set by tb so far. usage see sfp_row_tb.
  assign inst[17] = sfp_acc;            // set by tb so far. usage see sfp_row_tb.
  assign inst[16] = sfp_processing;
  assign inst[15:12] = qkmem_add;
  assign inst[11:8]  = 4'b0;
  assign inst[7] = execute;
  assign inst[6] = load;
  assign inst[5] = qmem_rd;
  assign inst[4] = qmem_wr;
  assign inst[3] = kmem_rd;
  assign inst[2] = kmem_wr;
  assign inst[1:0] = 2'b0;

  core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core_instance (
    .reset(reset),
    .clk(clk),
    .mem_in(mem_in),
    .inst(inst),
    .sum_out(),
    .out()
  );

  initial begin
    $dumpfile("sim/waveform/core.vcd");
    $dumpvars(0, core_tb);


    $display("##### Q data txt reading #####");
    qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
    for (q = 0; q < total_cycle; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end

    for (q = 0; q < 2; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

    $display("##### K data txt reading #####");
    for (q = 0; q < 10; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end
    reset = 0;

    qkvn_file = $fopen("sim/pattern/kdata.txt", "r");
    for (q = 0; q < col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end

    // $display("##### Estimated multiplication result #####");
    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1)
        result[t][q] = 0;
    for (t = 0; t < total_cycle; t = t+1) begin
      for (q = 0; q < col; q = q+1) begin
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];
        temp5b = result[t][q];
        temp16b = {temp16b[139:0], temp5b};
      end
      $display("prd @cycle%2d: %40h", t, temp16b);
    end

    $display("QK Product Phase");
    VN_mode = 1'b0;

    $display("##### Qmem writing #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      qmem_wr = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      mem_in[1*bw-1:0*bw] = Q[q][0];
      mem_in[2*bw-1:1*bw] = Q[q][1];
      mem_in[3*bw-1:2*bw] = Q[q][2];
      mem_in[4*bw-1:3*bw] = Q[q][3];
      mem_in[5*bw-1:4*bw] = Q[q][4];
      mem_in[6*bw-1:5*bw] = Q[q][5];
      mem_in[7*bw-1:6*bw] = Q[q][6];
      mem_in[8*bw-1:7*bw] = Q[q][7];
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0;
    qmem_wr = 0;
    qkmem_add = 0;
    #0.5 clk = 1'b1;

    $display("##### Kmem writing #####");
    for (q = 0; q < col; q = q+1) begin
      #0.5 clk = 1'b0;
      kmem_wr = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      mem_in[1*bw-1:0*bw] = K[q][0];
      mem_in[2*bw-1:1*bw] = K[q][1];
      mem_in[3*bw-1:2*bw] = K[q][2];
      mem_in[4*bw-1:3*bw] = K[q][3];
      mem_in[5*bw-1:4*bw] = K[q][4];
      mem_in[6*bw-1:5*bw] = K[q][5];
      mem_in[7*bw-1:6*bw] = K[q][6];
      mem_in[8*bw-1:7*bw] = K[q][7];
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0;
    kmem_wr = 0;
    qkmem_add = 0;
    #0.5 clk = 1'b1;

    for (q = 0; q < 2; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

    $display("##### K data loading to processor #####");
    for (q = 0; q < col+1; q = q+1) begin
      #0.5 clk = 1'b0;
      load = 1;
      if (q == 1) kmem_rd = 1;
      if (q > 1) qkmem_add = qkmem_add + 1;
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0;
    kmem_rd = 0;
    qkmem_add = 0;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;
    load = 0;
    #0.5 clk = 1'b1;

    for (q = 0; q < 10; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

    $display("##### execute #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      execute = 1;
      qmem_rd = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0;
    qmem_rd = 0;
    qkmem_add = 0;
    execute = 0;
    #0.5 clk = 1'b1;

    for (q = 0; q < 10; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end


    $display("");
    $display("##### sfp processing #####");
    sfp_processing = 1'b1;
    for (q = 0; q < col; q = q + 1) begin
      #0.5 clk = 1'b0;
      kmem_rd = 1;
      #0.5 clk = 1'b1;

      for (p = 1; p < 8; p = p + 1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end
    end





















    // // RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
    // for (c = 0; c < col; c = c+1)
    //   golden_col[c] = 7 - c;

    // $display("");
    // $display("##### sample ofifo out & compare to golden #####");
    // $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    // $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
    // err = 0;
    // for (q = 0; q < total_cycle; q = q+1) begin
    //   #0.5 clk = 1'b0;
    //   ofifo_rd = 1;
    //   #0.5;  // sample before posedge: pmem_out = row being read (result[q])
    //   row = q;
    //   $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row,
    //     $signed(pmem_out[0*bw_psum +: bw_psum]), $signed(pmem_out[1*bw_psum +: bw_psum]),
    //     $signed(pmem_out[2*bw_psum +: bw_psum]), $signed(pmem_out[3*bw_psum +: bw_psum]),
    //     $signed(pmem_out[4*bw_psum +: bw_psum]), $signed(pmem_out[5*bw_psum +: bw_psum]),
    //     $signed(pmem_out[6*bw_psum +: bw_psum]), $signed(pmem_out[7*bw_psum +: bw_psum]));
    //   $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
    //     result[row][7], result[row][6], result[row][5], result[row][4],
    //     result[row][3], result[row][2], result[row][1], result[row][0]);
    //   row_err = 0;
    //   for (c = 0; c < col; c = c+1) begin
    //     if ($signed(pmem_out[c*bw_psum +: bw_psum]) !== result[row][golden_col[c]]) begin
    //       $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*bw_psum +: bw_psum]), result[row][golden_col[c]]);
    //       err = err + 1;
    //       row_err = row_err + 1;
    //     end
    //   end
    //   $display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
    //   $display("");
    //   #0.5 clk = 1'b1;
    // end
    // #0.5 clk = 1'b0;
    // ofifo_rd = 0;
    // #0.5 clk = 1'b1;

    // $display("------------------------------------------------------------");
    // if (err == 0) begin
    //   $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    //   $display("------------------------------------------------------------");
    // end else begin
    //   $display("  FAIL  %0d mismatches", err);
    //   $display("------------------------------------------------------------");
    // end
    // $display("");

    for (q = 0; q < 5; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end




    $display("VN Product Phase");
    VN_mode = 1'b1;
















    #10 $finish;
  end

endmodule
