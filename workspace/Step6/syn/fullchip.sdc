# =============================================================================
# fullchip.sdc  --  Two-clock async SDC for fullchip dual-core synthesis
#
# Clock topology (matches fullchip_tb.v):
#   clk0 : Core-0 domain  period = 1.0 ns  (H_CYCLE0 = 0.5)
#   clk1 : Core-1 domain  period = 1.2 ns  (H_CYCLE1 = 0.6)
#   The two domains communicate via async FIFO (CDC).
#   => set_clock_groups -asynchronous : no cross-domain path is timed.
#
# I/O port mapping:
#   clk0 domain: reset0 start0 set_mode0 mode_in0 mem_in0 inst_ext0 | out0 status0
#   clk1 domain: reset1 start1 set_mode1 mode_in1 mem_in1 inst_ext1 | out1 status1
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
