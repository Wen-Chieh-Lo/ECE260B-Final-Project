// Fullchip Shell - Interactive verification for post_sim (xrun, PnR netlist)
// Reads stdin for writeQ, simulate, verifypmem etc. PnR netlist: fullchip.pnr.v
// tb_utils include after fullchip instance for xrun compatibility.

`timescale 1ns/1ps
`define TB_TOP fullchip_shell_tb
`define TB_FULLCHIP
`include "sim/tb/params.v"

`ifndef SFP_THRESHOLD
  `define SFP_THRESHOLD 0
`endif

module fullchip_shell_tb;
	int qkvn_file, qkvn_scan_file, captured_data;
	int i, j, k, t, p, q, s, u, m, r, c;
	int err_count;
	int err, err0, err1, row_err, row;
	int total_mismatches;
	int verify_count;
	int verify_err[0:1023];

	// Norm gate (TB golden): cumulative across all simulate() / ComputeEstimatedFullchip calls
	int norm_gate_skip_total_all;
	int norm_gate_row_total_all;

	int sum_abs, divisor, unsigned_val;

	// Dual-core data
	int K_c0     [`COL-1:0][`PR-1:0];
	int K_c1     [`COL-1:0][`PR-1:0];
	int Q        [`TOTAL_CYCLE-1:0][`PR-1:0];
	int V_T      [`TOTAL_CYCLE-1:0][`PR-1:0];
	int result_c0 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int result_c1 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int abs_result_c0 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int abs_result_c1 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int sum_c0   [`TOTAL_CYCLE-1:0];
	int sum_c1   [`TOTAL_CYCLE-1:0];
	int N_est_c0 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int N_est_c1 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int vn_c0    [`TOTAL_CYCLE-1:0][`COL-1:0];
	int vn_c1    [`TOTAL_CYCLE-1:0][`COL-1:0];
	int golden_estimate_c0 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int golden_estimate_c1 [`TOTAL_CYCLE-1:0][`COL-1:0];
	int golden_col [0:7];

	logic [2:0] current_mode;
	logic last_writeQ_was_vdata;
	logic map_ok;
	string cmd, arg;

	// Independent clk0 / clk1 (periods H_CYCLE0, H_CYCLE1 from params / set_clock_period).
	logic clk0 = 0, clk1 = 0;
	always #(`H_CYCLE0) clk0 = ~clk0;
	always #(`H_CYCLE1) clk1 = ~clk1;

	logic reset = 1;
	logic start0 = 0, start1 = 0;
	logic [`PR*`BW-1:0] mem_in0, mem_in1;
	logic [1:0] mem_cmd_ext0 = 2'd0, mem_cmd_ext1 = 2'd0;
	logic [3:0] addr_ext0 = 4'd0, addr_ext1 = 4'd0;

	logic [5:0] inst_ext0, inst_ext1;
	assign inst_ext0 = {addr_ext0, mem_cmd_ext0};
	assign inst_ext1 = {addr_ext1, mem_cmd_ext1};

	logic set_mode0 = 0, set_mode1 = 0;
	logic [2:0] mode_in0, mode_in1;

	logic [3:0] status0, status1;
	logic [`BW_PSUM*`COL-1:0] pmem_out0, pmem_out1;
	logic [`BW_PSUM*`COL-1:0] out0, out1;
	logic busy0, busy1;
	assign busy0 = status0[3];
	assign busy1 = status1[3];
	assign pmem_out0 =  (^out0 === 1'bx)? 0 : out0;
	assign pmem_out1 =  (^out1 === 1'bx)? 0 : out1;
	fullchip fullchip_instance (
		.reset0(reset), .reset1(reset),
		.clk0(clk0), .clk1(clk1),
		.start0(start0), .start1(start1),
		.set_mode0(set_mode0), .set_mode1(set_mode1),
		.mode_in0(mode_in0), .mode_in1(mode_in1),
		.mem_in0(mem_in0), .mem_in1(mem_in1),
		.inst_ext0(inst_ext0), .inst_ext1(inst_ext1),
		.out0(out0), 		.out1(out1),
		.status0(status0), .status1(status1)
	);

	`include "sim/tb/tb_utils.v"

	initial begin
		DumpVCD("waveform/fullchip_shell.vcd");
		MonitorStatusFullchip;
		current_mode = `CORE_MODE_MULT_save_to_PMEM;
		last_writeQ_was_vdata = 0;
		total_mismatches = 0;
		verify_count = 0;
		norm_gate_skip_total_all = 0;
		norm_gate_row_total_all = 0;
		Reset2CycFullchip;

		$display(">>> Fullchip shell (post_sim). Type: set_exec_target, writeQ, writeK0, writeK1, simulate, verifypmem, reset, exit, help");
		forever begin
			$write("fullchip_shell> ");
			if ($fscanf(`STDIN, "%s", cmd) >= 1) begin
				$display("");
				if (cmd.len() > 0 && cmd[0] == "#") ;
				else if (cmd == "set_exec_target") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1) begin
						MapModeToValue(arg, current_mode, map_ok);
						if (map_ok) CoreSetModeFullchip(current_mode);
						else $display("Unknown mode: %s", arg);
					end else $display("set_exec_target requires mode argument");
				end else if (cmd == "writeQ") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1)
						LoadAndWriteQFullchip(arg, last_writeQ_was_vdata);
					else $display("writeQ requires path argument");
				end else if (cmd == "writeK0") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1) begin
						last_writeQ_was_vdata = 0;
						LoadAndWriteK0Fullchip(arg);
					end else $display("writeK0 requires path argument");
				end else if (cmd == "writeK1") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1) begin
						last_writeQ_was_vdata = 0;
						LoadAndWriteK1Fullchip(arg);
					end else $display("writeK1 requires path argument");
				end else if (cmd == "simulate") begin
					ComputeAndStoreGoldenFullchip(current_mode, last_writeQ_was_vdata);
					Start1CycFullchip;
					WaitCoreDoneFullchip;
				end
				else if (cmd == "verifypmem") begin
					VerifyPMEMGoldenFullchip(0);
					err0 = err;
					VerifyPMEMGoldenFullchip(1);
					err1 = err;
					verify_err[verify_count] = err0; total_mismatches += err0; verify_count++;
					verify_err[verify_count] = err1; total_mismatches += err1; verify_count++;
					$display("------------------------------------------------------------");
					if (err0 == 0 && err1 == 0)
						$display("  PASS  both cores match golden");
					else
						$display("  FAIL  C0: %0d  C1: %0d mismatches", err0, err1);
					$display("------------------------------------------------------------");
					$display("");
				end
				else if (cmd == "verifypmem0") begin
					VerifyPMEMGoldenFullchip(0);
					verify_err[verify_count] = err;
					total_mismatches += err;
					verify_count++;
				end
				else if (cmd == "verifypmem1") begin
					VerifyPMEMGoldenFullchip(1);
					verify_err[verify_count] = err;
					total_mismatches += err;
					verify_count++;
				end
				else if (cmd == "reset") Reset2CycFullchip;
				else if (cmd == "exit") begin
					PrintSummaryFullchip;
					$finish;
				end
				else if (cmd == "help") PrintHelpShellFullchip;
				else $display("Unknown command: %s (type help)", cmd);
			end
		end
	end

endmodule
