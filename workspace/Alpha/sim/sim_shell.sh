#!/bin/bash
# =============================================================================
# Interactive Simulation Shell - ECE260B Final Project
# =============================================================================
# Run from project root:  ./sim/sim_shell.sh   or   make sim-shell
# =============================================================================

PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJ_ROOT" || exit 1

# Waveform paths
SIM_WAVE="sim/waveform"
GLS_WAVE="gls/waveform"

# Target -> waveform file mapping
declare -A WAVEFORMS
WAVEFORMS[fullchip]="fullchip.vcd"
WAVEFORMS[controller]="controller.vcd"
WAVEFORMS[core]="core.vcd"
WAVEFORMS[mac]="mac_array.vcd"
WAVEFORMS[sfp_row]="sfp_row.vcd"
WAVEFORMS[sfp_row_dual]="sfp_row_dualcore.vcd"

print_header() {
	echo ""
	echo "=============================================="
	echo "  ECE260B - Interactive Simulation Shell"
	echo "=============================================="
	echo "  Project: $PROJ_ROOT"
	echo "=============================================="
}

print_menu() {
	echo ""
	echo "  [1] Run RTL sim (core)          - single core verification"
	echo "  [2] Run RTL sim (fullchip)      - fullchip"
	echo "  [3] Run RTL sim (controller)    - controller"
	echo "  [4] Run RTL sim (mac)           - mac_array"
	echo "  [5] Run RTL sim (sfp_row)       - sfp_row"
	echo "  [6] Run RTL sim (sfp_row_dual)  - sfp_row dual-core"
	echo "  [7] Run gate-level sim (core)   - post-synthesis"
	echo "  [8] View RTL waveform           - GTKWave (last sim target)"
	echo "  [9] View GLS waveform           - GTKWave (gate-level)"
	echo "  [i] Interactive core sim        - stdin commands (qkp, norm, vp, reset, quit)"
	echo "  [c] Clean compiled binaries"
	echo "  [h] Help"
	echo "  [q] Quit"
	echo ""
}

run_sim() {
	local target="$1"
	echo ""
	echo ">>> Running: make sim TARGET=$target"
	make sim TARGET="$target"
	echo ""
	read -rp "Press Enter to continue..."
}

run_gls() {
	local target="${1:-core}"
	echo ""
	echo ">>> Running: make gls TARGET=$target"
	make gls TARGET="$target"
	echo ""
	read -rp "Press Enter to continue..."
}

run_interactive() {
	echo ""
	echo ">>> Running: make sim-i (interactive core sim)"
	echo "    Commands: qkp, norm, vp, reset, quit, help"
	echo ""
	make sim-i
	echo ""
	read -rp "Press Enter to continue..."
}

view_waveform() {
	local vcd_path="$1"
	if [[ -f "$vcd_path" ]]; then
		echo ""
		echo ">>> Opening $vcd_path with GTKWave..."
		if command -v gtkwave &>/dev/null; then
			gtkwave "$vcd_path" &
			echo "GTKWave launched in background."
		else
			echo "GTKWave not found. Install with: sudo apt install gtkwave"
			echo "Or view manually: $vcd_path"
		fi
	else
		echo ""
		echo "Waveform not found: $vcd_path"
		echo "Run simulation first."
	fi
	echo ""
	read -rp "Press Enter to continue..."
}

do_clean() {
	echo ""
	echo ">>> Running: make clean"
	make clean
	echo ""
	read -rp "Press Enter to continue..."
}

show_help() {
	echo ""
	make help
	echo ""
	read -rp "Press Enter to continue..."
}

# Main loop
LAST_TARGET="core"

while true; do
	print_header
	print_menu
	read -rp "Select option: " choice
	choice="${choice,,}"

	case "$choice" in
		1) run_sim core; LAST_TARGET="core" ;;
		2) run_sim fullchip; LAST_TARGET="fullchip" ;;
		3) run_sim controller; LAST_TARGET="controller" ;;
		4) run_sim mac; LAST_TARGET="mac" ;;
		5) run_sim sfp_row; LAST_TARGET="sfp_row" ;;
		6) run_sim sfp_row_dual; LAST_TARGET="sfp_row_dual" ;;
		7) run_gls core ;;
		8) view_waveform "$SIM_WAVE/${WAVEFORMS[$LAST_TARGET]}" ;;
		9) view_waveform "$GLS_WAVE/core.vcd" ;;
		i) run_interactive ;;
		c|clean) do_clean ;;
		h|help) show_help ;;
		q|quit|exit) echo ""; echo "Bye."; exit 0 ;;
		"") ;;
		*) echo "Unknown option: $choice"; sleep 1 ;;
	esac
done
