############################################
# Pin Placement Script - Single Core
# Inputs  : West (Left)
# Outputs : South (Bottom)
############################################

# ---------- INPUT PINS (WEST) ----------
setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 4 -pin {clk reset inst[*] mem_in[*]}  -fixedPin true

setPinAssignMode -pinEditInBatch false


# ---------- OUTPUT PINS (SOUTH) ----------
setPinAssignMode -pinEditInBatch true

editPin -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Bottom -layer 4 -spreadType center -spacing 2 -pin {out[*]}  -fixedPin true

setPinAssignMode -pinEditInBatch false

checkPinAssignment
