this is fullchip.v pls tell me if right:
// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission

// Fullchip verification TB adapted from core_dual_tb.v
// Phase 1 (QK product): Q/K files -> qmem/kmem write -> K load -> execute
//                       -> sample pmem out from both cores, compare partial and full golden.
// Phase 2 (Normalize ): identical scoreboard style as core_dual_tb.v.
//                       Golden is displayed; kmem write is observed through core printouts.
// Phase 3 (VN product): identical to phase 1, but using V and N.

`timescale 1ns/1ps

module fullchip_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;   // fullchip/core uses 2*bw+4 here
  parameter pr = 16;
  parameter half_pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;
  parameter sfp_acc_lat = 1;
  `ifdef SFP_LONGDIV
    parameter sfp_div_lat = 8;
  `else
    parameter sfp_div_lat = 0;
  `endif

  integer qkvn_file, qkvn_scan_file, captured_data;

  integer K   [col-1:0][pr-1:0];
  integer Q   [total_cycle-1:0][pr-1:0];
  integer N   [total_cycle-1:0][col-1:0];
  integer V_T [pr-1:0][col-1:0];

  integer qk_result       [total_cycle-1:0][col-1:0];  // full 16-wide golden
  integer qk_result_core0 [total_cycle-1:0][col-1:0];  // lower 8 contribution
  integer qk_result_core1 [total_cycle-1:0][col-1:0];  // upper 8 contribution
  
   // VN golden
  integer vn_result_lo [total_cycle-1:0][col-1:0];  // final output[0:7]
  integer vn_result_hi [total_cycle-1:0][col-1:0];  // final output[8:15]

  
  integer sum [total_cycle-1:0];

  integer estimated [0:total_cycle*col-1];

  integer i, j, k, t, p, q, s, u, m, r, c;
  integer err_count;
  integer err, row_err, row;
  integer sum_abs, divisor, unsigned_val;
  integer golden_col [0:7];

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
  assign inst[11:8]  = pmem_add;
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

  task tick_both;
    begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
  endtask

  task idle_both;
    input integer n;
    integer zz;
    begin
      for (zz = 0; zz < n; zz = zz + 1)
        tick_both();
    end
  endtask

  initial begin
    $dumpfile("gls/waveform/fullchip.vcd");
    $dumpvars(0, fullchip_tb);

    mem_in = 0;

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        K[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < pr; j = j + 1) begin
        Q[i][j] = 0;
        V_T[i][j] = 0;
      end

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
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

    idle_both(2);

    // ------------------------------------------------------------
    // K read
    // ------------------------------------------------------------
    $display("##### K data txt reading #####");
    idle_both(10);
    reset = 0;

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
        qk_result[t][q]       = 0;
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
    qkmem_add = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      qmem_wr = 1'b1;
      if (q > 0) qkmem_add = qkmem_add + 1;

      // core0 gets Q[q][0..7], reversed inside the 64-bit lane
      mem_in[1*bw-1:0*bw]   = Q[q][7];
      mem_in[2*bw-1:1*bw]   = Q[q][6];
      mem_in[3*bw-1:2*bw]   = Q[q][5];
      mem_in[4*bw-1:3*bw]   = Q[q][4];
      mem_in[5*bw-1:4*bw]   = Q[q][3];
      mem_in[6*bw-1:5*bw]   = Q[q][2];
      mem_in[7*bw-1:6*bw]   = Q[q][1];
      mem_in[8*bw-1:7*bw]   = Q[q][0];

      // core1 gets Q[q][8..15], reversed inside the upper 64-bit lane
      mem_in[9*bw-1:8*bw]   = Q[q][15];
      mem_in[10*bw-1:9*bw]  = Q[q][14];
      mem_in[11*bw-1:10*bw] = Q[q][13];
      mem_in[12*bw-1:11*bw] = Q[q][12];
      mem_in[13*bw-1:12*bw] = Q[q][11];
      mem_in[14*bw-1:13*bw] = Q[q][10];
      mem_in[15*bw-1:14*bw] = Q[q][9];
      mem_in[16*bw-1:15*bw] = Q[q][8];

      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    qmem_wr = 1'b0;
    qkmem_add = 0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    // ----- K mem write -----
    $display("##### Kmem writing #####");
    for (q = 0; q < col; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      kmem_wr = 1'b1;
      if (q > 0) qkmem_add = qkmem_add + 1;

      mem_in[1*bw-1:0*bw]   = K[q][7];
      mem_in[2*bw-1:1*bw]   = K[q][6];
      mem_in[3*bw-1:2*bw]   = K[q][5];
      mem_in[4*bw-1:3*bw]   = K[q][4];
      mem_in[5*bw-1:4*bw]   = K[q][3];
      mem_in[6*bw-1:5*bw]   = K[q][2];
      mem_in[7*bw-1:6*bw]   = K[q][1];
      mem_in[8*bw-1:7*bw]   = K[q][0];

      mem_in[9*bw-1:8*bw]   = K[q][15];
      mem_in[10*bw-1:9*bw]  = K[q][14];
      mem_in[11*bw-1:10*bw] = K[q][13];
      mem_in[12*bw-1:11*bw] = K[q][12];
      mem_in[13*bw-1:12*bw] = K[q][11];
      mem_in[14*bw-1:13*bw] = K[q][10];
      mem_in[15*bw-1:14*bw] = K[q][9];
      mem_in[16*bw-1:15*bw] = K[q][8];

      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    kmem_wr = 1'b0;
    qkmem_add = 0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    idle_both(2);

    // ----- K load to processor -----
    $display("##### K data loading to processor #####");
    for (q = 0; q < col + 1; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      load = 1'b1;
      if (q == 1) kmem_rd = 1'b1;
      if (q > 1) qkmem_add = qkmem_add + 1;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    kmem_rd = 1'b0;
    qkmem_add = 0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    load = 1'b0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    idle_both(10);

    // ----- execute -----
    $display("##### execute #####");
    for (q = 0; q < total_cycle; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      execute = 1'b1;
      qmem_rd = 1'b1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    qmem_rd = 1'b0;
    qkmem_add = 0;
    execute = 1'b0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    tick_both();
    tick_both();

    idle_both(10);

    // ----- verify pmem rows -----
    for (c = 0; c < col; c = c + 1)
      golden_col[c] = 7 - c;

    $display("QK phase verification start (checking pmem content)");
    $display("");
    err = 0;

    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    pmem_rd = 1'b1;
    pmem_add = 4'd0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    for (q = 0; q < total_cycle; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      pmem_add = pmem_add + 1;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;

      row = q;
      $display("Row %0d", row);
      $display("  core0 RTL   : %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core0[7*bw_psum +: bw_psum]), $signed(pmem_out_core0[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[5*bw_psum +: bw_psum]), $signed(pmem_out_core0[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[3*bw_psum +: bw_psum]), $signed(pmem_out_core0[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[1*bw_psum +: bw_psum]), $signed(pmem_out_core0[0*bw_psum +: bw_psum]));
      $display("  core0 golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        qk_result_core0[row][0], qk_result_core0[row][1], qk_result_core0[row][2], qk_result_core0[row][3],
        qk_result_core0[row][4], qk_result_core0[row][5], qk_result_core0[row][6], qk_result_core0[row][7]);

      $display("  core1 RTL   : %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core1[7*bw_psum +: bw_psum]), $signed(pmem_out_core1[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[5*bw_psum +: bw_psum]), $signed(pmem_out_core1[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[3*bw_psum +: bw_psum]), $signed(pmem_out_core1[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[1*bw_psum +: bw_psum]), $signed(pmem_out_core1[0*bw_psum +: bw_psum]));
      $display("  core1 golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        qk_result_core1[row][0], qk_result_core1[row][1], qk_result_core1[row][2], qk_result_core1[row][3],
        qk_result_core1[row][4], qk_result_core1[row][5], qk_result_core1[row][6], qk_result_core1[row][7]);

      $display("  full  sum   : %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core0[7*bw_psum +: bw_psum]) + $signed(pmem_out_core1[7*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[6*bw_psum +: bw_psum]) + $signed(pmem_out_core1[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[5*bw_psum +: bw_psum]) + $signed(pmem_out_core1[5*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[4*bw_psum +: bw_psum]) + $signed(pmem_out_core1[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[3*bw_psum +: bw_psum]) + $signed(pmem_out_core1[3*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[2*bw_psum +: bw_psum]) + $signed(pmem_out_core1[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[1*bw_psum +: bw_psum]) + $signed(pmem_out_core1[1*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[0*bw_psum +: bw_psum]) + $signed(pmem_out_core1[0*bw_psum +: bw_psum]));
      $display("  full  golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        qk_result[row][0], qk_result[row][1], qk_result[row][2], qk_result[row][3],
        qk_result[row][4], qk_result[row][5], qk_result[row][6], qk_result[row][7]);

      row_err = 0;
      for (c = 0; c < col; c = c + 1) begin
        if ( ($signed(pmem_out_core0[c*bw_psum +: bw_psum]) + $signed(pmem_out_core1[c*bw_psum +: bw_psum]))
             !== qk_result[row][golden_col[c]] ) begin
          $display("    >>> col%0d FULL MISMATCH (RTL %0d != golden %0d)", c,
            $signed(pmem_out_core0[c*bw_psum +: bw_psum]) + $signed(pmem_out_core1[c*bw_psum +: bw_psum]),
            qk_result[row][golden_col[c]]);
          err = err + 1;
          row_err = row_err + 1;
        end
      end
      $display("    %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end

    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    pmem_rd = 1'b0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    $display("------------------------------------------------------------");
    if (err == 0) begin
      $display("  PASS  %0d rows x %0d cols  all fullchip sums match estimated qk_result", total_cycle, col);
      $display("------------------------------------------------------------");
    end else begin
      $display("  FAIL  %0d mismatches", err);
      $display("------------------------------------------------------------");
    end
    $display("");

    // ------------------------------------------------------------
    // Estimated normalization from full 16-wide qk_result
    // ------------------------------------------------------------
    $display("##### Estimated normalization (sum_abs>>7, then signed divide) #####");
    for (r = 0; r < total_cycle; r = r + 1) begin
      sum_abs = 0;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = qk_result[r][c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val - 1'b1);
        sum_abs = sum_abs + unsigned_val;
      end
      if (sum_abs == 0) sum_abs = 1;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = qk_result[r][c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val - 1'b1);
        estimated[r*col + c] = {unsigned_val, {sfp_out_shift{1'b0}}} / sum_abs;
      end
    end

    // ------------------------------------------------------------
    // Phase 2: SFP processing / normalization
    // ------------------------------------------------------------
    $display("");
    $display("##### sfp processing #####");
    $display("estimated:        col0    col1    col2    col3    col4    col5    col6    col7 ");
    $display("to kmem  :       63:56   55:48   47:40   39:32   31:24   23:16   15: 8    7: 0 ");

    sfp_processing = 1'b1;
    pmem_add = 0;
    qkmem_add = 0;
    pmem_rd = 1'b1;

    for (q = 0; q < col; q = q + 1) begin
      tick_both();                      // posedge 1
      tick_both(); sfp_acc = 1'b1;      // posedge 2
      tick_both();                      // posedge 3
      tick_both(); sfp_acc = 1'b0;      // posedge 4
      for (s = 0; s < sfp_acc_lat; s = s + 1) tick_both();
      tick_both(); sfp_div = 1'b1;      // posedge 5
      tick_both();                      // posedge 6
      tick_both(); sfp_div = 1'b0;      // posedge 7
      for (s = 0; s < sfp_div_lat; s = s + 1) tick_both();
      tick_both(); kmem_wr = 1'b1;      // posedge 8

      $display("");
      $display("estimated:     %7d %7d %7d %7d %7d %7d %7d %7d",
        estimated[q*col + 0], estimated[q*col + 1],
        estimated[q*col + 2], estimated[q*col + 3],
        estimated[q*col + 4], estimated[q*col + 5],
        estimated[q*col + 6], estimated[q*col + 7]);

      tick_both(); kmem_wr = 1'b0;      // posedge 9

      pmem_add = pmem_add + 1;
      qkmem_add = qkmem_add + 1;
    end

    idle_both(10);
    sfp_processing = 1'b0;
    pmem_rd = 1'b0;

    $display("------------------------------------------------------------");
    $display("Please check manually, since there's no output port for kmem.");
    $display("Both cores will print Write to kmem lines during normalization.");
    $display("------------------------------------------------------------");
    $display("");

    idle_both(10);

    // ------------------------------------------------------------
    // Phase 3: VN Product
    // ------------------------------------------------------------
    $display("");
    $display("VN Product Phase");
    VN_mode = 1'b1;
    reset = 1'b1;
    idle_both(10);
    reset = 1'b0;

    // ----- V read -----
    $display("##### V data txt reading #####");
    qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
    for (q = 0; q < col; q = q + 1) begin
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        V_T[j][q] = captured_data;
      end
    end

    // ----- N read or estimated -----
    $display("##### norm data txt reading #####");
    idle_both(10);
    reset = 0;

    `ifdef LOAD_OTHER_NORM_FILE
      qkvn_file = $fopen("sim/pattern/norm.txt", "r");
      for (q = 0; q < total_cycle; q = q + 1)
        for (j = 0; j < col; j = j + 1) begin
          qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
          N[q][j] = captured_data;
        end
    `else
      for (q = 0; q < total_cycle; q = q + 1)
        for (j = 0; j < col; j = j + 1)
          N[q][j] = estimated[q*col + j];
    `endif

    // ----- VN golden -----
    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < col; j = j + 1) begin
        vn_result_lo[i][j] = 0;
        vn_result_hi[i][j] = 0;
      end

    for (i = 0; i < total_cycle; i = i + 1) begin
      for (j = 0; j < col; j = j + 1) begin
        for (k = 0; k < col; k = k + 1) begin
          vn_result_lo[i][j] = vn_result_lo[i][j] + V_T[i][k]   * N[j][k];
          vn_result_hi[i][j] = vn_result_hi[i][j] + V_T[i+8][k] * N[j][k];
        end
      end
    end

    // ----- Qmem writing with V -----
    $display("##### Qmem writing #####");
    qkmem_add = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      qmem_wr = 1'b1;
      if (q > 0) qkmem_add = qkmem_add + 1;

      mem_in[1*bw-1:0*bw]   = V_T[q][7];
      mem_in[2*bw-1:1*bw]   = V_T[q][6];
      mem_in[3*bw-1:2*bw]   = V_T[q][5];
      mem_in[4*bw-1:3*bw]   = V_T[q][4];
      mem_in[5*bw-1:4*bw]   = V_T[q][3];
      mem_in[6*bw-1:5*bw]   = V_T[q][2];
      mem_in[7*bw-1:6*bw]   = V_T[q][1];
      mem_in[8*bw-1:7*bw]   = V_T[q][0];

      mem_in[9*bw-1:8*bw]   = V_T[q][15];
      mem_in[10*bw-1:9*bw]  = V_T[q][14];
      mem_in[11*bw-1:10*bw] = V_T[q][13];
      mem_in[12*bw-1:11*bw] = V_T[q][12];
      mem_in[13*bw-1:12*bw] = V_T[q][11];
      mem_in[14*bw-1:13*bw] = V_T[q][10];
      mem_in[15*bw-1:14*bw] = V_T[q][9];
      mem_in[16*bw-1:15*bw] = V_T[q][8];

      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    qmem_wr = 1'b0;
    qkmem_add = 0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    `ifdef LOAD_OTHER_NORM_FILE
      $display("##### Kmem writing #####");
      for (q = 0; q < col; q = q + 1) begin
        #0.5 clk0 = 1'b0; clk1 = 1'b0;
        kmem_wr = 1'b1;
        if (q > 0) qkmem_add = qkmem_add + 1;

        mem_in[1*bw-1:0*bw]   = N[q][7];
        mem_in[2*bw-1:1*bw]   = N[q][6];
        mem_in[3*bw-1:2*bw]   = N[q][5];
        mem_in[4*bw-1:3*bw]   = N[q][4];
        mem_in[5*bw-1:4*bw]   = N[q][3];
        mem_in[6*bw-1:5*bw]   = N[q][2];
        mem_in[7*bw-1:6*bw]   = N[q][1];
        mem_in[8*bw-1:7*bw]   = N[q][0];

        mem_in[9*bw-1:8*bw]   = N[q][15];
        mem_in[10*bw-1:9*bw]  = N[q][14];
        mem_in[11*bw-1:10*bw] = N[q][13];
        mem_in[12*bw-1:11*bw] = N[q][12];
        mem_in[13*bw-1:12*bw] = N[q][11];
        mem_in[14*bw-1:13*bw] = N[q][10];
        mem_in[15*bw-1:14*bw] = N[q][9];
        mem_in[16*bw-1:15*bw] = N[q][8];

        #0.5 clk0 = 1'b1; clk1 = 1'b1;
      end
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      kmem_wr = 1'b0;
      qkmem_add = 0;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    `endif

    idle_both(2);

    // ----- K load to processor -----
    $display("##### K data loading to processor #####");
    for (q = 0; q < col + 1; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      load = 1'b1;
      if (q == 1) kmem_rd = 1'b1;
      if (q > 1) qkmem_add = qkmem_add + 1;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    kmem_rd = 1'b0;
    qkmem_add = 0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    load = 1'b0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    idle_both(10);

    // ----- execute -----
    $display("##### execute #####");
    for (q = 0; q < total_cycle; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      execute = 1'b1;
      qmem_rd = 1'b1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;
    end
    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    qmem_rd = 1'b0;
    qkmem_add = 0;
    execute = 1'b0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    tick_both();
    tick_both();

    idle_both(10);

    // ----- verify VN pmem -----
    for (c = 0; c < col; c = c + 1)
      golden_col[c] = 7 - c;

    $display("VN phase verification start (checking pmem content)");
    $display("");
    err = 0;

    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    pmem_rd = 1'b1;
    pmem_add = 4'd0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    for (q = 0; q < total_cycle; q = q + 1) begin
      #0.5 clk0 = 1'b0; clk1 = 1'b0;
      pmem_add = pmem_add + 1;
      #0.5 clk0 = 1'b1; clk1 = 1'b1;

      row = q;
      $display("Row %0d", row);
      $display("  core0 RTL   : %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core0[7*bw_psum +: bw_psum]), $signed(pmem_out_core0[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[5*bw_psum +: bw_psum]), $signed(pmem_out_core0[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[3*bw_psum +: bw_psum]), $signed(pmem_out_core0[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core0[1*bw_psum +: bw_psum]), $signed(pmem_out_core0[0*bw_psum +: bw_psum]));
      $display("  core0 golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_lo[row][0], vn_result_lo[row][1], vn_result_lo[row][2], vn_result_lo[row][3],
        vn_result_lo[row][4], vn_result_lo[row][5], vn_result_lo[row][6], vn_result_lo[row][7]);

      $display("  core1 RTL   : %7d %7d %7d %7d %7d %7d %7d %7d",
        $signed(pmem_out_core1[7*bw_psum +: bw_psum]), $signed(pmem_out_core1[6*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[5*bw_psum +: bw_psum]), $signed(pmem_out_core1[4*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[3*bw_psum +: bw_psum]), $signed(pmem_out_core1[2*bw_psum +: bw_psum]),
        $signed(pmem_out_core1[1*bw_psum +: bw_psum]), $signed(pmem_out_core1[0*bw_psum +: bw_psum]));
      $display("  core1 golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_hi[row][0], vn_result_hi[row][1], vn_result_hi[row][2], vn_result_hi[row][3],
        vn_result_hi[row][4], vn_result_hi[row][5], vn_result_hi[row][6], vn_result_hi[row][7]);

           row_err = 0;
      for (c = 0; c < col; c = c + 1) begin
        if ($signed(pmem_out_core0[c*bw_psum +: bw_psum]) !== vn_result_lo[row][golden_col[c]]) begin
          $display("    >>> core0 col%0d MISMATCH (RTL %0d != golden %0d)", c,
            $signed(pmem_out_core0[c*bw_psum +: bw_psum]),
            vn_result_lo[row][golden_col[c]]);
          err = err + 1;
          row_err = row_err + 1;
        end

        if ($signed(pmem_out_core1[c*bw_psum +: bw_psum]) !== vn_result_hi[row][golden_col[c]]) begin
          $display("    >>> core1 col%0d MISMATCH (RTL %0d != golden %0d)", c,
            $signed(pmem_out_core1[c*bw_psum +: bw_psum]),
            vn_result_hi[row][golden_col[c]]);
          err = err + 1;
          row_err = row_err + 1;
        end
      end

      $display("    %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end

    #0.5 clk0 = 1'b0; clk1 = 1'b0;
    pmem_rd = 1'b0;
    #0.5 clk0 = 1'b1; clk1 = 1'b1;

    $display("------------------------------------------------------------");
    if (err == 0) begin
      $display("  PASS  VN lower/upper 8-element halves match expected 16-element output");
      $display("------------------------------------------------------------");
    end else begin
      $display("  FAIL  %0d mismatches", err);
      $display("------------------------------------------------------------");
    end
    $display("");

    #10 $finish;
  end

endmodule