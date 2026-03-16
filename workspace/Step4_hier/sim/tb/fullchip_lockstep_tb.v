// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission

`timescale 1ns/1ps

module fullchip_tb;

  // ── Parameters ──────────────────────────────────────────────────────────────
  parameter total_cycle   = 8;
  parameter bw            = 8;
  parameter bw_psum       = 2*bw+4;
  parameter pr            = 8;          // elements per vector, per core
  parameter col           = 8;          // MAC columns per core
  parameter sfp_out_shift = 7;          // matches core.v
  parameter sfp_acc_lat   = 1;          // acc→fifo_wr latency
  parameter sfp_div_lat   = 0;          // combinational div

  // ── File handles ─────────────────────────────────────────────────────────────
  integer qk_file, qk_scan_file, captured_data;
  `define NULL 0

  // ── Stimulus arrays ──────────────────────────────────────────────────────────
  integer K  [2*col-1:0][pr-1:0];
  integer Q  [total_cycle-1:0][pr-1:0];
  integer V_T[total_cycle-1:0][pr-1:0];

  // ── Golden results ───────────────────────────────────────────────────────────
  reg signed [bw_psum-1:0]   result    [total_cycle-1:0][2*col-1:0];
  reg signed [bw_psum-1:0]   abs_result[total_cycle-1:0][2*col-1:0];
  reg signed [bw_psum+4-1:0] sum_core0 [total_cycle-1:0];
  reg signed [bw_psum+4-1:0] sum_core1 [total_cycle-1:0];
  integer N_est_core0[total_cycle-1:0][col-1:0];
  integer N_est_core1[total_cycle-1:0][col-1:0];
  integer vn_result_core0[total_cycle-1:0][col-1:0];
  integer vn_result_core1[total_cycle-1:0][col-1:0];

  // ── Mismatch counters ────────────────────────────────────────────────────────
  integer mismatch_prd_core0, mismatch_prd_core1;
  integer mismatch_vn_core0,  mismatch_vn_core1;

  // ── Loop variables ────────────────────────────────────────────────────────────
  integer j, k, t, q, row, c, row_err;

  // ── DUT I/O ───────────────────────────────────────────────────────────────────
  wire [2*col*bw_psum-1:0] out;
  reg  reset   = 1;
  reg  clk     = 0;
  reg  VN_mode = 0;

  reg  [pr*bw-1:0]   mem_in_core0;
  reg  [pr*bw-1:0]   mem_in_core1;
  wire [2*pr*bw-1:0] mem_in;
  assign mem_in = {mem_in_core1, mem_in_core0};

  wire [19:0] inst;
  reg  ofifo_rd = 0;
  reg  qmem_rd  = 0;
  reg  qmem_wr  = 0;
  reg  kmem_rd  = 0;
  reg  kmem_wr  = 0;
  reg  pmem_rd  = 0;
  reg  execute  = 0;
  reg  load     = 0;
  reg  [3:0] qkmem_add = 0;
  reg  [3:0] pmem_add  = 0;
  reg  acc = 0;
  reg  div = 0;

  assign inst[19]    = VN_mode;
  assign inst[18]    = div;
  assign inst[17]    = acc;
  assign inst[16]    = ofifo_rd;   // sfp_processing
  assign inst[15:12] = qkmem_add;
  assign inst[11:8]  = pmem_add;
  assign inst[7]     = execute;
  assign inst[6]     = load;
  assign inst[5]     = qmem_rd;
  assign inst[4]     = qmem_wr;
  assign inst[3]     = kmem_rd;
  assign inst[2]     = kmem_wr;
  assign inst[1]     = pmem_rd;    // KEY: must=1 during SFP so pmem_add=inst[11:8]
  assign inst[0]     = 1'b0;

  reg [bw_psum-1:0]     temp5b;
  reg [bw_psum*col-1:0] temp16b;
  reg [bw_psum-1:0]     norm_result;
  reg [bw_psum*col-1:0] norm;

  // ── DUT ───────────────────────────────────────────────────────────────────────
  fullchip_lockstep #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(2*pr)) fullchip_instance (
    .reset(reset),
    .clk0(clk),
    .clk1(clk),
    .mem_in(mem_in),
    .inst(inst),
    .out(out)
  );

  task tick; begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end endtask

  // ═══════════════════════════════════════════════════════════════════════════════
  initial begin

    $dumpfile("fullchip_tb.vcd");
    $dumpvars(0, fullchip_tb);

    mismatch_prd_core0 = 0;  mismatch_prd_core1 = 0;
    mismatch_vn_core0  = 0;  mismatch_vn_core1  = 0;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Read Q data
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Q data txt reading #####");
    qk_file = $fopen("./sim/pattern/qdata.txt", "r");
    if (qk_file == `NULL) begin $display("ERROR: cannot open qdata.txt"); $finish; end
    for (q = 0; q < total_cycle; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end

    tick; tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Read K data
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### K data txt reading #####");
    repeat(10) tick;
    reset = 0;

    qk_file = $fopen("./sim/pattern/kdata_dual.txt", "r");
    if (qk_file == `NULL) begin $display("ERROR: cannot open kdata_dualcore.txt"); $finish; end
    for (q = 0; q < 2*col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Software golden: QK + L1 sums + estimated N
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Estimated QK result CORE0 #####");
    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1) begin
        result[t][q] = 0;
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];
        temp5b  = result[t][q];
        temp16b = {temp16b[bw_psum*col-bw_psum-1:0], temp5b};
      end
    for (t = 0; t < total_cycle; t = t+1)
      $display("prd @cycle%2d: %40h", t, temp16b);

    for (t = 0; t < total_cycle; t = t+1) begin
      sum_core0[t] = 0;
      for (q = 0; q < col; q = q+1) begin
        abs_result[t][q] = (result[t][q] >= 0) ? result[t][q] : -result[t][q];
        sum_core0[t] = sum_core0[t] + abs_result[t][q];
      end
    end

    $display("##### Estimated QK result CORE1 #####");
    for (t = 0; t < total_cycle; t = t+1)
      for (q = col; q < 2*col; q = q+1) begin
        result[t][q] = 0;
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];
        temp5b  = result[t][q];
        temp16b = {temp16b[bw_psum*col-bw_psum-1:0], temp5b};
      end
    for (t = 0; t < total_cycle; t = t+1)
      $display("prd @cycle%2d: %40h", t, temp16b);

    for (t = 0; t < total_cycle; t = t+1) begin
      sum_core1[t] = 0;
      for (q = col; q < 2*col; q = q+1) begin
        abs_result[t][q] = (result[t][q] >= 0) ? result[t][q] : -result[t][q];
        sum_core1[t] = sum_core1[t] + abs_result[t][q];
      end
    end

    // Estimated N: abs(QK) << sfp_out_shift / (sum_core0 + sum_core1)
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

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Write Qmem  (byte-reversed: LSB lane = Q[q][pr-1], MSB = Q[q][0])
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Qmem writing #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      qmem_wr = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      mem_in_core0[1*bw-1:0*bw] = Q[q][7]; mem_in_core0[2*bw-1:1*bw] = Q[q][6];
      mem_in_core0[3*bw-1:2*bw] = Q[q][5]; mem_in_core0[4*bw-1:3*bw] = Q[q][4];
      mem_in_core0[5*bw-1:4*bw] = Q[q][3]; mem_in_core0[6*bw-1:5*bw] = Q[q][2];
      mem_in_core0[7*bw-1:6*bw] = Q[q][1]; mem_in_core0[8*bw-1:7*bw] = Q[q][0];
      mem_in_core1 = mem_in_core0;
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; qmem_wr=0; qkmem_add=0; #0.5 clk=1;

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Write Kmem
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Kmem writing #####");
    for (q = 0; q < col; q = q+1) begin
      #0.5 clk = 1'b0;
      kmem_wr = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      mem_in_core0[1*bw-1:0*bw] = K[q][7];     mem_in_core0[2*bw-1:1*bw] = K[q][6];
      mem_in_core0[3*bw-1:2*bw] = K[q][5];     mem_in_core0[4*bw-1:3*bw] = K[q][4];
      mem_in_core0[5*bw-1:4*bw] = K[q][3];     mem_in_core0[6*bw-1:5*bw] = K[q][2];
      mem_in_core0[7*bw-1:6*bw] = K[q][1];     mem_in_core0[8*bw-1:7*bw] = K[q][0];
      mem_in_core1[1*bw-1:0*bw] = K[q+col][7]; mem_in_core1[2*bw-1:1*bw] = K[q+col][6];
      mem_in_core1[3*bw-1:2*bw] = K[q+col][5]; mem_in_core1[4*bw-1:3*bw] = K[q+col][4];
      mem_in_core1[5*bw-1:4*bw] = K[q+col][3]; mem_in_core1[6*bw-1:5*bw] = K[q+col][2];
      mem_in_core1[7*bw-1:6*bw] = K[q+col][1]; mem_in_core1[8*bw-1:7*bw] = K[q+col][0];
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; kmem_wr=0; qkmem_add=0; #0.5 clk=1;
    tick; tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Load K into MAC array
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### K loading to MAC array #####");
    for (q = 0; q < col+1; q = q+1) begin
      #0.5 clk = 1'b0;
      load = 1;
      if (q == 1) kmem_rd = 1;
      if (q > 1)  qkmem_add = qkmem_add + 1;
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; kmem_rd=0; qkmem_add=0; #0.5 clk=1;
    #0.5 clk=0; load=0;                 #0.5 clk=1;
    repeat(10) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Execute QK
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### QK execute #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      execute = 1; qmem_rd = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; qmem_rd=0; qkmem_add=0; execute=0; #0.5 clk=1;
    repeat(10) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 8. ofifo → pmem (QK)
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### ofifo -> pmem (QK) #####");
    for (q = 0; q < total_cycle+2; q = q+1) begin
      #0.5 clk=0; ofifo_rd=1; #0.5 clk=1;
    end
    #0.5 clk=0; ofifo_rd=0; #0.5 clk=1;
    repeat(5) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 9. HW vs EST: QK dot product comparison (pmem_rd readback, golden_col=7-c)
    // ─────────────────────────────────────────────────────────────────────────
    $display("");
    $display("========== HW vs EST: QK Dot Product Comparison ==========");

    #0.5 clk=0; pmem_rd=1; pmem_add=4'd0; #0.5 clk=1;
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk=0; pmem_add=pmem_add+1; #0.5 clk=1;
      row = q;

      $display("  [%0d] CORE0  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row,
        $signed(out[7*bw_psum+:bw_psum]), $signed(out[6*bw_psum+:bw_psum]),
        $signed(out[5*bw_psum+:bw_psum]), $signed(out[4*bw_psum+:bw_psum]),
        $signed(out[3*bw_psum+:bw_psum]), $signed(out[2*bw_psum+:bw_psum]),
        $signed(out[1*bw_psum+:bw_psum]), $signed(out[0*bw_psum+:bw_psum]));
      $display("       CORE0  golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        result[row][0], result[row][1], result[row][2], result[row][3],
        result[row][4], result[row][5], result[row][6], result[row][7]);
      row_err = 0;
      for (c = 0; c < col; c = c+1)
        if ($signed(out[c*bw_psum+:bw_psum]) !== result[row][7-c]) begin
          $display("       >>> CORE0 col%0d MISMATCH (RTL=%0d golden=%0d)",
            c, $signed(out[c*bw_psum+:bw_psum]), result[row][7-c]);
          row_err = row_err + 1;
          mismatch_prd_core0 = mismatch_prd_core0 + 1;
        end
      $display("       CORE0 %s", (row_err==0) ? "--> PASS" : "--> FAIL");

      $display("  [%0d] CORE1  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row,
        $signed(out[col*bw_psum+7*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+6*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+5*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+4*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+3*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+2*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+1*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+0*bw_psum+:bw_psum]));
      $display("       CORE1  golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        result[row][col+0], result[row][col+1], result[row][col+2], result[row][col+3],
        result[row][col+4], result[row][col+5], result[row][col+6], result[row][col+7]);
      row_err = 0;
      for (c = 0; c < col; c = c+1)
        if ($signed(out[col*bw_psum+c*bw_psum+:bw_psum]) !== result[row][col+7-c]) begin
          $display("       >>> CORE1 col%0d MISMATCH (RTL=%0d golden=%0d)",
            c, $signed(out[col*bw_psum+c*bw_psum+:bw_psum]), result[row][col+7-c]);
          row_err = row_err + 1;
          mismatch_prd_core1 = mismatch_prd_core1 + 1;
        end
      $display("       CORE1 %s", (row_err==0) ? "--> PASS" : "--> FAIL");
      $display("  --");
    end
    #0.5 clk=0; pmem_rd=0; pmem_add=0; #0.5 clk=1;

    $display("  CORE0 QK mismatches: %0d", mismatch_prd_core0);
    $display("  CORE1 QK mismatches: %0d", mismatch_prd_core1);
    $display(  (mismatch_prd_core0==0 && mismatch_prd_core1==0)
             ? "  >>> QK phase: ALL PASS <<<"
             : "  >>> QK phase: FAILED <<<");
    $display("===========================================================");
    $display("");
    repeat(5) tick;

    // =========================================================================
    //  SFP PHASE: pmem → sfp_row → N → kmem
    //
    //  CRITICAL FIX: assert pmem_rd=1 (inst[1]=1) throughout SFP so that
    //    pmem_add = inst[11:8]  (our controlled address)
    //  not:
    //    pmem_add = fifo_valid_cnt  (stuck at 0 after QK, reads pmem[0] every time)
    //
    //  Timing per row (from core_tb, sfp_acc_lat=1, sfp_div_lat=0):
    //   tick 1        : pmem[q] presented to sfp_in (pmem SRAM latency)
    //   tick 2        : -
    //   tick 2→acc=1  : seen on tick 3
    //   tick 3        : acc=1 → sum_q ← sum8_out; acc_d1 ← 1
    //   tick 4→acc=0  : acc still 1 → fifo_wr fires (writes this core's L1 sum
    //                   to ext_fifo for other core)
    //   tick 5        : sfp_acc_lat=1 extra; ext_fifo data crosses to other core
    //   tick 5→div=1  : seen on tick 6
    //   tick 6        : div=1 → div_q fires → reads other core's ext_fifo
    //                   → sum_2core = own + cross; sfp_out ← div results
    //   tick 7→div=0
    //   tick 8→kmem_wr=1 : sfp_processing=1 → kmem_in=sfp_out; write N row
    //   tick 9→kmem_wr=0 : committed; advance pmem_add & qkmem_add
    // =========================================================================
    $display("##### SFP: normalize QK, write N to kmem #####");
    ofifo_rd  = 1;   // sfp_processing = 1: enables pmem_rd internally, kmem_in=sfp_out
    pmem_rd   = 1;   // inst[1]=1: pmem_add = inst[11:8] (our address, NOT fifo_valid_cnt)
    pmem_add  = 0;
    qkmem_add = 0;

    for (q = 0; q < total_cycle; q = q+1) begin
      if (q > 0) begin pmem_add = pmem_add + 1; qkmem_add = qkmem_add + 1; end

      tick;                  // tick 1: pmem[q] settles on sfp_in
      tick;                  // tick 2
      tick; acc = 1;         // tick 2→acc=1, seen tick 3
      tick;                  // tick 3: sum_q←sum8_out, acc_d1←1
      tick; acc = 0;         // tick 4: fifo_wr fires (acc_d1 was 1)
      tick;                  // tick 5: sfp_acc_lat=1, ext_fifo settles
      tick; div = 1;         // tick 5→div=1, seen tick 6
      tick;                  // tick 6: div_q fires, sfp_out←div results
      tick; div = 0;         // tick 7
      // sfp_div_lat=0: results already registered in sfp_out_sign0..7
      tick; kmem_wr = 1;     // tick 8→kmem_wr=1: write N row to kmem[q]
      $display("SFP row%0d  N_est C0: %3d %3d %3d %3d %3d %3d %3d %3d", q,
        N_est_core0[q][0], N_est_core0[q][1], N_est_core0[q][2], N_est_core0[q][3],
        N_est_core0[q][4], N_est_core0[q][5], N_est_core0[q][6], N_est_core0[q][7]);
      $display("SFP row%0d  N_est C1: %3d %3d %3d %3d %3d %3d %3d %3d", q,
        N_est_core1[q][0], N_est_core1[q][1], N_est_core1[q][2], N_est_core1[q][3],
        N_est_core1[q][4], N_est_core1[q][5], N_est_core1[q][6], N_est_core1[q][7]);
      tick; kmem_wr = 0;     // tick 9: committed
    end
    #0.5 clk=0; ofifo_rd=0; pmem_rd=0; div=0; acc=0;
                kmem_wr=0; qkmem_add=0; pmem_add=0; #0.5 clk=1;
    repeat(10) tick;

    // =========================================================================
    //  VN PHASE
    // =========================================================================

    // ─────────────────────────────────────────────────────────────────────────
    // 10. Read V data
    //     vdata.txt layout (core_tb): q=0..col-1, j=0..pr-1 → V_T[j][q]
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### V data txt reading #####");
    qk_file = $fopen("./sim/pattern/vdata.txt", "r");
    if (qk_file == `NULL) begin $display("ERROR: cannot open vdata.txt"); $finish; end
    for (q = 0; q < col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
        V_T[j][q] = captured_data;
      end

    // ─────────────────────────────────────────────────────────────────────────
    // 11. Software golden: VN  (vn_result[t][q] = Σ_k V_T[t][k] * N_est[q][k])
    //     N_est row q is stored in kmem[q], loaded into MAC col (col-1-q) = 7-q
    //     → same golden_col[c]=7-c mapping applies
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Estimated VN result #####");
    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1) begin
        vn_result_core0[t][q] = 0;
        vn_result_core1[t][q] = 0;
        for (k = 0; k < pr; k = k+1) begin
          vn_result_core0[t][q] = vn_result_core0[t][q] + V_T[t][k] * N_est_core0[q][k];
          vn_result_core1[t][q] = vn_result_core1[t][q] + V_T[t][k] * N_est_core1[q][k];
        end
      end
    for (t = 0; t < total_cycle; t = t+1) begin
      $display("VN est C0 row%0d: %5d %5d %5d %5d %5d %5d %5d %5d", t,
        vn_result_core0[t][0], vn_result_core0[t][1],
        vn_result_core0[t][2], vn_result_core0[t][3],
        vn_result_core0[t][4], vn_result_core0[t][5],
        vn_result_core0[t][6], vn_result_core0[t][7]);
      $display("VN est C1 row%0d: %5d %5d %5d %5d %5d %5d %5d %5d", t,
        vn_result_core1[t][0], vn_result_core1[t][1],
        vn_result_core1[t][2], vn_result_core1[t][3],
        vn_result_core1[t][4], vn_result_core1[t][5],
        vn_result_core1[t][6], vn_result_core1[t][7]);
    end

    // ─────────────────────────────────────────────────────────────────────────
    // 12. Reset for VN (sram_w16 has no reset → kmem retains N values from SFP)
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Reset for VN phase #####");
    VN_mode = 1;
    reset   = 1;
    repeat(10) tick;
    reset = 0;
    repeat(2) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 13. Write V to Qmem (byte-reversed, same for both cores)
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### Qmem writing (V) #####");
    qkmem_add = 0;
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      qmem_wr = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      mem_in_core0[1*bw-1:0*bw] = V_T[q][7]; mem_in_core0[2*bw-1:1*bw] = V_T[q][6];
      mem_in_core0[3*bw-1:2*bw] = V_T[q][5]; mem_in_core0[4*bw-1:3*bw] = V_T[q][4];
      mem_in_core0[5*bw-1:4*bw] = V_T[q][3]; mem_in_core0[6*bw-1:5*bw] = V_T[q][2];
      mem_in_core0[7*bw-1:6*bw] = V_T[q][1]; mem_in_core0[8*bw-1:7*bw] = V_T[q][0];
      mem_in_core1 = mem_in_core0;
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; qmem_wr=0; qkmem_add=0; #0.5 clk=1;
    tick; tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 14. Load N from kmem into MAC array (kmem still holds SFP output)
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### N loading to MAC array (VN) #####");
    for (q = 0; q < col+1; q = q+1) begin
      #0.5 clk = 1'b0;
      load = 1;
      if (q == 1) kmem_rd = 1;
      if (q > 1)  qkmem_add = qkmem_add + 1;
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; kmem_rd=0; qkmem_add=0; #0.5 clk=1;
    #0.5 clk=0; load=0;                 #0.5 clk=1;
    repeat(10) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 15. Execute VN
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### VN execute #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      execute = 1; qmem_rd = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      #0.5 clk = 1'b1;
    end
    #0.5 clk=0; qmem_rd=0; qkmem_add=0; execute=0; #0.5 clk=1;
    repeat(10) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 16. ofifo → pmem (VN)
    // ─────────────────────────────────────────────────────────────────────────
    $display("##### ofifo -> pmem (VN) #####");
    for (q = 0; q < total_cycle+2; q = q+1) begin
      #0.5 clk=0; ofifo_rd=1; #0.5 clk=1;
    end
    #0.5 clk=0; ofifo_rd=0; #0.5 clk=1;
    repeat(5) tick;

    // ─────────────────────────────────────────────────────────────────────────
    // 17. HW vs EST: VN comparison (pmem_rd readback, golden_col[c]=7-c)
    // ─────────────────────────────────────────────────────────────────────────
    $display("");
    $display("========== HW vs EST: VN Dot Product Comparison ==========");

    #0.5 clk=0; pmem_rd=1; pmem_add=4'd0; #0.5 clk=1;
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk=0; pmem_add=pmem_add+1; #0.5 clk=1;
      row = q;

      // CORE 0
      $display("  [%0d] CORE0  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row,
        $signed(out[7*bw_psum+:bw_psum]), $signed(out[6*bw_psum+:bw_psum]),
        $signed(out[5*bw_psum+:bw_psum]), $signed(out[4*bw_psum+:bw_psum]),
        $signed(out[3*bw_psum+:bw_psum]), $signed(out[2*bw_psum+:bw_psum]),
        $signed(out[1*bw_psum+:bw_psum]), $signed(out[0*bw_psum+:bw_psum]));
      $display("       CORE0  golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_core0[row][0], vn_result_core0[row][1],
        vn_result_core0[row][2], vn_result_core0[row][3],
        vn_result_core0[row][4], vn_result_core0[row][5],
        vn_result_core0[row][6], vn_result_core0[row][7]);
      row_err = 0;
      for (c = 0; c < col; c = c+1)
        if ($signed(out[c*bw_psum+:bw_psum]) !== vn_result_core0[row][7-c]) begin
          $display("       >>> CORE0 col%0d MISMATCH (RTL=%0d golden=%0d)",
            c, $signed(out[c*bw_psum+:bw_psum]), vn_result_core0[row][7-c]);
          row_err = row_err + 1;
          mismatch_vn_core0 = mismatch_vn_core0 + 1;
        end
      $display("       CORE0 %s", (row_err==0) ? "--> PASS" : "--> FAIL");

      // CORE 1
      $display("  [%0d] CORE1  RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row,
        $signed(out[col*bw_psum+7*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+6*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+5*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+4*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+3*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+2*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+1*bw_psum+:bw_psum]),
        $signed(out[col*bw_psum+0*bw_psum+:bw_psum]));
      $display("       CORE1  golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        vn_result_core1[row][0], vn_result_core1[row][1],
        vn_result_core1[row][2], vn_result_core1[row][3],
        vn_result_core1[row][4], vn_result_core1[row][5],
        vn_result_core1[row][6], vn_result_core1[row][7]);
      row_err = 0;
      for (c = 0; c < col; c = c+1)
        if ($signed(out[col*bw_psum+c*bw_psum+:bw_psum]) !== vn_result_core1[row][7-c]) begin
          $display("       >>> CORE1 col%0d MISMATCH (RTL=%0d golden=%0d)",
            c, $signed(out[col*bw_psum+c*bw_psum+:bw_psum]), vn_result_core1[row][7-c]);
          row_err = row_err + 1;
          mismatch_vn_core1 = mismatch_vn_core1 + 1;
        end
      $display("       CORE1 %s", (row_err==0) ? "--> PASS" : "--> FAIL");
      $display("  --");
    end
    #0.5 clk=0; pmem_rd=0; pmem_add=0; #0.5 clk=1;

    $display("  CORE0 VN mismatches: %0d", mismatch_vn_core0);
    $display("  CORE1 VN mismatches: %0d", mismatch_vn_core1);
    $display(  (mismatch_vn_core0==0 && mismatch_vn_core1==0)
             ? "  >>> VN phase: ALL PASS <<<"
             : "  >>> VN phase: FAILED <<<");
    $display("===========================================================");
    $display("");

    // ─────────────────────────────────────────────────────────────────────────
    // Overall summary
    // ─────────────────────────────────────────────────────────────────────────
    $display("=================== OVERALL SUMMARY ====================");
    $display("  QK phase -- CORE0: %0d  CORE1: %0d mismatch(es)",
             mismatch_prd_core0, mismatch_prd_core1);
    $display("  VN phase -- CORE0: %0d  CORE1: %0d mismatch(es)",
             mismatch_vn_core0,  mismatch_vn_core1);
    if (mismatch_prd_core0==0 && mismatch_prd_core1==0 &&
        mismatch_vn_core0 ==0 && mismatch_vn_core1 ==0)
      $display("  >>> ALL TESTS PASSED <<<");
    else
      $display("  >>> SOME TESTS FAILED <<<");
    $display("=========================================================");

    #10 $finish;
  end

endmodule