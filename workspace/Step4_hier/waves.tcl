# Clocks & Reset
probe -create fullchip_sepclk_tb.clk0
probe -create fullchip_sepclk_tb.clk1
probe -create fullchip_sepclk_tb.reset

# Instructions
probe -create fullchip_sepclk_tb.inst0
probe -create fullchip_sepclk_tb.inst1

# Memory inputs
probe -create fullchip_sepclk_tb.mem_in_core0
probe -create fullchip_sepclk_tb.mem_in_core1

# Outputs
probe -create fullchip_sepclk_tb.out
probe -create fullchip_sepclk_tb.fifo0_empty
probe -create fullchip_sepclk_tb.fifo1_empty

# Key control signals - Core0
probe -create fullchip_sepclk_tb.execute_c0
probe -create fullchip_sepclk_tb.load_c0
probe -create fullchip_sepclk_tb.ofifo_rd_c0
probe -create fullchip_sepclk_tb.acc_c0
probe -create fullchip_sepclk_tb.div_c0
probe -create fullchip_sepclk_tb.VN_mode_c0

# Key control signals - Core1
probe -create fullchip_sepclk_tb.execute_c1
probe -create fullchip_sepclk_tb.load_c1
probe -create fullchip_sepclk_tb.ofifo_rd_c1
probe -create fullchip_sepclk_tb.acc_c1
probe -create fullchip_sepclk_tb.div_c1
probe -create fullchip_sepclk_tb.VN_mode_c1

run