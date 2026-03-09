// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
`timescale 1ns/1ps

module fullchip_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter pr = 16;
  parameter half_pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;
  `ifdef SFP_LONGDIV
    parameter sfp_div_lat = 8;
  `else
    parameter sfp_div_lat = 0;
  `endif

  parameter real CLK0_PERIOD = 1.0;
  parameter real CLK1_PERIOD = 2.0;

  reg reset = 1;
  reg clk0 = 0;
  reg clk1 = 0;

  // per-core packed inputs
  reg [half_pr*bw-1:0] mem_in_core0;
  reg [half_pr*bw-1:0] mem_in_core1;
  wire [pr*bw-1:0] mem_in;

  reg [19:0] inst0;
  reg [19:0] inst1;
  wire [39:0] inst;

  assign mem_in = {mem_in_core1, mem_in_core0};
  assign inst   = {inst1, inst0};

  // decoded control regs for core0
  reg VN_mode_0 = 0, sfp_div_0 = 0, sfp_acc_0 = 0, sfp_processing_0 = 0;
  reg qmem_rd_0 = 0, qmem_wr_0 = 0, kmem_rd_0 = 0, kmem_wr_0 = 0, pmem_rd_0 = 0, pmem_wr_0 = 0;
  reg execute_0 = 0, load_0 = 0;
  reg [3:0] qkmem_add_0 = 0;
  reg [3:0] pmem_add_0  = 0;

  // decoded control regs for core1
  reg VN_mode_1 = 0, sfp_div_1 = 0, sfp_acc_1 = 0, sfp_processing_1 = 0;
  reg qmem_rd_1 = 0, qmem_wr_1 = 0, kmem_rd_1 = 0, kmem_wr_1 = 0, pmem_rd_1 = 0, pmem_wr_1 = 0;
  reg execute_1 = 0, load_1 = 0;
  reg [3:0] qkmem_add_1 = 0;
  reg [3:0] pmem_add_1  = 0;

  reg core0_qk_done = 0;
  reg core1_qk_done = 0;
  reg core0_vn_done = 0;
  reg core1_vn_done = 0;

  integer i, j, q, k, t, c, row;
  integer qkvn_file, qkvn_scan_file, captured_data;
  integer err, row_err, sum_abs, unsigned_val;
  integer golden_col [0:col-1];

  integer K   [col-1:0][pr-1:0];
  integer Q   [total_cycle-1:0][pr-1:0];
  integer N   [total_cycle-1:0][col-1:0];
  integer V_T [pr-1:0][col-1:0];

  integer qk_result       [total_cycle-1:0][col-1:0];
  integer qk_result_core0 [total_cycle-1:0][col-1:0];
  integer qk_result_core1 [total_cycle-1:0][col-1:0];
  integer vn_result_lo    [total_cycle-1:0][col-1:0];
  integer vn_result_hi    [total_cycle-1:0][col-1:0];
  integer estimated       [0:total_cycle*pr-1];

  wire [bw_psum*col*2-1:0] out;
  wire [bw_psum*col-1:0] pmem_out_core0;
  wire [bw_psum*col-1:0] pmem_out_core1;

  assign pmem_out_core0 = out[bw_psum*col-1:0];
  assign pmem_out_core1 = out[bw_psum*col*2-1:bw_psum*col];

  // pack inst0
  always @(*) begin
    inst0[19]    = VN_mode_0;
    inst0[18]    = sfp_div_0;
    inst0[17]    = sfp_acc_0;
    inst0[16]    = sfp_processing_0;
    inst0[15:12] = qkmem_add_0;
    inst0[11:8]  = pmem_add_0;
    inst0[7]     = execute_0;
    inst0[6]     = load_0;
    inst0[5]     = qmem_rd_0;
    inst0[4]     = qmem_wr_0;
    inst0[3]     = kmem_rd_0;
    inst0[2]     = kmem_wr_0;
    inst0[1]     = pmem_rd_0;
    inst0[0]     = pmem_wr_0;
  end

  // pack inst1
  always @(*) begin
    inst1[19]    = VN_mode_1;
    inst1[18]    = sfp_div_1;
    inst1[17]    = sfp_acc_1;
    inst1[16]    = sfp_processing_1;
    inst1[15:12] = qkmem_add_1;
    inst1[11:8]  = pmem_add_1;
    inst1[7]     = execute_1;
    inst1[6]     = load_1;
    inst1[5]     = qmem_rd_1;
    inst1[4]     = qmem_wr_1;
    inst1[3]     = kmem_rd_1;
    inst1[2]     = kmem_wr_1;
    inst1[1]     = pmem_rd_1;
    inst1[0]     = pmem_wr_1;
  end

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

  always #(CLK0_PERIOD/2.0) clk0 = ~clk0;
  always #(CLK1_PERIOD/2.0) clk1 = ~clk1;

  // setup / read files / checking block
  initial begin
    $dumpfile("sim/waveform/fullchip.vcd");
    $dumpvars(0, fullchip_tb);

    mem_in_core0 = 0;
    mem_in_core1 = 0;
    core0_qk_done = 0;
    core1_qk_done = 0;
    core0_vn_done = 0;
    core1_vn_done = 0;

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        K[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        Q[i][j] = 0;

    for (i = 0; i < pr; i = i + 1)
      for (j = 0; j < col; j = j + 1)
        V_T[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < col; j = j + 1)
        N[i][j] = 0;

    qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
    for (q = 0; q < total_cycle; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end

    qkvn_file = $fopen("sim/pattern/kdata.txt", "r");
    for (q = 0; q < col; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end

    qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
    for (q = 0; q < col; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        V_T[j][q] = captured_data;
      end

    for (t = 0; t < total_cycle; t = t + 1)
      for (q = 0; q < col; q = q + 1) begin
        qk_result[t][q]       = 0;
        qk_result_core0[t][q] = 0;
        qk_result_core1[t][q] = 0;
      end

    for (t = 0; t < total_cycle; t = t + 1)
      for (q = 0; q < col; q = q + 1) begin
        for (k = 0; k < half_pr; k = k + 1)
          qk_result_core0[t][q] = qk_result_core0[t][q] + Q[t][k] * K[q][k];
        for (k = half_pr; k < pr; k = k + 1)
          qk_result_core1[t][q] = qk_result_core1[t][q] + Q[t][k] * K[q][k];
        qk_result[t][q] = qk_result_core0[t][q] + qk_result_core1[t][q];
      end

    repeat(5) @(posedge clk0);
    repeat(3) @(posedge clk1);
    reset = 0;

    // wait long enough for both core stimulus blocks to complete QK phase
    wait(core0_qk_done && core1_qk_done);
    repeat(2) @(posedge clk0);

    for (c = 0; c < col; c = c + 1)
      golden_col[c] = 7 - c;

    err = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      row = q;
      for (c = 0; c < col; c = c + 1) begin
        sum_abs = $signed(pmem_out_core0[c*bw_psum +: bw_psum]) +
                  $signed(pmem_out_core1[c*bw_psum +: bw_psum]);
        unsigned_val = (sum_abs < 0) ? -sum_abs : sum_abs;
        estimated[q*pr + (7-c)] = (unsigned_val >>> sfp_out_shift);
      end
    end

    for (q = 0; q < total_cycle; q = q + 1)
      for (j = 0; j < col; j = j + 1)
        N[q][j] = estimated[q*pr + j];

    for (t = 0; t < total_cycle; t = t + 1)
      for (q = 0; q < col; q = q + 1) begin
        vn_result_lo[t][q] = 0;
        vn_result_hi[t][q] = 0;
        for (k = 0; k < pr/2; k = k + 1) begin
          vn_result_lo[t][q] = vn_result_lo[t][q] + N[t][k] * V_T[k][q];
          vn_result_hi[t][q] = vn_result_hi[t][q] + N[t][k] * V_T[k+8][q];
        end
      end

    // wait long enough for VN phase to complete
    wait(core0_vn_done && core1_vn_done);
    repeat(2) @(posedge clk0);

    err = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      row = q;
      row_err = 0;
      for (c = 0; c < col; c = c + 1) begin
        if ($signed(pmem_out_core0[c*bw_psum +: bw_psum]) != $signed(vn_result_lo[row][7-c])) begin
          err = err + 1;
          row_err = row_err + 1;
        end
        if ($signed(pmem_out_core1[c*bw_psum +: bw_psum]) != $signed(vn_result_hi[row][7-c])) begin
          err = err + 1;
          row_err = row_err + 1;
        end
      end
      $display("row %0d : %s", row, (row_err==0) ? "OK" : "MISMATCH");
    end

    if (err == 0) $display("PASS");
    else $display("FAIL err=%0d", err);

    #100 $finish;
  end

  // core0 driver
  initial begin
    wait(reset == 0);

    // Q write
    VN_mode_0 = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      qmem_wr_0 = 1;
      qkmem_add_0 = q;
      mem_in_core0[1*bw-1:0*bw] = Q[q][7];
      mem_in_core0[2*bw-1:1*bw] = Q[q][6];
      mem_in_core0[3*bw-1:2*bw] = Q[q][5];
      mem_in_core0[4*bw-1:3*bw] = Q[q][4];
      mem_in_core0[5*bw-1:4*bw] = Q[q][3];
      mem_in_core0[6*bw-1:5*bw] = Q[q][2];
      mem_in_core0[7*bw-1:6*bw] = Q[q][1];
      mem_in_core0[8*bw-1:7*bw] = Q[q][0];
    end
    @(posedge clk0) qmem_wr_0 = 0;

    // K write
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk0);
      kmem_wr_0 = 1;
      qkmem_add_0 = q;
      mem_in_core0[1*bw-1:0*bw] = K[q][7];
      mem_in_core0[2*bw-1:1*bw] = K[q][6];
      mem_in_core0[3*bw-1:2*bw] = K[q][5];
      mem_in_core0[4*bw-1:3*bw] = K[q][4];
      mem_in_core0[5*bw-1:4*bw] = K[q][3];
      mem_in_core0[6*bw-1:5*bw] = K[q][2];
      mem_in_core0[7*bw-1:6*bw] = K[q][1];
      mem_in_core0[8*bw-1:7*bw] = K[q][0];
    end
    @(posedge clk0) kmem_wr_0 = 0;

    // K load
    @(posedge clk0) begin load_0 = 1; kmem_rd_0 = 1; qkmem_add_0 = 0; end
    repeat(col) @(posedge clk0) qkmem_add_0 = qkmem_add_0 + 1;
    @(posedge clk0) begin load_0 = 0; kmem_rd_0 = 0; end

    repeat(10) @(posedge clk0);

    // Q execute
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      execute_0 = 1;
      qmem_rd_0 = 1;
      qkmem_add_0 = q;
    end
    @(posedge clk0) begin execute_0 = 0; qmem_rd_0 = 0; end

    repeat(10) @(posedge clk0);

    // QK read
    @(posedge clk0) begin pmem_rd_0 = 1; pmem_add_0 = 0; end
    for (q = 0; q < total_cycle; q = q + 1)
      @(posedge clk0) pmem_add_0 = q + 1;
    @(posedge clk0) pmem_rd_0 = 0;

    core0_qk_done = 1;

    // normalization
    sfp_processing_0 = 1;
    pmem_rd_0 = 1;
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk0) pmem_add_0 = q;
      repeat(2) @(posedge clk0);
      @(posedge clk0) sfp_acc_0 = 1;
      @(posedge clk0) sfp_acc_0 = 0;
      repeat(10) @(posedge clk1);
      @(posedge clk0) sfp_div_0 = 1;
      @(posedge clk0) sfp_div_0 = 0;
      repeat(sfp_div_lat + 2) @(posedge clk0);
      @(posedge clk0) begin kmem_wr_0 = 1; qkmem_add_0 = q; end
      @(posedge clk0) kmem_wr_0 = 0;
    end
    sfp_processing_0 = 0;
    pmem_rd_0 = 0;

    // V write
    VN_mode_0 = 1;
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk0);
      kmem_wr_0 = 1;
      qkmem_add_0 = q;
      mem_in_core0[1*bw-1:0*bw] = V_T[7][q];
      mem_in_core0[2*bw-1:1*bw] = V_T[6][q];
      mem_in_core0[3*bw-1:2*bw] = V_T[5][q];
      mem_in_core0[4*bw-1:3*bw] = V_T[4][q];
      mem_in_core0[5*bw-1:4*bw] = V_T[3][q];
      mem_in_core0[6*bw-1:5*bw] = V_T[2][q];
      mem_in_core0[7*bw-1:6*bw] = V_T[1][q];
      mem_in_core0[8*bw-1:7*bw] = V_T[0][q];
    end
    @(posedge clk0) kmem_wr_0 = 0;

    // V load
    @(posedge clk0) begin load_0 = 1; kmem_rd_0 = 1; qkmem_add_0 = 0; end
    repeat(col) @(posedge clk0) qkmem_add_0 = qkmem_add_0 + 1;
    @(posedge clk0) begin load_0 = 0; kmem_rd_0 = 0; end

    // N write
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      qmem_wr_0 = 1;
      qkmem_add_0 = q;
      mem_in_core0[1*bw-1:0*bw] = N[q][7];
      mem_in_core0[2*bw-1:1*bw] = N[q][6];
      mem_in_core0[3*bw-1:2*bw] = N[q][5];
      mem_in_core0[4*bw-1:3*bw] = N[q][4];
      mem_in_core0[5*bw-1:4*bw] = N[q][3];
      mem_in_core0[6*bw-1:5*bw] = N[q][2];
      mem_in_core0[7*bw-1:6*bw] = N[q][1];
      mem_in_core0[8*bw-1:7*bw] = N[q][0];
    end
    @(posedge clk0) qmem_wr_0 = 0;

    // VN execute
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      execute_0 = 1;
      qmem_rd_0 = 1;
      qkmem_add_0 = q;
    end
    @(posedge clk0) begin execute_0 = 0; qmem_rd_0 = 0; end

    repeat(10) @(posedge clk0);

    // VN read
    @(posedge clk0) begin pmem_rd_0 = 1; pmem_add_0 = 0; end
    @(posedge clk0);
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk0);
      if (q < total_cycle - 1) pmem_add_0 = q + 1;
      else pmem_rd_0 = 0;
    end

    core0_vn_done = 1;

  end

  // core1 driver
  initial begin
    wait(reset == 0);

    // Q write
    VN_mode_1 = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk1);
      qmem_wr_1 = 1;
      qkmem_add_1 = q;
      mem_in_core1[1*bw-1:0*bw] = Q[q][15];
      mem_in_core1[2*bw-1:1*bw] = Q[q][14];
      mem_in_core1[3*bw-1:2*bw] = Q[q][13];
      mem_in_core1[4*bw-1:3*bw] = Q[q][12];
      mem_in_core1[5*bw-1:4*bw] = Q[q][11];
      mem_in_core1[6*bw-1:5*bw] = Q[q][10];
      mem_in_core1[7*bw-1:6*bw] = Q[q][9];
      mem_in_core1[8*bw-1:7*bw] = Q[q][8];
    end
    @(posedge clk1) qmem_wr_1 = 0;

    // K write
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk1);
      kmem_wr_1 = 1;
      qkmem_add_1 = q;
      mem_in_core1[1*bw-1:0*bw] = K[q][15];
      mem_in_core1[2*bw-1:1*bw] = K[q][14];
      mem_in_core1[3*bw-1:2*bw] = K[q][13];
      mem_in_core1[4*bw-1:3*bw] = K[q][12];
      mem_in_core1[5*bw-1:4*bw] = K[q][11];
      mem_in_core1[6*bw-1:5*bw] = K[q][10];
      mem_in_core1[7*bw-1:6*bw] = K[q][9];
      mem_in_core1[8*bw-1:7*bw] = K[q][8];
    end
    @(posedge clk1) kmem_wr_1 = 0;

    // K load
    @(posedge clk1) begin load_1 = 1; kmem_rd_1 = 1; qkmem_add_1 = 0; end
    repeat(col) @(posedge clk1) qkmem_add_1 = qkmem_add_1 + 1;
    @(posedge clk1) begin load_1 = 0; kmem_rd_1 = 0; end

    repeat(10) @(posedge clk1);

    // Q execute
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk1);
      execute_1 = 1;
      qmem_rd_1 = 1;
      qkmem_add_1 = q;
    end
    @(posedge clk1) begin execute_1 = 0; qmem_rd_1 = 0; end

    repeat(10) @(posedge clk1);

    // QK read
    @(posedge clk1) begin pmem_rd_1 = 1; pmem_add_1 = 0; end
    for (q = 0; q < total_cycle; q = q + 1)
      @(posedge clk1) pmem_add_1 = q + 1;
    @(posedge clk1) pmem_rd_1 = 0;

    core1_qk_done = 1;

    // normalization
    sfp_processing_1 = 1;
    pmem_rd_1 = 1;
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk1) pmem_add_1 = q;
      repeat(2) @(posedge clk1);
      @(posedge clk1) sfp_acc_1 = 1;
      @(posedge clk1) sfp_acc_1 = 0;
      repeat(10) @(posedge clk0);
      @(posedge clk1) sfp_div_1 = 1;
      @(posedge clk1) sfp_div_1 = 0;
      repeat(sfp_div_lat + 2) @(posedge clk1);
      @(posedge clk1) begin kmem_wr_1 = 1; qkmem_add_1 = q; end
      @(posedge clk1) kmem_wr_1 = 0;
    end
    sfp_processing_1 = 0;
    pmem_rd_1 = 0;

    // V write
    VN_mode_1 = 1;
    for (q = 0; q < col; q = q + 1) begin
      @(posedge clk1);
      kmem_wr_1 = 1;
      qkmem_add_1 = q;
      mem_in_core1[1*bw-1:0*bw] = V_T[15][q];
      mem_in_core1[2*bw-1:1*bw] = V_T[14][q];
      mem_in_core1[3*bw-1:2*bw] = V_T[13][q];
      mem_in_core1[4*bw-1:3*bw] = V_T[12][q];
      mem_in_core1[5*bw-1:4*bw] = V_T[11][q];
      mem_in_core1[6*bw-1:5*bw] = V_T[10][q];
      mem_in_core1[7*bw-1:6*bw] = V_T[9][q];
      mem_in_core1[8*bw-1:7*bw] = V_T[8][q];
    end
    @(posedge clk1) kmem_wr_1 = 0;

    // V load
    @(posedge clk1) begin load_1 = 1; kmem_rd_1 = 1; qkmem_add_1 = 0; end
    repeat(col) @(posedge clk1) qkmem_add_1 = qkmem_add_1 + 1;
    @(posedge clk1) begin load_1 = 0; kmem_rd_1 = 0; end

    // N write
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk1);
      qmem_wr_1 = 1;
      qkmem_add_1 = q;
      mem_in_core1[1*bw-1:0*bw] = N[q][7];
      mem_in_core1[2*bw-1:1*bw] = N[q][6];
      mem_in_core1[3*bw-1:2*bw] = N[q][5];
      mem_in_core1[4*bw-1:3*bw] = N[q][4];
      mem_in_core1[5*bw-1:4*bw] = N[q][3];
      mem_in_core1[6*bw-1:5*bw] = N[q][2];
      mem_in_core1[7*bw-1:6*bw] = N[q][1];
      mem_in_core1[8*bw-1:7*bw] = N[q][0];
    end
    @(posedge clk1) qmem_wr_1 = 0;

    // VN execute
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk1);
      execute_1 = 1;
      qmem_rd_1 = 1;
      qkmem_add_1 = q;
    end
    @(posedge clk1) begin execute_1 = 0; qmem_rd_1 = 0; end

    repeat(10) @(posedge clk1);

    // VN read
    @(posedge clk1) begin pmem_rd_1 = 1; pmem_add_1 = 0; end
    @(posedge clk1);
    for (q = 0; q < total_cycle; q = q + 1) begin
      @(posedge clk1);
      if (q < total_cycle - 1) pmem_add_1 = q + 1;
      else pmem_rd_1 = 0;
    end

    core1_vn_done = 1;

  end

