# =============================================================================
# ECE260B Final Project - Simulation Makefile
# =============================================================================
#
# Usage:  make [target]
#
#   target        description              filelist (in filelists/)
#   ------------- -----------------------  --------------------------
#   (default)     fullchip single-core     filelist
#   fullchip      same as default          filelist
#   mac           mac_array                filelist_mac
#   dual          fullchip dual-core       filelist_dual
#   sfp_row       sfp_row single-core      filelist_sfp_row
#   sfp_row_dual  sfp_row dual-core        filelist_sfp_row_dual
#   vproduct      Vproduct (norm)          filelist_vproduct
#   all           run all of the above
#
# Waveforms: sim/waveform/*.vcd (fullchip.vcd, mac_array.vcd, ...)
# =============================================================================

FILELISTS_DIR := filelists
IVERILOG      := iverilog
VVP           := vvp
OUT           := sim/compiled

# Target -> filelist (used by rules below)
#   make target  reads  filelists/<filelist>
TARGET_FILELIST_table := \
	fullchip:filelist \
	mac:filelist_mac \
	dual:filelist_dual \
	sfp_row:filelist_sfp_row \
	sfp_row_dual:filelist_sfp_row_dual \
	vproduct:filelist_vproduct

# Target -> waveform .vcd name
TARGET_WAVEFORM_table := \
	fullchip:fullchip.vcd \
	mac:mac_array.vcd \
	dual:fullchip_dual.vcd \
	sfp_row:sfp_row.vcd \
	sfp_row_dual:sfp_row_dualcore.vcd \
	vproduct:vproduct.vcd

SIM_TARGETS := fullchip mac dual sfp_row sfp_row_dual vproduct

$(foreach p,$(TARGET_FILELIST_table),$(eval $(firstword $(subst :, ,$(p))): FILELIST_NAME := $(word 2,$(subst :, ,$(p)))))
$(foreach p,$(TARGET_WAVEFORM_table),$(eval $(firstword $(subst :, ,$(p))): WAVEFORM := $(word 2,$(subst :, ,$(p)))))

.PHONY: all clean help default $(SIM_TARGETS)

default: fullchip

all: $(SIM_TARGETS)
	@echo "--- All done. Waveforms: sim/waveform/*.vcd ---"

$(SIM_TARGETS):
	@mkdir -p sim
	$(IVERILOG) -o $(OUT) -f $(FILELISTS_DIR)/$(FILELIST_NAME)
	$(VVP) $(OUT)
	@echo ""
	@echo ">>> Waveform: sim/waveform/$(WAVEFORM) (GTKWave or any VCD viewer) <<<"

# Compile only: make compile [TARGET=mac]
TARGET ?= fullchip
compile:
	@mkdir -p sim
	@fl=$$(echo '$(TARGET_FILELIST_table)' | tr ' ' '\n' | grep '^$(TARGET):' | cut -d: -f2); \
	$(IVERILOG) -o $(OUT) -f $(FILELISTS_DIR)/$$fl; \
	echo "Built $(OUT). Run '$(VVP) $(OUT)' to generate waveform."

clean:
	rm -f $(OUT)
	@echo "Removed $(OUT)"

help:
	@echo "Targets (make <target> = build + run):"
	@echo ""
	@echo "  target         filelist               waveform"
	@echo "  ------------   -------------------   -------------------------"
	@echo "  fullchip       filelist               fullchip.vcd"
	@echo "  mac            filelist_mac           mac_array.vcd"
	@echo "  dual           filelist_dual          fullchip_dual.vcd"
	@echo "  sfp_row        filelist_sfp_row       sfp_row.vcd"
	@echo "  sfp_row_dual   filelist_sfp_row_dual  sfp_row_dualcore.vcd"
	@echo "  vproduct       filelist_vproduct      vproduct.vcd"
	@echo ""
	@echo "  all            run all above"
	@echo "  compile TARGET=<target>   compile only (no run)"
	@echo "  clean          remove sim/compiled"
	@echo "  help           this message"
