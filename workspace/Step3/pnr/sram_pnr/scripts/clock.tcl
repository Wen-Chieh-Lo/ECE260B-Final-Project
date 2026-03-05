############################################
# Clock Tree Synthesis
############################################

# Improve skew/transition targets for 1GHz
set_ccopt_property -update_io_latency false
set_ccopt_property target_skew 0.1

# Create CTS spec
create_ccopt_clock_tree_spec -file $desdir/constraints/$design.ccopt

# Run CTS
ccopt_design

# Switch to propagated clocks
set_propagated_clock [all_clocks]

# Post-CTS timing optimization
optDesign -postCTS -hold
saveDesign cts.enc