############################################
# SRAM Pin Placement (Step 3 - Hierarchical)
############################################

# Allow batch pin editing
setPinAssignMode -pinEditInBatch true 

############################################
# D input bus -> Bottom edge (M4)
############################################
editPin -fixOverlap 1 -unit MICRON -side Bottom -layer 4 -spreadType center -spreadDirection clockwise -spacing 4 -pin {D[*]} -fixedPin true

############################################
# Q output bus -> Top edge (M4)
############################################
editPin -fixOverlap 1 -unit MICRON -side Top -layer 4 -spreadType center -spreadDirection counterclockwise -spacing 4 -pin {Q[*]} -fixedPin true

############################################
# Control / address pins -> Left edge
############################################
editPin -fixOverlap 1 -unit MICRON -side Left -layer 3 -spreadType center -spreadDirection clockwise -spacing 4 -pin {CLK WEN CEN A[*]} -fixedPin true

# End batch mode
setPinAssignMode -pinEditInBatch false