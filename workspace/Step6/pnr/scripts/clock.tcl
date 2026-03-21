# Clock tree synthesis 
set_ccopt_property -update_io_latency false

set desdir "/home/linux/ieng6/ECE260B_WI26_A00/miw090/ECE260B-Final-Project/workspace/Step6/pnr"
create_ccopt_clock_tree_spec -file $desdir/constraints/$design.ccopt
ccopt_design

# Use actual clock network
set_propagated_clock [all_clocks]

# Post-CTS timing optimization
optDesign -postCTS -hold
saveDesign cts.enc
