# Shared SDC: clock and I/O constraints (same delay for all; used for any top)

set clock_cycle 1.0
set io_delay    0.2

# Support both clk and CLK (e.g. core uses clk, sram_* uses CLK)
set clock_ports [get_ports -quiet clk]
if { [sizeof_collection $clock_ports] == 0 } {
  set clock_ports [get_ports -quiet CLK]
}
create_clock -name clk -period $clock_cycle $clock_ports

set_input_delay  -clock [get_clocks clk] -max $io_delay [all_inputs]
set_output_delay -clock [get_clocks clk] -max $io_delay [all_outputs]