endmodule

/*
`timescale 1ns/1ps

module fullchip_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter pr = 16;
  parameter half_pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;
  parameter sfp_acc_lat = 1;

  parameter CLK0_PERIOD = 2;
  parameter CLK1_PERIOD = 4;

  `ifdef SFP_LONGDIV
    parameter sfp_div_lat = 8;
  `else
    parameter sfp_div_lat = 0;
  `endif

  integer qkvn_file, qkvn_scan_file, captured_data;

  integer K   [col-1:0][pr-1:0];
  integer Q   [total_cycle-1:0][pr-1:0];
  integer N   [total_cycle-1:0][col-1:0];
  integer V_T [pr-1:0][col-1:0];

  integer qk_result       [total_cycle-1:0][col-1:0];
  integer qk_result_core0 [total_cycle-1:0][col-1:0];
  integer qk_result_core1 [total_cycle-1:0][col-1:0];

  integer vn_result_lo [total_cycle-1:0][col-1:0];
  integer vn_result_hi [total_cycle-1:0][col-1:0];

  integer estimated [0:total_cycle*pr-1];

  integer i, j, k, t, q, c;
  integer err, row_err, row;
  integer sum_abs, unsigned_val;
  integer golden_col [0:col-1];

  integer q0, q1;

  reg reset = 1;
  reg clk0 = 0;
  reg clk1 = 0;

  // -------------------------------
  // Per-core TB-side buses
  // -------------------------------
  reg [half_pr*bw-1:0] mem_in_core0_tb;
  reg [half_pr*bw-1:0] mem_in_core1_tb;

  reg [19:0] inst0_tb;
  reg [19:0] inst1_tb;

  wire [pr*bw-1:0] mem_in;
  wire [39:0]      inst;

  assign mem_in = {mem_in_core1_tb, mem_in_core0_tb};
  assign inst   = {inst1_tb, inst0_tb};

  // -------------------------------
  // Core0 control fields
  // -------------------------------
  reg VN_mode_0 = 0;
  reg sfp_div_0 = 0, sfp_acc_0 = 0, sfp_processing_0 = 0;
  reg qmem_rd_0 = 0, qmem_wr_0 = 0, kmem_rd_0 = 0, kmem_wr_0 = 0, pmem_rd_0 = 0, pmem_wr_0 = 0;
  reg execute_0 = 0, load_0 = 0;
  reg [3:0] qkmem_add_0 = 0;
  reg [3:0] pmem_add_0  = 0;

  // -------------------------------
  // Core1 control fields
  // -------------------------------
  reg VN_mode_1 = 0;
  reg sfp_div_1 = 0, sfp_acc_1 = 0, sfp_processing_1 = 0;
  reg qmem_rd_1 = 0, qmem_wr_1 = 0, kmem_rd_1 = 0, kmem_wr_1 = 0, pmem_rd_1 = 0, pmem_wr_1 = 0;
  reg execute_1 = 0, load_1 = 0;
  reg [3:0] qkmem_add_1 = 0;
  reg [3:0] pmem_add_1  = 0;

  // pack inst0
  always @(*) begin
    inst0_tb[19]   = VN_mode_0;
    inst0_tb[18]   = sfp_div_0;
    inst0_tb[17]   = sfp_acc_0;
    inst0_tb[16]   = sfp_processing_0;
    inst0_tb[15:12]= qkmem_add_0;
    inst0_tb[11:8] = pmem_add_0;
    inst0_tb[7]    = execute_0;
    inst0_tb[6]    = load_0;
    inst0_tb[5]    = qmem_rd_0;
    inst0_tb[4]    = qmem_wr_0;
    inst0_tb[3]    = kmem_rd_0;
    inst0_tb[2]    = kmem_wr_0;
    inst0_tb[1]    = pmem_rd_0;
    inst0_tb[0]    = pmem_wr_0;
  end

  // pack inst1
  always @(*) begin
    inst1_tb[19]   = VN_mode_1;
    inst1_tb[18]   = sfp_div_1;
    inst1_tb[17]   = sfp_acc_1;
    inst1_tb[16]   = sfp_processing_1;
    inst1_tb[15:12]= qkmem_add_1;
    inst1_tb[11:8] = pmem_add_1;
    inst1_tb[7]    = execute_1;
    inst1_tb[6]    = load_1;
    inst1_tb[5]    = qmem_rd_1;
    inst1_tb[4]    = qmem_wr_1;
    inst1_tb[3]    = kmem_rd_1;
    inst1_tb[2]    = kmem_wr_1;
    inst1_tb[1]    = pmem_rd_1;
    inst1_tb[0]    = pmem_wr_1;
  end

  wire [bw_psum*col*2-1:0] out;
  wire [bw_psum*col-1:0] pmem_out_core0;
  wire [bw_psum*col-1:0] pmem_out_core1;

  assign pmem_out_core0 = out[bw_psum*col-1:0];
  assign pmem_out_core1 = out[bw_psum*col*2-1:bw_psum*col];

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

  always #(CLK0_PERIOD/2.0) clk0 = ~clk0;
  always #(CLK1_PERIOD/2.0) clk1 = ~clk1;

  // -------------------------------
  // Phase/event control
  // -------------------------------
  event ev_start_q_write,  ev_done_q_write_0,  ev_done_q_write_1;
  event ev_start_k_write,  ev_done_k_write_0,  ev_done_k_write_1;
  event ev_start_k_load,   ev_done_k_load_0,   ev_done_k_load_1;
  event ev_start_q_exec,   ev_done_q_exec_0,   ev_done_q_exec_1;
  event ev_start_q_read,   ev_done_q_read_0,   ev_done_q_read_1;
  event ev_start_norm,     ev_done_norm_0,     ev_done_norm_1;
  event ev_start_v_write,  ev_done_v_write_0,  ev_done_v_write_1;
  event ev_start_v_load,   ev_done_v_load_0,   ev_done_v_load_1;
  event ev_start_n_write,  ev_done_n_write_0,  ev_done_n_write_1;
  event ev_start_vn_exec,  ev_done_vn_exec_0,  ev_done_vn_exec_1;
  event ev_start_vn_read,  ev_done_vn_read_0,  ev_done_vn_read_1;

  // -------------------------------
  // Helper tasks: core0 packing
  // -------------------------------
  task load_q_core0;
    input integer row_idx;
    begin
      mem_in_core0_tb[1*bw-1:0*bw] = Q[row_idx][7];
      mem_in_core0_tb[2*bw-1:1*bw] = Q[row_idx][6];
      mem_in_core0_tb[3*bw-1:2*bw] = Q[row_idx][5];
      mem_in_core0_tb[4*bw-1:3*bw] = Q[row_idx][4];
      mem_in_core0_tb[5*bw-1:4*bw] = Q[row_idx][3];
      mem_in_core0_tb[6*bw-1:5*bw] = Q[row_idx][2];
      mem_in_core0_tb[7*bw-1:6*bw] = Q[row_idx][1];
      mem_in_core0_tb[8*bw-1:7*bw] = Q[row_idx][0];
    end
  endtask

  task load_q_core1;
    input integer row_idx;
    begin
      mem_in_core1_tb[1*bw-1:0*bw] = Q[row_idx][15];
      mem_in_core1_tb[2*bw-1:1*bw] = Q[row_idx][14];
      mem_in_core1_tb[3*bw-1:2*bw] = Q[row_idx][13];
      mem_in_core1_tb[4*bw-1:3*bw] = Q[row_idx][12];
      mem_in_core1_tb[5*bw-1:4*bw] = Q[row_idx][11];
      mem_in_core1_tb[6*bw-1:5*bw] = Q[row_idx][10];
      mem_in_core1_tb[7*bw-1:6*bw] = Q[row_idx][9];
      mem_in_core1_tb[8*bw-1:7*bw] = Q[row_idx][8];
    end
  endtask

  task load_k_core0;
    input integer row_idx;
    begin
      mem_in_core0_tb[1*bw-1:0*bw] = K[row_idx][7];
      mem_in_core0_tb[2*bw-1:1*bw] = K[row_idx][6];
      mem_in_core0_tb[3*bw-1:2*bw] = K[row_idx][5];
      mem_in_core0_tb[4*bw-1:3*bw] = K[row_idx][4];
      mem_in_core0_tb[5*bw-1:4*bw] = K[row_idx][3];
      mem_in_core0_tb[6*bw-1:5*bw] = K[row_idx][2];
      mem_in_core0_tb[7*bw-1:6*bw] = K[row_idx][1];
      mem_in_core0_tb[8*bw-1:7*bw] = K[row_idx][0];
    end
  endtask

  task load_k_core1;
    input integer row_idx;
    begin
      mem_in_core1_tb[1*bw-1:0*bw] = K[row_idx][15];
      mem_in_core1_tb[2*bw-1:1*bw] = K[row_idx][14];
      mem_in_core1_tb[3*bw-1:2*bw] = K[row_idx][13];
      mem_in_core1_tb[4*bw-1:3*bw] = K[row_idx][12];
      mem_in_core1_tb[5*bw-1:4*bw] = K[row_idx][11];
      mem_in_core1_tb[6*bw-1:5*bw] = K[row_idx][10];
      mem_in_core1_tb[7*bw-1:6*bw] = K[row_idx][9];
      mem_in_core1_tb[8*bw-1:7*bw] = K[row_idx][8];
    end
  endtask

  task load_v_core0;
    input integer col_idx;
    begin
      mem_in_core0_tb[1*bw-1:0*bw] = V_T[7][col_idx];
      mem_in_core0_tb[2*bw-1:1*bw] = V_T[6][col_idx];
      mem_in_core0_tb[3*bw-1:2*bw] = V_T[5][col_idx];
      mem_in_core0_tb[4*bw-1:3*bw] = V_T[4][col_idx];
      mem_in_core0_tb[5*bw-1:4*bw] = V_T[3][col_idx];
      mem_in_core0_tb[6*bw-1:5*bw] = V_T[2][col_idx];
      mem_in_core0_tb[7*bw-1:6*bw] = V_T[1][col_idx];
      mem_in_core0_tb[8*bw-1:7*bw] = V_T[0][col_idx];
    end
  endtask

  task load_v_core1;
    input integer col_idx;
    begin
      mem_in_core1_tb[1*bw-1:0*bw] = V_T[15][col_idx];
      mem_in_core1_tb[2*bw-1:1*bw] = V_T[14][col_idx];
      mem_in_core1_tb[3*bw-1:2*bw] = V_T[13][col_idx];
      mem_in_core1_tb[4*bw-1:3*bw] = V_T[12][col_idx];
      mem_in_core1_tb[5*bw-1:4*bw] = V_T[11][col_idx];
      mem_in_core1_tb[6*bw-1:5*bw] = V_T[10][col_idx];
      mem_in_core1_tb[7*bw-1:6*bw] = V_T[9][col_idx];
      mem_in_core1_tb[8*bw-1:7*bw] = V_T[8][col_idx];
    end
  endtask

  task load_n_core_same;
    input integer row_idx;
    input integer which_core; // unused except to keep calls symmetric
    begin
      // N is only 8-wide, so both cores get the same N[row][0:7]
      if (which_core == 0) begin
        mem_in_core0_tb[1*bw-1:0*bw] = N[row_idx][7];
        mem_in_core0_tb[2*bw-1:1*bw] = N[row_idx][6];
        mem_in_core0_tb[3*bw-1:2*bw] = N[row_idx][5];
        mem_in_core0_tb[4*bw-1:3*bw] = N[row_idx][4];
        mem_in_core0_tb[5*bw-1:4*bw] = N[row_idx][3];
        mem_in_core0_tb[6*bw-1:5*bw] = N[row_idx][2];
        mem_in_core0_tb[7*bw-1:6*bw] = N[row_idx][1];
        mem_in_core0_tb[8*bw-1:7*bw] = N[row_idx][0];
      end else begin
        mem_in_core1_tb[1*bw-1:0*bw] = N[row_idx][7];
        mem_in_core1_tb[2*bw-1:1*bw] = N[row_idx][6];
        mem_in_core1_tb[3*bw-1:2*bw] = N[row_idx][5];
        mem_in_core1_tb[4*bw-1:3*bw] = N[row_idx][4];
        mem_in_core1_tb[5*bw-1:4*bw] = N[row_idx][3];
        mem_in_core1_tb[6*bw-1:5*bw] = N[row_idx][2];
        mem_in_core1_tb[7*bw-1:6*bw] = N[row_idx][1];
        mem_in_core1_tb[8*bw-1:7*bw] = N[row_idx][0];
      end
    end
  endtask

  // -------------------------------
  // Setup + orchestration + checking
  // -------------------------------
  initial begin
    $dumpfile("sim/waveform/fullchip.vcd");
    $dumpvars(0, fullchip_tb);

    mem_in_core0_tb = 0;
    mem_in_core1_tb = 0;

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        K[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        Q[i][j] = 0;

    for (i = 0; i < pr; i = i + 1)
      for (j = 0; j < col; j = j + 1)
        V_T[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < col; j = j + 1)
        N[i][j] = 0;

    $display("##### Q data txt reading #####");
    qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
    for (q = 0; q < total_cycle; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end

    $display("##### K data txt reading #####");
    qkvn_file = $fopen("sim/pattern/kdata.txt", "r");
    for (q = 0; q < col; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end

    $display("##### V data txt reading #####");
    qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
    for (q = 0; q < col; q = q + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        V_T[j][q] = captured_data;
      end

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

    for (t = 0; t < total_cycle; t = t + 1) begin
      for (q = 0; q < col; q = q + 1) begin
        vn_result_lo[t][q] = 0;
        vn_result_hi[t][q] = 0;
        for (k = 0; k < pr/2; k = k + 1) begin
          vn_result_lo[t][q] = vn_result_lo[t][q] + N[t][k] * V_T[k][q];
          vn_result_hi[t][q] = vn_result_hi[t][q] + N[t][k] * V_T[k+8][q];
        end
      end
    end

    repeat(5) @(posedge clk0);
    repeat(3) @(posedge clk1);
    reset = 0;

    // ---------------- Q write ----------------
    -> ev_start_q_write;
    @ev_done_q_write_0;
    @ev_done_q_write_1;

    // ---------------- K write ----------------
    -> ev_start_k_write;
    @ev_done_k_write_0;
    @ev_done_k_write_1;

    // ---------------- K load ----------------
    -> ev_start_k_load;
    @ev_done_k_load_0;
    @ev_done_k_load_1;

    repeat(10) @(posedge clk0);

    // ---------------- Q execute ----------------
    -> ev_start_q_exec;
    @ev_done_q_exec_0;
    @ev_done_q_exec_1;

    repeat(10) @(posedge clk0);

    // ---------------- QK read/check ----------------
    for (c = 0; c < col; c = c + 1)
      golden_col[c] = 7 - c;

    -> ev_start_q_read;
    @ev_done_q_read_0;
    @ev_done_q_read_1;

    err = 0;
    for (q = 0; q < total_cycle; q = q + 1) begin
      row = q;
      @(posedge clk0);
      for (c = 0; c < col; c = c + 1) begin
        sum_abs = $signed(pmem_out_core0[c*bw_psum +: bw_psum]) +
                  $signed(pmem_out_core1[c*bw_psum +: bw_psum]);
        unsigned_val = (sum_abs < 0) ? -sum_abs : sum_abs;
        estimated[q*pr + (7-c)] = (unsigned_val >>> sfp_out_shift);
        if (sum_abs !== qk_result[row][golden_col[c]])
          err = err + 1;
      end
    end

    // N from scoreboard
    for (q = 0; q < total_cycle; q = q + 1)
      for (j = 0; j < col; j = j + 1)
        N[q][j] = estimated[q*pr + j];

    // ---------------- normalization ----------------
    -> ev_start_norm;
    @ev_done_norm_0;
    @ev_done_norm_1;

    // ---------------- V write ----------------
    -> ev_start_v_write;
    @ev_done_v_write_0;
    @ev_done_v_write_1;

    // ---------------- V load ----------------
    -> ev_start_v_load;
    @ev_done_v_load_0;
    @ev_done_v_load_1;

    // recompute VN golden now that N is available
    for (t = 0; t < total_cycle; t = t + 1) begin
      for (q = 0; q < col; q = q + 1) begin
        vn_result_lo[t][q] = 0;
        vn_result_hi[t][q] = 0;
        for (k = 0; k < pr/2; k = k + 1) begin
          vn_result_lo[t][q] = vn_result_lo[t][q] + N[t][k] * V_T[k][q];
          vn_result_hi[t][q] = vn_result_hi[t][q] + N[t][k] * V_T[k+8][q];
        end
      end
    end

    // ---------------- N write ----------------
    -> ev_start_n_write;
    @ev_done_n_write_0;
    @ev_done_n_write_1;

    // ---------------- VN execute ----------------
    -> ev_start_vn_exec;
    @ev_done_vn_exec_0;
    @ev_done_vn_exec_1;

    repeat(10) @(posedge clk0);

    // ---------------- VN read ----------------
    -> ev_start_vn_read;
    @ev_done_vn_read_0;
    @ev_done_vn_read_1;

    $display("##### Final Verification #####");
    err = 0;

    for (q = 0; q < total_cycle; q = q + 1) begin
      row = q;
      @(posedge clk0);

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
          err = err + 1;
          row_err = row_err + 1;
        end
        if ($signed(pmem_out_core1[c*bw_psum +: bw_psum]) != $signed(vn_result_hi[row][golden_col[c]])) begin
          err = err + 1;
          row_err = row_err + 1;
        end
      end
      $display("  Status: %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
      $display("");
    end

    if (err == 0)
      $display("##### SIMULATION PASSED! Total Errors: %0d #####", err);
    else
      $display("##### SIMULATION FAILED! Total Errors: %0d #####", err);

    #100 $finish;
  end

  // -------------------------------
  // Core0 driver
  // -------------------------------
  initial begin
    forever begin
      @ev_start_q_write;
      for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
        @(posedge clk0);
        qmem_wr_0   = 1'b1;
        qkmem_add_0 = q0;
        load_q_core0(q0);
      end
      @(posedge clk0) qmem_wr_0 = 1'b0;
      -> ev_done_q_write_0;

      @ev_start_k_write;
      for (q0 = 0; q0 < col; q0 = q0 + 1) begin
        @(posedge clk0);
        kmem_wr_0   = 1'b1;
        qkmem_add_0 = q0;
        load_k_core0(q0);
      end
      @(posedge clk0) kmem_wr_0 = 1'b0;
      -> ev_done_k_write_0;

      @ev_start_k_load;
      @(posedge clk0) begin load_0 = 1'b1; kmem_rd_0 = 1'b1; qkmem_add_0 = 0; end
      repeat(col) @(posedge clk0) qkmem_add_0 = qkmem_add_0 + 1;
      @(posedge clk0) begin load_0 = 1'b0; kmem_rd_0 = 1'b0; end
      -> ev_done_k_load_0;

      @ev_start_q_exec;
      for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
        @(posedge clk0);
        execute_0   = 1'b1;
        qmem_rd_0   = 1'b1;
        qkmem_add_0 = q0;
      end
      @(posedge clk0) begin execute_0 = 1'b0; qmem_rd_0 = 1'b0; end
      -> ev_done_q_exec_0;

      @ev_start_q_read;
      @(posedge clk0) begin pmem_rd_0 = 1'b1; pmem_add_0 = 0; end
      for (q0 = 0; q0 < total_cycle; q0 = q0 + 1)
        @(posedge clk0) pmem_add_0 = q0 + 1;
      @(posedge clk0) pmem_rd_0 = 1'b0;
      -> ev_done_q_read_0;

      @ev_start_norm;
      sfp_processing_0 = 1'b1;
      pmem_rd_0 = 1'b1;
      for (q0 = 0; q0 < col; q0 = q0 + 1) begin
        @(posedge clk0) pmem_add_0 = q0;
        repeat(2) @(posedge clk0);
        @(posedge clk0) sfp_acc_0 = 1'b1;
        @(posedge clk0) sfp_acc_0 = 1'b0;
        repeat(10) @(posedge clk1);
        @(posedge clk0) sfp_div_0 = 1'b1;
        @(posedge clk0) sfp_div_0 = 1'b0;
        repeat(sfp_div_lat + 2) @(posedge clk0);
        @(posedge clk0) begin kmem_wr_0 = 1'b1; qkmem_add_0 = q0; end
        @(posedge clk0) kmem_wr_0 = 1'b0;
      end
      sfp_processing_0 = 1'b0;
      pmem_rd_0 = 1'b0;
      -> ev_done_norm_0;

      @ev_start_v_write;
      VN_mode_0 = 1'b1;
      for (q0 = 0; q0 < col; q0 = q0 + 1) begin
        @(posedge clk0);
        kmem_wr_0   = 1'b1;
        qkmem_add_0 = q0;
        load_v_core0(q0);
      end
      @(posedge clk0) kmem_wr_0 = 1'b0;
      -> ev_done_v_write_0;

      @ev_start_v_load;
      @(posedge clk0) begin load_0 = 1'b1; kmem_rd_0 = 1'b1; qkmem_add_0 = 0; end
      repeat(col) @(posedge clk0) qkmem_add_0 = qkmem_add_0 + 1;
      @(posedge clk0) begin load_0 = 1'b0; kmem_rd_0 = 1'b0; end
      -> ev_done_v_load_0;

      @ev_start_n_write;
      for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
        @(posedge clk0);
        qmem_wr_0   = 1'b1;
        qkmem_add_0 = q0;
        load_n_core_same(q0, 0);
      end
      @(posedge clk0) qmem_wr_0 = 1'b0;
      -> ev_done_n_write_0;

      @ev_start_vn_exec;
      for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
        @(posedge clk0);
        execute_0   = 1'b1;
        qmem_rd_0   = 1'b1;
        qkmem_add_0 = q0;
      end
      @(posedge clk0) begin execute_0 = 1'b0; qmem_rd_0 = 1'b0; end
      -> ev_done_vn_exec_0;

      @ev_start_vn_read;
      @(posedge clk0) begin pmem_rd_0 = 1'b1; pmem_add_0 = 0; end
      @(posedge clk0);
      for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
        @(posedge clk0);
        if (q0 < total_cycle - 1) pmem_add_0 = q0 + 1;
        else pmem_rd_0 = 1'b0;
      end
      -> ev_done_vn_read_0;
    end
  end

  // -------------------------------
  // Core1 driver
  // -------------------------------
  initial begin
    forever begin
      @ev_start_q_write;
      for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
        @(posedge clk1);
        qmem_wr_1   = 1'b1;
        qkmem_add_1 = q1;
        load_q_core1(q1);
      end
      @(posedge clk1) qmem_wr_1 = 1'b0;
      -> ev_done_q_write_1;

      @ev_start_k_write;
      for (q1 = 0; q1 < col; q1 = q1 + 1) begin
        @(posedge clk1);
        kmem_wr_1   = 1'b1;
        qkmem_add_1 = q1;
        load_k_core1(q1);
      end
      @(posedge clk1) kmem_wr_1 = 1'b0;
      -> ev_done_k_write_1;

      @ev_start_k_load;
      @(posedge clk1) begin load_1 = 1'b1; kmem_rd_1 = 1'b1; qkmem_add_1 = 0; end
      repeat(col) @(posedge clk1) qkmem_add_1 = qkmem_add_1 + 1;
      @(posedge clk1) begin load_1 = 1'b0; kmem_rd_1 = 1'b0; end
      -> ev_done_k_load_1;

      @ev_start_q_exec;
      for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
        @(posedge clk1);
        execute_1   = 1'b1;
        qmem_rd_1   = 1'b1;
        qkmem_add_1 = q1;
      end
      @(posedge clk1) begin execute_1 = 1'b0; qmem_rd_1 = 1'b0; end
      -> ev_done_q_exec_1;

      @ev_start_q_read;
      @(posedge clk1) begin pmem_rd_1 = 1'b1; pmem_add_1 = 0; end
      for (q1 = 0; q1 < total_cycle; q1 = q1 + 1)
        @(posedge clk1) pmem_add_1 = q1 + 1;
      @(posedge clk1) pmem_rd_1 = 1'b0;
      -> ev_done_q_read_1;

      @ev_start_norm;
      sfp_processing_1 = 1'b1;
      pmem_rd_1 = 1'b1;
      for (q1 = 0; q1 < col; q1 = q1 + 1) begin
        @(posedge clk1) pmem_add_1 = q1;
        repeat(2) @(posedge clk1);
        @(posedge clk1) sfp_acc_1 = 1'b1;
        @(posedge clk1) sfp_acc_1 = 1'b0;
        repeat(10) @(posedge clk0);
        @(posedge clk1) sfp_div_1 = 1'b1;
        @(posedge clk1) sfp_div_1 = 1'b0;
        repeat(sfp_div_lat + 2) @(posedge clk1);
        @(posedge clk1) begin kmem_wr_1 = 1'b1; qkmem_add_1 = q1; end
        @(posedge clk1) kmem_wr_1 = 1'b0;
      end
      sfp_processing_1 = 1'b0;
      pmem_rd_1 = 1'b0;
      -> ev_done_norm_1;

      @ev_start_v_write;
      VN_mode_1 = 1'b1;
      for (q1 = 0; q1 < col; q1 = q1 + 1) begin
        @(posedge clk1);
        kmem_wr_1   = 1'b1;
        qkmem_add_1 = q1;
        load_v_core1(q1);
      end
      @(posedge clk1) kmem_wr_1 = 1'b0;
      -> ev_done_v_write_1;

      @ev_start_v_load;
      @(posedge clk1) begin load_1 = 1'b1; kmem_rd_1 = 1'b1; qkmem_add_1 = 0; end
      repeat(col) @(posedge clk1) qkmem_add_1 = qkmem_add_1 + 1;
      @(posedge clk1) begin load_1 = 1'b0; kmem_rd_1 = 1'b0; end
      -> ev_done_v_load_1;

      @ev_start_n_write;
      for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
        @(posedge clk1);
        qmem_wr_1   = 1'b1;
        qkmem_add_1 = q1;
        load_n_core_same(q1, 1);
      end
      @(posedge clk1) qmem_wr_1 = 1'b0;
      -> ev_done_n_write_1;

      @ev_start_vn_exec;
      for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
        @(posedge clk1);
        execute_1   = 1'b1;
        qmem_rd_1   = 1'b1;
        qkmem_add_1 = q1;
      end
      @(posedge clk1) begin execute_1 = 1'b0; qmem_rd_1 = 1'b0; end
      -> ev_done_vn_exec_1;

      @ev_start_vn_read;
      @(posedge clk1) begin pmem_rd_1 = 1'b1; pmem_add_1 = 0; end
      @(posedge clk1);
      for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
        @(posedge clk1);
        if (q1 < total_cycle - 1) pmem_add_1 = q1 + 1;
        else pmem_rd_1 = 1'b0;
      end
      -> ev_done_vn_read_1;
    end
  end

endmodule

/*

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