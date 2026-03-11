  task DumpVCD(input string filename);
	$dumpfile(filename);
	$dumpvars(0, `TB_TOP);
	$display("");
  endtask

  task LoadAndWriteQ(input string path, output logic was_vdata);
	integer fd, i;
	logic is_vdata;
	begin
	  is_vdata = 0;
	  for (i = 0; i + 5 <= path.len(); i = i + 1)
	    if (path.substr(i, i+4) == "vdata") is_vdata = 1;
	  was_vdata = is_vdata;
	  fd = $fopen(path, "r");
	  if (fd != 0) begin
	    for (q = 0; q < `TOTAL_CYCLE; q++)
	      for (j = 0; j < `PR; j++) begin
	        qkvn_scan_file = $fscanf(fd, "%d\n", captured_data);
	        if (is_vdata) V_T[j][q] = captured_data; else Q[q][j] = captured_data;
	      end
	    $fclose(fd);
	    WriteMemToCore(`EXT_CMD_QMEM_WR, is_vdata ? "V_T" : "Q");
	  end else
	    $display("LoadAndWriteQ: not found: %s", path);
	end
  endtask

  task LoadAndWriteK(input string path);
	integer fd;
	begin
	  fd = $fopen(path, "r");
	  if (fd != 0) begin
	    for (q = 0; q < `TOTAL_CYCLE; q++)
	      for (j = 0; j < `PR; j++) begin
	        qkvn_scan_file = $fscanf(fd, "%d\n", captured_data);
	        K[q][j] = captured_data;
	      end
	    $fclose(fd);
	    WriteMemToCore(`EXT_CMD_KMEM_WR, "K");
	  end else
	    $display("LoadAndWriteK: not found: %s", path);
	end
  endtask

  task MapModeToValue(input string arg, output logic [2:0] mode, output logic ok);
	integer parsed;
	begin
	  ok = 0;
	  mode = 3'b0;
	  if ($sscanf(arg, "%d", parsed) == 1 && parsed >= 0 && parsed <= 7) begin
	    mode = parsed[2:0];
	    ok = 1;
	  end else if (arg == "CORE_MODE_MULT_save_to_PMEM") begin
	    mode = `CORE_MODE_MULT_save_to_PMEM;
	    ok = 1;
	  end else if (arg == "CORE_MODE_MULT_NORM_save_to_PMEM") begin
	    mode = `CORE_MODE_MULT_NORM_save_to_PMEM;
	    ok = 1;
	  end else if (arg == "CORE_MODE_MULT_NORM_save_to_KMEM") begin
	    mode = `CORE_MODE_MULT_NORM_save_to_KMEM;
	    ok = 1;
	  end else if (arg == "CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM") begin
	    mode = `CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM;
	    ok = 1;
	  end
	end
  endtask

  task VerifyPMEMGolden;
	for (c = 0; c < `COL; c++) golden_col[c] = 7 - c;
	err = 0;
	@(negedge clk);
	mem_cmd_ext = `EXT_CMD_PMEM_RD;
	addr_ext = 4'd0;
	@(negedge clk);
	for (q = 0; q < `TOTAL_CYCLE; q++) begin
	  row = q;
	  $display("   [%0d]   RTL   : %5d %5d %5d %5d %5d %5d %5d %5d", row,
		$signed(pmem_out[7*`BW_PSUM +: `BW_PSUM]), $signed(pmem_out[6*`BW_PSUM +: `BW_PSUM]),
		$signed(pmem_out[5*`BW_PSUM +: `BW_PSUM]), $signed(pmem_out[4*`BW_PSUM +: `BW_PSUM]),
		$signed(pmem_out[3*`BW_PSUM +: `BW_PSUM]), $signed(pmem_out[2*`BW_PSUM +: `BW_PSUM]),
		$signed(pmem_out[1*`BW_PSUM +: `BW_PSUM]), $signed(pmem_out[0*`BW_PSUM +: `BW_PSUM]));
	  $display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
	    golden_estimate[row][0], golden_estimate[row][1], golden_estimate[row][2], golden_estimate[row][3],
	    golden_estimate[row][4], golden_estimate[row][5], golden_estimate[row][6], golden_estimate[row][7]);
	  row_err = 0;
	  for (c = 0; c < `COL; c++) begin
	    if ($signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]) !== golden_estimate[row][golden_col[c]]) begin
	      $display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]), golden_estimate[row][golden_col[c]]);
	      err++; row_err++;
	    end
	  end
	  $display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
	  addr_ext = addr_ext + 1;
	  @(negedge clk);
	end
	mem_cmd_ext = `EXT_CMD_NO_OP;
	$display("------------------------------------------------------------");
	if (err == 0)
	  $display("  PASS  %0d rows x %0d cols  all match golden", `TOTAL_CYCLE, `COL);
	else
	  $display("  FAIL  %0d mismatches", err);
	$display("------------------------------------------------------------");
	$display("");
  endtask

  task MonitorStatus;
	begin
		$monitor("time %6t    | start %b   | busy %b   | qmem_locked %b   | kmem_locked %b  | pmem_locked %b",
			$time, start, busy, qmem_locked, kmem_locked, pmem_locked);
	end
  endtask

  task PrintHelpShell;
	begin
		$display("  set_exec_target <mode>  - Set mode (CORE_MODE_MULT_save_to_PMEM, CORE_MODE_MULT_NORM_save_to_PMEM, CORE_MODE_MULT_NORM_save_to_KMEM, CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM, or 0-7)");
		$display("  writeQ <path>          - Load Q or V_T from path, write to QMEM");
		$display("  writeK <path>           - Load K from path, write to KMEM");
		$display("  simulate                - Run core, compute golden, wait done");
		$display("  verifypmem              - Compare PMEM vs golden");
		$display("  reset                   - Reset core");
		$display("  exit                    - Exit");
		$display("  help                    - Show this help");
	end
  endtask

  task PrintSummary;
	begin
		$display("");
		$display("========== SIMULATION SUMMARY ==========");
		$display("  Parameters: CYCLE=%0d  BW=%0d  PR=%0d  COL=%0d  TOTAL_CYCLE=%0d",
			`CYCLE, `BW, `PR, `COL, `TOTAL_CYCLE);
		$display("             OUTPUT_DIR=%s", `OUTPUT_DIR);
		`ifdef SFP_LONGDIV
		$display("             SFP_LONGDIV=yes");
		`else
		$display("             SFP_LONGDIV=no");
		`endif
		$display("  verifypmem calls: %0d", verify_count);
		if (total_mismatches == 0)
			$display("  Result: PASS (all verifypmem matched)");
		else begin
			$display("  Failed verifypmem:");
			for (c = 0; c < verify_count; c++)
				if (verify_err[c] > 0)
					$display("    #%0d: %0d mismatches", c + 1, verify_err[c]);
			$display("  Result: FAIL (%0d total mismatches in %0d verifypmem)", total_mismatches, verify_count);
		end
		$display("=========================================");
		$display("");
	end
  endtask

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
		Reset2Cyc;
		@(negedge clk);
		set_mode = 1'b1;
		mode_in = mode;
		@(negedge clk);
		set_mode = 1'b0;
		mode_in = 3'b000;
		@(negedge clk);
	end
  endtask

  task WriteMemToCore(input [1:0] cmd, input string src);
	@(negedge clk);
	mem_cmd_ext = cmd;
	addr_ext = 0;
	for (q = 0; q < `COL; q++) begin
		if (src == "K") begin
			mem_in[1*`BW-1:0*`BW] = K[q][7];
			mem_in[2*`BW-1:1*`BW] = K[q][6];
			mem_in[3*`BW-1:2*`BW] = K[q][5];
			mem_in[4*`BW-1:3*`BW] = K[q][4];
			mem_in[5*`BW-1:4*`BW] = K[q][3];
			mem_in[6*`BW-1:5*`BW] = K[q][2];
			mem_in[7*`BW-1:6*`BW] = K[q][1];
			mem_in[8*`BW-1:7*`BW] = K[q][0];
		end else if (src == "Q") begin
			mem_in[1*`BW-1:0*`BW] = Q[q][7];
			mem_in[2*`BW-1:1*`BW] = Q[q][6];
			mem_in[3*`BW-1:2*`BW] = Q[q][5];
			mem_in[4*`BW-1:3*`BW] = Q[q][4];
			mem_in[5*`BW-1:4*`BW] = Q[q][3];
			mem_in[6*`BW-1:5*`BW] = Q[q][2];
			mem_in[7*`BW-1:6*`BW] = Q[q][1];
			mem_in[8*`BW-1:7*`BW] = Q[q][0];
		end else if (src == "V_T") begin
			mem_in[1*`BW-1:0*`BW] = V_T[q][7];
			mem_in[2*`BW-1:1*`BW] = V_T[q][6];
			mem_in[3*`BW-1:2*`BW] = V_T[q][5];
			mem_in[4*`BW-1:3*`BW] = V_T[q][4];
			mem_in[5*`BW-1:4*`BW] = V_T[q][3];
			mem_in[6*`BW-1:5*`BW] = V_T[q][2];
			mem_in[7*`BW-1:6*`BW] = V_T[q][1];
			mem_in[8*`BW-1:7*`BW] = V_T[q][0];
		end else begin
			$display("WriteMemToCore: unknown src \"%s\" (use K, Q, or V_T)", src);
		end
		@(negedge clk);
		addr_ext = addr_ext + 4'd1;
	end
	mem_cmd_ext = `EXT_CMD_NO_OP;
	addr_ext = 0;
	@(negedge clk);
  endtask

  task WaitCoreDone;
	begin
		wait (!status[3]);
		@(negedge clk);
	end
  endtask

  task ComputeAndStoreGolden(input [2:0] mode, input use_vp);
	begin
	  ComputeEstimated;
	  if (mode == `CORE_MODE_MULT_save_to_PMEM) begin
	    if (use_vp)
	      for (r = 0; r < `TOTAL_CYCLE; r++)
	        for (c = 0; c < `COL; c++)
	          golden_estimate[r][c] = estimated2[r][c];
	    else
	      for (r = 0; r < `TOTAL_CYCLE; r++)
	        for (c = 0; c < `COL; c++)
	          golden_estimate[r][c] = estimated2_t1[r][c];
	  end else
	    for (r = 0; r < `TOTAL_CYCLE; r++)
	      for (c = 0; c < `COL; c++)
	        golden_estimate[r][c] = estimated1[r*`COL + c];
	end
  endtask

  task ComputeEstimated;
	begin
		for (t = 0; t < `TOTAL_CYCLE; t++)
			for (q = 0; q < `COL; q++)
				estimated2_t1[t][q] = 0;
		for (t = 0; t < `TOTAL_CYCLE; t++) begin
			for (q = 0; q < `COL; q++) begin
				for (k = 0; k < `PR; k++)
					estimated2_t1[t][q] += Q[t][k] * K[q][k];
			end
		end
		for (r = 0; r < `TOTAL_CYCLE; r++) begin
			sum_abs = 0;
			for (c = 0; c < `COL; c++) begin
				unsigned_val = estimated2_t1[r][c];
				if (unsigned_val[`BW_PSUM-1]) unsigned_val = ~(unsigned_val - 1'b1);
				sum_abs += unsigned_val;
			end
			if (sum_abs == 0) sum_abs = 1;
			for (c = 0; c < `COL; c++) begin
				unsigned_val = estimated2_t1[r][c];
				if (unsigned_val[`BW_PSUM-1]) unsigned_val = ~(unsigned_val - 1'b1);
				estimated1[r*`COL + c] = {unsigned_val, {`SFP_OUT_SHIFT{1'b0}}} / sum_abs;
			end
		end
		for (t = 0; t < `TOTAL_CYCLE; t++)
			for (q = 0; q < `COL; q++)
				estimated2[t][q] = 0;
		for (t = 0; t < `TOTAL_CYCLE; t++) begin
			for (q = 0; q < `COL; q++) begin
				for (k = 0; k < `PR; k++)
					estimated2[t][q] += V_T[t][k] * estimated1[q*`COL + k];
			end
		end
	end
  endtask
