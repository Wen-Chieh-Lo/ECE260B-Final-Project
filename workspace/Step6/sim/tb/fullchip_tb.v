// Core Verification - CDC 3-initial architecture (ref: fullchip_sepclk_tb)
// Initial 1: data + golden (no timing). Initial 2: clk0 domain (C0). Initial 3: clk1 domain (C1).
// C0 inputs driven by tick0; C1 inputs driven by tick1.

`timescale 1ns/1ps
`define CYCLE 1
`define H_CYCLE 0.5
`define H_CYCLE0 0.5   // clk0: period 1ns
`define H_CYCLE1 0.6   // clk1: period 1.2ns (different freq for CDC)
`define TIME_OUT 100000

`ifndef SFP_THRESHOLD
  `define SFP_THRESHOLD 0
`endif

module fullchip_tb;
	parameter total_cycle = 8;
	parameter bw = 8;
	parameter bw_psum = 2*bw+4;
	parameter pr = 8;
	parameter col = 8;
	parameter sfp_out_shift = 7;
	parameter sfp_acc_lat = 1;

	//================= integer / array storage =====================//
	integer qkvn_file, qkvn_scan_file, captured_data;
	integer j, k, t, q, c;
	integer row_err, row;
	integer divisor, sum_2core;

	integer K_c0     [col-1:0][pr-1:0];
	integer K_c1     [col-1:0][pr-1:0];
	integer Q        [total_cycle-1:0][pr-1:0];
	integer V_T      [total_cycle-1:0][pr-1:0];
	integer result_c0 [total_cycle-1:0][col-1:0];
	integer result_c1 [total_cycle-1:0][col-1:0];
	integer abs_result_c0 [total_cycle-1:0][col-1:0];
	integer abs_result_c1 [total_cycle-1:0][col-1:0];
	integer sum_c0   [total_cycle-1:0];
	integer sum_c1   [total_cycle-1:0];
	integer N_est_c0 [total_cycle-1:0][col-1:0];
	integer N_est_c1 [total_cycle-1:0][col-1:0];
	integer vn_c0    [total_cycle-1:0][col-1:0];
	integer vn_c1    [total_cycle-1:0][col-1:0];
	integer err0, err1;
	integer mismatch_t1_c0, mismatch_t1_c1;  // Test 1 (QK)
	integer mismatch_t2_c0, mismatch_t2_c1;  // Test 2 (Norm)
	integer mismatch_t3_c0, mismatch_t3_c1;  // Test 3 (VN)
	integer q0, q1, row0, row1, row_err0, row_err1, c0, c1;
	integer          golden_col [0:7];  // RTL col c -> golden result[t][golden_col[c]] (chain mapping)



	//================= clk (CDC: tick-based, different freq) ==========//
	reg                clk0  = 0;
	reg                clk1  = 0;
	task tick0; begin #(`H_CYCLE0) clk0=1'b0; #(`H_CYCLE0) clk0=1'b1; end endtask
	task tick1; begin #(`H_CYCLE1) clk1=1'b0; #(`H_CYCLE1) clk1=1'b1; end endtask

	//================= CDC sync flags (ref: fullchip_sepclk_tb) =================//
	reg data_ready_flag = 0;
	reg reset_done_c0_flag = 0;
	reg test1_done_c0_flag = 0, test1_done_c1_flag = 0;
	reg test2_done_c0_flag = 0, test2_done_c1_flag = 0;
	reg test3_done_c0_flag = 0, test3_done_c1_flag = 0;

	//================= timeout ======================//
	initial #(`TIME_OUT) $finish;

	//============= Input to DUT  ===============//
	reg               	reset0 = 1, reset1 = 1;
	reg        			start0 = 0, start1 = 0;
	reg  [pr*bw-1:0]  	mem_in0, 	mem_in1;
	reg  [1:0]        	mem_cmd_ext0 = 2'd0, mem_cmd_ext1 = 2'd0; 
  	reg  [3:0]        	addr_ext0 = 4'd0, addr_ext1 = 4'd0; 

	wire [5:0]       	inst_ext0, inst_ext1;
	assign inst_ext0 = {addr_ext0, mem_cmd_ext0};  // core.v expects inst_ext[5:2]=addr, [1:0]=cmd
	assign inst_ext1 = {addr_ext1, mem_cmd_ext1};

	// 00: No Op, 01: kmem wr, 10: qmem wr, 11: pmem rd
	localparam EXT_CMD_NO_OP   = 2'b00;
	localparam EXT_CMD_KMEM_WR = 2'b01;
	localparam EXT_CMD_QMEM_WR = 2'b10;
	localparam EXT_CMD_PMEM_RD = 2'b11;

 
	reg 		set_mode0 = 0, set_mode1 = 0;
	reg [2:0]   mode_in0, mode_in1;
	// Mode setting.
	localparam CORE_MODE_MULT_save_to_PMEM					= 3'b100;
	localparam CORE_MODE_MULT_NORM_save_to_PMEM 			= 3'b001;
	localparam CORE_MODE_MULT_NORM_save_to_KMEM 			= 3'b010;
	localparam CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM 	= 3'b011;

	//============= DUT's Output  ===============//
	wire [3:0] 	status0, status1;      // {busy, qmem_locked, kmem_locked, pmem_locked} from controller
	wire [bw_psum*col-1:0]	pmem_out0, pmem_out1;
	wire busy0, busy1, qmem_locked0, qmem_locked1, kmem_locked0, kmem_locked1, pmem_locked0, pmem_locked1;
	assign busy0 = status0[3];
	assign qmem_locked0 = status0[2];
	assign kmem_locked0 = status0[1];
	assign pmem_locked0 = status0[0];
	assign busy1 = status1[3];
	assign qmem_locked1 = status1[2];
	assign kmem_locked1 = status1[1];
	assign pmem_locked1 = status1[0];


	fullchip #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(2*pr), .half_pr(pr)) fullchip_instance(
		.reset0(reset0), 		.reset1(reset1), 	
		.clk0(clk0), 			.clk1(clk1), 	
		.start0(start0), 		.start1(start1),
		.set_mode0(set_mode0), 	.set_mode1(set_mode1),
		.mode_in0(mode_in0), 	.mode_in1(mode_in1),
		.mem_in0(mem_in0), 		.mem_in1(mem_in1), 
		.inst_ext0(inst_ext0), 	.inst_ext1(inst_ext1),
		.out0(pmem_out0), 		.out1(pmem_out1),	
		.status0(status0), 		.status1(status1)
	);

	// ========== Initial 1: Data + Golden (no timing) ==========
	initial begin
		$dumpfile("sim/waveform/fullchip.vcd");
		$dumpvars(0, fullchip_tb);
		$display("");

		//########################################################################
		//  data.txt -> Integer Arrays: Q, K_c0, K_c1, V_T
		//########################################################################
		$display("##### Q data txt reading #####");
		qkvn_file = $fopen("sim/pattern/qdata.txt", "r");
		if (qkvn_file == 0) begin $display("ERROR: cannot open qdata.txt"); $finish; end
		for (q = 0; q < total_cycle; q = q+1)
			for (j = 0; j < pr; j = j+1) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d", captured_data);
				Q[q][j] = captured_data;
			end
		$display("##### K data core0 txt reading #####");
		qkvn_file = $fopen("sim/pattern/kdata_core0.txt", "r");
		if (qkvn_file == 0) begin $display("ERROR: cannot open kdata_core0.txt"); $finish; end
		for (q = 0; q < col; q = q+1)
			for (j = 0; j < pr; j = j+1) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d", captured_data);
				K_c0[q][j] = captured_data;
			end
		$display("##### K data core1 txt reading #####");
		qkvn_file = $fopen("sim/pattern/kdata_core1.txt", "r");
		if (qkvn_file == 0) begin $display("ERROR: cannot open kdata_core1.txt"); $finish; end
		for (q = 0; q < col; q = q+1)
			for (j = 0; j < pr; j = j+1) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d", captured_data);
				K_c1[q][j] = captured_data;
			end
		$display("##### V data txt reading #####");
		qkvn_file = $fopen("sim/pattern/vdata.txt", "r");
		if (qkvn_file == 0) begin $display("ERROR: cannot open vdata.txt"); $finish; end
		for (q = 0; q < col; q = q+1)
			for (j = 0; j < pr; j = j+1) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d", captured_data);
				V_T[j][q] = captured_data;
			end

		//########################################################################
		//  Golden: result_c0, result_c1, sum_c0, sum_c1, N_est_c0, N_est_c1, vn_c0, vn_c1
		//########################################################################
		for (t = 0; t < total_cycle; t = t+1)
			for (q = 0; q < col; q = q+1) begin
				result_c0[t][q] = 0;
				result_c1[t][q] = 0;
			end
		for (t = 0; t < total_cycle; t = t+1) begin
			for (q = 0; q < col; q = q+1) begin
				for (k = 0; k < pr; k = k+1) begin
					result_c0[t][q] = result_c0[t][q] + Q[t][k] * K_c0[q][k];
					result_c1[t][q] = result_c1[t][q] + Q[t][k] * K_c1[q][k];
				end
			end
		end
		for (t = 0; t < total_cycle; t = t+1) begin
			sum_c0[t] = 0;
			sum_c1[t] = 0;
			for (q = 0; q < col; q = q+1) begin
				abs_result_c0[t][q] = (result_c0[t][q] >= 0) ? result_c0[t][q] : -result_c0[t][q];
				abs_result_c1[t][q] = (result_c1[t][q] >= 0) ? result_c1[t][q] : -result_c1[t][q];
				sum_c0[t] = sum_c0[t] + abs_result_c0[t][q];
				sum_c1[t] = sum_c1[t] + abs_result_c1[t][q];
			end
		end
		// sfp_row: sum_2core = sum_this_core + sum_in; TB models dual-core as sum_c0+sum_c1 per row.
		for (t = 0; t < total_cycle; t = t+1) begin
			sum_2core = sum_c0[t] + sum_c1[t];
			if (sum_2core < `SFP_THRESHOLD) begin
				if (`SFP_THRESHOLD > 0)
					$display("[TB][Norm gate] row %0d (dual-core): sum_2core = sum_c0+sum_c1 = %0d < SFP_THRESHOLD=%0d -> golden N_est_c0/N_est_c1 forced to 0",
						t, sum_2core, `SFP_THRESHOLD);
				for (q = 0; q < col; q = q+1) begin
					N_est_c0[t][q] = 0;
					N_est_c1[t][q] = 0;
				end
			end else begin
				divisor = (sum_2core == 0) ? 1 : sum_2core;
				for (q = 0; q < col; q = q+1) begin
					N_est_c0[t][q] = (abs_result_c0[t][q] << sfp_out_shift) / divisor;
					N_est_c1[t][q] = (abs_result_c1[t][q] << sfp_out_shift) / divisor;
				end
			end
		end
		for (t = 0; t < total_cycle; t = t+1)
			for (q = 0; q < col; q = q+1) begin
				vn_c0[t][q] = 0;
				vn_c1[t][q] = 0;
				for (k = 0; k < pr; k = k+1) begin
					vn_c0[t][q] = vn_c0[t][q] + V_T[t][k] * N_est_c0[q][k];
					vn_c1[t][q] = vn_c1[t][q] + V_T[t][k] * N_est_c1[q][k];
				end
			end
		for (c = 0; c < col; c = c+1) golden_col[c] = 7 - c;

		#0; data_ready_flag = 1;

		mismatch_t1_c0 = 0; mismatch_t1_c1 = 0;
		mismatch_t2_c0 = 0; mismatch_t2_c1 = 0;
		mismatch_t3_c0 = 0; mismatch_t3_c1 = 0;

		wait(test1_done_c0_flag && test1_done_c1_flag);
		wait(test2_done_c0_flag && test2_done_c1_flag);
		wait(test3_done_c0_flag && test3_done_c1_flag);

		$display("##### All tests complete, checking results #####");
		$display("------------------------------------------------------------");
		$display("  Test 1 (QK)  -- C0: %0d  C1: %0d mismatch(es)",
			mismatch_t1_c0, mismatch_t1_c1);
		$display("  Test 2 (Norm)-- C0: %0d  C1: %0d mismatch(es)",
			mismatch_t2_c0, mismatch_t2_c1);
		$display("  Test 3 (VN)  -- C0: %0d  C1: %0d mismatch(es)",
			mismatch_t3_c0, mismatch_t3_c1);
		if (mismatch_t1_c0 == 0 && mismatch_t1_c1 == 0 &&
		    mismatch_t2_c0 == 0 && mismatch_t2_c1 == 0 &&
		    mismatch_t3_c0 == 0 && mismatch_t3_c1 == 0) begin
			$display("  PASS  %0d rows x %0d cols  all tests match estimated result", total_cycle, col);
			$display("------------------------------------------------------------");
		end else begin
			$display("  FAIL  T1:%0d + T2:%0d + T3:%0d mismatches",
				mismatch_t1_c0 + mismatch_t1_c1,
				mismatch_t2_c0 + mismatch_t2_c1,
				mismatch_t3_c0 + mismatch_t3_c1);
			$display("------------------------------------------------------------");
		end
		$display("");

		#10 $finish;
	end


















	// ========== Initial 2: clk0 domain (C0 stimulus) ==========
	initial begin
		while (!data_ready_flag) tick0;

		// Reset C0
		reset0 = 1;
		repeat(3) tick0;
		reset0 = 0;
		reset_done_c0_flag = 1;
		tick0;

		// ===== Test 1 =====
		set_mode0 = 1'b1; mode_in0 = CORE_MODE_MULT_save_to_PMEM;
		repeat(2) tick0;
		set_mode0 = 1'b0; mode_in0 = 3'b000; tick0;

		mem_cmd_ext0 = EXT_CMD_KMEM_WR; addr_ext0 = 0;
		for (q0 = 0; q0 < col; q0 = q0+1) begin
			mem_in0[1*bw-1:0*bw] = K_c0[q0][7]; mem_in0[2*bw-1:1*bw] = K_c0[q0][6];
			mem_in0[3*bw-1:2*bw] = K_c0[q0][5]; mem_in0[4*bw-1:3*bw] = K_c0[q0][4];
			mem_in0[5*bw-1:4*bw] = K_c0[q0][3]; mem_in0[6*bw-1:5*bw] = K_c0[q0][2];
			mem_in0[7*bw-1:6*bw] = K_c0[q0][1]; mem_in0[8*bw-1:7*bw] = K_c0[q0][0];
			tick0; addr_ext0 = addr_ext0 + 4'd1;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP; addr_ext0 = 0; tick0;

		mem_cmd_ext0 = EXT_CMD_QMEM_WR; addr_ext0 = 0;
		for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
			mem_in0[1*bw-1:0*bw] = Q[q0][7]; mem_in0[2*bw-1:1*bw] = Q[q0][6];
			mem_in0[3*bw-1:2*bw] = Q[q0][5]; mem_in0[4*bw-1:3*bw] = Q[q0][4];
			mem_in0[5*bw-1:4*bw] = Q[q0][3]; mem_in0[6*bw-1:5*bw] = Q[q0][2];
			mem_in0[7*bw-1:6*bw] = Q[q0][1]; mem_in0[8*bw-1:7*bw] = Q[q0][0];
			tick0; addr_ext0 = addr_ext0 + 4'd1;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP; addr_ext0 = 0; tick0;

		start0 = 1;
		repeat(2) tick0;
		start0 = 0; tick0;
		while (busy0) tick0;
		repeat(2) tick0;  // margin for PMEM output

		$display("################################################################## ");
		$display("      Test 1   |  Dual-core Matrix Multiplication (PMEM = Q*K)   ");
		$display("------------------------------------------------------------------ ");
		$display("  C0 PMEM content :");
		$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
		$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
		err0 = 0;
		mem_cmd_ext0 = EXT_CMD_PMEM_RD; addr_ext0 = 0;
		repeat(2) tick0;  // PMEM read latency
		for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
			row0 = q0;
			$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row0,
				$signed(pmem_out0[7*bw_psum +: bw_psum]), $signed(pmem_out0[6*bw_psum +: bw_psum]),
				$signed(pmem_out0[5*bw_psum +: bw_psum]), $signed(pmem_out0[4*bw_psum +: bw_psum]),
				$signed(pmem_out0[3*bw_psum +: bw_psum]), $signed(pmem_out0[2*bw_psum +: bw_psum]),
				$signed(pmem_out0[1*bw_psum +: bw_psum]), $signed(pmem_out0[0*bw_psum +: bw_psum]));
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				result_c0[row0][0], result_c0[row0][1], result_c0[row0][2], result_c0[row0][3],
				result_c0[row0][4], result_c0[row0][5], result_c0[row0][6], result_c0[row0][7]);
			row_err0 = 0;
			for (c0 = 0; c0 < col; c0 = c0+1)
				if ($signed(pmem_out0[c0*bw_psum +: bw_psum]) !== result_c0[row0][golden_col[c0]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c0,
						$signed(pmem_out0[c0*bw_psum +: bw_psum]), result_c0[row0][golden_col[c0]]);
					err0 = err0 + 1; row_err0 = row_err0 + 1;
				end
			$display("       %s", (row_err0 == 0) ? "[OK]" : "[MISMATCH]");
			addr_ext0 = addr_ext0 + 1; repeat(2) tick0;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP;
		mismatch_t1_c0 = err0;
		$display("------------------------------------------------------------");
		if (err0 == 0) $display("  PASS  C0: %0d rows x %0d cols  all match", total_cycle, col);
		else $display("  FAIL  C0: %0d mismatches", err0);
		$display("------------------------------------------------------------");
		$display("");
		test1_done_c0_flag = 1;
		while (!test1_done_c1_flag) tick0;

		// ===== Test 2 =====
		reset0 = 1; repeat(3) tick0; reset0 = 0; tick0;
		set_mode0 = 1'b1; mode_in0 = CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM;
		repeat(2) tick0; set_mode0 = 1'b0; mode_in0 = 3'b000; tick0;

		mem_cmd_ext0 = EXT_CMD_KMEM_WR; addr_ext0 = 0;
		for (q0 = 0; q0 < col; q0 = q0+1) begin
			mem_in0[1*bw-1:0*bw] = K_c0[q0][7]; mem_in0[2*bw-1:1*bw] = K_c0[q0][6];
			mem_in0[3*bw-1:2*bw] = K_c0[q0][5]; mem_in0[4*bw-1:3*bw] = K_c0[q0][4];
			mem_in0[5*bw-1:4*bw] = K_c0[q0][3]; mem_in0[6*bw-1:5*bw] = K_c0[q0][2];
			mem_in0[7*bw-1:6*bw] = K_c0[q0][1]; mem_in0[8*bw-1:7*bw] = K_c0[q0][0];
			tick0; addr_ext0 = addr_ext0 + 4'd1;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP; addr_ext0 = 0; tick0;

		mem_cmd_ext0 = EXT_CMD_QMEM_WR; addr_ext0 = 0;
		for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
			mem_in0[1*bw-1:0*bw] = Q[q0][7]; mem_in0[2*bw-1:1*bw] = Q[q0][6];
			mem_in0[3*bw-1:2*bw] = Q[q0][5]; mem_in0[4*bw-1:3*bw] = Q[q0][4];
			mem_in0[5*bw-1:4*bw] = Q[q0][3]; mem_in0[6*bw-1:5*bw] = Q[q0][2];
			mem_in0[7*bw-1:6*bw] = Q[q0][1]; mem_in0[8*bw-1:7*bw] = Q[q0][0];
			tick0; addr_ext0 = addr_ext0 + 4'd1;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP; addr_ext0 = 0; tick0;

		start0 = 1; repeat(2) tick0; start0 = 0; tick0;
		while (busy0) tick0; repeat(2) tick0;

		$display("################################################################## ");
		$display("     Test 2   |  Dual-core MatMul + Norm (cross-core sum FIFO)    ");
		$display("------------------------------------------------------------------ ");
		$display("  C0 PMEM content :");
		$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
		$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
		err0 = 0;
		mem_cmd_ext0 = EXT_CMD_PMEM_RD; addr_ext0 = 0;
		repeat(2) tick0;  // PMEM read latency
		for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
			row0 = q0;
			$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row0,
				$signed(pmem_out0[7*bw_psum +: bw_psum]), $signed(pmem_out0[6*bw_psum +: bw_psum]),
				$signed(pmem_out0[5*bw_psum +: bw_psum]), $signed(pmem_out0[4*bw_psum +: bw_psum]),
				$signed(pmem_out0[3*bw_psum +: bw_psum]), $signed(pmem_out0[2*bw_psum +: bw_psum]),
				$signed(pmem_out0[1*bw_psum +: bw_psum]), $signed(pmem_out0[0*bw_psum +: bw_psum]));
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				N_est_c0[row0][0], N_est_c0[row0][1], N_est_c0[row0][2], N_est_c0[row0][3],
				N_est_c0[row0][4], N_est_c0[row0][5], N_est_c0[row0][6], N_est_c0[row0][7]);
			row_err0 = 0;
			for (c0 = 0; c0 < col; c0 = c0+1)
				if ($signed(pmem_out0[c0*bw_psum +: bw_psum]) !== N_est_c0[row0][golden_col[c0]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c0,
						$signed(pmem_out0[c0*bw_psum +: bw_psum]), N_est_c0[row0][golden_col[c0]]);
					err0 = err0 + 1; row_err0 = row_err0 + 1;
				end
			$display("       %s", (row_err0 == 0) ? "[OK]" : "[MISMATCH]");
			addr_ext0 = addr_ext0 + 1; repeat(2) tick0;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP;
		mismatch_t2_c0 = err0;
		$display("------------------------------------------------------------");
		if (err0 == 0) $display("  PASS  C0: %0d rows x %0d cols  all match (norm)", total_cycle, col);
		else $display("  FAIL  C0: %0d mismatches", err0);
		$display("------------------------------------------------------------");
		$display("");
		test2_done_c0_flag = 1;
		while (!test2_done_c1_flag) tick0;

		// ===== Test 3 =====
		reset0 = 1; repeat(3) tick0; reset0 = 0; tick0;
		set_mode0 = 1'b1; mode_in0 = CORE_MODE_MULT_save_to_PMEM;
		repeat(2) tick0; set_mode0 = 1'b0; mode_in0 = 3'b000; tick0;

		mem_cmd_ext0 = EXT_CMD_QMEM_WR; addr_ext0 = 0;
		for (q0 = 0; q0 < col; q0 = q0+1) begin
			mem_in0[1*bw-1:0*bw] = V_T[q0][7]; mem_in0[2*bw-1:1*bw] = V_T[q0][6];
			mem_in0[3*bw-1:2*bw] = V_T[q0][5]; mem_in0[4*bw-1:3*bw] = V_T[q0][4];
			mem_in0[5*bw-1:4*bw] = V_T[q0][3]; mem_in0[6*bw-1:5*bw] = V_T[q0][2];
			mem_in0[7*bw-1:6*bw] = V_T[q0][1]; mem_in0[8*bw-1:7*bw] = V_T[q0][0];
			tick0; addr_ext0 = addr_ext0 + 4'd1;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP; addr_ext0 = 0; tick0;

		start0 = 1; repeat(2) tick0; start0 = 0; tick0;
		while (busy0) tick0; repeat(2) tick0;

		$display("################################################################## ");
		$display("     Test 3   |  Full pipeline VN (PMEM = V * N from Test2 KMEM)  ");
		$display("------------------------------------------------------------------ ");
		$display("  C0 PMEM content :");
		$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
		$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
		err0 = 0;
		mem_cmd_ext0 = EXT_CMD_PMEM_RD; addr_ext0 = 0;
		repeat(2) tick0;  // PMEM read latency
		for (q0 = 0; q0 < total_cycle; q0 = q0+1) begin
			row0 = q0;
			$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row0,
				$signed(pmem_out0[7*bw_psum +: bw_psum]), $signed(pmem_out0[6*bw_psum +: bw_psum]),
				$signed(pmem_out0[5*bw_psum +: bw_psum]), $signed(pmem_out0[4*bw_psum +: bw_psum]),
				$signed(pmem_out0[3*bw_psum +: bw_psum]), $signed(pmem_out0[2*bw_psum +: bw_psum]),
				$signed(pmem_out0[1*bw_psum +: bw_psum]), $signed(pmem_out0[0*bw_psum +: bw_psum]));
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				vn_c0[row0][0], vn_c0[row0][1], vn_c0[row0][2], vn_c0[row0][3],
				vn_c0[row0][4], vn_c0[row0][5], vn_c0[row0][6], vn_c0[row0][7]);
			row_err0 = 0;
			for (c0 = 0; c0 < col; c0 = c0+1)
				if ($signed(pmem_out0[c0*bw_psum +: bw_psum]) !== vn_c0[row0][golden_col[c0]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c0,
						$signed(pmem_out0[c0*bw_psum +: bw_psum]), vn_c0[row0][golden_col[c0]]);
					err0 = err0 + 1; row_err0 = row_err0 + 1;
				end
			$display("       %s", (row_err0 == 0) ? "[OK]" : "[MISMATCH]");
			addr_ext0 = addr_ext0 + 1; repeat(2) tick0;
		end
		mem_cmd_ext0 = EXT_CMD_NO_OP;
		mismatch_t3_c0 = err0;
		$display("------------------------------------------------------------");
		if (err0 == 0) $display("  PASS  C0: %0d rows x %0d cols  all match (VN)", total_cycle, col);
		else $display("  FAIL  C0: %0d mismatches", err0);
		$display("------------------------------------------------------------");
		$display("");
		test3_done_c0_flag = 1;
		while (!test3_done_c1_flag) tick0;

		while (1) tick0;  // keep clk0 running
	end

	// ========== Initial 3: clk1 domain (C1 stimulus) ==========
	initial begin
		while (!data_ready_flag) tick1;
		while (!reset_done_c0_flag) tick1;

		// Reset C1
		reset1 = 1;
		repeat(3) tick1;
		reset1 = 0;
		tick1;

		// ===== Test 1 =====
		set_mode1 = 1'b1; mode_in1 = CORE_MODE_MULT_save_to_PMEM;
		repeat(2) tick1;
		set_mode1 = 1'b0; mode_in1 = 3'b000; tick1;

		mem_cmd_ext1 = EXT_CMD_KMEM_WR; addr_ext1 = 0;
		for (q1 = 0; q1 < col; q1 = q1+1) begin
			mem_in1[1*bw-1:0*bw] = K_c1[q1][7]; mem_in1[2*bw-1:1*bw] = K_c1[q1][6];
			mem_in1[3*bw-1:2*bw] = K_c1[q1][5]; mem_in1[4*bw-1:3*bw] = K_c1[q1][4];
			mem_in1[5*bw-1:4*bw] = K_c1[q1][3]; mem_in1[6*bw-1:5*bw] = K_c1[q1][2];
			mem_in1[7*bw-1:6*bw] = K_c1[q1][1]; mem_in1[8*bw-1:7*bw] = K_c1[q1][0];
			tick1; addr_ext1 = addr_ext1 + 4'd1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP; addr_ext1 = 0; tick1;

		mem_cmd_ext1 = EXT_CMD_QMEM_WR; addr_ext1 = 0;
		for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
			mem_in1[1*bw-1:0*bw] = Q[q1][7]; mem_in1[2*bw-1:1*bw] = Q[q1][6];
			mem_in1[3*bw-1:2*bw] = Q[q1][5]; mem_in1[4*bw-1:3*bw] = Q[q1][4];
			mem_in1[5*bw-1:4*bw] = Q[q1][3]; mem_in1[6*bw-1:5*bw] = Q[q1][2];
			mem_in1[7*bw-1:6*bw] = Q[q1][1]; mem_in1[8*bw-1:7*bw] = Q[q1][0];
			tick1; addr_ext1 = addr_ext1 + 4'd1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP; addr_ext1 = 0; tick1;

		start1 = 1;
		repeat(2) tick1;
		start1 = 0; tick1;
		while (busy1) tick1;
		repeat(2) tick1;  // margin for PMEM output (clk1 domain)

		$display("################################################################## ");
		$display("      Test 1   |  Dual-core Matrix Multiplication (PMEM = Q*K)   ");
		$display("------------------------------------------------------------------ ");
		$display("  C1 PMEM content :");
		$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
		$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
		err1 = 0;
		mem_cmd_ext1 = EXT_CMD_PMEM_RD; addr_ext1 = 0;
		repeat(2) tick1;  // PMEM read latency
		for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
			row1 = q1;
			$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row1,
				$signed(pmem_out1[7*bw_psum +: bw_psum]), $signed(pmem_out1[6*bw_psum +: bw_psum]),
				$signed(pmem_out1[5*bw_psum +: bw_psum]), $signed(pmem_out1[4*bw_psum +: bw_psum]),
				$signed(pmem_out1[3*bw_psum +: bw_psum]), $signed(pmem_out1[2*bw_psum +: bw_psum]),
				$signed(pmem_out1[1*bw_psum +: bw_psum]), $signed(pmem_out1[0*bw_psum +: bw_psum]));
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				result_c1[row1][0], result_c1[row1][1], result_c1[row1][2], result_c1[row1][3],
				result_c1[row1][4], result_c1[row1][5], result_c1[row1][6], result_c1[row1][7]);
			row_err1 = 0;
			for (c1 = 0; c1 < col; c1 = c1+1)
				if ($signed(pmem_out1[c1*bw_psum +: bw_psum]) !== result_c1[row1][golden_col[c1]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c1,
						$signed(pmem_out1[c1*bw_psum +: bw_psum]), result_c1[row1][golden_col[c1]]);
					err1 = err1 + 1; row_err1 = row_err1 + 1;
				end
			$display("       %s", (row_err1 == 0) ? "[OK]" : "[MISMATCH]");
			addr_ext1 = addr_ext1 + 1; repeat(2) tick1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP;
		mismatch_t1_c1 = err1;
		$display("------------------------------------------------------------");
		if (err1 == 0) $display("  PASS  C1: %0d rows x %0d cols  all match", total_cycle, col);
		else $display("  FAIL  C1: %0d mismatches", err1);
		$display("------------------------------------------------------------");
		$display("");
		test1_done_c1_flag = 1;
		while (!test1_done_c0_flag) tick1;

		// ===== Test 2 =====
		reset1 = 1; repeat(3) tick1; reset1 = 0; tick1;
		set_mode1 = 1'b1; mode_in1 = CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM;
		repeat(2) tick1; set_mode1 = 1'b0; mode_in1 = 3'b000; tick1;

		mem_cmd_ext1 = EXT_CMD_KMEM_WR; addr_ext1 = 0;
		for (q1 = 0; q1 < col; q1 = q1+1) begin
			mem_in1[1*bw-1:0*bw] = K_c1[q1][7]; mem_in1[2*bw-1:1*bw] = K_c1[q1][6];
			mem_in1[3*bw-1:2*bw] = K_c1[q1][5]; mem_in1[4*bw-1:3*bw] = K_c1[q1][4];
			mem_in1[5*bw-1:4*bw] = K_c1[q1][3]; mem_in1[6*bw-1:5*bw] = K_c1[q1][2];
			mem_in1[7*bw-1:6*bw] = K_c1[q1][1]; mem_in1[8*bw-1:7*bw] = K_c1[q1][0];
			tick1; addr_ext1 = addr_ext1 + 4'd1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP; addr_ext1 = 0; tick1;

		mem_cmd_ext1 = EXT_CMD_QMEM_WR; addr_ext1 = 0;
		for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
			mem_in1[1*bw-1:0*bw] = Q[q1][7]; mem_in1[2*bw-1:1*bw] = Q[q1][6];
			mem_in1[3*bw-1:2*bw] = Q[q1][5]; mem_in1[4*bw-1:3*bw] = Q[q1][4];
			mem_in1[5*bw-1:4*bw] = Q[q1][3]; mem_in1[6*bw-1:5*bw] = Q[q1][2];
			mem_in1[7*bw-1:6*bw] = Q[q1][1]; mem_in1[8*bw-1:7*bw] = Q[q1][0];
			tick1; addr_ext1 = addr_ext1 + 4'd1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP; addr_ext1 = 0; tick1;

		start1 = 1; repeat(2) tick1; start1 = 0; tick1;
		while (busy1) tick1; repeat(2) tick1;

		$display("################################################################## ");
		$display("     Test 2   |  Dual-core MatMul + Norm (cross-core sum FIFO)    ");
		$display("------------------------------------------------------------------ ");
		$display("  C1 PMEM content :");
		$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
		$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
		err1 = 0;
		mem_cmd_ext1 = EXT_CMD_PMEM_RD; addr_ext1 = 0;
		repeat(2) tick1;  // PMEM read latency
		for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
			row1 = q1;
			$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row1,
				$signed(pmem_out1[7*bw_psum +: bw_psum]), $signed(pmem_out1[6*bw_psum +: bw_psum]),
				$signed(pmem_out1[5*bw_psum +: bw_psum]), $signed(pmem_out1[4*bw_psum +: bw_psum]),
				$signed(pmem_out1[3*bw_psum +: bw_psum]), $signed(pmem_out1[2*bw_psum +: bw_psum]),
				$signed(pmem_out1[1*bw_psum +: bw_psum]), $signed(pmem_out1[0*bw_psum +: bw_psum]));
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				N_est_c1[row1][0], N_est_c1[row1][1], N_est_c1[row1][2], N_est_c1[row1][3],
				N_est_c1[row1][4], N_est_c1[row1][5], N_est_c1[row1][6], N_est_c1[row1][7]);
			row_err1 = 0;
			for (c1 = 0; c1 < col; c1 = c1+1)
				if ($signed(pmem_out1[c1*bw_psum +: bw_psum]) !== N_est_c1[row1][golden_col[c1]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c1,
						$signed(pmem_out1[c1*bw_psum +: bw_psum]), N_est_c1[row1][golden_col[c1]]);
					err1 = err1 + 1; row_err1 = row_err1 + 1;
				end
			$display("       %s", (row_err1 == 0) ? "[OK]" : "[MISMATCH]");
			addr_ext1 = addr_ext1 + 1; repeat(2) tick1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP;
		mismatch_t2_c1 = err1;
		$display("------------------------------------------------------------");
		if (err1 == 0) $display("  PASS  C1: %0d rows x %0d cols  all match (norm)", total_cycle, col);
		else $display("  FAIL  C1: %0d mismatches", err1);
		$display("------------------------------------------------------------");
		$display("");
		test2_done_c1_flag = 1;
		while (!test2_done_c0_flag) tick1;

		// ===== Test 3 =====
		reset1 = 1; repeat(3) tick1; reset1 = 0; tick1;
		set_mode1 = 1'b1; mode_in1 = CORE_MODE_MULT_save_to_PMEM;
		repeat(2) tick1; set_mode1 = 1'b0; mode_in1 = 3'b000; tick1;

		mem_cmd_ext1 = EXT_CMD_QMEM_WR; addr_ext1 = 0;
		for (q1 = 0; q1 < col; q1 = q1+1) begin
			mem_in1[1*bw-1:0*bw] = V_T[q1][7]; mem_in1[2*bw-1:1*bw] = V_T[q1][6];
			mem_in1[3*bw-1:2*bw] = V_T[q1][5]; mem_in1[4*bw-1:3*bw] = V_T[q1][4];
			mem_in1[5*bw-1:4*bw] = V_T[q1][3]; mem_in1[6*bw-1:5*bw] = V_T[q1][2];
			mem_in1[7*bw-1:6*bw] = V_T[q1][1]; mem_in1[8*bw-1:7*bw] = V_T[q1][0];
			tick1; addr_ext1 = addr_ext1 + 4'd1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP; addr_ext1 = 0; tick1;

		start1 = 1; repeat(2) tick1; start1 = 0; tick1;
		while (busy1) tick1; repeat(2) tick1;

		$display("################################################################## ");
		$display("     Test 3   |  Full pipeline VN (PMEM = V * N from Test2 KMEM)  ");
		$display("------------------------------------------------------------------ ");
		$display("  C1 PMEM content :");
		$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
		$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
		err1 = 0;
		mem_cmd_ext1 = EXT_CMD_PMEM_RD; addr_ext1 = 0;
		repeat(2) tick1;  // PMEM read latency
		for (q1 = 0; q1 < total_cycle; q1 = q1+1) begin
			row1 = q1;
			$display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row1,
				$signed(pmem_out1[7*bw_psum +: bw_psum]), $signed(pmem_out1[6*bw_psum +: bw_psum]),
				$signed(pmem_out1[5*bw_psum +: bw_psum]), $signed(pmem_out1[4*bw_psum +: bw_psum]),
				$signed(pmem_out1[3*bw_psum +: bw_psum]), $signed(pmem_out1[2*bw_psum +: bw_psum]),
				$signed(pmem_out1[1*bw_psum +: bw_psum]), $signed(pmem_out1[0*bw_psum +: bw_psum]));
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				vn_c1[row1][0], vn_c1[row1][1], vn_c1[row1][2], vn_c1[row1][3],
				vn_c1[row1][4], vn_c1[row1][5], vn_c1[row1][6], vn_c1[row1][7]);
			row_err1 = 0;
			for (c1 = 0; c1 < col; c1 = c1+1)
				if ($signed(pmem_out1[c1*bw_psum +: bw_psum]) !== vn_c1[row1][golden_col[c1]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c1,
						$signed(pmem_out1[c1*bw_psum +: bw_psum]), vn_c1[row1][golden_col[c1]]);
					err1 = err1 + 1; row_err1 = row_err1 + 1;
				end
			$display("       %s", (row_err1 == 0) ? "[OK]" : "[MISMATCH]");
			addr_ext1 = addr_ext1 + 1; repeat(2) tick1;
		end
		mem_cmd_ext1 = EXT_CMD_NO_OP;
		mismatch_t3_c1 = err1;
		$display("------------------------------------------------------------");
		if (err1 == 0) $display("  PASS  C1: %0d rows x %0d cols  all match (VN)", total_cycle, col);
		else $display("  FAIL  C1: %0d mismatches", err1);
		$display("------------------------------------------------------------");
		$display("");
		test3_done_c1_flag = 1;
		while (!test3_done_c0_flag) tick1;

		while (1) tick1;  // keep clk1 running
	end

endmodule