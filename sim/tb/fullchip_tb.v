// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission


`timescale 1ns/1ps

module fullchip_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;   // fullchip/core uses 2*bw+4 here
  parameter pr = 16;
  parameter half_pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;
  parameter sfp_acc_lat = 1;

  parameter CLK0_PERIOD = 1;
  parameter CLK1_PERIOD = 2;

  `ifdef SFP_LONGDIV
    parameter sfp_div_lat = 8;
  `else
    parameter sfp_div_lat = 0;
  `endif

  integer qkvn_file, qkvn_scan_file, captured_data;

  integer K   [col-1:0][pr-1:0];
  integer Q   [total_cycle-1:0][pr-1:0];
  integer N    [total_cycle-1:0][col-1:0];
  integer V_T [pr-1:0][col-1:0];

  integer qk_result       [total_cycle-1:0][col-1:0];  // full 16-wide golden
  integer qk_result_core0 [total_cycle-1:0][col-1:0];  // lower 8 contribution
  integer qk_result_core1 [total_cycle-1:0][col-1:0];  // upper 8 contribution
  
   // VN golden
  integer vn_result_lo [total_cycle-1:0][col-1:0];  // final output[0:7]
  integer vn_result_hi [total_cycle-1:0][col-1:0];  // final output[8:15]

  
  integer sum [total_cycle-1:0];

  integer estimated [0:total_cycle*pr-1];

  integer i, j, k, t, p, q, s, u, m, r, c;
  integer err_count;
  integer err, row_err, row;
  integer sum_abs, divisor, unsigned_val;
  integer golden_col [0:col-1];

  reg reset = 1;
  reg clk0 = 0;
  reg clk1 = 0;

  reg [pr*bw-1:0] mem_in;

  reg sfp_processing = 0;
  reg sfp_div = 0, sfp_acc = 0;
  reg VN_mode = 0;

  wire [19:0] inst;
  reg qmem_rd = 0, qmem_wr = 0, kmem_rd = 0, kmem_wr = 0, pmem_rd = 0, pmem_wr = 0;
  reg execute = 0, load = 0;
  reg [3:0] qkmem_add = 0;
  reg [3:0] pmem_add = 0;

  wire [bw_psum*col*2-1:0] out;

  // split outputs
  wire [bw_psum*col-1:0] pmem_out_core0;
  wire [bw_psum*col-1:0] pmem_out_core1;

  assign pmem_out_core0 = out[bw_psum*col-1:0];
  assign pmem_out_core1 = out[bw_psum*col*2-1:bw_psum*col];

  assign inst[19] = VN_mode;
  assign inst[18] = sfp_div;
  assign inst[17] = sfp_acc;
  assign inst[16] = sfp_processing;
  assign inst[15:12] = qkmem_add;
  assign inst[11:8]  = pmem_add;
  assign inst[7] = execute;
  assign inst[6] = load;
  assign inst[5] = qmem_rd;
  assign inst[4] = qmem_wr;
  assign inst[3] = kmem_rd;
  assign inst[2] = kmem_wr;
  assign inst[1] = pmem_rd;
  assign inst[0] = pmem_wr;

  fullchip #(
    .bw(bw),
    .bw_psum(bw_psum),
    .col(col),
    .pr(pr)
  ) fullchip_instance (
    .clk0(clk0),
    .clk1(clk1),
    .mem_in(mem_in),
    .inst(inst),
    .reset(reset),
    .out(out)
  );

  
  always #(CLK0_PERIOD/2) clk0 = ~clk0;
  always #(CLK1_PERIOD/2) clk1 = ~clk1;
    

  initial begin
    $dumpfile("sim/waveform/fullchip.vcd");
    $dumpvars(0, fullchip_tb);

    mem_in = 0;

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        K[i][j] = 0;

   for (i = 0; i < total_cycle; i = i + 1)
    for (j = 0; j < pr; j = j + 1)
      Q[i][j] = 0;

  for (i = 0; i < pr; i = i + 1)        // V_T has pr=16 rows
    for (j = 0; j < col; j = j + 1)     // V_T has col=8 cols
      V_T[i][j] = 0;

  for (i = 0; i < total_cycle; i = i + 1)  // N has total_cycle=8 rows
    for (j = 0; j < col; j = j + 1)        // N has col=8 cols
      N[i][j] = 0;
    // ------------------------------------------------------------
    // Q read
    // ------------------------------------------------------------
    $display("##### Q data txt reading #####");
    qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
    for (q = 0; q < total_cycle; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end

    repeat(5) @(posedge clk0);
    reset = 0;

    // ------------------------------------------------------------
    // K read
    // ------------------------------------------------------------
    $display("##### K data txt reading #####");
    

    qkvn_file = $fopen("sim/pattern/kdata.txt", "r");
    for (q = 0; q < col; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end

    // ------------------------------------------------------------
    // Full / partial goldens for QK phase
    // ------------------------------------------------------------
    for (t = 0; t < total_cycle; t = t + 1)
      for (q = 0; q < col; q = q + 1) begin
        qk_result[t][q]       = 0;
        qk_result_core0[t][q] = 0;
        qk_result_core1[t][q] = 0;
      end

    for (t = 0; t < total_cycle; t = t + 1) begin
      for (q = 0; q < col; q = q + 1) begin
        for (k = 0; k < half_pr; k = k + 1)
          qk_result_core0[t][q] = qk_result_core0[t][q] + Q[t][k] * K[q][k];

        for (k = half_pr; k < pr; k = k + 1)
          qk_result_core1[t][q] = qk_result_core1[t][q] + Q[t][k] * K[q][k];

        qk_result[t][q] = qk_result_core0[t][q] + qk_result_core1[t][q];
      end
    end

    // ------------------------------------------------------------
    // Phase 1: QK Product
    // ------------------------------------------------------------
    $display("");
    $display("QK Product Phase");
    VN_mode = 1'b0;

    // ----- Q mem write -----
    $display("##### Qmem writing #####");
    
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      qmem_wr = 1'b1; qkmem_add = q;
      //if (q > 0) qkmem_add = qkmem_add + 1;

     
      mem_in[1*bw-1:0*bw]   = Q[q][7];
      mem_in[2*bw-1:1*bw]   = Q[q][6];
      mem_in[3*bw-1:2*bw]   = Q[q][5];
      mem_in[4*bw-1:3*bw]   = Q[q][4];
      mem_in[5*bw-1:4*bw]   = Q[q][3];
      mem_in[6*bw-1:5*bw]   = Q[q][2];
      mem_in[7*bw-1:6*bw]   = Q[q][1];
      mem_in[8*bw-1:7*bw]   = Q[q][0];

      
      mem_in[9*bw-1:8*bw]   = Q[q][15];
      mem_in[10*bw-1:9*bw]  = Q[q][14];
      mem_in[11*bw-1:10*bw] = Q[q][13];
      mem_in[12*bw-1:11*bw] = Q[q][12];
      mem_in[13*bw-1:12*bw] = Q[q][11];
      mem_in[14*bw-1:13*bw] = Q[q][10];
      mem_in[15*bw-1:14*bw] = Q[q][9];
      mem_in[16*bw-1:15*bw] = Q[q][8];

      
    end
   
    @(posedge clk0) qmem_wr = 1'b0;

    
    $display("##### Kmem writing #####");
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk0);
      kmem_wr = 1'b1;
      qkmem_add = q;

      mem_in[1*bw-1:0*bw]   = K[q][7];
      mem_in[2*bw-1:1*bw]   = K[q][6];
      mem_in[3*bw-1:2*bw]   = K[q][5];
      mem_in[4*bw-1:3*bw]   = K[q][4];
      mem_in[5*bw-1:4*bw]   = K[q][3];
      mem_in[6*bw-1:5*bw]   = K[q][2];
      mem_in[7*bw-1:6*bw]   = K[q][1];
      mem_in[8*bw-1:7*bw]   = K[q][0];

      mem_in[9*bw-1:8*bw]   = K[q][15];
      mem_in[10*bw-1:9*bw]  = K[q][14];
      mem_in[11*bw-1:10*bw] = K[q][13];
      mem_in[12*bw-1:11*bw] = K[q][12];
      mem_in[13*bw-1:12*bw] = K[q][11];
      mem_in[14*bw-1:13*bw] = K[q][10];
      mem_in[15*bw-1:14*bw] = K[q][9];
      mem_in[16*bw-1:15*bw] = K[q][8];

      
    end
    @(posedge clk0) kmem_wr = 1'b0;

   
    $display("##### K data loading to processor #####");
    @(posedge clk0) load = 1'b1; kmem_rd = 1'b1; qkmem_add = 0;
    repeat(col) @(posedge clk0) qkmem_add = qkmem_add + 1;
    @(posedge clk0) load = 1'b0; kmem_rd = 1'b0;

    repeat(10) @(posedge clk0);

    $display("##### execute #####");
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0); execute = 1'b1; qmem_rd = 1'b1; qkmem_add = q;
    end
    @(posedge clk0) begin execute = 1'b0; qmem_rd = 1'b0; end

    repeat(10) @(posedge clk0);

 
   for (c = 0; c < col; c = c + 1) golden_col[c] = 7 - c;
    err = 0;
    @(posedge clk0) begin pmem_rd = 1'b1; pmem_add = 0; end
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0) pmem_add = q + 1;
      row = q;
     for (c = 0; c < col; c = c + 1) begin
        sum_abs = $signed(pmem_out_core0[c*bw_psum +: bw_psum]) + $signed(pmem_out_core1[c*bw_psum +: bw_psum]);
        
        // Scoreboard calculation (N)
        unsigned_val = (sum_abs < 0) ? -sum_abs : sum_abs;
        estimated[q*pr + (7-c)]     = (unsigned_val >>> sfp_out_shift); 
        //estimated[q*pr + (7-c) + 8] = (unsigned_val >>> sfp_out_shift); 

        if (sum_abs !== qk_result[row][golden_col[c]]) begin
          err = err + 1;
        end
      end
    end
    @(posedge clk0) pmem_rd = 1'b0;

    //NORMALISATION PHASE:
    $display("##### sfp processing #####");
    sfp_processing = 1'b1; pmem_rd = 1'b1;
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk0) pmem_add = q;
      repeat(2) @(posedge clk0);
      @(posedge clk0) sfp_acc = 1'b1;
      @(posedge clk0) sfp_acc = 1'b0;
      
      // WAITing for Async FIFO Sync
      repeat(10) @(posedge clk1); 

      @(posedge clk0) sfp_div = 1'b1;
      @(posedge clk0) sfp_div = 1'b0;
      repeat(sfp_div_lat + 2) @(posedge clk0);
      @(posedge clk0) begin kmem_wr = 1'b1; qkmem_add = q; end
      @(posedge clk0) kmem_wr = 1'b0;
    end
    sfp_processing = 0; pmem_rd = 0;

    //repeat(10) @(posedge clk0);
    // --- VN PRODUCT ---
     $display("##### Phase 3: VN Product #####");
    //golden VN prod:
    for (t = 0; t < total_cycle; t = t + 1) begin
      for (q = 0; q < col; q = q + 1) begin
        vn_result_lo[t][q] = 0;
        vn_result_hi[t][q] = 0;
        for (k = 0; k < pr/2; k = k + 1) begin
          // Core 0 (lower 8) uses V_T[0:7]
          vn_result_lo[t][q] = vn_result_lo[t][q] + N[t][k] * V_T[k][q]; 
          // Core 1 (upper 8) uses V_T[8:15]
          vn_result_hi[t][q] = vn_result_hi[t][q] + N[t][k] * V_T[k+8][q];
        end
      end
    end

  $display("##### V data txt reading #####");
  qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
  for (q=0; q<col; q=q+1) begin
    for (j=0; j<pr; j=j+1) begin
      qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
      V_T[j][q] = captured_data;
    end
  end

   
    VN_mode = 1'b1;
    // loading V
    $display("##### Loading V into Kmem #####");
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk0);
      kmem_wr = 1'b1; qkmem_add = q;
      
      mem_in[1*bw-1:0*bw]   = V_T[7][q];  mem_in[2*bw-1:1*bw]   = V_T[6][q];
      mem_in[3*bw-1:2*bw]   = V_T[5][q];  mem_in[4*bw-1:3*bw]   = V_T[4][q];
      mem_in[5*bw-1:4*bw]   = V_T[3][q];  mem_in[6*bw-1:5*bw]   = V_T[2][q];
      mem_in[7*bw-1:6*bw]   = V_T[1][q];  mem_in[8*bw-1:7*bw]   = V_T[0][q];
      mem_in[9*bw-1:8*bw]   = V_T[15][q]; mem_in[10*bw-1:9*bw]  = V_T[14][q];
      mem_in[11*bw-1:10*bw] = V_T[13][q]; mem_in[12*bw-1:11*bw] = V_T[12][q];
      mem_in[13*bw-1:12*bw] = V_T[11][q]; mem_in[14*bw-1:13*bw] = V_T[10][q];
      mem_in[15*bw-1:14*bw] = V_T[9][q];  mem_in[16*bw-1:15*bw] = V_T[8][q];
    end
    @(posedge clk0) kmem_wr = 1'b0;

   
    @(posedge clk0) begin load = 1'b1; kmem_rd = 1'b1; qkmem_add = 0; end
    repeat(col) @(posedge clk0) qkmem_add = qkmem_add + 1;
    @(posedge clk0) begin load = 1'b0; kmem_rd = 1'b0; end

    $display("##### Norm data loading #####");
    `ifdef LOAD_OTHER_NORM_FILE
    //**************************//
    //   LOAD_OTHER_NORM_FILE   //
    //**************************//
    qkvn_file = $fopen("sim/pattern/norm.txt", "r");
    // Assuming norm.txt is formatted for the full width
    for (q=0; q<total_cycle; q=q+1) begin
      for (j=0; j<col; j=j+1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        N[q][j] = captured_data;
      end
    end
  `else
    //******************************************//
    // Use N calculated from QK product scoreboard //
    //******************************************//
    for (q=0; q<total_cycle; q=q+1) begin
      for (j=0; j<col; j=j+1) begin
        // Use the 'estimated' array generated during the QK phase
        N[q][j] = estimated[q*pr + j];
      end
    end
  `endif

    // Loading N 
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      qmem_wr = 1'b1; qkmem_add = q;
    
      mem_in[1*bw-1:0*bw] = N[q][7];  mem_in[2*bw-1:1*bw] = N[q][6];
      mem_in[3*bw-1:2*bw] = N[q][5];  mem_in[4*bw-1:3*bw] = N[q][4];
      mem_in[5*bw-1:4*bw] = N[q][3];  mem_in[6*bw-1:5*bw] = N[q][2];
      mem_in[7*bw-1:6*bw] = N[q][1];  mem_in[8*bw-1:7*bw] = N[q][0];
      mem_in[9*bw-1:8*bw] = N[q][7];  mem_in[10*bw-1:9*bw] = N[q][6];
      mem_in[11*bw-1:10*bw] = N[q][5]; mem_in[12*bw-1:11*bw] = N[q][4];
      mem_in[13*bw-1:12*bw] = N[q][3]; mem_in[14*bw-1:13*bw] = N[q][2];
      mem_in[15*bw-1:14*bw] = N[q][1]; mem_in[16*bw-1:15*bw] = N[q][0];
    end
    @(posedge clk0) qmem_wr = 1'b0;


    // Execute VN Matrix-Vector Multiplication
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0); 
      execute = 1'b1; qmem_rd = 1'b1; qkmem_add = q;
    end
    @(posedge clk0) begin execute = 1'b0; qmem_rd = 1'b0; end

    repeat(10) @(posedge clk0);

    
    $display("##### Final Verification #####");
    err = 0;

    @(posedge clk0) begin
    pmem_rd = 1'b1; 
    pmem_add = 0;

    end

    @(posedge clk0);

    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      if (q < total_cycle - 1) pmem_add = q + 1; else pmem_rd = 1'b0;
      row = q;
      
      $display("Row %0d:", row);
      $display("  Core0 RTL: %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core0[7*bw_psum +: bw_psum]), $signed(pmem_out_core0[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[5*bw_psum +: bw_psum]), $signed(pmem_out_core0[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[3*bw_psum +: bw_psum]), $signed(pmem_out_core0[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[1*bw_psum +: bw_psum]), $signed(pmem_out_core0[0*bw_psum +: bw_psum]));
      $display("  Core0 Gld: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_lo[row][0], vn_result_lo[row][1], vn_result_lo[row][2], vn_result_lo[row][3],
        vn_result_lo[row][4], vn_result_lo[row][5], vn_result_lo[row][6], vn_result_lo[row][7]);

      $display("  Core1 RTL: %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core1[7*bw_psum +: bw_psum]), $signed(pmem_out_core1[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[5*bw_psum +: bw_psum]), $signed(pmem_out_core1[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[3*bw_psum +: bw_psum]), $signed(pmem_out_core1[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[1*bw_psum +: bw_psum]), $signed(pmem_out_core1[0*bw_psum +: bw_psum]));
      $display("  Core1 Gld: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_hi[row][0], vn_result_hi[row][1], vn_result_hi[row][2], vn_result_hi[row][3],
        vn_result_hi[row][4], vn_result_hi[row][5], vn_result_hi[row][6], vn_result_hi[row][7]);

      row_err = 0;
      for (c = 0; c < col; c = c + 1) begin
        if ($signed(pmem_out_core0[c*bw_psum +: bw_psum]) != $signed(vn_result_lo[row][golden_col[c]])) begin
          err = err + 1; row_err = row_err + 1;
        end
        if ($signed(pmem_out_core1[c*bw_psum +: bw_psum]) != $signed(vn_result_hi[row][golden_col[c]])) begin
          err = err + 1; row_err = row_err + 1;
        end
      end
      $display("  Status: %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
       @(posedge clk0) 
    end

   pmem_rd = 1'b0;

    if (err == 0)
      $display("##### SIMULATION PASSED! Total Errors: %0d #####", err);
    else
      $display("##### SIMULATION FAILED! Total Errors: %0d #####", err);

  #100 $finish;
  end

endmodule