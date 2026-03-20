# =============================================================================
# ECE260B Final Project - Simulation and Synthesis Makefile
# =============================================================================
#
# Usage:  make sim  [TARGET=<name>]                       -- run simulation
#         make syn  [TARGET=<name>] [SYN_EFFORT=<level>]  -- run synthesis (Design Compiler)
#         make all  [TARGET=<name>] [SYN_EFFORT=<level>]  -- run sim + syn for one target
#
# SystemVerilog:  make sim uses -g2012 by default. Override with IVERILOG_SV= (empty to disable).
#
# Simulation targets (TARGET=):
#   target        description              filelist (in sim/filelists/)
#   ------------- -----------------------  --------------------------
#   fullchip      fullchip (shell TB)      filelist_fullchip_shell (sim/gls); syn uses syn/filelists/filelist_fullchip
#   controller    controller               filelist_controller
#   core          single core              filelist_core
#   mac           mac_array                filelist_mac
#   sfp_row       sfp_row single-core      filelist_sfp_row
#   sfp_row_dual  sfp_row dual-core        filelist_sfp_row_dual
#
# Gate-level simulation:  make gls [TARGET=<name>]
#   Uses gls/filelists/ + gls/tb/ + syn/gate/*.out.v + PDK
#   Waveforms: gls/waveform/*.vcd
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
USER_DEFINES ?= SFP_LONGDIV

# ----- Tool and path configuration -----
SIM_FILELISTS_DIR := sim/filelists
GLS_FILELISTS_DIR := gls/filelists
SYN_FILELISTS_DIR := syn/filelists
IVERILOG          := iverilog
IVERILOG_SV       ?= -g2012
VVP               := vvp
OUT_DIR           := sim/compiled
GLS_OUT_DIR       := gls/compiled
SYNDIR            := syn


  PROJ_ROOT := $(CURDIR)


# ----- Lookup tables -----
# target -> filelist filename (shared between sim and syn for filelist name lookup)
TARGET_FILELIST_table := \
	fullchip:filelist_fullchip_shell \
	controller:filelist_controller \
	core:filelist_core \
	core_shell:filelist_core_shell \
	mac:filelist_mac \
	sfp_row:filelist_sfp_row \
	sfp_row_dual:filelist_sfp_row_dual

# target -> waveform filename
TARGET_WAVEFORM_table := \
	fullchip:fullchip.vcd \
	controller:controller.vcd \
	core:core.vcd \
	core_shell:core.vcd \
	mac:mac_array.vcd \
	sfp_row:sfp_row.vcd \
	sfp_row_dual:sfp_row_dualcore.vcd

# target -> RTL top_module name (synthesis only; differs where make-target != module name)
TARGET_TOP_MODULE_table := \
	fullchip:fullchip \
	core:core \
	controller:controller \
	mac:mac_array \
	sfp_row:sfp_row

SIM_TARGETS := fullchip controller core core_shell mac sfp_row sfp_row_dual
SYN_TARGETS := fullchip  sfp_row controller core mac

$(foreach p,$(TARGET_FILELIST_table),$(eval $(firstword $(subst :, ,$(p))): FILELIST_NAME := $(word 2,$(subst :, ,$(p)))))
$(foreach p,$(TARGET_WAVEFORM_table),$(eval $(firstword $(subst :, ,$(p))): WAVEFORM     := $(word 2,$(subst :, ,$(p)))))

# gls_* targets inherit filelist/waveform from sim target
$(foreach p,$(TARGET_FILELIST_table),$(eval gls_$(firstword $(subst :, ,$(p))): FILELIST_NAME := $(word 2,$(subst :, ,$(p)))))
$(foreach p,$(TARGET_WAVEFORM_table),$(eval gls_$(firstword $(subst :, ,$(p))): WAVEFORM     := $(word 2,$(subst :, ,$(p)))))

# ----- Phony declarations -----
.PHONY: all clean help default sim syn gls sim-shell parse $(SIM_TARGETS) $(addprefix gls_,$(SIM_TARGETS))

default: sim

# ----- Simulation -----
TARGET ?= fullchip
sim: $(TARGET)

# ----- Gate-level simulation -----
gls: gls_$(TARGET)

$(addprefix gls_,$(SIM_TARGETS)):
	@mkdir -p gls gls/waveform gls/pattern $(GLS_OUT_DIR)
	$(IVERILOG) $(IVERILOG_SV) $(IVERILOG_DEFINES) -o $(GLS_OUT_DIR)/$(patsubst gls_%,%,$@) -f $(GLS_FILELISTS_DIR)/$(FILELIST_NAME)
	$(VVP) $(GLS_OUT_DIR)/$(patsubst gls_%,%,$@)
	@echo ""
	@echo ">>> Gate sim waveform: gls/waveform/$(WAVEFORM) <<<"

