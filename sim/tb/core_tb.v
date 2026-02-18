// Mac verification: TB + DUT (mac_array_top) in one file.
// Phase 1 (QK product): Q/K files -> qmem/kmem write -> K load -> execute -> sample pmem out, compare to golden.
// Phase 2 (Normalize ): sfu_row takes input from pmem, and store output into kmem. Golden is displayed by tb simultaneously.
// Phase 3 (VN product): LOAD_OTHER_NORM_FILE decides whether we use TA's norm.txt. Other than that, the flow is identical to phase 1.   

// `define LOAD_OTHER_NORM_FILE     // If you want to use TA's norm.txt 

`timescale 1ns/1ps


module core_tb;

  parameter total_cycle = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+3;
  parameter pr = 8;
  parameter col = 8;
  parameter sfp_out_shift = 7;

  integer qkvn_file, qkvn_scan_file, captured_data;
  integer weight [col*pr-1:0];
  integer K [col-1:0][pr-1:0];
  integer Q [total_cycle-1:0][pr-1:0];
  integer N [col-1:0][pr-1:0]; 
  integer V_T[total_cycle-1:0][pr-1:0];
  integer result [total_cycle-1:0][col-1:0];
  integer sum [total_cycle-1:0];
  integer i, j, k, t, p, q, s, u, m, r, c;

  integer estimated [0:total_cycle*col-1];   // computed from mac_data (same formula as sfp_row)
  integer u0, u1, u2, u3, u4, u5, u6, u7;
  integer err_count;
  integer err, row_err, row;
  integer sum_abs, divisor, unsigned_val;

  reg reset = 1;
  reg clk = 0;
  reg [pr*bw-1:0] mem_in;
  reg sfp_processing = 0;
  reg sfp_div=0, sfp_acc=0;
  reg VN_mode = 0;
  // wire [18:0] inst;
  wire [19:0] inst;
  reg qmem_rd = 0, qmem_wr = 0, kmem_rd = 0, kmem_wr = 0, pmem_rd = 0, pmem_wr = 0;
  reg execute = 0, load = 0;
  reg [3:0] qkmem_add = 0;
  reg [3:0] pmem_add = 0;

  reg [bw_psum-1:0] temp5b;
  reg [bw_psum+3:0] temp_sum;
  reg [bw_psum*col-1:0] temp16b;

  wire [bw_psum*col-1:0] pmem_out;
  integer golden_col [0:7];  // RTL col c -> golden result[t][golden_col[c]] (chain mapping)

  assign inst[19] = VN_mode;
  assign inst[18] = sfp_div;            // set by tb so far. usage see sfp_row_tb.
  assign inst[17] = sfp_acc;            // set by tb so far. usage see sfp_row_tb.
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

  core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core_instance (
    .reset(reset),
    .clk(clk),
    .mem_in(mem_in),
    .inst(inst),
    .sum_out(),
    .out(pmem_out)
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
        // temp5b = result[t][q];
        // temp16b = {temp16b[139:0], temp5b};
      end
      // $display("prd @cycle%2d: %40h", t, temp16b);
    end

    $display("QK Product Phase");
    VN_mode = 1'b0;

    $display("##### Qmem writing #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk = 1'b0;
      qmem_wr = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      mem_in[1*bw-1:0*bw] = Q[q][7];
      mem_in[2*bw-1:1*bw] = Q[q][6];
      mem_in[3*bw-1:2*bw] = Q[q][5];
      mem_in[4*bw-1:3*bw] = Q[q][4];
      mem_in[5*bw-1:4*bw] = Q[q][3];
      mem_in[6*bw-1:5*bw] = Q[q][2];
      mem_in[7*bw-1:6*bw] = Q[q][1];
      mem_in[8*bw-1:7*bw] = Q[q][0];
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
      mem_in[1*bw-1:0*bw] = K[q][7];
      mem_in[2*bw-1:1*bw] = K[q][6];
      mem_in[3*bw-1:2*bw] = K[q][5];
      mem_in[4*bw-1:3*bw] = K[q][4];
      mem_in[5*bw-1:4*bw] = K[q][3];
      mem_in[6*bw-1:5*bw] = K[q][2];
      mem_in[7*bw-1:6*bw] = K[q][1];
      mem_in[8*bw-1:7*bw] = K[q][0];
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





// RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
    for (c = 0; c < col; c = c+1)
      golden_col[c] = 7 - c;
  $display("QK phase verification start (checking pmem content)\n");
  $display("##### sample pmem content & compare to golden #####");
  $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
  $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
  err = 0;
  
  #0.5 clk = 1'b0;pmem_rd = 1'b1; pmem_add=4'd0;
  #0.5 clk = 1'b1;
  for (q = 0; q < total_cycle; q = q+1) begin
    #0.5 clk = 1'b0; pmem_add = pmem_add+1; // sample before posedge: pmem_out = row being read (result[q])
    #0.5 clk = 1'b1; 
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
  #0.5 clk = 1'b0;
  pmem_rd = 1'b0;
  #0.5 clk = 1'b1;

  $display("------------------------------------------------------------");
  if (err == 0) begin
    $display("  PASS  %0d rows x %0d cols  all match estimated result", total_cycle, col);
    $display("------------------------------------------------------------");
  end else begin
    $display("  FAIL  %0d mismatches", err);
    $display("------------------------------------------------------------");
  end
  $display("");

  // ----- Estimated: same as sfp_row (sum_abs = sum of |row|, divisor = sum_abs>>7, out[c] = signed(row[c])/divisor)
    $display("##### Estimated normalization (sum_abs>>7, then signed divide) #####");
    for (r = 0; r < total_cycle; r = r + 1) begin
      sum_abs = 0;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = result[r][c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val-1'b1);
        sum_abs = sum_abs + unsigned_val;
      end
      if (sum_abs == 0) sum_abs = 1;
      for (c = 0; c < col; c = c + 1) begin
        unsigned_val = result[r][c];
        if (unsigned_val[bw_psum-1] == 1'b1)
          unsigned_val = ~(unsigned_val-1'b1); 
        estimated[r*col + c] = {unsigned_val, {sfp_out_shift{1'b0}}} / sum_abs;
      end
    end





    $display("");
    $display("##### sfp processing #####");
    $display("estimated:        col0    col1    col2    col3    col4    col5    col6    col7 ");
    $display("to kmem  :       63:56   55:48   47:40   39:32   31:24   23:16   15: 8    7: 0 ");
    sfp_processing = 1'b1;
    pmem_add = 0;
    qkmem_add = 0;
    pmem_rd = 1;

    
    for (q = 0; q < col; q = q + 1) begin
      #0.5 clk = 1'b0; #0.5 clk = 1'b1;                 //posedge 1
      #0.5 clk = 1'b0; #0.5 clk = 1'b1; sfp_acc = 1'b1; //posedge 2
      #0.5 clk = 1'b0; #0.5 clk = 1'b1;                 //posedge 3
      #0.5 clk = 1'b0; #0.5 clk = 1'b1; sfp_acc = 1'b0; //posedge 4
      #0.5 clk = 1'b0; #0.5 clk = 1'b1; sfp_div = 1'b1; //posedge 5
      #0.5 clk = 1'b0; #0.5 clk = 1'b1;                 //posedge 6
      #0.5 clk = 1'b0; #0.5 clk = 1'b1; sfp_div = 1'b0; //posedge 7
      #0.5 clk = 1'b0; #0.5 clk = 1'b1; kmem_wr = 1'b1; //posedge 8
      $display("");
      $display("estimated:     %7d %7d %7d %7d %7d %7d %7d %7d ", 
                                estimated[q*col + 0], estimated[q*col + 1], 
                                estimated[q*col + 2], estimated[q*col + 3], 
                                estimated[q*col + 4], estimated[q*col + 5], 
                                estimated[q*col + 6], estimated[q*col + 7]);

      #0.5 clk = 1'b0; #0.5 clk = 1'b1; kmem_wr = 1'b0; //posedge 9
      pmem_add = pmem_add + 1;
      qkmem_add = qkmem_add + 1;
    end

    for (q = 0; q < 10; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end
    sfp_processing = 1'b0;
    pmem_rd = 1'b0;
   
    $display("------------------------------------------------------------");
    $display("Please check manually, since there's no output port for kmem.");
    $display("------------------------------------------------------------");
    $display("");

    

    for (q = 0; q < 10; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end




    $display("");
    $display("VN Product Phase");
    VN_mode = 1'b1;
    reset = 1'b1;
    for (q = 0; q < 10; q = q+1) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end
    reset = 1'b0;
    


  ///// V data txt reading /////
  $display("##### V data txt reading #####");
    qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
    // V_T := [pr-1:0][col-1:0]
    for (q=0; q<col; q=q+1) begin
      for (j=0; j<pr; j=j+1) begin
            qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
            V_T[j][q] = captured_data;
      end
    end


  ///// Norm data txt reading /////
  $display("##### norm data txt reading #####");
  for (q=0; q<10; q=q+1) #0.5 clk = 1'b0; #0.5 clk = 1'b1;   
  reset = 0;
  

  `ifdef LOAD_OTHER_NORM_FILE
  //**************************//
  //   LOAD_OTHER_NORM_FILE   //
  //**************************//
  qkvn_file = $fopen("sim/pattern/norm.txt", "r");
  // N := [total_cycle-1:0][col-1:0]
  for (q=0; q<total_cycle; q=q+1) begin
    for (j=0; j<col; j=j+1) begin
          qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
          N[q][j] = captured_data;
    end
  end

  `else
  //*****************************//
  // Calculate N from QK product //
  //*****************************//
  for (q=0; q<total_cycle; q=q+1) begin
    for (j=0; j<col; j=j+1) begin
          N[q][j] = estimated[q*col+j];
    end
  end

`endif

