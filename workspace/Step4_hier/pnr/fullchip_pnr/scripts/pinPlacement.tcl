############################################
# Pin Placement Script - Single Core
# Inputs  : West (Left)
# Outputs : South (Bottom)
############################################

# ---------- INPUT PINS (WEST) ----------
setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 5 -spreadType center -spacing 6 -pin {clk0 clk1 reset} -fixedPin true

setPinAssignMode -pinEditInBatch false

setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Bottom -layer 4 -spreadType center -spacing 6 -pin {mem_in[*] inst[*]} -fixedPin true

setPinAssignMode -pinEditInBatch false

# ---------- OUTPUT PINS (SOUTH) ----------
setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 6 -spreadType center -spacing 4 -pin {out[*] fifo0_empty fifo1_empty} -fixedPin true

setPinAssignMode -pinEditInBatch false

checkPinAssignment
