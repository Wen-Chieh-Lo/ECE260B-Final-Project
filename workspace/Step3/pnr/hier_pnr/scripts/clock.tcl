############################################
# Clock Tree Synthesis
############################################

# Improve skew/transition targets for 1GHz
set_ccopt_property -update_io_latency false
set_ccopt_property target_skew 0.05
set_ccopt_property target_max_trans 0.1

# Create CTS spec
set desdir "/home/linux/ieng6/ECE260B_WI26_A00/miw090/ECE260B-Final-Project/workspace/Step3/pnr/hier_pnr"
create_ccopt_clock_tree_spec -file $desdir/constraints/$design.ccopt

# Run CTS
ccopt_design

# Switch to propagated clocks
set_propagated_clock [all_clocks]

# Post-CTS timing optimization
optDesign -postCTS -hold

saveDesign cts.enc
