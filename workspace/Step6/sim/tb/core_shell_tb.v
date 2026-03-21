// Core Shell - Interactive verification (SystemVerilog)

`timescale 1ns/1ps
`define TB_TOP core_shell_tb
`include "sim/tb/params.v"

`ifndef SFP_THRESHOLD
  `define SFP_THRESHOLD 0
`endif

module core_shell_tb;
	`include "sim/tb/tb_utils.v"

	int qkvn_file, qkvn_scan_file, captured_data;
	int i, j, k, t, p, q, s, u, m, r, c;
	int err_count;
	int err, row_err, row;
	int total_mismatches;  // accumulated across all verifypmem
	int verify_count;      // number of verifypmem calls
	int verify_err[0:1023]; // mismatch count per verifypmem call (1-based index in report)
	int sum_abs, divisor, unsigned_val;
	int mac_sum4, mac_s1, mac_s2;  // mac_8in two-stage reference (match verilog/mac/mac_8in.v)

	int K        [`COL-1:0][`PR-1:0];
	int Q        [`TOTAL_CYCLE-1:0][`PR-1:0];
	int V_T      [`TOTAL_CYCLE-1:0][`PR-1:0];
	int estimated2_t1[`TOTAL_CYCLE-1:0][`COL-1:0];
	int estimated2[`TOTAL_CYCLE-1:0][`COL-1:0];
	int sum      [`TOTAL_CYCLE-1:0];
	int estimated1[0:`TOTAL_CYCLE*`COL-1];
	int golden_col [0:7];

	// Single golden register for verifypmem (set by simulate; one of Q*K^T, norm, or V*Norm^T)
	int golden_estimate[`TOTAL_CYCLE-1:0][`COL-1:0];

	logic [2:0] current_mode;
	logic last_writeQ_was_vdata;
	logic map_ok;
	string cmd, arg;

	logic clk = 0;
	always #(`H_CYCLE) clk = ~clk;

	logic reset = 1;
	logic start = 0;
	logic [`PR*`BW-1:0] mem_in;
	logic [1:0] mem_cmd_ext = 2'd0;
	logic [3:0] addr_ext = 4'd0;

	logic [5:0] inst_ext;
	assign inst_ext = {addr_ext, mem_cmd_ext};

	logic set_mode;
	logic [2:0] mode_in;

	logic [3:0] status;
	logic [`BW_PSUM*`COL-1:0] pmem_out;
	logic busy, qmem_locked, kmem_locked, pmem_locked;
	assign busy         = status[3];
	assign qmem_locked  = status[2];
	assign kmem_locked  = status[1];
	assign pmem_locked  = status[0];

	// Single-core shell: no partner core — drive sum_in=0, sum_in_valid=1 so norm (div) can
	// complete (core.v gates div_start on sum_in_valid; see core_tb.v same tie-off).
	logic [`BW_PSUM+3:0] sum_in_tb;
	logic                  sum_in_valid_tb;
	assign sum_in_tb       = {(`BW_PSUM+4){1'b0}};
	assign sum_in_valid_tb = 1'b1;

	core #(.bw(`BW), .bw_psum(`BW_PSUM), .col(`COL), .pr(`PR)) core_instance (
		.reset(reset),
		.clk(clk),
		.set_mode(set_mode),
		.mode_in(mode_in),
		.mem_in(mem_in),
		.inst_ext(inst_ext),
		.sum_in(sum_in_tb),
		.sum_in_valid(sum_in_valid_tb),
		.sum_in_fifo_pop(),
		.sum_out(),
		.sum_out_valid(),
		.out(pmem_out),
		.start(start),
		.status(status)
	);

	initial begin
`ifndef NO_DUMP_VCD
		DumpVCD("sim/waveform/core.vcd");
`endif
		MonitorStatus;
		current_mode = `CORE_MODE_MULT_save_to_PMEM;
		last_writeQ_was_vdata = 0;
		total_mismatches = 0;
		verify_count = 0;
		Reset2Cyc;

		$display(">>> Core shell. Type: set_exec_target, writeQ, writeK, simulate, verifypmem, reset, exit, help");
		forever begin
			$write("core_shell> ");
			if ($fscanf(`STDIN, "%s", cmd) >= 1) begin
				$display("");
				if (cmd.len() > 0 && cmd[0] == "#") ; // skip comment
				else if (cmd == "set_exec_target") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1) begin
						MapModeToValue(arg, current_mode, map_ok);
						if (map_ok) CoreSetMode(current_mode);
						else $display("Unknown mode: %s", arg);
					end else $display("set_exec_target requires mode argument");
				end else if (cmd == "writeQ") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1)
						LoadAndWriteQ(arg, last_writeQ_was_vdata);
					else $display("writeQ requires path argument");
				end else if (cmd == "writeK") begin
					if ($fscanf(`STDIN, "%s", arg) >= 1) begin
						last_writeQ_was_vdata = 0;
						LoadAndWriteK(arg);
					end else $display("writeK requires path argument");
				end else if (cmd == "simulate") begin
					ComputeAndStoreGolden(current_mode, last_writeQ_was_vdata);
					Start1Cyc;
					WaitCoreDone;
				end 
				else if (cmd == "verifypmem") begin
					VerifyPMEMGolden;
					verify_err[verify_count] = err;
					total_mismatches += err;
					verify_count++;
				end
				else if (cmd == "reset") Reset2Cyc;
				else if (cmd == "exit") begin
					PrintSummary;
					$finish;
				end
				else if (cmd == "help") PrintHelpShell;
				else $display("Unknown command: %s (type help)", cmd);
			end
		end
	end

endmodule
