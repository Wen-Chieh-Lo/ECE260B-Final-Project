############################################
# SRAM Placement (Step 3)
############################################

# Limit routing to M4 as required
setMaxRouteLayer 4

# Save floorplan
saveDesign floorplan.enc

# Placement settings
setPlaceMode -timingDriven false -reorderScan false -congEffort medium -modulePlan false

# Optimization mode
setOptMode -effort high -powerEffort high -leakageToDynamicRatio 0.5 -fixFanoutLoad true -restruct true -verbose true

# Run placement
place_opt_design

# Save placement database
saveDesign placement.enc