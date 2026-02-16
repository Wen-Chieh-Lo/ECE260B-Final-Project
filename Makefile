# =============================================================================
# ECE260B Final Project - Simulation Makefile
# =============================================================================
#
# Usage:  make [target]
#
#   target          description
#   --------------- ----------------------------------------------------------
#   (default)       fullchip (same as filelist)
#   filelist        fullchip
#   filelist_mac    mac_col
#   filelist_dual   fullchip_dual
#   filelist_sfp_row      sfp_row single-core
#   filelist_sfp_row_dual sfp_row dual-core
#   all             run all of the above in sequence
#
# Waveforms (see sim/waveform/*.vcd after run):
#   fullchip.vcd, mac_col.vcd, fullchip_dual.vcd,
#   sfp_row.vcd, sfp_row_dualcore.vcd  (use GTKWave or any VCD viewer)
# =============================================================================

FILELISTS_DIR := filelists
IVERILOG      := iverilog
VVP           := vvp
OUT           := sim/compiled

# Collect all filelist names from filelists/ (no path)
FILELIST_NAMES := $(notdir $(wildcard $(FILELISTS_DIR)/filelist*))

# Map: filelist target -> waveform .vcd filename (single source of truth)
WAVEFORM_map := filelist:fullchip.vcd \
	filelist_mac:mac_col.vcd \
	filelist_dual:fullchip_dual.vcd \
	filelist_sfp_row:sfp_row.vcd \
	filelist_sfp_row_dual:sfp_row_dualcore.vcd
$(foreach p,$(WAVEFORM_map),$(eval $(firstword $(subst :, ,$(p))): WAVEFORM := $(word 2,$(subst :, ,$(p)))))

.PHONY: all clean help $(FILELIST_NAMES)

# Default: use filelist (fullchip)
default: filelist

# Run all filelist modes (overwrites sim/compiled and waveform)
all: $(FILELIST_NAMES)
	@echo "--- All modes done. Waveforms: sim/waveform/*.vcd ---"

# Generic rule: one target per filelist in filelists/
# Build: iverilog -o sim/compiled -f filelists/<name>
# Run:   vvp sim/compiled → waveform path per comments above
$(FILELIST_NAMES):
	@mkdir -p sim
	$(IVERILOG) -o $(OUT) -f $(FILELISTS_DIR)/$@
	$(VVP) $(OUT)
	@echo ""
	@echo ">>> Waveform: sim/waveform/$(WAVEFORM) (open with GTKWave or any VCD viewer) <<<"

# Compile only, no run (override with FILELIST=filelist_mac etc.; default filelist)
FILELIST ?= filelist
compile:
	@mkdir -p sim
	$(IVERILOG) -o $(OUT) -f $(FILELISTS_DIR)/$(FILELIST)
	@echo "Built $(OUT). Run '$(VVP) $(OUT)' to generate waveform."

clean:
	rm -f $(OUT)
	@echo "Removed $(OUT)"

help:
	@echo "Targets:"
	@echo "  make / make filelist        - build and run filelists/filelist; waveform: sim/waveform/fullchip.vcd"
	@echo "  make filelist_mac           - filelists/filelist_mac; waveform: sim/waveform/mac_col.vcd"
	@echo "  make filelist_dual          - filelists/filelist_dual; waveform: sim/waveform/fullchip_dual.vcd"
	@echo "  make filelist_sfp_row       - filelists/filelist_sfp_row; waveform: sim/waveform/sfp_row.vcd"
	@echo "  make filelist_sfp_row_dual  - filelists/filelist_sfp_row_dual; waveform: sim/waveform/sfp_row_dualcore.vcd"
	@echo "  make all                    - run all modes"
	@echo "  make compile FILELIST=xxx   - compile only (xxx=filelist|filelist_mac|filelist_dual|filelist_sfp_row|filelist_sfp_row_dual)"
	@echo "  make clean                  - remove sim/compiled"
	@echo "  make help                   - show this help"
