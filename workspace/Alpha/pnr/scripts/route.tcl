# ── NanoRoute settings (without invalid options) ──
setNanoRouteMode -quiet -drouteAllowMergedWireAtPin  false
setNanoRouteMode -quiet -drouteFixAntenna            true
setNanoRouteMode -quiet -routeWithTimingDriven       true
setNanoRouteMode -quiet -routeWithSiDriven           true
setNanoRouteMode -quiet -routeSiEffort               high
setNanoRouteMode -quiet -routeWithSiPostRouteFix     true
setNanoRouteMode -quiet -drouteAutoStop              false
setNanoRouteMode -quiet -routeSelectedNetOnly        false

routeDesign -globalDetail

ecoRoute -fix_drc

setExtractRCMode -engine postRoute
extractRC
set_interactive_constraint_modes [all_constraint_modes]

set_clock_groups -asynchronous -group [get_clocks clk0] -group [get_clocks clk1]

setAnalysisMode -analysisType onChipVariation -cppr both
optDesign -postRoute -setup
optDesign -postRoute -hold
optDesign -postRoute -drv
optDesign -postRoute -inc

verifyGeometry    -error 100000 -report ./drc_route.rpt
verifyConnectivity -type all -error 100000 -report ./connectivity_route.rpt

report_timing -nworst 10 > ./timing_route.rpt
report_power             > ./power_route.rpt
report_area              > ./area_route.rpt

saveDesign route.enc