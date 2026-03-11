// Core Verification

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

	integer K        [col-1:0][pr-1:0];
	integer Q        [total_cycle-1:0][pr-1:0];
	integer V_T      [total_cycle-1:0][pr-1:0];
	integer result   [total_cycle-1:0][col-1:0];
	integer sum      [total_cycle-1:0];
	integer estimated[0:total_cycle*col-1];   // computed from mac_data (same formula as sfp_row)
	integer          golden_col [0:7];  // RTL col c -> golden result[t][golden_col[c]] (chain mapping)



	//================= clk ==========================//
	reg                clk   = 0;
	always #(`H_CYCLE) clk = ~clk;

	//================= timeout ======================//
	initial #(`TIME_OUT) $finish;

	//============= Input to DUT  ===============//
	reg               	reset = 1;
	reg        			start = 0;
	reg  [pr*bw-1:0]  	mem_in;
	reg  [1:0]        	mem_cmd_ext = 2'd0;
  	reg  [3:0]        	addr_ext = 4'd0;

	wire [5:0]       	inst_ext;
	assign inst_ext = {addr_ext, mem_cmd_ext};

	// 00: No Op, 01: kmem wr, 10: qmem wr, 11: pmem rd
	localparam EXT_CMD_NO_OP   = 2'b00;
	localparam EXT_CMD_KMEM_WR = 2'b01;
	localparam EXT_CMD_QMEM_WR = 2'b10;
	localparam EXT_CMD_PMEM_RD = 2'b11;

 
	reg 		set_mode;
	reg [2:0]   mode_in;
	// Mode setting.
	localparam CORE_MODE_MULT_save_to_PMEM					= 3'b100;
	localparam CORE_MODE_MULT_NORM_save_to_PMEM 			= 3'b001;
	localparam CORE_MODE_MULT_NORM_save_to_KMEM 			= 3'b010;
	localparam CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM 	= 3'b011;

	//============= DUT's Output  ===============//
	wire [3:0] 							status;      // {busy, qmem_locked, kmem_locked, pmem_locked} from controller
	wire [bw_psum*col-1:0]	pmem_out;
	wire busy, qmem_locked, kmem_locked, pmem_locked;
	assign busy = status[3];
	assign qmem_locked = status[2];
	assign kmem_locked = status[1];
	assign pmem_locked = status[0];

	core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core_instance (
			.reset(reset),
			.clk(clk),
			.set_mode(set_mode),
			.mode_in(mode_in),
			.mem_in(mem_in),
			.inst_ext(inst_ext),
			.sum_out(),
			.out(pmem_out),
			.start(start),
			.status(status)
	);

	
	
initial begin
	$dumpfile("sim/waveform/core.vcd");
	$dumpvars(0, core_tb);
	$display("");
	
//########################################################################
//  				data.txt -> Integer Arrays: Q, K, V_T						  
//########################################################################
	// $display("##### Q data txt reading #####");
	qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
	for (q = 0; q < total_cycle; q = q+1)begin
		for (j = 0; j < pr; j = j+1) begin
			qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
			Q[q][j] = captured_data;
	  end
	end
	// $display("##### K data txt reading #####");
	qkvn_file = $fopen("sim/pattern/kdata.txt", "r");
	for (q = 0; q < total_cycle; q = q+1)begin
		for (j = 0; j < pr; j = j+1) begin
			qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
			K[q][j] = captured_data;
		end
	end
	// $display("##### V data txt reading #####");
    qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
    for (q = 0; q < total_cycle; q = q+1)begin
      for (j = 0; j < pr; j = j+1) begin
            qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
            V_T[j][q] = captured_data;
      end
    end

Reset2Cyc;
$monitor ("time %6t    | start %b   | busy %b   | qmem_locked %b   | kmem_locked %b  | pmem_locked %b", 
			  $time, 		 start, 	  busy, 	  qmem_locked, 		 kmem_locked, 	   pmem_locked);

//########################################################################
// Test 1: Matrix Multiplication		 				 				 
// K -> KMEM  |  Result = Q * Transpose(K)
// Q -> QMEM  |  Verify PMEM  =?=  Result
//########################################################################
//============     Ground Truth Calculation: Result     ==================
	for (t = 0; t < total_cycle; t = t+1)
	  for (q = 0; q < col; q = q+1)
		result[t][q] = 0;
	for (t = 0; t < total_cycle; t = t+1) begin
	  for (q = 0; q < col; q = q+1) begin
		for (k = 0; k < pr; k = k+1)
		  result[t][q] = result[t][q] + Q[t][k] * K[q][k];
	  end
	end

