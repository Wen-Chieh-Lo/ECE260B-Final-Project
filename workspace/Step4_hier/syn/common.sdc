# =============================================================================
# fullchip.sdc  --  Two-clock async SDC for fullchip dual-core synthesis
#
# Clock topology (matches fullchip_tb.v):
#   clk0 : Core-0 domain  period = 1.0 ns  (H_CYCLE0 = 0.5)
#   clk1 : Core-1 domain  period = 1.2 ns  (H_CYCLE1 = 0.6)
#   The two domains communicate via async FIFO (CDC).
#   => set_clock_groups -asynchronous : no cross-domain path is timed.
#
# Actual port list (from fullchip.v module declaration):
#   clk0 domain inputs : reset0  mem_in0  inst0
#   clk0 domain outputs: out0    fifo1_empty   (fifo_inst_ext_core1_0: rd_clk=clk0)
#
#   clk1 domain inputs : reset1  mem_in1  inst1
#   clk1 domain outputs: out1    fifo0_empty   (fifo_inst_ext_core0_1: rd_clk=clk1)
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
set_input_delay  -clock clk0 -max $io_delay [get_ports {reset0 mem_in0 inst0}]
set_output_delay -clock clk0 -max $io_delay [get_ports {out0 fifo1_empty}]

# ---- I/O delays: clk1 domain ----
set_input_delay  -clock clk1 -max $io_delay [get_ports {reset1 mem_in1 inst1}]
set_output_delay -clock clk1 -max $io_delay [get_ports {out1 fifo0_empty}]
