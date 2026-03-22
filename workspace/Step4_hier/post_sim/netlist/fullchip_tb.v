// fullchip_tb.v
// Post-PnR GLS testbench — fullchip_tb.v:
//

`timescale 1ns/1ps

module fullchip_tb;

  parameter total_cycle   = 8;
  parameter bw            = 8;
  parameter bw_psum       = 2*bw+4;       // 20
  parameter pr            = 8;
  parameter col           = 8;
  parameter sfp_out_shift = 7;

  // Timeout guard limits — increase if simulation is legitimately slow
  parameter FIFO_TIMEOUT  = 500;          // ticks before declaring CDC deadlock

  integer qk_file, qk_scan_file, captured_data;
  integer K        [2*col-1:0][pr-1:0];
  integer Q        [total_cycle-1:0][pr-1:0];
  integer V_T      [total_cycle-1:0][pr-1:0];

  reg signed [bw_psum-1:0]   result      [total_cycle-1:0][2*col-1:0];
  reg signed [bw_psum-1:0]   abs_result  [total_cycle-1:0][2*col-1:0];
  reg signed [bw_psum+4-1:0] sum_core0   [total_cycle-1:0];
  reg signed [bw_psum+4-1:0] sum_core1   [total_cycle-1:0];
  integer N_est_core0    [total_cycle-1:0][col-1:0];
  integer N_est_core1    [total_cycle-1:0][col-1:0];
  integer vn_result_core0[total_cycle-1:0][col-1:0];
  integer vn_result_core1[total_cycle-1:0][col-1:0];

  integer mismatch_qk_core0, mismatch_qk_core1;
  integer mismatch_vn_core0, mismatch_vn_core1;

  integer j, k, t, q, c;
  integer golden_col [0:7];
  integer q0, q1, row0, row1, c0, c1, row_err0, row_err1;
  integer guard0, guard1;                 

  reg [bw_psum-1:0]     temp5b;
  reg [bw_psum*col-1:0] temp16b;

  
  // Flags set by Initial 2; arbiter drives `reset` accordingly.
  reg data_ready_flag       = 0;
  reg do_qk_reset           = 0;   // pulse: Initial 2 requests QK reset
  reg qk_reset_done_flag    = 0;   // ack back to Initial 2
  reg do_vn_reset           = 0;   // pulse: Initial 2 requests VN reset
  reg vn_reset_done_flag    = 0;   // ack back to Initial 2
  // C1 sets this after QK verify + SFP acc so C0 SFP knows C1's sum is ready
  reg c1_qk_done_flag       = 0;
  reg vn_done_c0_flag       = 0;
  reg vn_done_c1_flag       = 0;

  // Per-row SFP handshake:
  //   c0_sfp_wrote[r] = C0 has written row r's sum into fifo0 (C0->C1)
  //   c1_sfp_wrote[r] = C1 has written row r's sum into fifo1 (C1->C0)
  // This enforces the protocol: C0 writes first each row, C1 follows.
  reg [total_cycle-1:0] c0_sfp_wrote = 0;
  reg [total_cycle-1:0] c1_sfp_wrote = 0;

  reg reset = 1;                   // single driver

  // Reset arbiter: one always block owns reset, responds to request flags
  always @(*) begin
    if (do_qk_reset || do_vn_reset)
      reset = 1;
    else
      reset = 0;
  end

  // ── Clocks ────────────────────────────────────────────────────────────────
  reg clk0 = 0;
  reg clk1 = 0;

  // clk0: 1ns period (matches SDC clk0_period = 1.0)
  task tick0; begin #0.5 clk0=1'b0; #0.5 clk0=1'b1; end endtask


  task tick1; begin
    #3.14159265358979323846 clk1=1'b0;
    #3.14159265358979323846 clk1=1'b1;
  end endtask

  // ── DUT ports ─────────────────────────────────────────────────────────────
  wire [2*col*bw_psum-1:0] out;

  reg  [pr*bw-1:0] mem_in_core0;
  reg  [pr*bw-1:0] mem_in_core1;

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

  wire fifo0_empty, fifo1_empty;

  fullchip fullchip_instance (
    .reset0(reset),
    .reset1(reset),
    .clk0(clk0),
    .clk1(clk1),
    .mem_in0(mem_in_core0),
    .mem_in1(mem_in_core1),
    .inst0(inst0),
    .inst1(inst1),
    .out0(out[bw_psum*col-1:0]),
    .out1(out[2*bw_psum*col-1:bw_psum*col]),
    .fifo0_empty(fifo0_empty),
    .fifo1_empty(fifo1_empty)
  );

  // =========================================================================
  // Initial 1: Data loading + golden computation (pure software, no timing)
  // =========================================================================
  initial begin
    $dumpfile("../gls/waveform/fullchip_sepclk.vcd");
    $dumpvars(0, fullchip_sepclk_tb);

    mismatch_qk_core0 = 0; mismatch_qk_core1 = 0;
    mismatch_vn_core0 = 0; mismatch_vn_core1 = 0;

    $display("##### Q data reading #####");
    qk_file = $fopen("../sim/pattern/qdata.txt", "r");
    if (qk_file == 0) begin $display("ERROR: cannot open qdata.txt"); $finish; end
    for (q = 0; q < total_cycle; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end
    $fclose(qk_file);

    $display("##### K data reading #####");
    qk_file = $fopen("../sim/pattern/kdata_dual.txt", "r");
    if (qk_file == 0) begin $display("ERROR: cannot open kdata_dual.txt"); $finish; end
    for (q = 0; q < 2*col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end
    $fclose(qk_file);

    $display("##### V data reading #####");
    qk_file = $fopen("../sim/pattern/vdata.txt", "r");
    if (qk_file == 0) begin $display("ERROR: cannot open vdata.txt"); $finish; end
    for (q = 0; q < col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        V_T[j][q] = captured_data;
      end
    $fclose(qk_file);

    // ── Golden QK (core0: K[0..7], core1: K[8..15]) ──
    for (t = 0; t < total_cycle; t = t+1) begin
      for (q = 0; q < 2*col; q = q+1) begin
        result[t][q] = 0;
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];
      end
    end

    // ── Golden SFP sums ──
    for (t = 0; t < total_cycle; t = t+1) begin
      sum_core0[t] = 0; sum_core1[t] = 0;
      for (q = 0; q < col; q = q+1) begin
        abs_result[t][q]     = (result[t][q]     >= 0) ? result[t][q]     : -result[t][q];
        abs_result[t][col+q] = (result[t][col+q] >= 0) ? result[t][col+q] : -result[t][col+q];
        sum_core0[t] = sum_core0[t] + abs_result[t][q];
        sum_core1[t] = sum_core1[t] + abs_result[t][col+q];
      end
    end

    // ── Golden N (normalized attention) ──
    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1) begin
        N_est_core0[t][q] = (abs_result[t][q]     << sfp_out_shift)
                             / (sum_core0[t] + sum_core1[t]);
        N_est_core1[t][q] = (abs_result[t][col+q] << sfp_out_shift)
                             / (sum_core0[t] + sum_core1[t]);
      end

    // ── Golden VN ──
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

    // Wait for both cores to finish VN before printing final summary
    wait(vn_done_c0_flag && vn_done_c1_flag);

    $display("############################################################");
    $display("  FINAL SUMMARY");
    $display("  QK  -- CORE0: %0d  CORE1: %0d mismatch(es)",
      mismatch_qk_core0, mismatch_qk_core1);
    $display("  VN  -- CORE0: %0d  CORE1: %0d mismatch(es)",
      mismatch_vn_core0, mismatch_vn_core1);
    if (mismatch_qk_core0 == 0 && mismatch_qk_core1 == 0 &&
        mismatch_vn_core0 == 0 && mismatch_vn_core1 == 0)
      $display("  PASS  %0d rows x %0d cols  all correct", total_cycle, col);
    else
      $display("  FAIL  QK:%0d  VN:%0d total mismatches",
        mismatch_qk_core0 + mismatch_qk_core1,
        mismatch_vn_core0 + mismatch_vn_core1);
    $display("############################################################");

    #10 $finish;
  end

  // =========================================================================
  // Initial 2: clk0 domain — QK, SFP, VN for core0
  // =========================================================================
  initial begin
    while (!data_ready_flag) tick0;

    // ── QK reset (FIX 3: set flag, arbiter drives reset) ──
    do_qk_reset = 1;
    repeat(12) tick0;
    do_qk_reset = 0;
    qk_reset_done_flag = 1;         // signal Initial 3 that reset is done
    VN_mode_c0 = 1'b0;

    // ── Write Q to qmem ──
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

    // ── Write K to kmem ──
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

    // ── Load K into MAC columns ──
    $display("##### K loading (C0) #####");
    for (q0 = 0; q0 < col+1; q0 = q0+1) begin
      load_c0 = 1;
      if (q0 == 1) kmem_rd_c0 = 1;
      if (q0 > 1)  qkmem_add_c0 = qkmem_add_c0 + 1;
      tick0;
    end
    kmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    load_c0 = 0; tick0;
    repeat(10) tick0;

    // ── Execute QK ──
    $display("##### Execute QK (C0) #####");
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      execute_c0 = 1; qmem_rd_c0 = 1; qkmem_add_c0 = q0; tick0;
    end
    execute_c0 = 0; qmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    repeat(10) tick0;

    // ── Drain ofifo → pmem ──
    $display("##### ofifo -> pmem (C0 QK) #####");
    for (q0 = 0; q0 < total_cycle+2; q0 = q0+1) begin
      ofifo_rd_c0 = 1; tick0;
    end
    ofifo_rd_c0 = 0; tick0;
    repeat(5) tick0;

    // pmem is synchronous-read: set pmem_rd+pmem_add, tick (posedge latches
    // address), then sample out after 50ps settling.
    // Address walks 0..7 — increment AFTER capture so row0 reads addr 0.
    $display("##### QK verification (C0) #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    pmem_rd_c0 = 1; pmem_add_c0 = 4'd0;
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      row0 = q0;
      tick0;          // posedge: pmem reads current pmem_add
      #0.05;          // 50ps settling for 20ps UDP + output path
      $display("   [%0d]  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row0,
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
      pmem_add_c0 = pmem_add_c0 + 1;  // advance address AFTER capture
    end
    pmem_rd_c0 = 0; pmem_add_c0 = 0; tick0;
    $display("--- C0 QK: %0d mismatch(es) ---", mismatch_qk_core0);

    // C0 SFP needs C1's QK sum to arrive via async FIFO.
    // Wait until C1 has finished its QK execute+drain and asserted c1_qk_done_flag.
    while (!c1_qk_done_flag) tick0;

    // ── SFP phase (C0) ──
    // Protocol per row:
    //   1. C0 acc + write sum to fifo0 (C0->C1)  → set c0_sfp_wrote[row]
    //   2. C1 sees c0_sfp_wrote, acc + write sum to fifo1 (C1->C0)  → set c1_sfp_wrote[row]
    //   3. C0 waits for c1_sfp_wrote[row], then div (uses both sums)
    // This strict ordering prevents the deadlock where both cores wait simultaneously.
    $display("##### SFP (C0) #####");
    ofifo_rd_c0 = 1; pmem_rd_c0 = 1;
    pmem_add_c0 = 0; qkmem_add_c0 = 0;

    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      if (q0 > 0) begin
        pmem_add_c0  = pmem_add_c0  + 1;
        qkmem_add_c0 = qkmem_add_c0 + 1;
      end
      tick0; tick0;

      // Step 1: accumulate C0's partial sum from pmem
      acc_c0 = 1; tick0;
      acc_c0 = 0; tick0;
      tick0; tick0; tick0; tick0;

      // Step 2: signal C1 that C0 is ready — C1 can now acc and push its sum
      // (C0 has not yet pushed to fifo0; we signal intent so C1 starts in parallel)
      c0_sfp_wrote[q0] = 1;

      // Step 3: wait for C1 to have pushed its sum into fifo1 (C1->C0)
      guard0 = 0;
      while (!c1_sfp_wrote[q0] && guard0 < FIFO_TIMEOUT) begin
        tick0; guard0 = guard0 + 1;
      end
      if (guard0 >= FIFO_TIMEOUT) begin
        $display("TIMEOUT (C0 SFP row %0d): c1_sfp_wrote never set.", q0);
        $finish;
      end

      // Step 4: wait for C1's sum to physically appear in fifo1 (CDC latency)
      guard0 = 0;
      while (fifo1_empty !== 1'b0 && guard0 < FIFO_TIMEOUT) begin
        tick0; guard0 = guard0 + 1;
      end
      if (guard0 >= FIFO_TIMEOUT) begin
        $display("TIMEOUT (C0 SFP row %0d): fifo1_empty never went low.", q0);
        $finish;
      end

      // Step 5: NOW div — sfp_sum_in_0 has latched C1's sum, denominator is correct
      // div also pushes C0's accumulated sum into fifo0 (C0->C1)
      div_c0 = 1; tick0;
      div_c0 = 0; tick0;

      // Step 6: store computed N into kmem
      kmem_wr_c0 = 1; tick0;
      kmem_wr_c0 = 0; tick0;

      // Wait for fifo0 (C0->C1) to drain before next row to avoid overflow
      guard0 = 0;
      while (fifo0_empty !== 1'b1 && guard0 < FIFO_TIMEOUT) begin
        tick0; guard0 = guard0 + 1;
      end
      if (guard0 >= FIFO_TIMEOUT) begin
        $display("TIMEOUT (C0 SFP drain row %0d): fifo0_empty never went high.", q0);
        $finish;
      end
    end

    ofifo_rd_c0 = 0; pmem_rd_c0 = 0; acc_c0 = 0; div_c0 = 0;
    kmem_wr_c0 = 0; qkmem_add_c0 = 0; pmem_add_c0 = 0; tick0;
    repeat(10) tick0;

    // ── VN reset ──
    VN_mode_c0 = 1'b1;
    do_vn_reset = 1;
    repeat(12) tick0;
    do_vn_reset = 0;
    vn_reset_done_flag = 1;
    repeat(2) tick0;

    // ── Write V to qmem ──
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

    // ── Load N into MAC columns ──
    $display("##### N loading (C0) #####");
    for (q0 = 0; q0 < col+1; q0 = q0+1) begin
      load_c0 = 1;
      if (q0 == 1) kmem_rd_c0 = 1;
      if (q0 > 1)  qkmem_add_c0 = qkmem_add_c0 + 1;
      tick0;
    end
    kmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    load_c0 = 0; tick0;
    repeat(10) tick0;

    // ── Execute VN ──
    $display("##### VN execute (C0) #####");
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      execute_c0 = 1; qmem_rd_c0 = 1; qkmem_add_c0 = q0; tick0;
    end
    execute_c0 = 0; qmem_rd_c0 = 0; qkmem_add_c0 = 0; tick0;
    repeat(10) tick0;

    // ── Drain ofifo → pmem ──
    $display("##### ofifo -> pmem (C0 VN) #####");
    for (q0 = 0; q0 < total_cycle+2; q0 = q0+1) begin
      ofifo_rd_c0 = 1; tick0;
    end
    ofifo_rd_c0 = 0; tick0;
    repeat(5) tick0;

    // ── VN verification (C0) ──
    $display("##### VN verification (C0) #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    pmem_rd_c0 = 1; pmem_add_c0 = 4'd0;
    for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
      row0 = q0;
      tick0;
      #0.05; // FIX 4: 50ps settling
      $display("   [%0d]  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row0,
        $signed(out[7*bw_psum+:bw_psum]), $signed(out[6*bw_psum+:bw_psum]),
        $signed(out[5*bw_psum+:bw_psum]), $signed(out[4*bw_psum+:bw_psum]),
        $signed(out[3*bw_psum+:bw_psum]), $signed(out[2*bw_psum+:bw_psum]),
        $signed(out[1*bw_psum+:bw_psum]), $signed(out[0*bw_psum+:bw_psum]));
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_core0[row0][0], vn_result_core0[row0][1],
        vn_result_core0[row0][2], vn_result_core0[row0][3],
        vn_result_core0[row0][4], vn_result_core0[row0][5],
        vn_result_core0[row0][6], vn_result_core0[row0][7]);
      row_err0 = 0;
      for (c0 = 0; c0 < col; c0 = c0+1) begin
        if ($signed(out[c0*bw_psum+:bw_psum]) !== vn_result_core0[row0][golden_col[c0]]) begin
          $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c0,
            $signed(out[c0*bw_psum+:bw_psum]), vn_result_core0[row0][golden_col[c0]]);
          row_err0 = row_err0 + 1; mismatch_vn_core0 = mismatch_vn_core0 + 1;
        end
      end
      $display("       %s", (row_err0 == 0) ? "[OK]" : "[MISMATCH]");
      pmem_add_c0 = pmem_add_c0 + 1;
    end
    pmem_rd_c0 = 0; pmem_add_c0 = 0; tick0;
    $display("--- C0 VN: %0d mismatch(es) ---", mismatch_vn_core0);

    vn_done_c0_flag = 1;
    while (1) tick0;   // keep clk0 alive until $finish from Initial 1
  end

  // =========================================================================
  // Initial 3: clk1 domain — QK, SFP, VN for core1
  // =========================================================================
  initial begin
    while (!data_ready_flag)      tick1;
    while (!qk_reset_done_flag)   tick1;  // wait for C0 to finish QK reset

    VN_mode_c1 = 1'b0;

    // ── Write Q to qmem ──
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

    // ── Write K (second half: rows 8–15) to kmem ──
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

    // ── Load K into MAC columns ──
    $display("##### K loading (C1) #####");
    for (q1 = 0; q1 < col+1; q1 = q1+1) begin
      load_c1 = 1;
      if (q1 == 1) kmem_rd_c1 = 1;
      if (q1 > 1)  qkmem_add_c1 = qkmem_add_c1 + 1;
      tick1;
    end
    kmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    load_c1 = 0; tick1;
    repeat(10) tick1;

    // ── Execute QK ──
    $display("##### Execute QK (C1) #####");
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      execute_c1 = 1; qmem_rd_c1 = 1; qkmem_add_c1 = q1; tick1;
    end
    execute_c1 = 0; qmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    repeat(10) tick1;

    // ── Drain ofifo → pmem ──
    $display("##### ofifo -> pmem (C1 QK) #####");
    for (q1 = 0; q1 < total_cycle+2; q1 = q1+1) begin
      ofifo_rd_c1 = 1; tick1;
    end
    ofifo_rd_c1 = 0; tick1;
    repeat(5) tick1;

    // ── QK verification (C1) ──
    $display("##### QK verification (C1) #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    pmem_rd_c1 = 1; pmem_add_c1 = 4'd0;
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      row1 = q1;
      tick1;
      #0.05; // FIX 4: 50ps settling
      $display("   [%0d]  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row1,
        $signed(out[col*bw_psum+7*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+6*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+5*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+4*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+3*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+2*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+1*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+0*bw_psum+:bw_psum]));
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
      pmem_add_c1 = pmem_add_c1 + 1;
    end
    pmem_rd_c1 = 0; pmem_add_c1 = 0; tick1;
    $display("--- C1 QK: %0d mismatch(es) ---", mismatch_qk_core1);

    // Signal C0 that C1's QK sum is now accumulated and ready in the async FIFO
    c1_qk_done_flag = 1;

    // ── SFP phase (C1) ──
    // C1 follows C0's lead each row:
    //   wait for c0_sfp_wrote[row] → acc → write sum to fifo1 → set c1_sfp_wrote[row]
    $display("##### SFP (C1) #####");
    ofifo_rd_c1 = 1; pmem_rd_c1 = 1;
    pmem_add_c1 = 0; qkmem_add_c1 = 0;

    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      if (q1 > 0) begin
        pmem_add_c1  = pmem_add_c1  + 1;
        qkmem_add_c1 = qkmem_add_c1 + 1;
      end

      // Wait for C0 to signal it has accumulated (c0_sfp_wrote means C0 is ready)
      guard1 = 0;
      while (!c0_sfp_wrote[q1] && guard1 < FIFO_TIMEOUT) begin
        tick1; guard1 = guard1 + 1;
      end
      if (guard1 >= FIFO_TIMEOUT) begin
        $display("TIMEOUT (C1 SFP row %0d): c0_sfp_wrote never set.", q1);
        $finish;
      end

      tick1; tick1;

      // Accumulate C1's partial sum
      acc_c1 = 1; tick1;
      acc_c1 = 0; tick1;
      tick1; tick1; tick1; tick1;

      // Wait for C0's sum to arrive physically in fifo0 (C0->C1)
      guard1 = 0;
      while (fifo0_empty !== 1'b0 && guard1 < FIFO_TIMEOUT) begin
        tick1; guard1 = guard1 + 1;
      end
      if (guard1 >= FIFO_TIMEOUT) begin
        $display("TIMEOUT (C1 SFP row %0d): fifo0_empty never went low.", q1);
        $finish;
      end

      // Extra margin: sfp_sum_in_1 sample-and-hold needs clk1 edges to latch C0's sum
      tick1; tick1; tick1; tick1;

      // div: sfp_sum_in_1 now holds C0's sum; denominator = sum_C1 + sum_C0 (correct)
      // Also pushes C1's accumulated sum into fifo1 (C1->C0)
      div_c1 = 1; tick1;
      div_c1 = 0; tick1;

      // Signal C0 that C1's sum is now in fifo1 and div has fired with correct denom
      c1_sfp_wrote[q1] = 1;

      // Store N into kmem
      kmem_wr_c1 = 1; tick1;
      kmem_wr_c1 = 0; tick1;

      // Wait for fifo1 (C1->C0) to drain before next row to avoid overflow
      guard1 = 0;
      while (fifo1_empty !== 1'b1 && guard1 < FIFO_TIMEOUT) begin
        tick1; guard1 = guard1 + 1;
      end
      if (guard1 >= FIFO_TIMEOUT) begin
        $display("TIMEOUT (C1 SFP drain row %0d): fifo1_empty never went high.", q1);
        $finish;
      end
    end

    ofifo_rd_c1 = 0; pmem_rd_c1 = 0; acc_c1 = 0; div_c1 = 0;
    kmem_wr_c1 = 0; qkmem_add_c1 = 0; pmem_add_c1 = 0; tick1;
    repeat(10) tick1;

    // Wait for C0 to assert VN reset before C1 starts VN
    while (!vn_reset_done_flag) tick1;
    VN_mode_c1 = 1'b1;

    // ── Write V to qmem ──
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

    // ── Load N into MAC columns ──
    $display("##### N loading (C1) #####");
    for (q1 = 0; q1 < col+1; q1 = q1+1) begin
      load_c1 = 1;
      if (q1 == 1) kmem_rd_c1 = 1;
      if (q1 > 1)  qkmem_add_c1 = qkmem_add_c1 + 1;
      tick1;
    end
    kmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    load_c1 = 0; tick1;
    repeat(10) tick1;

    // ── Execute VN ──
    $display("##### VN execute (C1) #####");
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      execute_c1 = 1; qmem_rd_c1 = 1; qkmem_add_c1 = q1; tick1;
    end
    execute_c1 = 0; qmem_rd_c1 = 0; qkmem_add_c1 = 0; tick1;
    repeat(10) tick1;

    // ── Drain ofifo → pmem ──
    $display("##### ofifo -> pmem (C1 VN) #####");
    for (q1 = 0; q1 < total_cycle+2; q1 = q1+1) begin
      ofifo_rd_c1 = 1; tick1;
    end
    ofifo_rd_c1 = 0; tick1;
    repeat(5) tick1;

    // ── VN verification (C1) ──
    $display("##### VN verification (C1) #####");
    $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
    pmem_rd_c1 = 1; pmem_add_c1 = 4'd0;
    for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
      row1 = q1;
      tick1;
      #0.05; // FIX 4: 50ps settling
      $display("   [%0d]  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row1,
        $signed(out[col*bw_psum+7*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+6*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+5*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+4*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+3*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+2*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+1*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+0*bw_psum+:bw_psum]));
      $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_core1[row1][0], vn_result_core1[row1][1],
        vn_result_core1[row1][2], vn_result_core1[row1][3],
        vn_result_core1[row1][4], vn_result_core1[row1][5],
        vn_result_core1[row1][6], vn_result_core1[row1][7]);
      row_err1 = 0;
      for (c1 = 0; c1 < col; c1 = c1+1) begin
        if ($signed(out[col*bw_psum+c1*bw_psum+:bw_psum]) !== vn_result_core1[row1][golden_col[c1]]) begin
          $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c1,
            $signed(out[col*bw_psum+c1*bw_psum+:bw_psum]), vn_result_core1[row1][golden_col[c1]]);
          row_err1 = row_err1 + 1; mismatch_vn_core1 = mismatch_vn_core1 + 1;
        end
      end
      $display("       %s", (row_err1 == 0) ? "[OK]" : "[MISMATCH]");
      pmem_add_c1 = pmem_add_c1 + 1;
    end
    pmem_rd_c1 = 0; pmem_add_c1 = 0; tick1;
    $display("--- C1 VN: %0d mismatch(es) ---", mismatch_vn_core1);

    vn_done_c1_flag = 1;
    while (1) tick1;   // keep clk1 alive until $finish from Initial 1
  end

endmodule