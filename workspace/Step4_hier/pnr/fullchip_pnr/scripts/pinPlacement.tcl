############################################
# Pin Placement Script - Single Core
# Inputs  : West (Left)
# Outputs : South (Bottom)
############################################


setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 6 -pin {clk0 reset0} -fixedPin true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Right -layer 3 -spreadType center -spacing 6 -pin {clk1 reset1} -fixedPin true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Bottom -layer 4 -spreadType center -spacing 8 -pin {mem_in0[*] inst0[*] inst1[*] mem_in1[*]} -fixedPin true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 4 -spreadType center -spacing 6 -pin {out0[*] out1[*] fifo0_empty fifo1_empty} -fixedPin true

setPinAssignMode -pinEditInBatch false

checkPinAssignment
