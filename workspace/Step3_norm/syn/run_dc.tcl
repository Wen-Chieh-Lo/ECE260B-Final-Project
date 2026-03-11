# =============================================================================
# Parameters: set by Makefile (make syn TARGET=mac) or dc_shell -x "set top_module ..."
# Defaults below used only when run standalone.
# =============================================================================
if { ![info exists top_module] }    { set top_module    mac }
if { ![info exists rtlPath] }       { set rtlPath       [file normalize [file join [pwd] ..]] }
if { ![info exists filelist_path] } { set filelist_path "syn/filelists/filelist_mac" }
if { ![info exists syn_effort] }    { set syn_effort    high }

set filelist_full [file join $rtlPath $filelist_path]

# Read RTL file list from filelist (exclude testbench)
set rtl_files {}
if { [file exists $filelist_full] } {
	set f [open $filelist_full r]
	while { [gets $f line] >= 0 } {
		set line [string trim $line]
		if { $line == "" || [string match "//*" $line] } { continue }
		if { [string match "*sim/tb*" $line] } { continue }
		if { [string match "./*" $line] } { set line [string range $line 2 end] }
		lappend rtl_files $line
	}
	close $f
} else {
	echo "ERROR: filelist not found: $filelist_full"
	exit 1
}

# Target library
set target_library /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gpluswc.db
set link_library $target_library
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true

set search_path [concat $rtlPath $rtlPath/verilog $rtlPath/verilog/memory $rtlPath/verilog/mac $search_path]
set link_library [concat * $link_library ]

set synthetic_library {}
set link_path [concat  $link_library $synthetic_library]
set dont_use_cells 1
set dont_use_cell_list ""

remove_design -all
if {![file exists work]} { exec mkdir work }
if {![file exists log]}  { exec mkdir log }
if {![file exists gate]} { exec mkdir gate }
set_svf work/default.svf

sh date
sh echo hostname
sh echo uptime

#Compiler directives
set_optimize_registers true
set_cost_priority -delay
set_max_area 0
set compile_effort   "high"
set compile_no_new_cells_at_top_level false
set hdlin_enable_vpp true
set hdlin_auto_save_templates false

define_design_lib WORK -path work/.template
set verilogout_single_bit false

# read RTL from filelist (no testbench)
# syn_defines: optional list of defines from Makefile (USER_DEFINES in USER_DEFINE_TASK_VARS)
if { [info exists syn_defines] && [llength $syn_defines] > 0 } {
	foreach vfile $rtl_files {
		analyze -format verilog -define $syn_defines -lib WORK $vfile
	}
} else {
	foreach vfile $rtl_files {
		analyze -format verilog -lib WORK $vfile
	}
}

elaborate $top_module -lib WORK -update
current_design $top_module

# Link Design
link

# Default SDC Constraints
read_sdc common.sdc
propagate_constraints

current_design $top_module

set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
set_fix_hold [all_clocks]

set_driving_cell -lib_cell BUFFD8 -pin Z [all_inputs]
#set_load [get_attribute "$target_library/BUFFD8/A" fanout_load] [all_outputs]
foreach_in_collection p [all_outputs] {
	set_load 0.050 $p
}

#More compiler directives
set compile_effort   "high"
set_app_var ungroup_keep_original_design true
set_register_merging [get_designs $top_module] false
set compile_seqmap_propagate_constants false
set compile_seqmap_propagate_high_effort false
# More constraints and setup before compile
foreach_in_collection design [ get_designs "*" ] {
	current_design $design
	#feedthrough / outputs / constants
	set_fix_multiple_port_nets -all
}
current_design $top_module


# Compile
# -gate_clock: map clock network GTECH to target library
echo "========================================================"
echo " Synthesis effort: $syn_effort"
echo "========================================================"

if { $syn_effort == "low" } {
    compile -map_effort low 
} elseif { $syn_effort == "medium" } {
    compile -map_effort medium
} else {
    compile_ultra -retime -gate_clock -exact_map
}

# Write Out Design - Hierarchical
current_design $top_module

change_names -rules verilog -hierarchy

write -format verilog -hier -output [format "gate/%s.out.v" $top_module]

# Write Reports
redirect [format "%s%s%s" log/ $top_module _area.rep] { report_area }
redirect -append [format "%s%s%s" log/ $top_module _area.rep] { report_reference }
redirect [format "%s%s%s" log/ $top_module _power.rep] { report_power }
redirect [format "%s%s%s" log/ $top_module _timing.rep] \
  { report_timing -path full -max_paths 100 -nets -transition_time -capacitance -significant_digits 3 -nosplit}

set inFile  [open log/$top_module\_area.rep]
while { [gets $inFile line]>=0 } {
    if { [regexp {Total cell area:} $line] } {
        set AREA [lindex $line 3]
    }
}
close $inFile
set inFile  [open log/$top_module\_power.rep]
while { [gets $inFile line]>=0 } {
    if { [regexp {Total Dynamic Power} $line] } {
        set PWR [lindex $line 4]
    } elseif { [regexp {Cell Leakage Power} $line] } {  
        set LEAK [lindex $line 4] 
    }
}
close $inFile

set unmapped_designs [get_designs -filter "is_unmapped == true" $top_module]
if {  [sizeof_collection $unmapped_designs] != 0 } {
	echo "****************************************************"
	echo "* ERROR!!!! Compile finished with unmapped logic.  *"
	echo "****************************************************"
}
# Done
sh date
sh uptime

# Move DC runtime artifacts to work/ to keep syn/ clean
foreach f {command.log filenames.log} {
    if { [file exists $f] } { file rename -force $f work/$f }
}
foreach d [glob -nocomplain alib-*] {
    if { [file exists work/$d] } { file delete -force work/$d }
    file rename -force $d work/$d
}

echo "run.scr completed successfully"

exit