# ----- All: sim + syn (+ pnr in the future) for a single TARGET -----
all:
	$(MAKE) sim TARGET=$(TARGET)
	$(MAKE) syn TARGET=$(TARGET)

# User defines: -DSFP_LONGDIV etc. for iverilog (from USER_DEFINE_TASK_VARS)
IVERILOG_DEFINES = $(patsubst %,-D%,$(USER_DEFINES))

# Optional compile-time overrides (make sim CYCLE=2 OUTPUT_DIR=sim/myout)
ifneq ($(CYCLE),)
  IVERILOG_DEFINES += -DCYCLE=$(CYCLE)
endif
ifneq ($(H_CYCLE),)
  IVERILOG_DEFINES += -DH_CYCLE=$(H_CYCLE)
endif
ifneq ($(OUTPUT_DIR),)
  IVERILOG_DEFINES += -DOUTPUT_DIR=\"$(OUTPUT_DIR)\"
endif

$(SIM_TARGETS):
	@mkdir -p sim sim/waveform $(OUT_DIR)
	$(IVERILOG) $(IVERILOG_SV) $(IVERILOG_DEFINES) -o $(OUT_DIR)/$@ -f $(SIM_FILELISTS_DIR)/$(FILELIST_NAME)
	$(VVP) $(OUT_DIR)/$@
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
# sim/gls use sim/filelists/filelist_fullchip_shell for fullchip; DC still reads RTL-only syn/filelists/filelist_fullchip
ifeq ($(SYN_TARGET),fullchip)
  SYN_FILELIST = $(SYN_FILELISTS_DIR)/filelist_fullchip
else
  SYN_FILELIST = $(SYN_FILELISTS_DIR)/$(word 2,$(subst :, ,$(filter $(SYN_TARGET):%,$(TARGET_FILELIST_table))))
endif

# Synthesis effort: low | medium | high  (built-in default: high)
SYN_EFFORT ?= high

syn:
	@cd $(SYNDIR) && dc_shell -f run_dc.tcl -x "set top_module $(TOP_MODULE); set rtlPath $(PROJ_ROOT); set filelist_path {$(SYN_FILELIST)}; set syn_effort $(SYN_EFFORT); set syn_defines {$(USER_DEFINES)}"

# ----- Interactive simulation shell (menu) -----
sim-shell:
	@./sim_shell.sh

# ----- Utilities -----
parse:  ## Parse syn/log/*.rep and print summary (uses shell script; no Python needed)
	@bash $(SYNDIR)/parse_reports.sh $(SYNDIR)/log

clean:
	rm -f $(addprefix $(OUT_DIR)/,$(SIM_TARGETS)) $(addprefix $(GLS_OUT_DIR)/,$(SIM_TARGETS))
	@echo "Removed $(OUT_DIR)/* $(GLS_OUT_DIR)/*"

help:
	@echo "Usage:  make sim [TARGET=<name>]"
	@echo "        make gls [TARGET=<name>]  # gate-level sim (gls/tb + syn/gate + PDK)"
	@echo "        make syn [TARGET=<name>] [SYN_EFFORT=low|medium|high]"
	@echo "        make all [TARGET=<name>] [SYN_EFFORT=low|medium|high]"
	@echo ""
	@echo "TARGET controls both sim and syn:"
	@echo "  sim valid: fullchip(default) | core | controller | mac | sfp_row | sfp_row_dual"
	@echo "  syn valid: fullchip | core(default) | controller | sfp_row | mac"
	@echo "  gls valid: same as sim (uses syn/gate/*.out.v + PDK)"
	@echo "  (if TARGET is sim-only, syn falls back to its default: core)"
	@echo ""
	@echo "SYN_EFFORT (default: high):"
	@echo "  low    - fast mapping, good for RTL sanity check"
	@echo "  medium - standard optimization, balanced speed/quality"
	@echo "  high   - full compile_ultra, slowest, for pre-PnR"
	@echo ""
	@echo "USER_DEFINES (in USER_DEFINE_TASK_VARS):"
	@echo "  Space-separated Verilog macros, e.g. SFP_LONGDIV LOAD_OTHER_NORM_FILE"
	@echo "  Applied to both sim (iverilog -D) and syn (DC -define)"
	@echo ""
	@echo "  make sim-shell  - Interactive sim menu (run sim, view waveform, clean)"
	@echo "  make parse  - Parse syn/log/*.rep summary (shell script, no Python)"
	@echo ""
	@echo "SystemVerilog: sim/gls use IVERILOG_SV=-g2012 by default. Set IVERILOG_SV= to disable."
	@echo ""
	@echo "Other: make clean"
