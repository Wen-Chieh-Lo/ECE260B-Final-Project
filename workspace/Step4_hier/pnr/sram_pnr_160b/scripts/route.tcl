############################################
# Routing (SRAM Step-3)
############################################

# Limit routing layers (project requirement)
setNanoRouteMode -routeTopRoutingLayer 4
setNanoRouteMode -routeBottomRoutingLayer 1

# Basic NanoRoute configuration
setNanoRouteMode -quiet -drouteAllowMergedWireAtPin false
setNanoRouteMode -quiet -drouteFixAntenna true
setNanoRouteMode -quiet -routeWithTimingDriven false
setNanoRouteMode -quiet -routeWithSiDriven false
setNanoRouteMode -quiet -drouteAutoStop true

# Basic timing analysis
setAnalysisMode -analysisType onChipVariation -cppr both
# Run routing
routeDesign

# Fix any remaining DRC
optDesign -postRoute -drv

# RC extraction
setExtractRCMode -engine postRoute
extractRC

# Incremental cleanup
optDesign -postRoute -inc

# Save database
saveDesign route.enc