# ── INPUT PINS → WEST ──
setPinAssignMode -pinEditInBatch true
editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 5 -spreadType center -spacing 5 -pin {clk0 clk1 reset0 reset1 start0 start1 set_mode0 set_mode1 mode_in0[*] mode_in1[*] mem_in0[*] mem_in1[*] inst_ext0[*] inst_ext1[*]} -fixedPin true
setPinAssignMode -pinEditInBatch false

# ── OUTPUT PINS → SOUTH ──
setPinAssignMode -pinEditInBatch true
editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Bottom -layer 4 -spreadType center -spacing 4 -pin {out0[*] out1[*] status0[*] status1[*]} -fixedPin true
setPinAssignMode -pinEditInBatch false

checkPinAssignment
legalizePin

saveDesign floorplan.enc
