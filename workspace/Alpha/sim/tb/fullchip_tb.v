// Core Verification

`timescale 1ns/1ps
`define CYCLE 1
`define H_CYCLE 0.5
`define TIME_OUT 1000


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
	integer divisor;

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
	integer          golden_col [0:7];  // RTL col c -> golden result[t][golden_col[c]] (chain mapping)



	//================= clk ==========================//
	reg                clk   = 0;
	always #(`H_CYCLE) clk = ~clk;

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


	fullchip #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(2*pr)) fullchip_instance(
		.reset0(reset0), 		.reset1(reset1), 	
		.clk0(clk), 			.clk1(clk), 	
		.start0(start0), 		.start1(start1),
		.set_mode0(set_mode0), 	.set_mode1(set_mode1),
		.mode_in0(mode_in0), 	.mode_in1(mode_in1),
		.mem_in0(mem_in0), 		.mem_in1(mem_in1), 
		.inst_ext0(inst_ext0), 	.inst_ext1(inst_ext1),
		.out0(pmem_out0), 		.out1(pmem_out1),	
		.status0(status0), 		.status1(status1)
	);

	
	
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
	for (t = 0; t < total_cycle; t = t+1)
		for (q = 0; q < col; q = q+1) begin
			divisor = sum_c0[t] + sum_c1[t];
			if (divisor == 0) divisor = 1;
			N_est_c0[t][q] = (abs_result_c0[t][q] << sfp_out_shift) / divisor;
			N_est_c1[t][q] = (abs_result_c1[t][q] << sfp_out_shift) / divisor;
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

	//########################################################################
	// Test 1: Matrix Multiplication (dual core, no cross-core sum)
	//########################################################################
	ResetBothCores;
	CoreSetMode0(CORE_MODE_MULT_save_to_PMEM);
	CoreSetMode1(CORE_MODE_MULT_save_to_PMEM);

	// Write K to both cores
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_KMEM_WR; mem_cmd_ext1 = EXT_CMD_KMEM_WR;
	addr_ext0 = 0; addr_ext1 = 0;
	for (q = 0; q < col; q = q+1) begin
		mem_in0[1*bw-1:0*bw] = K_c0[q][7]; mem_in0[2*bw-1:1*bw] = K_c0[q][6];
		mem_in0[3*bw-1:2*bw] = K_c0[q][5]; mem_in0[4*bw-1:3*bw] = K_c0[q][4];
		mem_in0[5*bw-1:4*bw] = K_c0[q][3]; mem_in0[6*bw-1:5*bw] = K_c0[q][2];
		mem_in0[7*bw-1:6*bw] = K_c0[q][1]; mem_in0[8*bw-1:7*bw] = K_c0[q][0];
		mem_in1[1*bw-1:0*bw] = K_c1[q][7]; mem_in1[2*bw-1:1*bw] = K_c1[q][6];
		mem_in1[3*bw-1:2*bw] = K_c1[q][5]; mem_in1[4*bw-1:3*bw] = K_c1[q][4];
		mem_in1[5*bw-1:4*bw] = K_c1[q][3]; mem_in1[6*bw-1:5*bw] = K_c1[q][2];
		mem_in1[7*bw-1:6*bw] = K_c1[q][1]; mem_in1[8*bw-1:7*bw] = K_c1[q][0];
		@(negedge clk);
		addr_ext0 = addr_ext0 + 4'd1; addr_ext1 = addr_ext1 + 4'd1;
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);

	// Write Q to both cores
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_QMEM_WR; mem_cmd_ext1 = EXT_CMD_QMEM_WR;
	addr_ext0 = 0; addr_ext1 = 0;
	for (q = 0; q < total_cycle; q = q+1) begin
		mem_in0[1*bw-1:0*bw] = Q[q][7]; mem_in0[2*bw-1:1*bw] = Q[q][6];
		mem_in0[3*bw-1:2*bw] = Q[q][5]; mem_in0[4*bw-1:3*bw] = Q[q][4];
		mem_in0[5*bw-1:4*bw] = Q[q][3]; mem_in0[6*bw-1:5*bw] = Q[q][2];
		mem_in0[7*bw-1:6*bw] = Q[q][1]; mem_in0[8*bw-1:7*bw] = Q[q][0];
		mem_in1[1*bw-1:0*bw] = Q[q][7]; mem_in1[2*bw-1:1*bw] = Q[q][6];
		mem_in1[3*bw-1:2*bw] = Q[q][5]; mem_in1[4*bw-1:3*bw] = Q[q][4];
		mem_in1[5*bw-1:4*bw] = Q[q][3]; mem_in1[6*bw-1:5*bw] = Q[q][2];
		mem_in1[7*bw-1:6*bw] = Q[q][1]; mem_in1[8*bw-1:7*bw] = Q[q][0];
		@(negedge clk);
		addr_ext0 = addr_ext0 + 4'd1; addr_ext1 = addr_ext1 + 4'd1;
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);

	StartBothCores;
	wait(!busy0 && !busy1); @(negedge clk);

	$display("################################################################## ");
	$display("      Test 1   |  Dual-core Matrix Multiplication (PMEM = Q*K)   ");
	$display("------------------------------------------------------------------ ");
	err0 = 0; err1 = 0;
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_PMEM_RD; mem_cmd_ext1 = EXT_CMD_PMEM_RD;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);
	for (q = 0; q < total_cycle; q = q+1) begin
		row = q;
		$display("  C0 [%0d] RTL: %5d %5d %5d %5d %5d %5d %5d %5d", row,
			$signed(pmem_out0[7*bw_psum +: bw_psum]), $signed(pmem_out0[6*bw_psum +: bw_psum]),
			$signed(pmem_out0[5*bw_psum +: bw_psum]), $signed(pmem_out0[4*bw_psum +: bw_psum]),
			$signed(pmem_out0[3*bw_psum +: bw_psum]), $signed(pmem_out0[2*bw_psum +: bw_psum]),
			$signed(pmem_out0[1*bw_psum +: bw_psum]), $signed(pmem_out0[0*bw_psum +: bw_psum]));
		$display("       golden: %5d %5d %5d %5d %5d %5d %5d %5d",
			result_c0[row][0], result_c0[row][1], result_c0[row][2], result_c0[row][3],
			result_c0[row][4], result_c0[row][5], result_c0[row][6], result_c0[row][7]);
		row_err = 0;
		for (c = 0; c < col; c = c+1) begin
			if ($signed(pmem_out0[c*bw_psum +: bw_psum]) !== result_c0[row][golden_col[c]]) begin
				$display("       >>> C0 col%0d MISMATCH", c);
				err0 = err0 + 1; row_err = row_err + 1;
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		$display("  C1 [%0d] RTL: %5d %5d %5d %5d %5d %5d %5d %5d", row,
			$signed(pmem_out1[7*bw_psum +: bw_psum]), $signed(pmem_out1[6*bw_psum +: bw_psum]),
			$signed(pmem_out1[5*bw_psum +: bw_psum]), $signed(pmem_out1[4*bw_psum +: bw_psum]),
			$signed(pmem_out1[3*bw_psum +: bw_psum]), $signed(pmem_out1[2*bw_psum +: bw_psum]),
			$signed(pmem_out1[1*bw_psum +: bw_psum]), $signed(pmem_out1[0*bw_psum +: bw_psum]));
		$display("       golden: %5d %5d %5d %5d %5d %5d %5d %5d",
			result_c1[row][0], result_c1[row][1], result_c1[row][2], result_c1[row][3],
			result_c1[row][4], result_c1[row][5], result_c1[row][6], result_c1[row][7]);
		row_err = 0;
		for (c = 0; c < col; c = c+1) begin
			if ($signed(pmem_out1[c*bw_psum +: bw_psum]) !== result_c1[row][golden_col[c]]) begin
				$display("       >>> C1 col%0d MISMATCH", c);
				err1 = err1 + 1; row_err = row_err + 1;
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		addr_ext0 = addr_ext0 + 1; addr_ext1 = addr_ext1 + 1;
		@(negedge clk);
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	$display("------------------------------------------------------------");
	if (err0 == 0 && err1 == 0)
		$display("  PASS  Test 1: both cores match golden");
	else
		$display("  FAIL  Test 1: C0 %0d + C1 %0d mismatches", err0, err1);
	$display("------------------------------------------------------------");
	$display("");

	//########################################################################
	// Test 2: MatMul + Norm (cross-core sum via FIFO)
	//########################################################################
	ResetBothCores;
	CoreSetMode0(CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM);
	CoreSetMode1(CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM);

	// Write K to both cores
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_KMEM_WR; mem_cmd_ext1 = EXT_CMD_KMEM_WR;
	addr_ext0 = 0; addr_ext1 = 0;
	for (q = 0; q < col; q = q+1) begin
		mem_in0[1*bw-1:0*bw] = K_c0[q][7]; mem_in0[2*bw-1:1*bw] = K_c0[q][6];
		mem_in0[3*bw-1:2*bw] = K_c0[q][5]; mem_in0[4*bw-1:3*bw] = K_c0[q][4];
		mem_in0[5*bw-1:4*bw] = K_c0[q][3]; mem_in0[6*bw-1:5*bw] = K_c0[q][2];
		mem_in0[7*bw-1:6*bw] = K_c0[q][1]; mem_in0[8*bw-1:7*bw] = K_c0[q][0];
		mem_in1[1*bw-1:0*bw] = K_c1[q][7]; mem_in1[2*bw-1:1*bw] = K_c1[q][6];
		mem_in1[3*bw-1:2*bw] = K_c1[q][5]; mem_in1[4*bw-1:3*bw] = K_c1[q][4];
		mem_in1[5*bw-1:4*bw] = K_c1[q][3]; mem_in1[6*bw-1:5*bw] = K_c1[q][2];
		mem_in1[7*bw-1:6*bw] = K_c1[q][1]; mem_in1[8*bw-1:7*bw] = K_c1[q][0];
		@(negedge clk);
		addr_ext0 = addr_ext0 + 4'd1; addr_ext1 = addr_ext1 + 4'd1;
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);

	// Write Q to both cores
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_QMEM_WR; mem_cmd_ext1 = EXT_CMD_QMEM_WR;
	addr_ext0 = 0; addr_ext1 = 0;
	for (q = 0; q < total_cycle; q = q+1) begin
		mem_in0[1*bw-1:0*bw] = Q[q][7]; mem_in0[2*bw-1:1*bw] = Q[q][6];
		mem_in0[3*bw-1:2*bw] = Q[q][5]; mem_in0[4*bw-1:3*bw] = Q[q][4];
		mem_in0[5*bw-1:4*bw] = Q[q][3]; mem_in0[6*bw-1:5*bw] = Q[q][2];
		mem_in0[7*bw-1:6*bw] = Q[q][1]; mem_in0[8*bw-1:7*bw] = Q[q][0];
		mem_in1[1*bw-1:0*bw] = Q[q][7]; mem_in1[2*bw-1:1*bw] = Q[q][6];
		mem_in1[3*bw-1:2*bw] = Q[q][5]; mem_in1[4*bw-1:3*bw] = Q[q][4];
		mem_in1[5*bw-1:4*bw] = Q[q][3]; mem_in1[6*bw-1:5*bw] = Q[q][2];
		mem_in1[7*bw-1:6*bw] = Q[q][1]; mem_in1[8*bw-1:7*bw] = Q[q][0];
		@(negedge clk);
		addr_ext0 = addr_ext0 + 4'd1; addr_ext1 = addr_ext1 + 4'd1;
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);

	StartBothCores;
	wait(!busy0 && !busy1); @(negedge clk);

	$display("################################################################## ");
	$display("     Test 2   |  Dual-core MatMul + Norm (cross-core sum FIFO)    ");
	$display("------------------------------------------------------------------ ");
	err0 = 0; err1 = 0;
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_PMEM_RD; mem_cmd_ext1 = EXT_CMD_PMEM_RD;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);
	for (q = 0; q < total_cycle; q = q+1) begin
		row = q;
		$display("  C0 [%0d] RTL: %5d %5d %5d %5d %5d %5d %5d %5d", row,
			$signed(pmem_out0[7*bw_psum +: bw_psum]), $signed(pmem_out0[6*bw_psum +: bw_psum]),
			$signed(pmem_out0[5*bw_psum +: bw_psum]), $signed(pmem_out0[4*bw_psum +: bw_psum]),
			$signed(pmem_out0[3*bw_psum +: bw_psum]), $signed(pmem_out0[2*bw_psum +: bw_psum]),
			$signed(pmem_out0[1*bw_psum +: bw_psum]), $signed(pmem_out0[0*bw_psum +: bw_psum]));
		$display("       golden: %5d %5d %5d %5d %5d %5d %5d %5d",
			N_est_c0[row][0], N_est_c0[row][1], N_est_c0[row][2], N_est_c0[row][3],
			N_est_c0[row][4], N_est_c0[row][5], N_est_c0[row][6], N_est_c0[row][7]);
		row_err = 0;
		for (c = 0; c < col; c = c+1) begin
			if ($signed(pmem_out0[c*bw_psum +: bw_psum]) !== N_est_c0[row][golden_col[c]]) begin
				$display("       >>> C0 col%0d MISMATCH", c);
				err0 = err0 + 1; row_err = row_err + 1;
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		$display("  C1 [%0d] RTL: %5d %5d %5d %5d %5d %5d %5d %5d", row,
			$signed(pmem_out1[7*bw_psum +: bw_psum]), $signed(pmem_out1[6*bw_psum +: bw_psum]),
			$signed(pmem_out1[5*bw_psum +: bw_psum]), $signed(pmem_out1[4*bw_psum +: bw_psum]),
			$signed(pmem_out1[3*bw_psum +: bw_psum]), $signed(pmem_out1[2*bw_psum +: bw_psum]),
			$signed(pmem_out1[1*bw_psum +: bw_psum]), $signed(pmem_out1[0*bw_psum +: bw_psum]));
		$display("       golden: %5d %5d %5d %5d %5d %5d %5d %5d",
			N_est_c1[row][0], N_est_c1[row][1], N_est_c1[row][2], N_est_c1[row][3],
			N_est_c1[row][4], N_est_c1[row][5], N_est_c1[row][6], N_est_c1[row][7]);
		row_err = 0;
		for (c = 0; c < col; c = c+1) begin
			if ($signed(pmem_out1[c*bw_psum +: bw_psum]) !== N_est_c1[row][golden_col[c]]) begin
				$display("       >>> C1 col%0d MISMATCH", c);
				err1 = err1 + 1; row_err = row_err + 1;
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		addr_ext0 = addr_ext0 + 1; addr_ext1 = addr_ext1 + 1;
		@(negedge clk);
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	$display("------------------------------------------------------------");
	if (err0 == 0 && err1 == 0)
		$display("  PASS  Test 2: both cores match golden (norm)");
	else
		$display("  FAIL  Test 2: C0 %0d + C1 %0d mismatches", err0, err1);
	$display("------------------------------------------------------------");
	$display("");

	//########################################################################
	// Test 3: Full pipeline VN (V * N, KMEM from Test 2)
	//########################################################################
	ResetBothCores;
	CoreSetMode0(CORE_MODE_MULT_save_to_PMEM);
	CoreSetMode1(CORE_MODE_MULT_save_to_PMEM);

	// Don't touch KMEM; only write V_T to QMEM
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_QMEM_WR; mem_cmd_ext1 = EXT_CMD_QMEM_WR;
	addr_ext0 = 0; addr_ext1 = 0;
	for (q = 0; q < col; q = q+1) begin
		mem_in0[1*bw-1:0*bw] = V_T[q][7]; mem_in0[2*bw-1:1*bw] = V_T[q][6];
		mem_in0[3*bw-1:2*bw] = V_T[q][5]; mem_in0[4*bw-1:3*bw] = V_T[q][4];
		mem_in0[5*bw-1:4*bw] = V_T[q][3]; mem_in0[6*bw-1:5*bw] = V_T[q][2];
		mem_in0[7*bw-1:6*bw] = V_T[q][1]; mem_in0[8*bw-1:7*bw] = V_T[q][0];
		mem_in1[1*bw-1:0*bw] = V_T[q][7]; mem_in1[2*bw-1:1*bw] = V_T[q][6];
		mem_in1[3*bw-1:2*bw] = V_T[q][5]; mem_in1[4*bw-1:3*bw] = V_T[q][4];
		mem_in1[5*bw-1:4*bw] = V_T[q][3]; mem_in1[6*bw-1:5*bw] = V_T[q][2];
		mem_in1[7*bw-1:6*bw] = V_T[q][1]; mem_in1[8*bw-1:7*bw] = V_T[q][0];
		@(negedge clk);
		addr_ext0 = addr_ext0 + 4'd1; addr_ext1 = addr_ext1 + 4'd1;
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);

	StartBothCores;
	wait(!busy0 && !busy1); @(negedge clk);

	$display("################################################################## ");
	$display("     Test 3   |  Full pipeline VN (PMEM = V * N from Test2 KMEM)  ");
	$display("------------------------------------------------------------------ ");
	err0 = 0; err1 = 0;
	@(negedge clk);
	mem_cmd_ext0 = EXT_CMD_PMEM_RD; mem_cmd_ext1 = EXT_CMD_PMEM_RD;
	addr_ext0 = 0; addr_ext1 = 0;
	@(negedge clk);
	for (q = 0; q < total_cycle; q = q+1) begin
		row = q;
		$display("  C0 [%0d] RTL: %5d %5d %5d %5d %5d %5d %5d %5d", row,
			$signed(pmem_out0[7*bw_psum +: bw_psum]), $signed(pmem_out0[6*bw_psum +: bw_psum]),
			$signed(pmem_out0[5*bw_psum +: bw_psum]), $signed(pmem_out0[4*bw_psum +: bw_psum]),
			$signed(pmem_out0[3*bw_psum +: bw_psum]), $signed(pmem_out0[2*bw_psum +: bw_psum]),
			$signed(pmem_out0[1*bw_psum +: bw_psum]), $signed(pmem_out0[0*bw_psum +: bw_psum]));
		$display("       golden: %5d %5d %5d %5d %5d %5d %5d %5d",
			vn_c0[row][0], vn_c0[row][1], vn_c0[row][2], vn_c0[row][3],
			vn_c0[row][4], vn_c0[row][5], vn_c0[row][6], vn_c0[row][7]);
		row_err = 0;
		for (c = 0; c < col; c = c+1) begin
			if ($signed(pmem_out0[c*bw_psum +: bw_psum]) !== vn_c0[row][golden_col[c]]) begin
				$display("       >>> C0 col%0d MISMATCH", c);
				err0 = err0 + 1; row_err = row_err + 1;
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		$display("  C1 [%0d] RTL: %5d %5d %5d %5d %5d %5d %5d %5d", row,
			$signed(pmem_out1[7*bw_psum +: bw_psum]), $signed(pmem_out1[6*bw_psum +: bw_psum]),
			$signed(pmem_out1[5*bw_psum +: bw_psum]), $signed(pmem_out1[4*bw_psum +: bw_psum]),
			$signed(pmem_out1[3*bw_psum +: bw_psum]), $signed(pmem_out1[2*bw_psum +: bw_psum]),
			$signed(pmem_out1[1*bw_psum +: bw_psum]), $signed(pmem_out1[0*bw_psum +: bw_psum]));
		$display("       golden: %5d %5d %5d %5d %5d %5d %5d %5d",
			vn_c1[row][0], vn_c1[row][1], vn_c1[row][2], vn_c1[row][3],
			vn_c1[row][4], vn_c1[row][5], vn_c1[row][6], vn_c1[row][7]);
		row_err = 0;
		for (c = 0; c < col; c = c+1) begin
			if ($signed(pmem_out1[c*bw_psum +: bw_psum]) !== vn_c1[row][golden_col[c]]) begin
				$display("       >>> C1 col%0d MISMATCH", c);
				err1 = err1 + 1; row_err = row_err + 1;
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		addr_ext0 = addr_ext0 + 1; addr_ext1 = addr_ext1 + 1;
		@(negedge clk);
	end
	mem_cmd_ext0 = EXT_CMD_NO_OP; mem_cmd_ext1 = EXT_CMD_NO_OP;
	$display("------------------------------------------------------------");
	if (err0 == 0 && err1 == 0)
		$display("  PASS  Test 3: both cores match golden (VN)");
	else
		$display("  FAIL  Test 3: C0 %0d + C1 %0d mismatches", err0, err1);
	$display("------------------------------------------------------------");
	$display("");

	#10 $finish;
end


















//================= Reusable Tasks ====================
  task ResetBothCores;
	begin
		@(negedge clk);
		reset0 = 1; reset1 = 1;
		repeat(2) @(negedge clk);
		reset0 = 0; reset1 = 0;
		@(negedge clk);
	end
  endtask

  task StartBothCores;
	begin
		@(negedge clk);
		start0 = 1; start1 = 1;
		@(negedge clk);
		start0 = 0; start1 = 0;
		@(negedge clk);
	end
  endtask

  task CoreSetMode0;
  	input [2:0] mode;
	begin
		@(negedge clk);
		set_mode0 = 1'b1;
		mode_in0 = mode;
		@(negedge clk);
		set_mode0 = 1'b0;
		mode_in0 = 3'b000;
		@(negedge clk);
	end
  endtask

  task CoreSetMode1;
  	input [2:0] mode;
	begin
		@(negedge clk);
		set_mode1 = 1'b1;
		mode_in1 = mode;
		@(negedge clk);
		set_mode1 = 1'b0;
		mode_in1 = 3'b000;
		@(negedge clk);
	end
  endtask

endmodule