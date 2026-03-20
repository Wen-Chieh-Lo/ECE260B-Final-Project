#set clock_cycle 1.0
#set io_delay 0.2 

#set clock_port clk0

#create_clock -name clk -period $clock_cycle [get_ports $clock_port]

#set_input_delay  $io_delay -clock $clock_port [all_#inputs] 
#set_output_delay $io_delay -clock $clock_port [all_outputs]

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


