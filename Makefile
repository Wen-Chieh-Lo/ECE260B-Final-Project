# =============================================================================
# ECE260B Final Project - Simulation and Synthesis Makefile
# =============================================================================
#
# Usage:  make sim  [TARGET=<name>]   -- run simulation
#         make syn  [TARGET=<name>]   -- run synthesis (Design Compiler)
#         make all  [TARGET=<name>]   -- run sim + syn (and pnr when added) for one target
#
# Simulation targets (TARGET=):
#   target        description              filelist (in sim/filelists/)
#   ------------- -----------------------  --------------------------
#   fullchip      fullchip single-core     filelist            (default)
#   core          single core              filelist_core
#   mac           mac_array                filelist_mac
#   dual          fullchip dual-core       filelist_dual
#   sfp_row       sfp_row single-core      filelist_sfp_row
#   sfp_row_dual  sfp_row dual-core        filelist_sfp_row_dual
#
# Synthesis targets (TARGET=):
#   target   top_module   filelist (in syn/filelists/)  SDC         outputs
#   -------- ------------ ---------------------------- ----------- --------------------------
#   core     core         filelist_core                 common.sdc  gate/core.out.v     (default)
#   sfp_row  sfp_row      filelist_sfp_row              common.sdc  gate/sfp_row.out.v
#   mac      mac_array    filelist_mac                  common.sdc  gate/mac_array.out.v
#
# Defaults can also be set in USER_DEFINE_TASK_VARS (command-line overrides that file).
# Waveforms  : sim/waveform/*.vcd
# Syn reports: syn/log/<top>_area.rep, <top>_timing.rep, <top>_power.rep
#
# =============================================================================

# ----- User-defined defaults (overridden by command line) -----
-include USER_DEFINE_TASK_VARS

# ----- Tool and path configuration -----
SIM_FILELISTS_DIR := sim/filelists
SYN_FILELISTS_DIR := syn/filelists
IVERILOG          := iverilog
VVP               := vvp
OUT               := sim/compiled
SYNDIR            := syn

ifneq ($(strip $(PROJECT_REPO_PATH)),)
  PROJ_ROOT := $(PROJECT_REPO_PATH)
else
  PROJ_ROOT := $(CURDIR)
endif

# ----- Lookup tables -----
# target -> filelist filename (shared between sim and syn for filelist name lookup)
TARGET_FILELIST_table := \
	fullchip:filelist \
	core:filelist_core \
	mac:filelist_mac \
	dual:filelist_dual \
	sfp_row:filelist_sfp_row \
	sfp_row_dual:filelist_sfp_row_dual

# target -> waveform filename
TARGET_WAVEFORM_table := \
	fullchip:fullchip.vcd \
	core:core.vcd \
	mac:mac_array.vcd \
	dual:fullchip_dual.vcd \
	sfp_row:sfp_row.vcd \
	sfp_row_dual:sfp_row_dualcore.vcd

# target -> RTL top_module name (synthesis only; differs where make-target != module name)
TARGET_TOP_MODULE_table := \
	core:core \
	mac:mac_array \
	sfp_row:sfp_row

SIM_TARGETS := fullchip core mac dual sfp_row sfp_row_dual
SYN_TARGETS := sfp_row core mac

$(foreach p,$(TARGET_FILELIST_table),$(eval $(firstword $(subst :, ,$(p))): FILELIST_NAME := $(word 2,$(subst :, ,$(p)))))
$(foreach p,$(TARGET_WAVEFORM_table),$(eval $(firstword $(subst :, ,$(p))): WAVEFORM     := $(word 2,$(subst :, ,$(p)))))

# ----- Phony declarations -----
.PHONY: all clean help default sim syn $(SIM_TARGETS)

default: sim

# ----- Simulation -----
TARGET ?= fullchip
sim: $(TARGET)

# ----- All: sim + syn (+ pnr in the future) for a single TARGET -----
all:
	$(MAKE) sim TARGET=$(TARGET)
	$(MAKE) syn TARGET=$(TARGET)

$(SIM_TARGETS):
	@mkdir -p sim
	$(IVERILOG) -o $(OUT) -f $(SIM_FILELISTS_DIR)/$(FILELIST_NAME)
	$(VVP) $(OUT)
	@echo ""
	@echo ">>> Waveform: sim/waveform/$(WAVEFORM) (GTKWave or any VCD viewer) <<<"

# ----- Synthesis -----
# Use TARGET if it is a valid syn target; otherwise fall back to core
ifeq ($(filter $(TARGET),$(SYN_TARGETS)),)
  SYN_TARGET := core
else
  SYN_TARGET := $(TARGET)
endif

TOP_MODULE   = $(word 2,$(subst :, ,$(filter $(SYN_TARGET):%,$(TARGET_TOP_MODULE_table))))
SYN_FILELIST = $(SYN_FILELISTS_DIR)/$(word 2,$(subst :, ,$(filter $(SYN_TARGET):%,$(TARGET_FILELIST_table))))

syn:
	@cd $(SYNDIR) && dc_shell -f run_dc.tcl -x "set top_module $(TOP_MODULE); set rtlPath $(PROJ_ROOT); set filelist_path {$(SYN_FILELIST)}"

# ----- Utilities -----
clean:
	rm -f $(OUT)
	@echo "Removed $(OUT)"

help:
	@echo "Usage:  make sim [TARGET=<name>]   make syn [TARGET=<name>]   make all [TARGET=<name>]"
	@echo ""
	@echo "TARGET controls both sim and syn:"
	@echo "  sim valid: fullchip(default) | core | mac | dual | sfp_row | sfp_row_dual"
	@echo "  syn valid: core(default)     | sfp_row | mac"
	@echo "  (if TARGET is sim-only, syn falls back to its default: core)"
	@echo ""
	@echo "Other: make clean"
