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

  reg qk_checked = 0;

  reg n_ready       = 0;

  integer i, j, qm,q0,q1, k, t, c, row;
  integer qkvn_file, qkvn_scan_file, captured_data;
  integer err, row_err, sum_abs, unsigned_val;
  integer golden_col [0:col-1];

  integer K   [0:half_pr-1][0:pr-1];          // K  : 8 x 16  (rows x cols)
  integer Q   [0:total_cycle-1][0:half_pr-1]; // Q  : 8 x 8
  integer N   [0:half_pr-1][0:pr-1];          // N  : 8 x 16
  integer V_T [0:total_cycle-1][0:half_pr-1]; // VT : 8 x 8 (streamed like Q)

  integer qk_result       [0:total_cycle-1][0:pr-1];
  integer qk_result_core0 [0:total_cycle-1][0:col-1];
  integer qk_result_core1 [0:total_cycle-1][0:col-1];
  integer vn_result_lo    [0:total_cycle-1][0:col-1];
  integer vn_result_hi    [0:total_cycle-1][0:col-1];
  integer estimated       [0:total_cycle*pr-1];

  // captured DUT rows so checker does not drive pmem controls
  integer qk_cap_core0 [0:total_cycle-1][0:col-1];
  integer qk_cap_core1 [0:total_cycle-1][0:col-1];
  integer vn_cap_core0 [0:total_cycle-1][0:col-1];
  integer vn_cap_core1 [0:total_cycle-1][0:col-1];

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
    n_ready = 0;

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        K[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < half_pr; j = j + 1)
        Q[i][j] = 0;

    for (i = 0; i < total_cycle; i = i + 1)
      for (j = 0; j < half_pr; j = j + 1)
        V_T[i][j] = 0;

    for (i = 0; i < col; i = i + 1)
      for (j = 0; j < pr; j = j + 1)
        N[i][j] = 0;

    qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
    for (qm = 0; qm < total_cycle; qm = qm + 1)
      for (j = 0; j < col; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        Q[qm][j] = captured_data;
      end
    $fclose(qkvn_file);

    qkvn_file = $fopen("sim/pattern/kdata_dual.txt", "r");
    for (qm = 0; qm < col; qm = qm + 1)
      for (j = 0; j < pr; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        K[qm][j] = captured_data;
      end
    $fclose(qkvn_file);

    qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
    for (qm = 0; qm < half_pr; qm = qm + 1)
      for (j = 0; j < total_cycle; j = j + 1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        V_T[j][qm] = captured_data;
      end
    $fclose(qkvn_file);

    for (t = 0; t < total_cycle; t = t + 1)
      for (j = 0; j < pr; j = j + 1)
        qk_result[t][j] = 0;

    for (t = 0; t < total_cycle; t = t + 1)
      for (j = 0; j < col; j = j + 1) begin
        vn_result_lo[t][j] = 0;
        vn_result_hi[t][j] = 0;
        qk_result_core0[t][j] = 0;
        qk_result_core1[t][j] = 0;
        qk_cap_core0[t][j] = 0;
        qk_cap_core1[t][j] = 0;
        vn_cap_core0[t][j] = 0;
        vn_cap_core1[t][j] = 0;
      end

      // Golden Q x K = (8x8) x (8x16) = 8x16
    for (t = 0; t < total_cycle; t = t + 1)
      for (qm = 0; qm < pr; qm = qm + 1)
        for (k = 0; k < half_pr; k = k + 1)
          qk_result[t][qm] = qk_result[t][qm] + Q[t][k] * K[k][qm];

    for (t = 0; t < total_cycle; t = t + 1)
      for (qm = 0; qm < col; qm = qm + 1) begin
        qk_result_core0[t][qm] = qk_result[t][qm];
        qk_result_core1[t][qm] = qk_result[t][qm+col];
      end

    repeat(5) @(posedge clk0);
    repeat(3) @(posedge clk1);
    reset = 0;
    //compare QK
    // wait long enough for both core stimulus blocks to complete QK phase
    wait(core0_qk_done && core1_qk_done);
    repeat(2) @(posedge clk0);

    for (c = 0; c < col; c = c + 1)
      golden_col[c] = 7 - c;

    err = 0;

    //@(posedge clk0);
    //pmem_rd_0 = 1;
    //pmem_add_0 = 0;
    //@(posedge clk1);
    //pmem_rd_1 = 1;
    //pmem_add_1 = 0;

    for (qm = 0; qm < total_cycle; qm = qm + 1) begin
      row = qm;
      row_err = 0;
      for (c = 0; c < col; c = c + 1) begin
        if (qk_cap_core0[row][c] !== qk_result_core0[row][golden_col[c]]) begin
          err = err + 1;
          row_err = row_err + 1;
          $display("QK core0 mismatch row=%0d col=%0d RTL=%0d golden=%0d",
                   row, c, qk_cap_core0[row][c], qk_result_core0[row][golden_col[c]]);
        end
        if (qk_cap_core1[row][c] !== qk_result_core1[row][golden_col[c]]) begin
          err = err + 1;
          row_err = row_err + 1;
          $display("QK core1 mismatch row=%0d col=%0d RTL=%0d golden=%0d",
                   row, c, qk_cap_core1[row][c], qk_result_core1[row][golden_col[c]]);
        end
      end
      $display("QK row %0d : %s", row, (row_err == 0) ? "OK" : "MISMATCH");
    end

    qk_checked = 1;
    
    
    //compare QK golden vs hardWARE PROD OUTPUT

    //VN phase 
    `ifdef LOAD_OTHER_NORM_FILE
      qkvn_file = $fopen("sim/pattern/norm_dual.txt", "r");
      for (qm = 0; qm < half_pr; qm = qm + 1)
        for (j = 0; j < pr; j = j + 1) begin
          qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
          N[qm][j] = captured_data;
        end
      $fclose(qkvn_file);
      n_ready = 1;
      `else
        for (qm = 0; qm < total_cycle; qm = qm + 1) begin
        sum_abs = 0;
        for (j = 0; j < pr; j = j + 1) begin
          unsigned_val = qk_result[qm][j];
          if (unsigned_val < 0)
            unsigned_val = -unsigned_val;
          sum_abs = sum_abs + unsigned_val;
        end
        if (sum_abs == 0)
          sum_abs = 1;

        for (j = 0; j < pr; j = j + 1) begin
          unsigned_val = qk_result[qm][j];
          if (unsigned_val < 0)
            unsigned_val = -unsigned_val;
          N[qm][j] = (unsigned_val <<< sfp_out_shift) / sum_abs;
          estimated[qm*pr + j] = N[qm][j];
        end
        end
    `endif

    //golden VT x N

    for (t = 0; t < total_cycle; t = t + 1)
      for (qm = 0; qm < col; qm = qm + 1) begin
        vn_result_lo[t][qm] = 0;
        vn_result_hi[t][qm] = 0;
        for (k = 0; k < half_pr; k = k + 1) begin
          vn_result_lo[t][qm] = vn_result_lo[t][qm] + N[k][qm] * V_T[t][k];
          vn_result_hi[t][qm] = vn_result_hi[t][qm] + N[k][qm+8] * V_T[t][k];
        end
      end
    //compare VN phase
    // wait long enough for VN phase to complete
    wait(core0_vn_done && core1_vn_done);
    repeat(2) @(posedge clk0);

    err = 0;
    
    //@(posedge clk0);
    //pmem_rd_0 = 1;
    //pmem_add_0 = 0;
    //@(posedge clk1);
    //pmem_rd_1 = 1;
    //pmem_add_1 = 0;

    for (qm = 0; qm < total_cycle; qm = qm + 1) begin
      //@(posedge clk0);
      row = qm;
      row_err = 0;
      for (c = 0; c < col; c = c + 1) begin
        if (vn_cap_core0[row][c] != vn_result_lo[row][7-c]) begin
          err = err + 1;
          row_err = row_err + 1;
          $display("VN core0 mismatch row=%0d col=%0d RTL=%0d golden=%0d",
                   row, c, vn_cap_core0[row][c], vn_result_lo[row][7-c]);
        end
        if (vn_cap_core1[row][c] != vn_result_hi[row][7-c]) begin
          err = err + 1;
          row_err = row_err + 1;
          $display("VN core1 mismatch row=%0d col=%0d RTL=%0d golden=%0d",
                   row, c, vn_cap_core1[row][c], vn_result_hi[row][7-c]);
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
    for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
      @(posedge clk0);
      qmem_wr_0 = 1;
      qkmem_add_0 = q0;
      mem_in_core0[1*bw-1:0*bw] = Q[q0][7];
      mem_in_core0[2*bw-1:1*bw] = Q[q0][6];
      mem_in_core0[3*bw-1:2*bw] = Q[q0][5];
      mem_in_core0[4*bw-1:3*bw] = Q[q0][4];
      mem_in_core0[5*bw-1:4*bw] = Q[q0][3];
      mem_in_core0[6*bw-1:5*bw] = Q[q0][2];
      mem_in_core0[7*bw-1:6*bw] = Q[q0][1];
      mem_in_core0[8*bw-1:7*bw] = Q[q0][0];
    end
    @(posedge clk0) qmem_wr_0 = 0;

    // K write
    for (q0 = 0; q0 < col; q0 = q0 + 1) begin
      @(posedge clk0);
      kmem_wr_0 = 1;
      qkmem_add_0 = q0;
      mem_in_core0[1*bw-1:0*bw] = K[q0][7];
      mem_in_core0[2*bw-1:1*bw] = K[q0][6];
      mem_in_core0[3*bw-1:2*bw] = K[q0][5];
      mem_in_core0[4*bw-1:3*bw] = K[q0][4];
      mem_in_core0[5*bw-1:4*bw] = K[q0][3];
      mem_in_core0[6*bw-1:5*bw] = K[q0][2];
      mem_in_core0[7*bw-1:6*bw] = K[q0][1];
      mem_in_core0[8*bw-1:7*bw] = K[q0][0];
    end
    @(posedge clk0) kmem_wr_0 = 0;

    // K load
    @(posedge clk0) begin load_0 = 1; kmem_rd_0 = 1; qkmem_add_0 = 0; end
    repeat(col) @(posedge clk0) qkmem_add_0 = qkmem_add_0 + 1;
    @(posedge clk0) begin load_0 = 0; kmem_rd_0 = 0; end

    repeat(10) @(posedge clk0);

    // Q execute
    for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
      @(posedge clk0);
      execute_0 = 1;
      qmem_rd_0 = 1;
      qkmem_add_0 = q0;
    end
    @(posedge clk0) begin execute_0 = 0; qmem_rd_0 = 0; end

    repeat(10) @(posedge clk0);

    // QK read
    @(posedge clk0) begin pmem_rd_0 = 1; pmem_add_0 = 0; end
    @(posedge clk0) begin
      qk_cap_core0[0][0] = $signed(pmem_out_core0[0*bw_psum +: bw_psum]);
      qk_cap_core0[0][1] = $signed(pmem_out_core0[1*bw_psum +: bw_psum]);
      qk_cap_core0[0][2] = $signed(pmem_out_core0[2*bw_psum +: bw_psum]);
      qk_cap_core0[0][3] = $signed(pmem_out_core0[3*bw_psum +: bw_psum]);
      qk_cap_core0[0][4] = $signed(pmem_out_core0[4*bw_psum +: bw_psum]);
      qk_cap_core0[0][5] = $signed(pmem_out_core0[5*bw_psum +: bw_psum]);
      qk_cap_core0[0][6] = $signed(pmem_out_core0[6*bw_psum +: bw_psum]);
      qk_cap_core0[0][7] = $signed(pmem_out_core0[7*bw_psum +: bw_psum]);
    end
    for (q0 = 1; q0 < total_cycle; q0 = q0 + 1)begin
      @(posedge clk0) pmem_add_0 = q0;
      @(posedge clk0) begin
        
        qk_cap_core0[q0][0] = $signed(pmem_out_core0[0*bw_psum +: bw_psum]);
        qk_cap_core0[q0][1] = $signed(pmem_out_core0[1*bw_psum +: bw_psum]);
        qk_cap_core0[q0][2] = $signed(pmem_out_core0[2*bw_psum +: bw_psum]);
        qk_cap_core0[q0][3] = $signed(pmem_out_core0[3*bw_psum +: bw_psum]);
        qk_cap_core0[q0][4] = $signed(pmem_out_core0[4*bw_psum +: bw_psum]);
        qk_cap_core0[q0][5] = $signed(pmem_out_core0[5*bw_psum +: bw_psum]);
        qk_cap_core0[q0][6] = $signed(pmem_out_core0[6*bw_psum +: bw_psum]);
        qk_cap_core0[q0][7] = $signed(pmem_out_core0[7*bw_psum +: bw_psum]);
      end
    end
    @(posedge clk0) pmem_rd_0 = 0;

    core0_qk_done = 1;
    wait(qk_checked == 1);

    // normalization
    sfp_processing_0 = 1;
    pmem_rd_0 = 1;
    for (q0 = 0; q0 < col; q0 = q0 + 1) begin
      @(posedge clk0) pmem_add_0 = q0;
      repeat(2) @(posedge clk0);
      @(posedge clk0) sfp_acc_0 = 1;
      @(posedge clk0) sfp_acc_0 = 0;
      repeat(10) @(posedge clk1);
      @(posedge clk0) sfp_div_0 = 1;
      @(posedge clk0) sfp_div_0 = 0;
      repeat(sfp_div_lat + 2) @(posedge clk0);
      @(posedge clk0) begin kmem_wr_0 = 1; qkmem_add_0 = q0; end
      @(posedge clk0) kmem_wr_0 = 0;
    end
    sfp_processing_0 = 0;
    pmem_rd_0 = 0;

    // V write
    VN_mode_0 = 1;
    for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
      @(posedge clk0);
      qmem_wr_0 = 1;
      qkmem_add_0 = q0;
      mem_in_core0[1*bw-1:0*bw] = V_T[q0][7];
      mem_in_core0[2*bw-1:1*bw] = V_T[q0][6];
      mem_in_core0[3*bw-1:2*bw] = V_T[q0][5];
      mem_in_core0[4*bw-1:3*bw] = V_T[q0][4];
      mem_in_core0[5*bw-1:4*bw] = V_T[q0][3];
      mem_in_core0[6*bw-1:5*bw] = V_T[q0][2];
      mem_in_core0[7*bw-1:6*bw] = V_T[q0][1];
      mem_in_core0[8*bw-1:7*bw] = V_T[q0][0];
    end
    @(posedge clk0) qmem_wr_0 = 0;

    `ifdef LOAD_OTHER_NORM_FILE

    wait(n_ready == 1);

    // N write
    for (q0 = 0; q0 < col; q0 = q0 + 1) begin
      @(posedge clk0);
      kmem_wr_0 = 1;
      qkmem_add_0 = q0;
      mem_in_core0[1*bw-1:0*bw] = N[q0][7];
      mem_in_core0[2*bw-1:1*bw] = N[q0][6];
      mem_in_core0[3*bw-1:2*bw] = N[q0][5];
      mem_in_core0[4*bw-1:3*bw] = N[q0][4];
      mem_in_core0[5*bw-1:4*bw] = N[q0][3];
      mem_in_core0[6*bw-1:5*bw] = N[q0][2];
      mem_in_core0[7*bw-1:6*bw] = N[q0][1];
      mem_in_core0[8*bw-1:7*bw] = N[q0][0];
    end
    @(posedge clk0) kmem_wr_0 = 0;
    

    // N load
    @(posedge clk0) begin load_0 = 1; kmem_rd_0 = 1; qkmem_add_0 = 0; end
    repeat(col) @(posedge clk0) qkmem_add_0 = qkmem_add_0 + 1;
    @(posedge clk0) begin load_0 = 0; kmem_rd_0 = 0; end
    `endif 
    
    // VN execute
    for (q0 = 0; q0 < total_cycle; q0 = q0 + 1) begin
      @(posedge clk0);
      execute_0 = 1;
      qmem_rd_0 = 1;
      qkmem_add_0 = q0;
    end
    @(posedge clk0) begin execute_0 = 0; qmem_rd_0 = 0; end

    repeat(10) @(posedge clk0);

    // VN read
    @(posedge clk0) begin pmem_rd_0 = 1; pmem_add_0 = 0; end
    @(posedge clk0)begin
      vn_cap_core0[0][0] = $signed(pmem_out_core0[0*bw_psum +: bw_psum]);
      vn_cap_core0[0][1] = $signed(pmem_out_core0[1*bw_psum +: bw_psum]);
      vn_cap_core0[0][2] = $signed(pmem_out_core0[2*bw_psum +: bw_psum]);
      vn_cap_core0[0][3] = $signed(pmem_out_core0[3*bw_psum +: bw_psum]);
      vn_cap_core0[0][4] = $signed(pmem_out_core0[4*bw_psum +: bw_psum]);
      vn_cap_core0[0][5] = $signed(pmem_out_core0[5*bw_psum +: bw_psum]);
      vn_cap_core0[0][6] = $signed(pmem_out_core0[6*bw_psum +: bw_psum]);
      vn_cap_core0[0][7] = $signed(pmem_out_core0[7*bw_psum +: bw_psum]);
    end
    for (q0 = 1; q0 < total_cycle; q0 = q0 + 1) begin
      @(posedge clk0) pmem_add_0 = q0;
      @(posedge clk0) begin
        //pmem_add_0 = q0;
        vn_cap_core0[q0][0] = $signed(pmem_out_core0[0*bw_psum +: bw_psum]);
        vn_cap_core0[q0][1] = $signed(pmem_out_core0[1*bw_psum +: bw_psum]);
        vn_cap_core0[q0][2] = $signed(pmem_out_core0[2*bw_psum +: bw_psum]);
        vn_cap_core0[q0][3] = $signed(pmem_out_core0[3*bw_psum +: bw_psum]);
        vn_cap_core0[q0][4] = $signed(pmem_out_core0[4*bw_psum +: bw_psum]);
        vn_cap_core0[q0][5] = $signed(pmem_out_core0[5*bw_psum +: bw_psum]);
        vn_cap_core0[q0][6] = $signed(pmem_out_core0[6*bw_psum +: bw_psum]);
        vn_cap_core0[q0][7] = $signed(pmem_out_core0[7*bw_psum +: bw_psum]);
      end
    end
    @(posedge clk0) pmem_rd_0 = 0;

    core0_vn_done = 1;

  end

  // core1 driver
  initial begin
    wait(reset == 0);

    // Q write
    VN_mode_1 = 0;
    for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
      @(posedge clk1);
      qmem_wr_1 = 1;
      qkmem_add_1 = q1;
      mem_in_core1[1*bw-1:0*bw] = Q[q1][7];
      mem_in_core1[2*bw-1:1*bw] = Q[q1][6];
      mem_in_core1[3*bw-1:2*bw] = Q[q1][5];
      mem_in_core1[4*bw-1:3*bw] = Q[q1][4];
      mem_in_core1[5*bw-1:4*bw] = Q[q1][3];
      mem_in_core1[6*bw-1:5*bw] = Q[q1][2];
      mem_in_core1[7*bw-1:6*bw] = Q[q1][1];
      mem_in_core1[8*bw-1:7*bw] = Q[q1][0];
    end
    @(posedge clk1) qmem_wr_1 = 0;

    // K write
    for (q1 = 0; q1 < col; q1 = q1 + 1) begin
      @(posedge clk1);
      kmem_wr_1 = 1;
      qkmem_add_1 = q1;
      mem_in_core1[1*bw-1:0*bw] = K[q1][15];
      mem_in_core1[2*bw-1:1*bw] = K[q1][14];
      mem_in_core1[3*bw-1:2*bw] = K[q1][13];
      mem_in_core1[4*bw-1:3*bw] = K[q1][12];
      mem_in_core1[5*bw-1:4*bw] = K[q1][11];
      mem_in_core1[6*bw-1:5*bw] = K[q1][10];
      mem_in_core1[7*bw-1:6*bw] = K[q1][9];
      mem_in_core1[8*bw-1:7*bw] = K[q1][8];
    end
    @(posedge clk1) kmem_wr_1 = 0;

    // K load
    @(posedge clk1) begin load_1 = 1; kmem_rd_1 = 1; qkmem_add_1 = 0; end
    repeat(col) @(posedge clk1) qkmem_add_1 = qkmem_add_1 + 1;
    @(posedge clk1) begin load_1 = 0; kmem_rd_1 = 0; end

    repeat(10) @(posedge clk1);

    // Q execute
    for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
      @(posedge clk1);
      execute_1 = 1;
      qmem_rd_1 = 1;
      qkmem_add_1 = q1;
    end
    @(posedge clk1) begin execute_1 = 0; qmem_rd_1 = 0; end

    repeat(10) @(posedge clk1);

    // QK read
    @(posedge clk1) begin pmem_rd_1 = 1; pmem_add_1 = 0; end
    @(posedge clk1) begin
      qk_cap_core1[0][0] = $signed(pmem_out_core1[0*bw_psum +: bw_psum]);
      qk_cap_core1[0][1] = $signed(pmem_out_core1[1*bw_psum +: bw_psum]);
      qk_cap_core1[0][2] = $signed(pmem_out_core1[2*bw_psum +: bw_psum]);
      qk_cap_core1[0][3] = $signed(pmem_out_core1[3*bw_psum +: bw_psum]);
      qk_cap_core1[0][4] = $signed(pmem_out_core1[4*bw_psum +: bw_psum]);
      qk_cap_core1[0][5] = $signed(pmem_out_core1[5*bw_psum +: bw_psum]);
      qk_cap_core1[0][6] = $signed(pmem_out_core1[6*bw_psum +: bw_psum]);
      qk_cap_core1[0][7] = $signed(pmem_out_core1[7*bw_psum +: bw_psum]);
    end
    for (q1 = 1; q1 < total_cycle; q1 = q1 + 1) begin
      @(posedge clk1) pmem_add_1 = q1;
      @(posedge clk1) begin
        //pmem_add_1 = q1;
        qk_cap_core1[q1][0] = $signed(pmem_out_core1[0*bw_psum +: bw_psum]);
        qk_cap_core1[q1][1] = $signed(pmem_out_core1[1*bw_psum +: bw_psum]);
        qk_cap_core1[q1][2] = $signed(pmem_out_core1[2*bw_psum +: bw_psum]);
        qk_cap_core1[q1][3] = $signed(pmem_out_core1[3*bw_psum +: bw_psum]);
        qk_cap_core1[q1][4] = $signed(pmem_out_core1[4*bw_psum +: bw_psum]);
        qk_cap_core1[q1][5] = $signed(pmem_out_core1[5*bw_psum +: bw_psum]);
        qk_cap_core1[q1][6] = $signed(pmem_out_core1[6*bw_psum +: bw_psum]);
        qk_cap_core1[q1][7] = $signed(pmem_out_core1[7*bw_psum +: bw_psum]);
      end
    end
    @(posedge clk1) pmem_rd_1 = 0;

    core1_qk_done = 1;

    wait(qk_checked == 1);

    // normalization
    sfp_processing_1 = 1;
    pmem_rd_1 = 1;
    for (q1 = 0; q1 < col; q1 = q1 + 1) begin
      @(posedge clk1) pmem_add_1 = q1;
      repeat(2) @(posedge clk1);
      @(posedge clk1) sfp_acc_1 = 1;
      @(posedge clk1) sfp_acc_1 = 0;
      repeat(10) @(posedge clk0);
      @(posedge clk1) sfp_div_1 = 1;
      @(posedge clk1) sfp_div_1 = 0;
      repeat(sfp_div_lat + 2) @(posedge clk1);
      @(posedge clk1) begin kmem_wr_1 = 1; qkmem_add_1 = q1; end
      @(posedge clk1) kmem_wr_1 = 0;
    end
    sfp_processing_1 = 0;
    pmem_rd_1 = 0;

    // V write
    VN_mode_1 = 1;
    for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
      @(posedge clk1);
      qmem_wr_1 = 1;
      qkmem_add_1 = q1;
      mem_in_core1[1*bw-1:0*bw] = V_T[q1][7];
      mem_in_core1[2*bw-1:1*bw] = V_T[q1][6];
      mem_in_core1[3*bw-1:2*bw] = V_T[q1][5];
      mem_in_core1[4*bw-1:3*bw] = V_T[q1][4];
      mem_in_core1[5*bw-1:4*bw] = V_T[q1][3];
      mem_in_core1[6*bw-1:5*bw] = V_T[q1][2];
      mem_in_core1[7*bw-1:6*bw] = V_T[q1][1];
      mem_in_core1[8*bw-1:7*bw] = V_T[q1][0];
    end
    @(posedge clk1) qmem_wr_1 = 0;

  
  `ifdef LOAD_OTHER_NORM_FILE
    wait(n_ready == 1);

    // N write
    for (q1 = 0; q1 < col; q1 = q1 + 1) begin
      @(posedge clk1);
      kmem_wr_1 = 1;
      qkmem_add_1 = q1;
      mem_in_core1[1*bw-1:0*bw] = N[q1][15];
      mem_in_core1[2*bw-1:1*bw] = N[q1][14];
      mem_in_core1[3*bw-1:2*bw] = N[q1][13];
      mem_in_core1[4*bw-1:3*bw] = N[q1][12];
      mem_in_core1[5*bw-1:4*bw] = N[q1][11];
      mem_in_core1[6*bw-1:5*bw] = N[q1][10];
      mem_in_core1[7*bw-1:6*bw] = N[q1][9];
      mem_in_core1[8*bw-1:7*bw] = N[q1][8];
    end
    @(posedge clk1) kmem_wr_1 = 0;

    // N load
    @(posedge clk1) begin load_1 = 1; kmem_rd_1 = 1; qkmem_add_1 = 0; end
    repeat(col) @(posedge clk1) qkmem_add_1 = qkmem_add_1 + 1;
    @(posedge clk1) begin load_1 = 0; kmem_rd_1 = 0; end

    `endif

    // VN execute
    for (q1 = 0; q1 < total_cycle; q1 = q1 + 1) begin
      @(posedge clk1);
      execute_1 = 1;
      qmem_rd_1 = 1;
      qkmem_add_1 = q1;
    end
    @(posedge clk1) begin execute_1 = 0; qmem_rd_1 = 0; end

    repeat(10) @(posedge clk1);

    // VN read
    @(posedge clk1) begin pmem_rd_1 = 1; pmem_add_1 = 0; end
    @(posedge clk1) begin
      vn_cap_core1[0][0] = $signed(pmem_out_core1[0*bw_psum +: bw_psum]);
      vn_cap_core1[0][1] = $signed(pmem_out_core1[1*bw_psum +: bw_psum]);
      vn_cap_core1[0][2] = $signed(pmem_out_core1[2*bw_psum +: bw_psum]);
      vn_cap_core1[0][3] = $signed(pmem_out_core1[3*bw_psum +: bw_psum]);
      vn_cap_core1[0][4] = $signed(pmem_out_core1[4*bw_psum +: bw_psum]);
      vn_cap_core1[0][5] = $signed(pmem_out_core1[5*bw_psum +: bw_psum]);
      vn_cap_core1[0][6] = $signed(pmem_out_core1[6*bw_psum +: bw_psum]);
      vn_cap_core1[0][7] = $signed(pmem_out_core1[7*bw_psum +: bw_psum]);
    end
    for (q1 = 1; q1 < total_cycle; q1 = q1 + 1) begin
      @(posedge clk1) pmem_add_1 = q1;
      @(posedge clk1) begin
        //pmem_add_1 = q1;
        vn_cap_core1[q1][0] = $signed(pmem_out_core1[0*bw_psum +: bw_psum]);
        vn_cap_core1[q1][1] = $signed(pmem_out_core1[1*bw_psum +: bw_psum]);
        vn_cap_core1[q1][2] = $signed(pmem_out_core1[2*bw_psum +: bw_psum]);
        vn_cap_core1[q1][3] = $signed(pmem_out_core1[3*bw_psum +: bw_psum]);
        vn_cap_core1[q1][4] = $signed(pmem_out_core1[4*bw_psum +: bw_psum]);
        vn_cap_core1[q1][5] = $signed(pmem_out_core1[5*bw_psum +: bw_psum]);
        vn_cap_core1[q1][6] = $signed(pmem_out_core1[6*bw_psum +: bw_psum]);
        vn_cap_core1[q1][7] = $signed(pmem_out_core1[7*bw_psum +: bw_psum]);
      end
    end
    @(posedge clk1) pmem_rd_1 = 0;

    core1_vn_done = 1;

  end

endmodule
