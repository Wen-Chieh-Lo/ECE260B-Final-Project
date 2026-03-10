# Clock tree synthesis 
set_ccopt_property -update_io_latency false
if {[info exists constraint_dir]} {
  create_ccopt_clock_tree_spec -file $constraint_dir/$design.ccopt
} else {
  create_ccopt_clock_tree_spec -file $desdir/constraints/$design.ccopt
}
ccopt_design

# Use actual clock network
set_propagated_clock [all_clocks]

# Post-CTS timing optimization
optDesign -postCTS -hold
saveDesign cts.enc
