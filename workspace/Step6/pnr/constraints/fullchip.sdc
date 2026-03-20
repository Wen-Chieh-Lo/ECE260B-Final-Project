# =============================================================================
# fullchip.sdc (PNR) — clocks / I/O MUST match Alpha/syn/fullchip.sdc.
# Innovus: PNR-only multicycle appended below.
# Use with loadDesignTech.tcl: set design "fullchip" (netlist top = fullchip).
# =============================================================================

set clk0_period 1.0
set clk1_period 1.2
set io_delay    0.2

# ---- Clocks ----
create_clock -name clk0 -period $clk0_period [get_ports clk0]
create_clock -name clk1 -period $clk1_period [get_ports clk1]

# ---- Asynchronous clock groups (no cross-domain timing paths) ----
set_clock_groups -asynchronous -group [get_clocks clk0] -group [get_clocks clk1]

# ---- I/O delays: clk0 domain ----
set_input_delay  -clock clk0 -max $io_delay [get_ports {reset0 start0 set_mode0 mode_in0 mem_in0 inst_ext0}]
set_output_delay -clock clk0 -max $io_delay [get_ports {out0 status0}]

# ---- I/O delays: clk1 domain ----
set_input_delay  -clock clk1 -max $io_delay [get_ports {reset1 start1 set_mode1 mode_in1 mem_in1 inst_ext1}]
set_output_delay -clock clk1 -max $io_delay [get_ports {out1 status1}]

# ---- PNR only: multicycle through SFP row divider (names depend on hierarchy) ----
set MCP_FROM [get_cells -hierarchical * -filter {is_sequential == true && (full_name =~ *sum_this_core_r_reg* || full_name =~ *sum_in_r_reg* || full_name =~ *abs_div_reg*)}]
set MCP_TO [get_cells -hierarchical * -filter {is_sequential == true && full_name =~ *div_out_q_reg*}]
set_multicycle_path 10 -setup -from $MCP_FROM -to $MCP_TO
set_multicycle_path 9  -hold  -from $MCP_FROM -to $MCP_TO
