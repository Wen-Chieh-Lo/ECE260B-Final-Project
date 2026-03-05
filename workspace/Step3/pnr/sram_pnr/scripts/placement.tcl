# Placement
#setMaxRouteLayer 4 
saveDesign floorplan.enc

setPlaceMode -timingDriven true -reorderScan false -congEffort high -modulePlan false
setOptMode -effort high -powerEffort high -leakageToDynamicRatio 0.5 -fixFanoutLoad true -restruct true -verbose true
place_opt_design

saveDesign placement.enc

