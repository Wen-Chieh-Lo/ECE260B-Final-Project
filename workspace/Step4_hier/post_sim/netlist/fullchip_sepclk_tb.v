// fullchip_sepclk_tb: real dual-clock, three-initial architecture.
// Initial 1: data + golden (no timing). Initial 2: clk0 domain, drives reset (multi-cycle).
// Initial 3: clk1 domain, waits for reset deassert before proceeding.
// Cores run independently; SFP sync via fifo_empty. QK and VN verified in each initial.

`timescale 1ns/1ps

module fullchip_sepclk_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;
  parameter sfp_acc_lat = 1;
  parameter sfp_div_lat = 0;

  integer qk_file, qk_scan_file, captured_data;
  integer K [2*col-1:0][pr-1:0];
  integer Q [total_cycle-1:0][pr-1:0];
  integer V_T[total_cycle-1:0][pr-1:0];

  reg signed [bw_psum-1:0]   result    [total_cycle-1:0][2*col-1:0];
  reg signed [bw_psum-1:0]   abs_result[total_cycle-1:0][2*col-1:0];
  reg signed [bw_psum+4-1:0] sum_core0 [total_cycle-1:0];
  reg signed [bw_psum+4-1:0] sum_core1 [total_cycle-1:0];
  integer N_est_core0[total_cycle-1:0][col-1:0];
  integer N_est_core1[total_cycle-1:0][col-1:0];
  integer vn_result_core0[total_cycle-1:0][col-1:0];
  integer vn_result_core1[total_cycle-1:0][col-1:0];

  integer mismatch_qk_core0, mismatch_qk_core1;
  integer mismatch_vn_core0, mismatch_vn_core1;

  integer j, k, t, q, c;
  integer golden_col [0:7];
  integer q0, q1, wait_guard0, wait_guard1, row0, row1, c0, c1, row_err0, row_err1;

  reg data_ready_flag = 0;
  reg reset_done_c0_flag = 0;
  reg vn_reset_done_c0_flag = 0;
  reg vn_done_c0_flag = 0, vn_done_c1_flag = 0;

  reg clk0 = 0;
  reg clk1 = 0;

  wire [2*col*bw_psum-1:0] out;
  reg  reset = 1;

  reg  [pr*bw-1:0]   mem_in_core0;
  reg  [pr*bw-1:0]   mem_in_core1;
  wire [2*pr*bw-1:0] mem_in;
  assign mem_in = {mem_in_core1, mem_in_core0};

  reg  VN_mode_c0  = 0, VN_mode_c1  = 0;
  reg  div_c0      = 0, div_c1      = 0;
  reg  acc_c0      = 0, acc_c1      = 0;
  reg  ofifo_rd_c0 = 0, ofifo_rd_c1 = 0;
  reg  [3:0] qkmem_add_c0 = 0, qkmem_add_c1 = 0;
  reg  [3:0] pmem_add_c0  = 0, pmem_add_c1  = 0;
  reg  execute_c0  = 0, execute_c1  = 0;
  reg  load_c0     = 0, load_c1     = 0;
  reg  qmem_rd_c0  = 0, qmem_rd_c1  = 0;
  reg  qmem_wr_c0  = 0, qmem_wr_c1  = 0;
  reg  kmem_rd_c0  = 0, kmem_rd_c1  = 0;
  reg  kmem_wr_c0  = 0, kmem_wr_c1  = 0;
  reg  pmem_rd_c0  = 0, pmem_rd_c1  = 0;

  wire [19:0] inst0, inst1;
  wire [39:0] inst;

  assign inst0[19]    = VN_mode_c0;
  assign inst0[18]    = div_c0;
  assign inst0[17]    = acc_c0;
  assign inst0[16]    = ofifo_rd_c0;
  assign inst0[15:12] = qkmem_add_c0;
  assign inst0[11:8]  = pmem_add_c0;
  assign inst0[7]     = execute_c0;
  assign inst0[6]     = load_c0;
  assign inst0[5]     = qmem_rd_c0;
  assign inst0[4]     = qmem_wr_c0;
  assign inst0[3]     = kmem_rd_c0;
  assign inst0[2]     = kmem_wr_c0;
  assign inst0[1]     = pmem_rd_c0;
  assign inst0[0]     = 1'b0;

  assign inst1[19]    = VN_mode_c1;
  assign inst1[18]    = div_c1;
  assign inst1[17]    = acc_c1;
  assign inst1[16]    = ofifo_rd_c1;
  assign inst1[15:12] = qkmem_add_c1;
  assign inst1[11:8]  = pmem_add_c1;
  assign inst1[7]     = execute_c1;
  assign inst1[6]     = load_c1;
  assign inst1[5]     = qmem_rd_c1;
  assign inst1[4]     = qmem_wr_c1;
  assign inst1[3]     = kmem_rd_c1;
  assign inst1[2]     = kmem_wr_c1;
  assign inst1[1]     = pmem_rd_c1;
  assign inst1[0]     = 1'b0;

  assign inst = {inst1, inst0};

  reg [bw_psum-1:0]     temp5b;
  reg [bw_psum*col-1:0] temp16b;

  wire fifo0_empty, fifo1_empty;

  fullchip fullchip_instance (
    .reset(reset),
    .clk0(clk0),
    .clk1(clk1),
    .mem_in(mem_in),
    .inst(inst),
    .out(out),
    .fifo0_empty(fifo0_empty),
    .fifo1_empty(fifo1_empty)
  );

  task tick0; begin #0.5   clk0=1'b0; #0.5   clk0=1'b1; end endtask
  task tick1; begin #3.14159265358979323846   clk1=1'b0; #3.14159265358979323846 clk1=1'b1; end endtask

  // ========== Initial 1: Data + Golden (no timing) ==========
  initial begin
    $dumpfile("../sim/waveform/fullchip_sepclk.vcd");
    $dumpvars(0, fullchip_sepclk_tb);

    mismatch_qk_core0 = 0; mismatch_qk_core1 = 0;
    mismatch_vn_core0 = 0; mismatch_vn_core1 = 0;

    $display("##### Q data txt reading #####");
    qk_file = $fopen("../sim/pattern/qdata.txt", "r");
    if (qk_file == 0) begin $display("ERROR: cannot open qdata.txt"); $finish; end
    for (q = 0; q < total_cycle; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end

    $display("##### K data txt reading #####");
    qk_file = $fopen("../sim/pattern/kdata_dual.txt", "r");
    if (qk_file == 0) begin $display("ERROR: cannot open kdata_dual.txt"); $finish; end
    for (q = 0; q < 2*col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end

    $display("##### V data txt reading #####");
    qk_file = $fopen("../sim/pattern/vdata.txt", "r");
    if (qk_file == 0) begin $display("ERROR: cannot open vdata.txt"); $finish; end
    for (q = 0; q < col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        V_T[j][q] = captured_data;
      end

    $display("##### Estimated QK result CORE0 #####");
    for (t = 0; t < total_cycle; t = t+1) begin
      for (q = 0; q < col; q = q+1) begin
        result[t][q] = 0;
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];
        temp5b  = result[t][q];
        temp16b = {temp16b[bw_psum*col-bw_psum-1:0], temp5b};
      end
      $display("prd @cycle%2d: %40h", t, temp16b);
    end

    for (t = 0; t < total_cycle; t = t+1) begin
      sum_core0[t] = 0;
      for (q = 0; q < col; q = q+1) begin
        abs_result[t][q] = (result[t][q] >= 0) ? result[t][q] : -result[t][q];
        sum_core0[t] = sum_core0[t] + abs_result[t][q];
      end
    end

    $display("##### Estimated QK result CORE1 #####");
    for (t = 0; t < total_cycle; t = t+1) begin
      for (q = col; q < 2*col; q = q+1) begin
        result[t][q] = 0;
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];
        temp5b  = result[t][q];
        temp16b = {temp16b[bw_psum*col-bw_psum-1:0], temp5b};
      end
      $display("prd @cycle%2d: %40h", t, temp16b);
    end

    for (t = 0; t < total_cycle; t = t+1) begin
      sum_core1[t] = 0;
      for (q = col; q < 2*col; q = q+1) begin
        abs_result[t][q] = (result[t][q] >= 0) ? result[t][q] : -result[t][q];
        sum_core1[t] = sum_core1[t] + abs_result[t][q];
      end
    end

    $display("##### Estimated N (normalized QK) #####");
    for (t = 0; t < total_cycle; t = t+1) begin
      for (q = 0; q < col; q = q+1) begin
        N_est_core0[t][q] = (abs_result[t][q]     << sfp_out_shift)
                             / (sum_core0[t] + sum_core1[t]);
        N_est_core1[t][q] = (abs_result[t][col+q] << sfp_out_shift)
                             / (sum_core0[t] + sum_core1[t]);
      end
      $display("N_est C0 row%0d: %3d %3d %3d %3d %3d %3d %3d %3d", t,
        N_est_core0[t][0], N_est_core0[t][1], N_est_core0[t][2], N_est_core0[t][3],
        N_est_core0[t][4], N_est_core0[t][5], N_est_core0[t][6], N_est_core0[t][7]);
      $display("N_est C1 row%0d: %3d %3d %3d %3d %3d %3d %3d %3d", t,
        N_est_core1[t][0], N_est_core1[t][1], N_est_core1[t][2], N_est_core1[t][3],
        N_est_core1[t][4], N_est_core1[t][5], N_est_core1[t][6], N_est_core1[t][7]);
    end

    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1) begin
        vn_result_core0[t][q] = 0;
        vn_result_core1[t][q] = 0;
        for (k = 0; k < pr; k = k+1) begin
          vn_result_core0[t][q] = vn_result_core0[t][q] + V_T[t][k] * N_est_core0[q][k];
          vn_result_core1[t][q] = vn_result_core1[t][q] + V_T[t][k] * N_est_core1[q][k];
        end
      end

    for (c = 0; c < col; c = c+1)
      golden_col[c] = 7 - c;

    #0; data_ready_flag = 1;

    wait(reset_done_c0_flag);
    reset = 0;

    wait(vn_reset_done_c0_flag);
    reset = 0;

    wait(vn_done_c0_flag && vn_done_c1_flag);

    $display("##### QK + VN verification complete, checking results #####");
    $display("------------------------------------------------------------");
    $display("  QK phase -- CORE0: %0d  CORE1: %0d mismatch(es)",
      mismatch_qk_core0, mismatch_qk_core1);
    $display("  VN phase -- CORE0: %0d  CORE1: %0d mismatch(es)",
      mismatch_vn_core0, mismatch_vn_core1);
    if (mismatch_qk_core0 == 0 && mismatch_qk_core1 == 0 &&
        mismatch_vn_core0 == 0 && mismatch_vn_core1 == 0) begin
      $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
      $display("------------------------------------------------------------");
    end else begin
      $display("  FAIL  QK:%0d + VN:%0d mismatches",
        mismatch_qk_core0 + mismatch_qk_core1, mismatch_vn_core0 + mismatch_vn_core1);
      $display("------------------------------------------------------------");
    end
    $display("");

    #10 $finish;
  end

  // ========== Initial 2: clk0 domain (drives reset multi-cycle) ==========
  initial begin
    while (!data_ready_flag) tick0;

    reset = 1;
    repeat(12) tick0;
    reset = 0;
    reset_done_c0_flag = 1;

    VN_mode_c0 = 1'b0;

    $display("##### Qmem writing (C0) #####");
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      qmem_wr_c0 = 1; qkmem_add_c0 = q0;
      mem_in_core0[1*bw-1:0*bw] = Q[q0][7]; mem_in_core0[2*bw-1:1*bw] = Q[q0][6];
      mem_in_core0[3*bw-1:2*bw] = Q[q0][5]; mem_in_core0[4*bw-1:3*bw] = Q[q0][4];
      mem_in_core0[5*bw-1:4*bw] = Q[q0][3]; mem_in_core0[6*bw-1:5*bw] = Q[q0][2];
      mem_in_core0[7*bw-1:6*bw] = Q[q0][1]; mem_in_core0[8*bw-1:7*bw] = Q[q0][0];
      tick0;
    end
    qmem_wr_c0 = 0; qkmem_add_c0 = 0; tick0;

    $display("##### Kmem writing (C0) #####");
    for (q0 = 0; q0 < col; q0 = q0+1) begin
      kmem_wr_c0 = 1; qkmem_add_c0 = q0;
      mem_in_core0[1*bw-1:0*bw] = K[q0][7]; mem_in_core0[2*bw-1:1*bw] = K[q0][6];
      mem_in_core0[3*bw-1:2*bw] = K[q0][5]; mem_in_core0[4*bw-1:3*bw] = K[q0][4];
      mem_in_core0[5*bw-1:4*bw] = K[q0][3]; mem_in_core0[6*bw-1:5*bw] = K[q0][2];
      mem_in_core0[7*bw-1:6*bw] = K[q0][1]; mem_in_core0[8*bw-1:7*bw] = K[q0][0];
      tick0;
    end
    kmem_wr_c0 = 0; qkmem_add_c0 = 0; tick0;
    repeat(2) tick0;

    $display("##### K data loading (C0) #####");
    for (q0 = 0; q0 < col+1; q0 = q0+1) begin
      load_c0 = 1;
      if (q0 == 1) kmem_rd_c0 = 1;
      if (q0 > 1) qkmem_add_c0 = qkmem_add_c0 + 1;
      tick0;
    end
    kmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    load_c0 = 0; tick0;
    repeat(10) tick0;

    $display("##### execute (C0) #####");
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      execute_c0 = 1; qmem_rd_c0 = 1; qkmem_add_c0 = q0;
      tick0;
    end
    execute_c0 = 0; qmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    repeat(10) tick0;

    $display("##### ofifo -> pmem (C0 QK) #####");
    for (q0 = 0; q0 < total_cycle+2; q0 = q0+1) begin
      ofifo_rd_c0 = 1; tick0;
    end
    ofifo_rd_c0 = 0; tick0;
    repeat(5) tick0;

    $display("##### QK phase verification (C0) #####");
    $display("QK phase verification start (checking pmem content)\n");
    $display("##### sample pmem content & compare to golden #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
    pmem_rd_c0 = 1; pmem_add_c0 = 4'd0; tick0;
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      row0 = q0;
      pmem_add_c0 = pmem_add_c0 + 1; tick0;
      $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row0,
        $signed(out[7*bw_psum+:bw_psum]), $signed(out[6*bw_psum+:bw_psum]),
        $signed(out[5*bw_psum+:bw_psum]), $signed(out[4*bw_psum+:bw_psum]),
        $signed(out[3*bw_psum+:bw_psum]), $signed(out[2*bw_psum+:bw_psum]),
        $signed(out[1*bw_psum+:bw_psum]), $signed(out[0*bw_psum+:bw_psum]));
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        result[row0][0], result[row0][1], result[row0][2], result[row0][3],
        result[row0][4], result[row0][5], result[row0][6], result[row0][7]);
      row_err0 = 0;
      for (c0 = 0; c0 < col; c0 = c0+1) begin
        if ($signed(out[c0*bw_psum+:bw_psum]) !== result[row0][7-c0]) begin
          $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c0,
            $signed(out[c0*bw_psum+:bw_psum]), result[row0][7-c0]);
          row_err0 = row_err0 + 1; mismatch_qk_core0 = mismatch_qk_core0 + 1;
        end
      end
      $display("       %s", (row_err0 == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end
    pmem_rd_c0 = 0; pmem_add_c0 = 0; tick0;
    $display("------------------------------------------------------------");
    if (mismatch_qk_core0 == 0)
      $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    else
      $display("  FAIL  %0d mismatches", mismatch_qk_core0);
    $display("------------------------------------------------------------");
    $display("");

    $display("##### SFP (C0) #####");
    ofifo_rd_c0 = 1; pmem_rd_c0 = 1;
    pmem_add_c0 = 0; qkmem_add_c0 = 0;

    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      if (q0 > 0) begin
        pmem_add_c0 = pmem_add_c0 + 1; qkmem_add_c0 = qkmem_add_c0 + 1;
      end

      tick0; tick0;

      acc_c0 = 1; tick0;
      acc_c0 = 0; tick0;

      tick0; tick0; tick0; tick0;

      // wait_guard0 = 0;
      // while (fifo1_empty !== 1'b0 && wait_guard0 < 32) begin
      while (fifo1_empty !== 1'b0) begin
        tick0;
        // wait_guard0 = wait_guard0 + 1;
      end

      div_c0 = 1; tick0;
      div_c0 = 0; tick0;

      kmem_wr_c0 = 1; tick0;
      kmem_wr_c0 = 0; tick0;

      // Wait for C0's FIFO (C0->C1) to drain before next row. Otherwise when
      // clk1<clk0, C0 writes row 0,1,2.. before C1 reads; C1 then waits for
      // fifo0_empty==1 but FIFO still has row1,2.. -> deadlock.
      while (fifo0_empty !== 1'b1) tick0;
    end

    ofifo_rd_c0 = 0; pmem_rd_c0 = 0; acc_c0 = 0; div_c0 = 0;
    kmem_wr_c0 = 0; qkmem_add_c0 = 0; pmem_add_c0 = 0; tick0;
    repeat(10) tick0;

    VN_mode_c0 = 1'b1;
    reset = 1;
    repeat(12) tick0;
    reset = 0;
    vn_reset_done_c0_flag = 1;
    repeat(2) tick0;

    $display("##### Qmem writing V (C0) #####");
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      qmem_wr_c0 = 1; qkmem_add_c0 = q0;
      mem_in_core0[1*bw-1:0*bw] = V_T[q0][7]; mem_in_core0[2*bw-1:1*bw] = V_T[q0][6];
      mem_in_core0[3*bw-1:2*bw] = V_T[q0][5]; mem_in_core0[4*bw-1:3*bw] = V_T[q0][4];
      mem_in_core0[5*bw-1:4*bw] = V_T[q0][3]; mem_in_core0[6*bw-1:5*bw] = V_T[q0][2];
      mem_in_core0[7*bw-1:6*bw] = V_T[q0][1]; mem_in_core0[8*bw-1:7*bw] = V_T[q0][0];
      tick0;
    end
    qmem_wr_c0 = 0; qkmem_add_c0 = 0; tick0;
    repeat(2) tick0;

    $display("##### N loading (C0) #####");
    for (q0 = 0; q0 < col+1; q0 = q0+1) begin
      load_c0 = 1;
      if (q0 == 1) kmem_rd_c0 = 1;
      if (q0 > 1) qkmem_add_c0 = qkmem_add_c0 + 1;
      tick0;
    end
    kmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    load_c0 = 0; tick0;
    repeat(10) tick0;

    $display("##### VN execute (C0) #####");
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      execute_c0 = 1; qmem_rd_c0 = 1; qkmem_add_c0 = q0; tick0;
    end
    execute_c0 = 0; qmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    repeat(10) tick0;

    $display("##### ofifo -> pmem (C0 VN) #####");
    for (q0 = 0; q0 < total_cycle+2; q0 = q0+1) begin
      ofifo_rd_c0 = 1; tick0;
    end
    ofifo_rd_c0 = 0; tick0;
    repeat(5) tick0;

    $display("##### VN phase verification (C0) #####");
    $display("VN phase verification start (checking pmem content)\n");
    $display("##### sample pmem content & compare to golden #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
    pmem_rd_c0 = 1; pmem_add_c0 = 4'd0; tick0;
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      row0 = q0;
      pmem_add_c0 = pmem_add_c0 + 1; tick0;
      $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row0,
        $signed(out[7*bw_psum+:bw_psum]), $signed(out[6*bw_psum+:bw_psum]),
        $signed(out[5*bw_psum+:bw_psum]), $signed(out[4*bw_psum+:bw_psum]),
        $signed(out[3*bw_psum+:bw_psum]), $signed(out[2*bw_psum+:bw_psum]),
        $signed(out[1*bw_psum+:bw_psum]), $signed(out[0*bw_psum+:bw_psum]));
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_core0[row0][0], vn_result_core0[row0][1], vn_result_core0[row0][2], vn_result_core0[row0][3],
        vn_result_core0[row0][4], vn_result_core0[row0][5], vn_result_core0[row0][6], vn_result_core0[row0][7]);
      row_err0 = 0;
      for (c0 = 0; c0 < col; c0 = c0+1) begin
        if ($signed(out[c0*bw_psum+:bw_psum]) !== vn_result_core0[row0][golden_col[c0]]) begin
          $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c0,
            $signed(out[c0*bw_psum+:bw_psum]), vn_result_core0[row0][golden_col[c0]]);
          row_err0 = row_err0 + 1; mismatch_vn_core0 = mismatch_vn_core0 + 1;
        end
      end
      $display("       %s", (row_err0 == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end
    pmem_rd_c0 = 0; pmem_add_c0 = 0; tick0;
    $display("------------------------------------------------------------");
    if (mismatch_vn_core0 == 0)
      $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    else
      $display("  FAIL  %0d mismatches", mismatch_vn_core0);
    $display("------------------------------------------------------------");
    $display("");

    vn_done_c0_flag = 1;
    // Keep clk0 toggling until $finish (in case C1 finishes later)
    while (1) tick0;
  end

  // ========== Initial 3: clk1 domain (waits for reset deassert) ==========
  initial begin
    while (!data_ready_flag) tick1;
    while (!reset_done_c0_flag) tick1;

    VN_mode_c1 = 1'b0;

    $display("##### Qmem writing (C1) #####");
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      qmem_wr_c1 = 1; qkmem_add_c1 = q1;
      mem_in_core1[1*bw-1:0*bw] = Q[q1][7]; mem_in_core1[2*bw-1:1*bw] = Q[q1][6];
      mem_in_core1[3*bw-1:2*bw] = Q[q1][5]; mem_in_core1[4*bw-1:3*bw] = Q[q1][4];
      mem_in_core1[5*bw-1:4*bw] = Q[q1][3]; mem_in_core1[6*bw-1:5*bw] = Q[q1][2];
      mem_in_core1[7*bw-1:6*bw] = Q[q1][1]; mem_in_core1[8*bw-1:7*bw] = Q[q1][0];
      tick1;
    end
    qmem_wr_c1 = 0; qkmem_add_c1 = 0; tick1;

    $display("##### Kmem writing (C1) #####");
    for (q1 = 0; q1 < col; q1 = q1+1) begin
      kmem_wr_c1 = 1; qkmem_add_c1 = q1;
      mem_in_core1[1*bw-1:0*bw] = K[q1+col][7]; mem_in_core1[2*bw-1:1*bw] = K[q1+col][6];
      mem_in_core1[3*bw-1:2*bw] = K[q1+col][5]; mem_in_core1[4*bw-1:3*bw] = K[q1+col][4];
      mem_in_core1[5*bw-1:4*bw] = K[q1+col][3]; mem_in_core1[6*bw-1:5*bw] = K[q1+col][2];
      mem_in_core1[7*bw-1:6*bw] = K[q1+col][1]; mem_in_core1[8*bw-1:7*bw] = K[q1+col][0];
      tick1;
    end
    kmem_wr_c1 = 0; qkmem_add_c1 = 0; tick1;
    repeat(2) tick1;

    $display("##### K data loading (C1) #####");
    for (q1 = 0; q1 < col+1; q1 = q1+1) begin
      load_c1 = 1;
      if (q1 == 1) kmem_rd_c1 = 1;
      if (q1 > 1) qkmem_add_c1 = qkmem_add_c1 + 1;
      tick1;
    end
    kmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    load_c1 = 0; tick1;
    repeat(10) tick1;

    $display("##### execute (C1) #####");
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      execute_c1 = 1; qmem_rd_c1 = 1; qkmem_add_c1 = q1;
      tick1;
    end
    execute_c1 = 0; qmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    repeat(10) tick1;

    $display("##### ofifo -> pmem (C1 QK) #####");
    for (q1 = 0; q1 < total_cycle+2; q1 = q1+1) begin
      ofifo_rd_c1 = 1; tick1;
    end
    ofifo_rd_c1 = 0; tick1;
    repeat(5) tick1;

    $display("##### QK phase verification (C1) #####");
    $display("QK phase verification start (checking pmem content)\n");
    $display("##### sample pmem content & compare to golden #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
    pmem_rd_c1 = 1; pmem_add_c1 = 4'd0; tick1;
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      row1 = q1;
      pmem_add_c1 = pmem_add_c1 + 1; tick1;
      $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row1,
        $signed(out[col*bw_psum+7*bw_psum+:bw_psum]), $signed(out[col*bw_psum+6*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+5*bw_psum+:bw_psum]), $signed(out[col*bw_psum+4*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+3*bw_psum+:bw_psum]), $signed(out[col*bw_psum+2*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+1*bw_psum+:bw_psum]), $signed(out[col*bw_psum+0*bw_psum+:bw_psum]));
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        result[row1][col+0], result[row1][col+1], result[row1][col+2], result[row1][col+3],
        result[row1][col+4], result[row1][col+5], result[row1][col+6], result[row1][col+7]);
      row_err1 = 0;
      for (c1 = 0; c1 < col; c1 = c1+1) begin
        if ($signed(out[col*bw_psum+c1*bw_psum+:bw_psum]) !== result[row1][col+7-c1]) begin
          $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c1,
            $signed(out[col*bw_psum+c1*bw_psum+:bw_psum]), result[row1][col+7-c1]);
          row_err1 = row_err1 + 1; mismatch_qk_core1 = mismatch_qk_core1 + 1;
        end
      end
      $display("       %s", (row_err1 == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end
    pmem_rd_c1 = 0; pmem_add_c1 = 0; tick1;
    $display("------------------------------------------------------------");
    if (mismatch_qk_core1 == 0)
      $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    else
      $display("  FAIL  %0d mismatches", mismatch_qk_core1);
    $display("------------------------------------------------------------");
    $display("");

    $display("##### SFP (C1) #####");
    ofifo_rd_c1 = 1; pmem_rd_c1 = 1;
    pmem_add_c1 = 0; qkmem_add_c1 = 0;

    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      if (q1 > 0) begin
        pmem_add_c1 = pmem_add_c1 + 1; qkmem_add_c1 = qkmem_add_c1 + 1;
      end

      tick1; tick1;

      acc_c1 = 1; tick1;
      acc_c1 = 0; tick1;

      tick1; tick1; tick1; tick1;

      // wait_guard1 = 0;
      // while (fifo0_empty !== 1'b0 && wait_guard1 < 64) begin
      while (fifo0_empty !== 1'b0) begin
        tick1;
        // wait_guard1 = wait_guard1 + 1;
      end

      // Extra margin for C1: when clk1>clk0, sample-and-hold (sfp_sum_in_1) needs
      // time to capture C0's sum from async FIFO. 6 tick1s ensure path settled.
      tick1; tick1; tick1; tick1;

      div_c1 = 1; tick1;
      div_c1 = 0; tick1;

      kmem_wr_c1 = 1; tick1;
      kmem_wr_c1 = 0; tick1;

      // wait_guard1 = 0;
      // while (fifo0_empty !== 1'b1 && wait_guard1 < 64) begin
      while (fifo0_empty !== 1'b1) begin
        tick1;
        // wait_guard1 = wait_guard1 + 1;
      end
    end

    ofifo_rd_c1 = 0; pmem_rd_c1 = 0; acc_c1 = 0; div_c1 = 0;
    kmem_wr_c1 = 0; qkmem_add_c1 = 0; pmem_add_c1 = 0; tick1;
    repeat(10) tick1;

    while (!vn_reset_done_c0_flag) tick1;  // wait for C0 to complete VN reset before starting VN

    VN_mode_c1 = 1'b1;

    $display("##### Qmem writing V (C1) #####");
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      qmem_wr_c1 = 1; qkmem_add_c1 = q1;
      mem_in_core1[1*bw-1:0*bw] = V_T[q1][7]; mem_in_core1[2*bw-1:1*bw] = V_T[q1][6];
      mem_in_core1[3*bw-1:2*bw] = V_T[q1][5]; mem_in_core1[4*bw-1:3*bw] = V_T[q1][4];
      mem_in_core1[5*bw-1:4*bw] = V_T[q1][3]; mem_in_core1[6*bw-1:5*bw] = V_T[q1][2];
      mem_in_core1[7*bw-1:6*bw] = V_T[q1][1]; mem_in_core1[8*bw-1:7*bw] = V_T[q1][0];
      tick1;
    end
    qmem_wr_c1 = 0; qkmem_add_c1 = 0; tick1;
    repeat(2) tick1;

    $display("##### N loading (C1) #####");
    for (q1 = 0; q1 < col+1; q1 = q1+1) begin
      load_c1 = 1;
      if (q1 == 1) kmem_rd_c1 = 1;
      if (q1 > 1) qkmem_add_c1 = qkmem_add_c1 + 1;
      tick1;
    end
    kmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    load_c1 = 0; tick1;
    repeat(10) tick1;

    $display("##### VN execute (C1) #####");
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      execute_c1 = 1; qmem_rd_c1 = 1; qkmem_add_c1 = q1; tick1;
    end
    execute_c1 = 0; qmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    repeat(10) tick1;

    $display("##### ofifo -> pmem (C1 VN) #####");
    for (q1 = 0; q1 < total_cycle+2; q1 = q1+1) begin
      ofifo_rd_c1 = 1; tick1;
    end
    ofifo_rd_c1 = 0; tick1;
    repeat(5) tick1;

    $display("##### VN phase verification (C1) #####");
    $display("VN phase verification start (checking pmem content)\n");
    $display("##### sample pmem content & compare to golden #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
    pmem_rd_c1 = 1; pmem_add_c1 = 4'd0; tick1;
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      row1 = q1;
      pmem_add_c1 = pmem_add_c1 + 1; tick1;
      $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row1,
        $signed(out[col*bw_psum+7*bw_psum+:bw_psum]), $signed(out[col*bw_psum+6*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+5*bw_psum+:bw_psum]), $signed(out[col*bw_psum+4*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+3*bw_psum+:bw_psum]), $signed(out[col*bw_psum+2*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+1*bw_psum+:bw_psum]), $signed(out[col*bw_psum+0*bw_psum+:bw_psum]));
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_core1[row1][0], vn_result_core1[row1][1], vn_result_core1[row1][2], vn_result_core1[row1][3],
        vn_result_core1[row1][4], vn_result_core1[row1][5], vn_result_core1[row1][6], vn_result_core1[row1][7]);
      row_err1 = 0;
      for (c1 = 0; c1 < col; c1 = c1+1) begin
        if ($signed(out[col*bw_psum+c1*bw_psum+:bw_psum]) !== vn_result_core1[row1][golden_col[c1]]) begin
          $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c1,
            $signed(out[col*bw_psum+c1*bw_psum+:bw_psum]), vn_result_core1[row1][golden_col[c1]]);
          row_err1 = row_err1 + 1; mismatch_vn_core1 = mismatch_vn_core1 + 1;
        end
      end
      $display("       %s", (row_err1 == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end
    pmem_rd_c1 = 0; pmem_add_c1 = 0; tick1;
    $display("------------------------------------------------------------");
    if (mismatch_vn_core1 == 0)
      $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    else
      $display("  FAIL  %0d mismatches", mismatch_vn_core1);
    $display("------------------------------------------------------------");
    $display("");

    vn_done_c1_flag = 1;
    // Keep clk1 toggling until $finish (in case C0 finishes later)
    while (1) tick1;
  end

endmodule
