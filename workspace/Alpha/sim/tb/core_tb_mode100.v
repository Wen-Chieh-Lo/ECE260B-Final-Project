// Mac verification: TB + DUT (mac_array_top) in one file.
// Phase 1 (QK product): Q/K files -> qmem/kmem write -> K load -> execute -> sample pmem out, compare to golden.
// Phase 2 (Normalize ): sfu_row takes input from pmem, and store output into kmem. Golden is displayed by tb simultaneously.
// Phase 3 (VN product): LOAD_OTHER_NORM_FILE decides whether we use TA's norm.txt. Other than that, the flow is identical to phase 1.   

// `define LOAD_OTHER_NORM_FILE     // If you want to use TA's norm.txt 

`timescale 1ns/1ps
`define CYCLE 1
`define H_CYCLE 0.5
`define TIME_OUT 100000


module core_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;
  parameter sfp_acc_lat = 1;
  `ifdef SFP_LONGDIV
    parameter sfp_div_lat = 8;  // div_longdiv: 1 input reg + 6 iter + 1
  `else
    parameter sfp_div_lat = 0;
  `endif

  //================= integer / array storage =====================//
  integer qkvn_file, qkvn_scan_file, captured_data;
  integer i, j, k, t, p, q, s, u, m, r, c;
  integer err_count;
  integer err, row_err, row;
  integer sum_abs, divisor, unsigned_val;

  integer weight   [col*pr-1:0];
  integer K        [col-1:0][pr-1:0];
  integer Q        [total_cycle-1:0][pr-1:0];
  integer N        [col-1:0][pr-1:0]; 
  integer V_T      [total_cycle-1:0][pr-1:0];
  integer result   [total_cycle-1:0][col-1:0];
  integer sum      [total_cycle-1:0];
  integer estimated[0:total_cycle*col-1];   // computed from mac_data (same formula as sfp_row)

  integer u0, u1, u2, u3, u4, u5, u6, u7;

  //================= DUT signals ==================//
  reg        reset = 1;
  reg        clk   = 0;
  reg [pr*bw-1:0]   mem_in;
  reg  [1:0]        mem_cmd_ext = 2'd0;
  reg  [3:0]        addr_ext = 4'd0;
  reg               sfp_processing = 0;
  reg               sfp_div = 0, sfp_acc = 0;
  reg               VN_mode = 0;

  reg qmem_rd = 0, qmem_wr = 0;
  reg kmem_rd = 0, kmem_wr = 0;
  reg pmem_rd = 0, pmem_wr = 0;

  reg        execute = 0, load = 0;
  reg [3:0]  qkmem_add = 0;
  reg [3:0]  pmem_add  = 0;

  reg  [bw_psum-1:0]     temp5b;
  reg  [bw_psum+3:0]     temp_sum;
  reg  [bw_psum*col-1:0] temp16b;

  //================= core interface ==================//
  wire [bw_psum*col-1:0] pmem_out;

  integer                golden_col [0:7];  // RTL col c -> golden result[t][golden_col[c]] (chain mapping)

  reg        start = 0;   // controller start (not used when driving inst from tb)
  wire [2:0] status;      // {busy, qmem_locked, kmem_locked} from controller

  wire   [5:0]         inst_ext;
  assign inst_ext[5:2] = addr_ext;
  assign inst_ext[1:0] = mem_cmd_ext;
  // 00: No Op, 01: kmem wr, 10: qmem wr, 11: pmem rd
  localparam EXT_CMD_NO_OP   = 2'b00;
  localparam EXT_CMD_KMEM_WR = 2'b01;
  localparam EXT_CMD_QMEM_WR = 2'b10;
  localparam EXT_CMD_PMEM_RD = 2'b11;

  localparam OP_MODE_MULT_NORM = 1'b0;
  localparam OP_MODE_MULT		   = 1'b1;



  core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core_instance (
    .reset(reset),
    .clk(clk),
    .mem_in(mem_in),
    .inst_ext(inst_ext),
    .sum_out(),
    .out(pmem_out),
    .start(start),
    .status(status)
  );

  

  //================= clk ==========================//
  always #(`H_CYCLE) clk = ~clk;

  //================= timeout ======================//
  initial #(`TIME_OUT) $finish;
  

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

    repeat(2) @(negedge clk);

    $display("##### K data txt reading #####");
    repeat(10) @(negedge clk);
    apply_2cycles_reset;


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
        // temp5b = result[t][q];
        // temp16b = {temp16b[139:0], temp5b};
      end
      // $display("prd @cycle%2d: %40h", t, temp16b);
    end


    $display("QK Product Phase");
    mem_cmd_ext = EXT_CMD_QMEM_WR;

    $display("##### Qmem writing #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      @(negedge clk);
      if (q > 0) addr_ext = addr_ext + 1;
      mem_in[1*bw-1:0*bw] = Q[q][7];
      mem_in[2*bw-1:1*bw] = Q[q][6];
      mem_in[3*bw-1:2*bw] = Q[q][5];
      mem_in[4*bw-1:3*bw] = Q[q][4];
      mem_in[5*bw-1:4*bw] = Q[q][3];
      mem_in[6*bw-1:5*bw] = Q[q][2];
      mem_in[7*bw-1:6*bw] = Q[q][1];
      mem_in[8*bw-1:7*bw] = Q[q][0];
      @(posedge clk);
    end
    @(negedge clk);
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext = 0;
    @(posedge clk);

    mem_cmd_ext = EXT_CMD_KMEM_WR;
    $display("##### Kmem writing #####");
    for (q = 0; q < col; q = q+1) begin
      @(negedge clk);
      if (q > 0) addr_ext = addr_ext + 1;
      mem_in[1*bw-1:0*bw] = K[q][7];
      mem_in[2*bw-1:1*bw] = K[q][6];
      mem_in[3*bw-1:2*bw] = K[q][5];
      mem_in[4*bw-1:3*bw] = K[q][4];
      mem_in[5*bw-1:4*bw] = K[q][3];
      mem_in[6*bw-1:5*bw] = K[q][2];
      mem_in[7*bw-1:6*bw] = K[q][1];
      mem_in[8*bw-1:7*bw] = K[q][0];
      @(posedge clk);
    end
    @(negedge clk);
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext = 0;
    @(posedge clk);

    repeat(2) @(negedge clk);


    @(negedge clk); start = 1;
    @(negedge clk); start = 0;
        
    repeat(32) @(negedge clk);




mem_cmd_ext = EXT_CMD_PMEM_RD;
// RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
    for (c = 0; c < col; c = c+1)
      golden_col[c] = 7 - c;
  $display("QK phase verification start (checking pmem content)\n");
  $display("##### sample pmem content & compare to golden #####");
  $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
  $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
  err = 0;
  
  @(negedge clk); addr_ext=4'd0;
  for (q = 0; q < total_cycle; q = q+1) begin
    @(negedge clk); addr_ext = addr_ext+1; // sample before posedge: pmem_out = row being read (result[q])
    row = q;
    $display("   [%0d]   RTL   : %7d %7d %7d %7d %7d %7d %7d %7d", row,
      $signed(pmem_out[7*bw_psum +: bw_psum]), $signed(pmem_out[6*bw_psum +: bw_psum]),
      $signed(pmem_out[5*bw_psum +: bw_psum]), $signed(pmem_out[4*bw_psum +: bw_psum]),
      $signed(pmem_out[3*bw_psum +: bw_psum]), $signed(pmem_out[2*bw_psum +: bw_psum]),
      $signed(pmem_out[1*bw_psum +: bw_psum]), $signed(pmem_out[0*bw_psum +: bw_psum]));
    $display("         golden: %7d %7d %7d %7d %7d %7d %7d %7d",
      result[row][0], result[row][1], result[row][2], result[row][3],
      result[row][4], result[row][5], result[row][6], result[row][7]);
    row_err = 0;
    for (c = 0; c < col; c = c+1) begin
      if ($signed(pmem_out[c*bw_psum +: bw_psum]) !== result[row][golden_col[c]]) begin
        $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*bw_psum +: bw_psum]), result[row][golden_col[c]]);
        err = err + 1;
        row_err = row_err + 1;
      end
    end
    $display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
    $display("");
    
  end
  @(negedge clk);
  mem_cmd_ext = EXT_CMD_NO_OP;

  $display("------------------------------------------------------------");
  if (err == 0) begin
    $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    $display("------------------------------------------------------------");
  end else begin
    $display("  FAIL  %0d mismatches", err);
    $display("------------------------------------------------------------");
  end
  $display("");


    #10 $finish;
  end




  task apply_2cycles_reset;
    begin
      reset = 1;
      repeat(2) @(negedge clk);
      reset = 0;
    end
  endtask




endmodule



