getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true
editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 20 -pin {clk0 reset0 start0 set_mode0 mode_in0[*]} -fixedPin true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Right -layer 3 -spreadType center -spacing 20 -pin {clk1 reset1 start1 set_mode1 mode_in1[*]} -fixedPin true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Bottom -layer 4 -spreadType center -spacing 3 -pin {mem_in0[*] inst_ext0[*] inst_ext1[*] mem_in1[*]} -fixedPin true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 4 -spreadType center -spacing 2 -pin {out0[*] out1[*] status0[*] status1[*]} -fixedPin true
setPinAssignMode -pinEditInBatch false