//============      	 Write Config to Core    		==================
CoreSetMode(CORE_MODE_MULT_save_to_PMEM);

//============      	 Write to Core's KMEM    		==================
	
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_KMEM_WR;
	addr_ext = 0;

    for (q = 0; q < col; q = q+1) begin
		mem_in[1*bw-1:0*bw] = K[q][7];
		mem_in[2*bw-1:1*bw] = K[q][6];
		mem_in[3*bw-1:2*bw] = K[q][5];
		mem_in[4*bw-1:3*bw] = K[q][4];
		mem_in[5*bw-1:4*bw] = K[q][3];
		mem_in[6*bw-1:5*bw] = K[q][2];
		mem_in[7*bw-1:6*bw] = K[q][1];
		mem_in[8*bw-1:7*bw] = K[q][0];
      	@(negedge clk);

	  	addr_ext = addr_ext + 4'd1;
    end
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext    = 0;

    @(negedge clk);

//============      	 Write to Core's QMEM    		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_QMEM_WR;
	addr_ext = 0;

    for (q = 0; q < col; q = q+1) begin
		mem_in[1*bw-1:0*bw] = Q[q][7];
		mem_in[2*bw-1:1*bw] = Q[q][6];
		mem_in[3*bw-1:2*bw] = Q[q][5];
		mem_in[4*bw-1:3*bw] = Q[q][4];
		mem_in[5*bw-1:4*bw] = Q[q][3];
		mem_in[6*bw-1:5*bw] = Q[q][2];
		mem_in[7*bw-1:6*bw] = Q[q][1];
		mem_in[8*bw-1:7*bw] = Q[q][0];
      	@(negedge clk);

	  	addr_ext = addr_ext + 4'd1;
    end
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext    = 0;

    @(negedge clk);

//============		  Start the core & wait for done	==================
Start1Cyc;
wait(!busy); @(negedge clk);

//============		  Pretty Verification Banner :D 	==================
	// RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
	for (c = 0; c < col; c = c+1) golden_col[c] = 7 - c;
	$display("################################################################## ");
	$display("               |  Matrix Multiplication						     ");
	$display("      Test 1   |  PMEM =?= QMEM * Transpose(KMEM)			 	 ");
	$display("------------------------------------------------------------------ ");		 				 	 				 
	$display("  PMEM content :  					");
	$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
	$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
	err = 0;

//============			Read Core's PMEM & Evaluate		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_PMEM_RD;
	addr_ext=4'd0;
	@(negedge clk); //mem read has 1 cyc latency

  	for (q = 0; q < total_cycle; q = q+1) begin // sample before posedge: pmem_out = row being read (result[q]) 
    	
		row = q;
    	$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row,
					$signed(pmem_out[7*bw_psum +: bw_psum]), $signed(pmem_out[6*bw_psum +: bw_psum]),
					$signed(pmem_out[5*bw_psum +: bw_psum]), $signed(pmem_out[4*bw_psum +: bw_psum]),
					$signed(pmem_out[3*bw_psum +: bw_psum]), $signed(pmem_out[2*bw_psum +: bw_psum]),
					$signed(pmem_out[1*bw_psum +: bw_psum]), $signed(pmem_out[0*bw_psum +: bw_psum]));
    	$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
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
		
		addr_ext = addr_ext+1;
		@(negedge clk);  //mem read has 1 cyc latency
  	end


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






Reset2Cyc;
//########################################################################
// Test 2: Matrix Multiplication + Result Normalization		 				 				 
// K -> KMEM  |  Estimated = Norm ( Q * Transpose(K))
// Q -> QMEM  |  Verify PMEM  =?=  Estimated (LONGDIV & VANILLA should match)
//########################################################################
//============     Ground Truth Calculation: Estimated  ==================
	for (t = 0; t < total_cycle; t = t+1)
	  for (q = 0; q < col; q = q+1)
		result[t][q] = 0;
	for (t = 0; t < total_cycle; t = t+1) begin
	  for (q = 0; q < col; q = q+1) begin
		for (k = 0; k < pr; k = k+1)
		  result[t][q] = result[t][q] + Q[t][k] * K[q][k];
	  end
	end
	// $display("##### Estimated normalization (sum_abs>>7, then signed divide) #####");
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


