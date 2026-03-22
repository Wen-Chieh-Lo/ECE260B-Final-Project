############################################
# Placement — Step 5 Flat Design
############################################

# Placement
saveDesign floorplan.enc
setPlaceMode -timingDriven true -reorderScan false -congEffort medium -modulePlan false
setOptMode -effort high -powerEffort high -leakageToDynamicRatio 0.5 -fixFanoutLoad true -restruct true -verbose true
place_opt_design

#addFiller -cell {FILL1 FILL2 FILL4 FILL8 FILL16 FILL32 DCAP DCAP4 DCAP8 DCAP16 DCAP32} -merge true

# ── Verify placement ──
checkPlace

saveDesign placement.enc