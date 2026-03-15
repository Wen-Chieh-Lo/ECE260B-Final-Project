############################################
# Pin Placement Script - Single Core
# Inputs  : West (Left)
# Outputs : South (Bottom)
############################################

# ---------- INPUT PINS (WEST) ----------
setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 4 -pin {clk reset ext_fifo_wr ext_fifo_rd} -fixedPin true

setPinAssignMode -pinEditInBatch false

setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Bottom -layer 4 -spreadType center -spacing 4 -pin {mem_in[*] sum_in[*]} -fixedPin true
editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Right -layer 3 -spreadType center -spacing 4 -pin {ext_fifo_in[*] inst[*]} -fixedPin true

setPinAssignMode -pinEditInBatch false

# ---------- OUTPUT PINS (SOUTH) ----------
setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 4 -spreadType center -spacing 4 -pin {out[*]} -fixedPin true

setPinAssignMode -pinEditInBatch false

checkPinAssignment
