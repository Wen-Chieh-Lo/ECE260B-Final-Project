# Shared SDC: clock and I/O constraints (same delay for all; used for any top)

set clock_cycle 1.0
set io_delay    0.2

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay  -clock [get_clocks clk] -max $io_delay [all_inputs]
set_output_delay -clock [get_clocks clk] -max $io_delay [all_outputs]
