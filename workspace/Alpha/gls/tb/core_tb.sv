// Core Gate-Level Verification - SystemVerilog
// Same structure as sim/tb/core_tb.sv, DUT = syn/gate/core.out.v

`timescale 1ns/1ps
`include "sim/tb/params.svh"
`include "sim/tb/pattern_path.vh"

module core_tb;
	`include "sim/tb/tb_utils.sv"

	//================= integer / array storage =====================//
	int qkvn_file, qkvn_scan_file, captured_data;
`ifdef SIM_INTERACTIVE
	string cmd;
`endif
	int i, j, k, t, p, q, s, u, m, r, c;
	int err_count;
	int err, row_err, row;
	int sum_abs, divisor, unsigned_val;

	int K        [`COL-1:0][`PR-1:0];
	int Q        [`TOTAL_CYCLE-1:0][`PR-1:0];
	int V_T      [`TOTAL_CYCLE-1:0][`PR-1:0];
	int estimated2_t1[`TOTAL_CYCLE-1:0][`COL-1:0];
	int estimated2[`TOTAL_CYCLE-1:0][`COL-1:0];
	int sum      [`TOTAL_CYCLE-1:0];
	int estimated1[0:`TOTAL_CYCLE*`COL-1];
	int golden_col [0:7];

	//================= clk ==========================//
	logic clk = 0;
	always #(`H_CYCLE) clk = ~clk;

	//================= timeout ======================//
`ifndef SIM_INTERACTIVE
	initial #(`TIME_OUT) $finish;
`endif

	//============= Input to DUT  ===============//
	logic reset = 1;
	logic start = 0;
	logic [`PR*`BW-1:0] mem_in;
	logic [1:0] mem_cmd_ext = 2'd0;
	logic [3:0] addr_ext = 4'd0;

	logic [5:0] inst_ext;
	assign inst_ext = {addr_ext, mem_cmd_ext};

	logic set_mode;
	logic [2:0] mode_in;

	//============= DUT's Output  ===============//
	logic [2:0] status;
	logic [`BW_PSUM*`COL-1:0] pmem_out;

	// Gate-level core (same interface as RTL, params flattened in netlist)
	core core_instance (
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
		// Set VCD waveform output file
		DumpVCD("gls/waveform/core.vcd");
		// Load Q, K, V_T test data (path from pattern_path.vh)
		LoadPatternData(`PATTERN_PATH);
		// Reset core
		Reset2Cyc;
		// Precompute all golden: estimated2_t1, estimated1, estimated2
		ComputeEstimated;