//============      	 Write Config to Core    		==================
CoreSetMode(CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM);

//============      	 Write to Core's KMEM    		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_KMEM_WR;
	addr_ext = 0;

    for (q = 0; q < col; q = q+1) begin
		mem_in[1*bw-1:0*bw] = K[q][7];
		mem_in[2*bw-1:1*bw] = K[q][6];
		mem_in[3*bw-1:2*bw] = K[q][5];
		mem_in[4*bw-1:3*bw] = K[q][4];
		mem_in[5*bw-1:4*bw] = K[q][3];
		mem_in[6*bw-1:5*bw] = K[q][2];
		mem_in[7*bw-1:6*bw] = K[q][1];
		mem_in[8*bw-1:7*bw] = K[q][0];
      	@(negedge clk);

	  	addr_ext = addr_ext + 4'd1;
    end
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext    = 0;

    @(negedge clk);

//============      	 Write to Core's QMEM    		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_QMEM_WR;
	addr_ext = 0;

    for (q = 0; q < col; q = q+1) begin
		mem_in[1*bw-1:0*bw] = Q[q][7];
		mem_in[2*bw-1:1*bw] = Q[q][6];
		mem_in[3*bw-1:2*bw] = Q[q][5];
		mem_in[4*bw-1:3*bw] = Q[q][4];
		mem_in[5*bw-1:4*bw] = Q[q][3];
		mem_in[6*bw-1:5*bw] = Q[q][2];
		mem_in[7*bw-1:6*bw] = Q[q][1];
		mem_in[8*bw-1:7*bw] = Q[q][0];
      	@(negedge clk);

	  	addr_ext = addr_ext + 4'd1;
    end
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext    = 0;

    @(negedge clk);

//============		  Start the core & wait for done	==================
Start1Cyc;
wait(!busy); @(negedge clk);

//============		  Pretty Verification Banner :D 	==================
	// RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
	for (c = 0; c < col; c = c+1) golden_col[c] = 7 - c;
	
	$display("################################################################## ");
	$display("               |  Matrix Multiplication + Result Normalization	 	 ");
	$display("     Test 2    |  PMEM  =?=  Norm (QMEM * Transpose(KMEM))			 ");
	$display("------------------------------------------------------------------ ");
	$display("               |  LONGDIV/VANILLA should match; LUTDIV might not");
	$display("     Notes     |  Norm is saved to both PMEM & KMEM in this mode");
	$display("------------------------------------------------------------------ ");		 				 
	$display("  PMEM content :  					");
	$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
	$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
	err = 0;

//============			Read Core's PMEM & Evaluate		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_PMEM_RD;
	addr_ext=4'd0;
	@(negedge clk); //mem read has 1 cyc latency

  	for (q = 0; q < total_cycle; q = q+1) begin // sample before posedge: pmem_out = row being read (result[q]) 
    	
		row = q;
    	$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row,
					$signed(pmem_out[7*bw_psum +: bw_psum]), $signed(pmem_out[6*bw_psum +: bw_psum]),
					$signed(pmem_out[5*bw_psum +: bw_psum]), $signed(pmem_out[4*bw_psum +: bw_psum]),
					$signed(pmem_out[3*bw_psum +: bw_psum]), $signed(pmem_out[2*bw_psum +: bw_psum]),
					$signed(pmem_out[1*bw_psum +: bw_psum]), $signed(pmem_out[0*bw_psum +: bw_psum]));
    	$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
							estimated[row*col + 0], estimated[row*col + 1], 
							estimated[row*col + 2], estimated[row*col + 3], 
							estimated[row*col + 4], estimated[row*col + 5], 
							estimated[row*col + 6], estimated[row*col + 7]);
    	row_err = 0;
    	for (c = 0; c < col; c = c+1) begin
      		if ($signed(pmem_out[c*bw_psum +: bw_psum]) !== estimated[row*col + golden_col[c]]) begin
        		$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*bw_psum +: bw_psum]), estimated[row*col + golden_col[c]]);
        		err = err + 1;
        		row_err = row_err + 1;
      		end
    	end
    	$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		
		addr_ext = addr_ext+1;
		@(negedge clk);  //mem read has 1 cyc latency
  	end


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



