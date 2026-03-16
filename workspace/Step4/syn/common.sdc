# Shared SDC: clock and I/O constraints (same delay for all; used for any top)

set clock_cycle_0 1.0
set clock_cycle_1 0.75 
#set clock_cycle_1 0.68 for 10% higher margin, safety

set io_delay    0.2

#set clock_port clk

create_clock -name clk0 -period $clock_cycle_0 [get_ports clk0]
create_clock -name clk1 -period $clock_cycle_1 [get_ports clk1]

set_false_path -from [get_clocks clk0] -to [get_clocks clk1]
set_false_path -from [get_clocks clk1] -to [get_clocks clk0]

set_input_delay  -clock [get_clocks clk0] -max $io_delay [get_ports {mem_in inst reset}]
set_output_delay -clock [get_clocks clk0] -max $io_delay [get_ports {out fifo0_empty fifo1_empty}]