`ifdef SIM_INTERACTIVE
		//########################################################################
		// Interactive mode: read commands from stdin
		// Commands: qkp | norm | vp | reset | quit | help
		//########################################################################
		$display("");
		$display(">>> Interactive GLS mode. Type: qkp, norm, vp, reset, quit, help");
		$display("");
		forever begin
			$write("gls_tb> ");
			if ($fscanf(`STDIN, "%s", cmd) >= 1) begin
			if (cmd == "qkp") begin
				CoreSetMode(`CORE_MODE_MULT_save_to_PMEM);
				WriteMemToCore(`EXT_CMD_KMEM_WR, 0);
				WriteMemToCore(`EXT_CMD_QMEM_WR, 1);
				Start1Cyc;
				WaitCoreDone;
				PrintVerifyHeader("Matrix Multiplication (GLS)", "Test 1   |  PMEM =?= QMEM * Transpose(KMEM)", "", "");
				VerifyPMEM(0);
			end else if (cmd == "norm") begin
				Reset2Cyc;
				CoreSetMode(`CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM);
				WriteMemToCore(`EXT_CMD_KMEM_WR, 0);
				WriteMemToCore(`EXT_CMD_QMEM_WR, 1);
				Start1Cyc;
				WaitCoreDone;
				PrintVerifyHeader("Matrix Multiplication + Result Normalization (GLS)", "Test 2    |  PMEM  =?=  Norm (QMEM * Transpose(KMEM))",
					"LONGDIV/VANILLA should match; LUTDIV might not", "Norm is saved to both PMEM & KMEM in this mode");
				VerifyPMEM(1);
			end else if (cmd == "vp") begin
				Reset2Cyc;
				CoreSetMode(`CORE_MODE_MULT_save_to_PMEM);
				WriteMemToCore(`EXT_CMD_QMEM_WR, 2);
				Start1Cyc;
				WaitCoreDone;
				PrintVerifyHeader("Full MULT-NORM-MULT Pipeline (GLS)", "Test 3   |  PMEM =?= QMEM * Transpose(Norm)",
					"This test depends on Test2", "The command to the core is the same as Test 1");
				VerifyPMEM(2);
			end else if (cmd == "reset") begin
				Reset2Cyc;
				$display("Reset done.");
			end else if (cmd == "quit" || cmd == "q") begin
				$display("Bye.");
				$finish;
			end else if (cmd == "help" || cmd == "h") begin
				$display("  qkp   - PMEM = Q*K^T");
				$display("  norm  - PMEM = Norm(Q*K^T)");
				$display("  vp    - PMEM = V_T*Norm^T (needs norm first)");
				$display("  reset - Reset core");
				$display("  quit  - Exit");
			end else begin
				$display("Unknown command: %s (type help)", cmd);
			end
			end
		end
`else
		//########################################################################
		// Test 1: Matrix Multiplication
		// PMEM = QMEM * Transpose(KMEM)
		//########################################################################
		CoreSetMode(`CORE_MODE_MULT_save_to_PMEM);
		WriteMemToCore(`EXT_CMD_KMEM_WR, 0);  // Write K to KMEM
		WriteMemToCore(`EXT_CMD_QMEM_WR, 1);  // Write Q to QMEM

		Start1Cyc;
		WaitCoreDone;

		PrintVerifyHeader("Matrix Multiplication (GLS)", "Test 1   |  PMEM =?= QMEM * Transpose(KMEM)", "", "");
		VerifyPMEM(0);  // Compare to estimated2_t1 (Q*K^T)

		Reset2Cyc;

		//########################################################################
		// Test 2: Matrix Multiplication + Result Normalization
		// PMEM = Norm(QMEM * Transpose(KMEM)), result saved to both PMEM & KMEM
		//########################################################################
		CoreSetMode(`CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM);

		WriteMemToCore(`EXT_CMD_KMEM_WR, 0);  // Write K to KMEM
		WriteMemToCore(`EXT_CMD_QMEM_WR, 1);  // Write Q to QMEM

		Start1Cyc;
		WaitCoreDone;

		PrintVerifyHeader("Matrix Multiplication + Result Normalization (GLS)", "Test 2    |  PMEM  =?=  Norm (QMEM * Transpose(KMEM))",
			"LONGDIV/VANILLA should match; LUTDIV might not", "Norm is saved to both PMEM & KMEM in this mode");
		VerifyPMEM(1);  // Compare to estimated1 (norm result)

		Reset2Cyc;

		//########################################################################
		// Test 3: Full MULT-NORM-MULT Pipeline
		// PMEM = V_T * Transpose(Norm), depends on Test 2 norm in KMEM
		//########################################################################
		CoreSetMode(`CORE_MODE_MULT_save_to_PMEM);

		WriteMemToCore(`EXT_CMD_QMEM_WR, 2);  // Write V_T to QMEM (KMEM has Test 2 norm)

		Start1Cyc;
		WaitCoreDone;

		PrintVerifyHeader("Full MULT-NORM-MULT Pipeline (GLS)", "Test 3   |  PMEM =?= QMEM * Transpose(Norm)",
			"This test depends on Test2", "The command to the core is the same as Test 1");
		VerifyPMEM(2);  // Compare to estimated2 (V_T * estimated1)

		#10 $finish;
`endif
	end

endmodule
