############################################
# Routing - Timing & SI Driven
############################################

# NanoRoute Settings
setNanoRouteMode -quiet -drouteAllowMergedWireAtPin false
setNanoRouteMode -quiet -drouteFixAntenna true
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeWithSiDriven true
setNanoRouteMode -quiet -routeSiEffort high
setNanoRouteMode -quiet -routeWithSiPostRouteFix true
setNanoRouteMode -quiet -drouteAutoStop false
setNanoRouteMode -quiet -routeSelectedNetOnly false
setNanoRouteMode -quiet -drouteStartIteration default

# Run Routing
routeDesign -globalDetail

# RC extraction
setExtractRCMode -engine postRoute
extractRC

# Accurate timing mode
setAnalysisMode -analysisType onChipVariation -cppr both

# Setup and Hold Optimization
optDesign -postRoute -setup
optDesign -postRoute -hold

# Early DRC repair
optDesign -postRoute -drv

# Final incremental cleanup
optDesign -postRoute -inc

saveDesign route.enc
