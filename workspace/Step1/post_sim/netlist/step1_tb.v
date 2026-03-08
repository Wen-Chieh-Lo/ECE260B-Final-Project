`timescale 1ns/1ps

module step1_tb;

  parameter total_cycle = 8;
  parameter bw          = 8;
  parameter bw_psum     = 2*bw+3;   // = 19
  parameter pr          = 8;
  parameter col         = 8;

  integer qkvn_file, qkvn_scan_file, captured_data;
  integer K [col-1:0][pr-1:0];
  integer Q [total_cycle-1:0][pr-1:0];
  integer result [total_cycle-1:0][col-1:0];
  integer q, j, k, t, c;
  integer err, row_err, row;

  reg reset = 1;
  reg clk   = 0;
  reg [pr*bw-1:0] mem_in;
  wire [19:0] inst;

  reg qmem_rd = 0, qmem_wr = 0;
  reg kmem_rd = 0, kmem_wr = 0;
  reg pmem_rd = 0, pmem_wr = 0;
  reg execute = 0, load = 0;
  reg [3:0] qkmem_add = 0;
  reg [3:0] pmem_add  = 0;

  wire [bw_psum*col-1:0] pmem_out;
  integer golden_col [0:7];

  // ── Instruction mapping ──
  // inst[16] -> ofifo.rd  (confirmed from netlist: ofifo_inst .rd(inst[16]))
  // inst[15:12] -> SRAM address (qkmem_add)
  // inst[7]  -> execute
  // inst[6]  -> load
  // inst[5]  -> qmem_rd
  // inst[4]  -> qmem_wr
  // inst[3]  -> kmem_rd
  // inst[2]  -> kmem_wr
  // inst[1:0], inst[11:8] -> unused by core
  assign inst[19] = 1'b0;
  assign inst[18] = 1'b0;
  assign inst[17] = 1'b0;
  assign inst[16] = pmem_rd;      // ofifo read enable
  assign inst[15:12] = qkmem_add;
  assign inst[11:8]  = pmem_add;
  assign inst[7]  = execute;
  assign inst[6]  = load;
  assign inst[5]  = qmem_rd;
  assign inst[4]  = qmem_wr;
  assign inst[3]  = kmem_rd;
  assign inst[2]  = kmem_wr;
  assign inst[1]  = pmem_rd;
  assign inst[0]  = pmem_wr;

  // ── DUT instantiation ──
  core step1_instance (
    .reset(reset),
    .clk(clk),
    .mem_in(mem_in),
    .inst(inst[18:0]),
    .out(pmem_out)
  );

  initial begin
    $dumpfile("../sim/waveform/step1.vcd");
    $dumpvars(0, step1_tb);

    // ── Read Q data ──
    $display("##### Q data txt reading #####");
    qkvn_file = $fopen("../sim/pattern/qdata.txt", "r");
    for (q = 0; q < total_cycle; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        Q[q][j] = captured_data;
      end
    $fclose(qkvn_file);

    // ── Reset pulse ──
    for (q = 0; q < 2;  q = q+1) begin #0.5 clk=0; #0.5 clk=1; end
    for (q = 0; q < 10; q = q+1) begin #0.5 clk=0; #0.5 clk=1; end
    reset = 0;

    // ── Read K data ──
    $display("##### K data txt reading #####");
    qkvn_file = $fopen("../sim/pattern/kdata.txt", "r");
    for (q = 0; q < col; q = q+1)
      for (j = 0; j < pr; j = j+1) begin
        qkvn_scan_file = $fscanf(qkvn_file, "%d\n", captured_data);
        K[q][j] = captured_data;
      end
    $fclose(qkvn_file);

    // ── Compute golden results ──
    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1)
        result[t][q] = 0;

    for (t = 0; t < total_cycle; t = t+1)
      for (q = 0; q < col; q = q+1)
        for (k = 0; k < pr; k = k+1)
          result[t][q] = result[t][q] + Q[t][k] * K[q][k];

    // ── Stage 1: Write Q to qmem ──
    $display("##### Qmem writing #####");
    qkmem_add = 0;
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk=0;
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
      #0.5 clk=1;
    end
    #0.5 clk=0; qmem_wr=0; qkmem_add=0; #0.5 clk=1;

    // ── Stage 2: Write K to kmem ──
    $display("##### Kmem writing #####");
    for (q = 0; q < col; q = q+1) begin
      #0.5 clk=0;
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
      #0.5 clk=1;
    end
    #0.5 clk=0; kmem_wr=0; qkmem_add=0; #0.5 clk=1;

    for (q = 0; q < 2; q = q+1) begin #0.5 clk=0; #0.5 clk=1; end

    // ── Stage 3: Load K into MAC columns ──
    $display("##### K loading to MAC #####");
    for (q = 0; q < col+1; q = q+1) begin
      #0.5 clk=0;
      load = 1;
      if (q == 1) kmem_rd = 1;
      if (q >  1) qkmem_add = qkmem_add + 1;
      #0.5 clk=1;
    end
    #0.5 clk=0; kmem_rd=0; qkmem_add=0; #0.5 clk=1;
    #0.5 clk=0; load=0;                 #0.5 clk=1;

    for (q = 0; q < 10; q = q+1) begin #0.5 clk=0; #0.5 clk=1; end

    // ── Stage 4: Execute QK MAC ──
    $display("##### Execute #####");
    for (q = 0; q < total_cycle; q = q+1) begin
      #0.5 clk=0;
      execute  = 1;
      qmem_rd  = 1;
      if (q > 0) qkmem_add = qkmem_add + 1;
      #0.5 clk=1;
    end
    #0.5 clk=0; qmem_rd=0; qkmem_add=0; execute=0; #0.5 clk=1;

    // ── Wait for pipeline to flush ──
    // The flush loop ends on a POSEDGE. We must NOT assert pmem_rd=1 in the
    // same time-step as that posedge, because the gate-level ofifo will
    // evaluate rd=1 on that posedge and consume result[0] one cycle early,
    // causing an off-by-one (every row reads the NEXT row's result).
    //
    // FIX: after the flush loop, step to NEGEDGE first, THEN assert pmem_rd.
    // This guarantees pmem_rd=1 is only seen by the NEXT posedge (inside the loop).
    for (q = 0; q < 30; q = q+1) begin #0.5 clk=0; #0.5 clk=1; end
    #0.5 clk=0;          // ← step to negedge; flush posedge is now safely in the past
    pmem_rd = 1;         // ← assert ofifo rd=1 here (at negedge, no pop yet)

    // ── Stage 5: Read and verify ofifo output ──
    // ofifo is show-ahead: "out" combinatorially reflects FIFO[rd_ptr].
    // A posedge with rd=1 increments rd_ptr, advancing to the next result.
    //
    // Sequence for each row:
    //   negedge  → $display captures current FIFO head (result[q])
    //   posedge  → rd_ptr++ advances FIFO to next entry
    $display("QK phase verification");
    $display("  [row]  RTL   : col0 col1 col2 col3 col4 col5 col6 col7");

    err = 0;
    for (c = 0; c < col; c = c+1)
      golden_col[c] = 7 - c;

    for (q = 0; q < total_cycle; q = q+1) begin
      // Already at negedge from the line above (q=0), or from previous posedge+negedge (q>0)
      row = q;
      $display("[%0d] RTL: %7d %7d %7d %7d %7d %7d %7d %7d", row,
        $signed(pmem_out[7*bw_psum+:bw_psum]),
        $signed(pmem_out[6*bw_psum+:bw_psum]),
        $signed(pmem_out[5*bw_psum+:bw_psum]),
        $signed(pmem_out[4*bw_psum+:bw_psum]),
        $signed(pmem_out[3*bw_psum+:bw_psum]),
        $signed(pmem_out[2*bw_psum+:bw_psum]),
        $signed(pmem_out[1*bw_psum+:bw_psum]),
        $signed(pmem_out[0*bw_psum+:bw_psum]));
      $display("     golden: %7d %7d %7d %7d %7d %7d %7d %7d",
        result[row][0], result[row][1], result[row][2], result[row][3],
        result[row][4], result[row][5], result[row][6], result[row][7]);

      row_err = 0;
      for (c = 0; c < col; c = c+1) begin
        if ($signed(pmem_out[c*bw_psum+:bw_psum]) !== result[row][golden_col[c]]) begin
          $display("  col%0d MISMATCH: RTL=%0d golden=%0d",
            c, $signed(pmem_out[c*bw_psum+:bw_psum]), result[row][golden_col[c]]);
          err = err+1; row_err = row_err+1;
        end
      end
      $display("  %s\n", (row_err==0) ? "[OK]" : "[MISMATCH]");

      // Posedge with rd=1 → FIFO advances to result[q+1]
      #0.5 clk=1;
      // Step to negedge for next iteration's display
      if (q < total_cycle-1) #0.5 clk=0;
    end

    // De-assert rd and finish
    #0.5 clk=0; pmem_rd=0; #0.5 clk=1;

    $display("--------------------------------------------");
    if (err == 0)
      $display("PASS: all %0d x %0d results correct", total_cycle, col);
    else
      $display("FAIL: %0d mismatches", err);
    $display("--------------------------------------------");

    #10 $finish;
  end

endmodule