############################################
# initialFloorplan.tcl — Step 5 FLAT Design
############################################

# ── Floorplan (adjust size based on area report) ──
floorPlan -site core -s 3000 3000 20.0 20.0 20.0 20.0

# ── Global power connections ──
globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

# ── Core power ring ──
addRing -spacing {top 2 bottom 2 left 2 right 2} -width   {top 4 bottom 4 left 4 right 4} -layer   {top M5 bottom M5 left M4 right M4} -center 1 -type core_rings -nets {VSS VDD}

# ── Power stripes ──
setAddStripeMode -break_at {block_ring}

addStripe -nets {VDD VSS} -layer M5 -direction horizontal -width 1 -spacing 4 -number_of_sets 25 -start_offset 5 -stop_offset  5 -stacked_via_top_layer    M8 -stacked_via_bottom_layer M1

fit
sroute
verifyConnectivity

