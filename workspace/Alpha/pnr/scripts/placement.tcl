############################################
# Placement — Step 5 Flat Design
############################################

# ── Place standard cells ──
setPlaceMode -timingDriven  true -reorderScan   false -congEffort    medium -modulePlan    false -placeIOPins   false 

setOptMode -effort high -powerEffort high -leakageToDynamicRatio  0.5 -fixFanoutLoad true -restruct true -verbose true

place_opt_design

# ── Verify placement ──
checkPlace

saveDesign placement.enc