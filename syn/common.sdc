# Shared SDC: clock and I/O constraints (same delay for all; used for any top)

set clock_cycle 1.2
set io_delay    0.2

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set in_ports  [remove_from_collection [all_inputs] [get_ports $clock_port]]
set_input_delay  -clock [get_clocks clk] -max $io_delay $in_ports

set out_ports [all_outputs]
set_output_delay -clock [get_clocks clk] -max $io_delay $out_ports