// $display("##### Estimated multiplication result #####");
    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1)
        result[t][q] = 0;
    for (t = 0; t < total_cycle; t = t+1) begin
      for (q = 0; q < col; q = q+1) begin
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + V_T[t][k] * N[q][k];
        // temp5b = result[t][q];
        // temp16b = {temp16b[139:0], temp5b};
      end
      // $display("prd @cycle%2d: %40h", t, temp16b);
    end


///// Qmem writing  /////
$display("##### Qmem writing  #####");
  qkmem_add = 0;
  for (q=0; q<total_cycle; q=q+1) begin

    #0.5 clk = 1'b0;  
    qmem_wr = 1;  if (q>0) qkmem_add = qkmem_add + 1; 
    
    mem_in[1*bw-1:0*bw] = V_T[q][7];
    mem_in[2*bw-1:1*bw] = V_T[q][6];
    mem_in[3*bw-1:2*bw] = V_T[q][5];
    mem_in[4*bw-1:3*bw] = V_T[q][4];
    mem_in[5*bw-1:4*bw] = V_T[q][3];
    mem_in[6*bw-1:5*bw] = V_T[q][2];
    mem_in[7*bw-1:6*bw] = V_T[q][1];
    mem_in[8*bw-1:7*bw] = V_T[q][0];

    #0.5 clk = 1'b1;  

  end


  #0.5 clk = 1'b0;  
  qmem_wr = 0; 
  qkmem_add = 0;
  #0.5 clk = 1'b1;  