Reset2Cyc;
//########################################################################
// Test 3: Full MULT-NORM-MULT Pipeline	
// Remember we saved the norm to KMEM in Test 2?				 				 
// V_T -> QMEM  |  Verify PMEM  =?=   V_T * Transpose(Norm)
//########################################################################
//============     Ground Truth Calculation: Result     ==================
	for (t = 0; t < total_cycle; t = t+1)
	  for (q = 0; q < col; q = q+1)
		result[t][q] = 0;
	for (t = 0; t < total_cycle; t = t+1) begin
	  for (q = 0; q < col; q = q+1) begin
		for (k = 0; k < pr; k = k+1)
		  result[t][q] = result[t][q] + V_T[t][k] * estimated[q*col+k];
	  end
	end

//============      	 Write Config to Core    		==================
CoreSetMode(CORE_MODE_MULT_save_to_PMEM);

//============    	Don't touch Core's KMEM !   		==================
//============      Only Write to Core's QMEM    		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_QMEM_WR;
	addr_ext = 0;

    for (q = 0; q < col; q = q+1) begin
		mem_in[1*bw-1:0*bw] = V_T[q][7];
		mem_in[2*bw-1:1*bw] = V_T[q][6];
		mem_in[3*bw-1:2*bw] = V_T[q][5];
		mem_in[4*bw-1:3*bw] = V_T[q][4];
		mem_in[5*bw-1:4*bw] = V_T[q][3];
		mem_in[6*bw-1:5*bw] = V_T[q][2];
		mem_in[7*bw-1:6*bw] = V_T[q][1];
		mem_in[8*bw-1:7*bw] = V_T[q][0];
      	@(negedge clk);

	  	addr_ext = addr_ext + 4'd1;
    end
    mem_cmd_ext = EXT_CMD_NO_OP;
    addr_ext    = 0;

    @(negedge clk);

//============		  Start the core & wait for done	==================
Start1Cyc;
wait(!busy); @(negedge clk);

//============		  Pretty Verification Banner :D 	==================
	// RTL column order: col c holds dot with K[7-c], so compare to result[t][7-c]
	for (c = 0; c < col; c = c+1) golden_col[c] = 7 - c;
	$display("################################################################## ");
	$display("               |  Full MULT-NORM-MULT Pipeline				     ");
	$display("      Test 3   |  PMEM =?= QMEM * Transpose(Norm)			 	     ");
	$display("------------------------------------------------------------------ ");		 				 	 				 
	$display("               |  This test depends on Test2");
	$display("     Notes     |  The command to the core is the same as Test 1");
	$display("------------------------------------------------------------------ ");		 				 
	$display("  PMEM content :  					");
	$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
	$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
	err = 0;

//============			Read Core's PMEM & Evaluate		==================
	@(negedge clk);
	mem_cmd_ext = EXT_CMD_PMEM_RD;
	addr_ext=4'd0;
	@(negedge clk); //mem read has 1 cyc latency

  	for (q = 0; q < total_cycle; q = q+1) begin // sample before posedge: pmem_out = row being read (result[q]) 
    	
		row = q;
    	$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row,
					$signed(pmem_out[7*bw_psum +: bw_psum]), $signed(pmem_out[6*bw_psum +: bw_psum]),
					$signed(pmem_out[5*bw_psum +: bw_psum]), $signed(pmem_out[4*bw_psum +: bw_psum]),
					$signed(pmem_out[3*bw_psum +: bw_psum]), $signed(pmem_out[2*bw_psum +: bw_psum]),
					$signed(pmem_out[1*bw_psum +: bw_psum]), $signed(pmem_out[0*bw_psum +: bw_psum]));
    	$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
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
		
		addr_ext = addr_ext+1;
		@(negedge clk);  //mem read has 1 cyc latency
  	end


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


















//================= Reusable Tasks ====================
  task Reset2Cyc;
	begin
		@(negedge clk);
		reset = 1;
		repeat(2) @(negedge clk);
		reset = 0;
		@(negedge clk);
	end
  endtask

  task Start1Cyc;
	begin
		@(negedge clk);
		start = 1;
		@(negedge clk);
		start = 0;
		@(negedge clk);
	end
  endtask

  task CoreSetMode;
  	input [2:0] mode;
	begin
		@(negedge clk);
		set_mode = 1'b1;
		mode_in = mode;
		@(negedge clk);
		set_mode = 1'b0;
		mode_in = 3'b000;
		@(negedge clk);
	end
  endtask

endmodule