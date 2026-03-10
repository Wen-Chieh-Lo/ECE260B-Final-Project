set clock_cycle 1.2
set io_delay 0.2

create_clock -name clk0 -period $clock_cycle [get_ports clk0]
create_clock -name clk1 -period $clock_cycle [get_ports clk1]

set_input_delay  $io_delay -clock clk0 [all_inputs]
set_output_delay $io_delay -clock clk0 [all_outputs]
