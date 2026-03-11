  task DumpVCD(input string filename);
	$dumpfile(filename);
	$dumpvars(0, core_tb);
	$display("");
  endtask

  task LoadPatternData(input string folder);
	begin
		qkvn_file = $fopen({folder, "/qdata.txt"}, "r");
		for (q = 0; q < `TOTAL_CYCLE; q++)
			for (j = 0; j < `PR; j++) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
				Q[q][j] = captured_data;
			end
		qkvn_file = $fopen({folder, "/kdata.txt"}, "r");
		for (q = 0; q < `TOTAL_CYCLE; q++)
			for (j = 0; j < `PR; j++) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
				K[q][j] = captured_data;
			end
		qkvn_file = $fopen({folder, "/vdata.txt"}, "r");
		for (q = 0; q < `TOTAL_CYCLE; q++)
			for (j = 0; j < `PR; j++) begin
				qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
				V_T[j][q] = captured_data;
			end
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
		@(negedge clk);
		set_mode = 1'b1;
		mode_in = mode;
		@(negedge clk);
		set_mode = 1'b0;
		mode_in = 3'b000;
		@(negedge clk);
	end
  endtask

  // src: 0=K, 1=Q, 2=V_T. KMEM uses K only; QMEM uses Q or V_T.
  task WriteMemToCore(input [1:0] cmd, input [1:0] src);
	@(negedge clk);
	mem_cmd_ext = cmd;
	addr_ext = 0;
	for (q = 0; q < `COL; q++) begin
		case (src)
			0: begin mem_in[1*`BW-1:0*`BW] = K[q][7]; mem_in[2*`BW-1:1*`BW] = K[q][6]; mem_in[3*`BW-1:2*`BW] = K[q][5]; mem_in[4*`BW-1:3*`BW] = K[q][4]; mem_in[5*`BW-1:4*`BW] = K[q][3]; mem_in[6*`BW-1:5*`BW] = K[q][2]; mem_in[7*`BW-1:6*`BW] = K[q][1]; mem_in[8*`BW-1:7*`BW] = K[q][0]; end
			1: begin mem_in[1*`BW-1:0*`BW] = Q[q][7]; mem_in[2*`BW-1:1*`BW] = Q[q][6]; mem_in[3*`BW-1:2*`BW] = Q[q][5]; mem_in[4*`BW-1:3*`BW] = Q[q][4]; mem_in[5*`BW-1:4*`BW] = Q[q][3]; mem_in[6*`BW-1:5*`BW] = Q[q][2]; mem_in[7*`BW-1:6*`BW] = Q[q][1]; mem_in[8*`BW-1:7*`BW] = Q[q][0]; end
			2: begin mem_in[1*`BW-1:0*`BW] = V_T[q][7]; mem_in[2*`BW-1:1*`BW] = V_T[q][6]; mem_in[3*`BW-1:2*`BW] = V_T[q][5]; mem_in[4*`BW-1:3*`BW] = V_T[q][4]; mem_in[5*`BW-1:4*`BW] = V_T[q][3]; mem_in[6*`BW-1:5*`BW] = V_T[q][2]; mem_in[7*`BW-1:6*`BW] = V_T[q][1]; mem_in[8*`BW-1:7*`BW] = V_T[q][0]; end
		endcase
		@(negedge clk);
		addr_ext = addr_ext + 4'd1;
	end
	mem_cmd_ext = `EXT_CMD_NO_OP;
	addr_ext = 0;
	@(negedge clk);
  endtask

  task WaitCoreDone;
	repeat(300) @(negedge clk);
  endtask

  // Compute all golden: estimated2_t1=Q*K^T, estimated1=norm, estimated2=V_T*estimated1
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

  task PrintVerifyHeader(input string title, input string test_line, input string note1, input string note2);
	$display("################################################################## ");
	$display("               |  %s", title);
	$display("     %s", test_line);
	$display("------------------------------------------------------------------ ");
	if (note1 != "") $display("               |  %s", note1);
	if (note2 != "") $display("     Notes     |  %s", note2);
	if (note1 != "" || note2 != "") $display("------------------------------------------------------------------ ");
	$display("  PMEM content :  					");
	$display("  [row]  RTL   :  col0  col1  col2  col3  col4  col5  col6  col7");
	$display("         golden:  ----  ----  ----  ----  ----  ----  ----  ----");
  endtask

  // stage: 0=estimated1, 1=estimated2
  task VerifyPMEM(input int stage);
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
		if (stage == 1)
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				estimated1[row*`COL + 0], estimated1[row*`COL + 1], estimated1[row*`COL + 2], estimated1[row*`COL + 3],
				estimated1[row*`COL + 4], estimated1[row*`COL + 5], estimated1[row*`COL + 6], estimated1[row*`COL + 7]);
		else if (stage == 0)
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				estimated2_t1[row][0], estimated2_t1[row][1], estimated2_t1[row][2], estimated2_t1[row][3],
				estimated2_t1[row][4], estimated2_t1[row][5], estimated2_t1[row][6], estimated2_t1[row][7]);
		else
			$display("         golden: %5d %5d %5d %5d %5d %5d %5d %5d",
				estimated2[row][0], estimated2[row][1], estimated2[row][2], estimated2[row][3],
				estimated2[row][4], estimated2[row][5], estimated2[row][6], estimated2[row][7]);
		row_err = 0;
		for (c = 0; c < `COL; c++) begin
			if (stage == 1) begin
				if ($signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]) !== estimated1[row*`COL + golden_col[c]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]), estimated1[row*`COL + golden_col[c]]);
					err++; row_err++;
				end
			end else if (stage == 0) begin
				if ($signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]) !== estimated2_t1[row][golden_col[c]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]), estimated2_t1[row][golden_col[c]]);
					err++; row_err++;
				end
			end else begin
				if ($signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]) !== estimated2[row][golden_col[c]]) begin
					$display("       >>> col%0d MISMATCH (RTL %d != golden %d)", c, $signed(pmem_out[c*`BW_PSUM +: `BW_PSUM]), estimated2[row][golden_col[c]]);
					err++; row_err++;
				end
			end
		end
		$display("       %s", (row_err == 0) ? "[OK]" : "[MISMATCH]");
		addr_ext = addr_ext + 1;
		@(negedge clk);
	end
	mem_cmd_ext = `EXT_CMD_NO_OP;
	$display("------------------------------------------------------------");
	if (err == 0)
		$display("  PASS  %0d rows x %0d cols  all match estimated result", `TOTAL_CYCLE, `COL);
	else
		$display("  FAIL  %0d mismatches", err);
	$display("------------------------------------------------------------");
	$display("");
  endtask