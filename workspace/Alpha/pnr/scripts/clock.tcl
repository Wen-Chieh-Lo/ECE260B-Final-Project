############################################
# Clock Tree Synthesis — Step 5
# clk0: 1.0 ns / clk1: 1.2 ns (async)
############################################

# ── CTS global properties ──
set_ccopt_property -update_io_latency false
set_ccopt_property target_skew        0.05
set_ccopt_property target_max_trans   0.10

# ── Create CTS spec ──
create_ccopt_clock_tree_spec -file $desdir/constraints/$design.ccopt

# ── Run CTS ──
ccopt_design

# ── Use actual clock network ──
set_propagated_clock [all_clocks]

# ── Re-apply async clock groups after CTS ──
set_clock_groups -asynchronous -group [get_clocks clk0] -group [get_clocks clk1]

# ── Post-CTS optimization ──
setAnalysisMode -analysisType onChipVariation -cppr both

optDesign -postCTS
optDesign -postCTS -hold

saveDesign cts.enc