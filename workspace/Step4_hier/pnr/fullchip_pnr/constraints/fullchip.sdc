set clock_cycle 1.0
set io_delay 0.2 

#set clock_port clk0

#create_clock -name clk -period $clock_cycle [get_ports $clock_port]

#set_input_delay  $io_delay -clock $clock_port [all_inputs] 
#set_output_delay $io_delay -clock $clock_port [all_outputs]

set clock_port clk0
create_clock -name clk0 -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk0] -add_delay -max $io_delay [get_ports {*}]
set_output_delay -clock [get_clocks clk0] -add_delay -max $io_delay [get_ports {*}]

set clock_port clk1
create_clock -name clk1 -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk1] -add_delay -max $io_delay [get_ports {*}]
set_output_delay -clock [get_clocks clk1] -add_delay -max $io_delay [get_ports {*}]

set_false_path -from [get_clocks clk0] -to [get_clocks clk1]
set_false_path -from [get_clocks clk1] -to [get_clocks clk0]

set_false_path -from [get_ports "reset"] 

set_clock_uncertainty 0.05 [get_clocks clk0] 
set_clock_uncertainty 0.05 [get_clocks clk1] 