///////////////////////////////////////////




`ifdef LOAD_OTHER_NORM_FILE
///// Kmem writing  /////

$display("##### Kmem writing #####");

  for (q=0; q<col; q=q+1) begin

    #0.5 clk = 1'b0;  
    kmem_wr = 1; if (q>0) qkmem_add = qkmem_add + 1; 
    
    mem_in[1*bw-1:0*bw] = N[q][7];
    mem_in[2*bw-1:1*bw] = N[q][6];
    mem_in[3*bw-1:2*bw] = N[q][5];
    mem_in[4*bw-1:3*bw] = N[q][4];
    mem_in[5*bw-1:4*bw] = N[q][3];
    mem_in[6*bw-1:5*bw] = N[q][2];
    mem_in[7*bw-1:6*bw] = N[q][1];
    mem_in[8*bw-1:7*bw] = N[q][0];

    #0.5 clk = 1'b1;  

  end

  #0.5 clk = 1'b0;  
  kmem_wr = 0;  
  qkmem_add = 0;
  #0.5 clk = 1'b1;  
///////////////////////////////////////////
`endif


for (q=0; q<2; q=q+1) begin
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;   
  end




/////  K data loading  /////
$display("##### K data loading to processor #####");

  for (q=0; q<col+1; q=q+1) begin
    #0.5 clk = 1'b0;  
    load = 1; 
    if (q==1) kmem_rd = 1;
    if (q>1) begin
       qkmem_add = qkmem_add + 1;
    end

    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;  
  kmem_rd = 0; qkmem_add = 0;
  #0.5 clk = 1'b1;  

  #0.5 clk = 1'b0;  
  load = 0; 
  #0.5 clk = 1'b1;  

///////////////////////////////////////////

 for (q=0; q<10; q=q+1) begin
    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   
 end





///// execution  /////
$display("##### execute #####");

  for (q=0; q<total_cycle; q=q+1) begin
    #0.5 clk = 1'b0;  
    execute = 1; 
    qmem_rd = 1;

    if (q>0) begin
       qkmem_add = qkmem_add + 1;
    end

    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;  
  qmem_rd = 0; qkmem_add = 0; execute = 0;
  #0.5 clk = 1'b1;  


///////////////////////////////////////////

 for (q=0; q<10; q=q+1) begin
    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   
 end






// RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
    for (c = 0; c < col; c = c+1)
      golden_col[c] = 7 - c;
  $display("VN phase verification start (checking pmem content)\n");
  $display("##### sample pmem content & compare to golden #####");
  $display("  [row]  RTL   :    col0    col1    col2    col3    col4    col5    col6    col7");
  $display("         golden:    ----    ----    ----    ----    ----    ----    ----    ----\n");
  err = 0;
  
  #0.5 clk = 1'b0;pmem_rd = 1'b1; pmem_add=4'd0;
  #0.5 clk = 1'b1;
  for (q = 0; q < total_cycle; q = q+1) begin
    #0.5 clk = 1'b0; pmem_add = pmem_add+1; // sample before posedge: pmem_out = row being read (result[q])
    #0.5 clk = 1'b1; 
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
  #0.5 clk = 1'b0;
  pmem_rd = 1'b0;
  #0.5 clk = 1'b1;

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

endmodule
