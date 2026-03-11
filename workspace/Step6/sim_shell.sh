#!/bin/bash
# =============================================================================
# Simulation Shell - ECE260B Final Project
# =============================================================================
# Run from project root:  ./sim_shell.sh   or   make sim-shell
#   ./sim_shell.sh              - interactive mode (stdin)
#   ./sim_shell.sh -f mingu.X   - feed X.mingu to interactive mode
#
# Shell-level commands (before fix_set): set_output_dir, set_sim_stage, set_sim_define, set_clock_period, set <var> <value>
# fix_set: lock settings, compile, start sim. After fix_set, TB commands go to vvp.
# User vars (set VAR value): use $VAR or ${VAR} in later lines; substituted before passing to vvp.
# =============================================================================

PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJ_ROOT" || exit 1

# Defaults (overridden by set_* before fix_set)
OUTPUT_DIR="sim/waveform"
SIM_STAGE="sim"
SIM_DEFINES="SFP_LONGDIV"
CLOCK_PERIOD="1"
TARGET="core"
FIXED=0

# Parse -f
INPUT_FILE=""
while getopts "f:" opt; do
	case "$opt" in
		f)
			if [[ "$(basename "$OPTARG")" == mingu.* ]]; then
				dir=$(dirname "$OPTARG")
				base="${OPTARG##*/}"
				INPUT_FILE="${dir}/${base#mingu.}.mingu"
			else
				INPUT_FILE="$OPTARG"
			fi
			;;
	esac
done

# Read input (stdin or file)
read_input() {
	if [[ -n "$INPUT_FILE" && -f "$INPUT_FILE" ]]; then
		cat "$INPUT_FILE"
	else
		cat
	fi
}

# Parse a line; return 1 if fix_set seen
parse_line() {
	local line="$1"
	local cmd="${line%% *}"
	local arg="${line#* }"

	if [[ "$cmd" == "" || "$cmd" == "#"* ]]; then
		return 0
	fi

	if [[ $FIXED -eq 1 ]]; then
		# After fix_set: pass through to vvp (TB commands)
		echo "$line"
		return 0
	fi

	# Before fix_set: shell-level commands
	case "$cmd" in
		set_output_dir)
			OUTPUT_DIR="$arg"
			;;
		set_sim_stage)
			SIM_STAGE="$arg"
			;;
		set_sim_define)
			SIM_DEFINES="$arg"
			;;
		set_clock_period)
			CLOCK_PERIOD="$arg"
			;;
		fix_set)
			FIXED=1
			return 1
			;;
		set_exec_target|writeQ|writeK|simulate|verifypmem|reset|exit|help)
			echo "Error: TB command '$cmd' before fix_set. Run fix_set first." >&2
			;;
		*)
			echo "Error: unknown command '$cmd' before fix_set" >&2
			;;
	esac
	return 0
}

# Build make args from current state
make_args() {
	local args="TARGET=core_shell"
	[[ -n "$OUTPUT_DIR" ]] && args="$args OUTPUT_DIR=$OUTPUT_DIR"
	[[ -n "$CLOCK_PERIOD" ]] && args="$args CYCLE=$CLOCK_PERIOD"
	[[ -n "$SIM_DEFINES" ]] && args="$args USER_DEFINES=\"$SIM_DEFINES\""
	if [[ "$SIM_STAGE" == "gls" ]]; then
		echo "gls $args"
	else
		echo "sim $args"
	fi
}

run_with_fix_set() {
	local content="$1"
	local after_fix=""
	local found_fix=0

	# First pass: parse set_* and find fix_set
	while IFS= read -r line; do
		line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
		[[ -z "$line" || "$line" == \#* ]] && continue

		if [[ "$line" == "fix_set" ]]; then
			found_fix=1
			FIXED=1
			break
		fi

		case "${line%% *}" in
			set_output_dir) OUTPUT_DIR="${line#* }" ;;
			set_sim_stage)  SIM_STAGE="${line#* }" ;;
			set_sim_define) SIM_DEFINES="${line#* }" ;;
			set_clock_period) CLOCK_PERIOD="${line#* }" ;;
			set)
				rest="${line#set }"; rest="${rest# }"
				var="${rest%% *}"
				value="${rest#* }"; value="${value# }"
				[[ -n "$var" ]] && export "$var=$value"
				;;
		esac
	done <<< "$content"

	# Collect lines after fix_set (or all TB commands if no fix_set)
	if [[ $found_fix -eq 0 ]]; then
		after_fix=$(echo "$content" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | grep -v '^set_output_dir' | grep -v '^set_sim_stage' | grep -v '^set_sim_define' | grep -v '^set_clock_period' | grep -v '^set ')
	else
		after_fix=$(echo "$content" | awk '/^[[:space:]]*fix_set[[:space:]]*$/{f=1;next}f' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')
	fi

	# Process "set VAR value" in after_fix (export for envsubst) and remove from output
	after_fix_filtered=""
	while IFS= read -r ln; do
		if [[ "$ln" == set\ * ]]; then
			rest="${ln#set }"; rest="${rest# }"
			var="${rest%% *}"
			value="${rest#* }"; value="${value# }"
			[[ -n "$var" ]] && export "$var=$value"
		else
			after_fix_filtered="$after_fix_filtered$ln"$'\n'
		fi
	done <<< "$after_fix"
	after_fix="$after_fix_filtered"

	# Substitute user vars ($VAR, ${VAR}) in TB commands
	after_fix=$(echo "$after_fix" | envsubst 2>/dev/null || echo "$after_fix")

	# Run make (sim or gls) with params; stdin to vvp
	if [[ "$SIM_STAGE" == "gls" ]]; then
		echo "$after_fix" | make gls TARGET=core_shell OUTPUT_DIR="$OUTPUT_DIR" CYCLE="$CLOCK_PERIOD" USER_DEFINES="$SIM_DEFINES"
	else
		echo "$after_fix" | make sim TARGET=core_shell OUTPUT_DIR="$OUTPUT_DIR" CYCLE="$CLOCK_PERIOD" USER_DEFINES="$SIM_DEFINES"
	fi
}

# Main
if [[ -n "$INPUT_FILE" && ! -f "$INPUT_FILE" ]]; then
	echo "File not found: $INPUT_FILE"
	exit 1
fi

# Read input once
INPUT_CONTENT=$(read_input)

# If input has fix_set, do two-phase; else simple
if echo "$INPUT_CONTENT" | grep -q '^[[:space:]]*fix_set[[:space:]]*$'; then
	run_with_fix_set "$INPUT_CONTENT"
else
	# Simple mode: no fix_set, parse set VAR, filter, substitute, then run
	if [[ -n "$INPUT_FILE" && -f "$INPUT_FILE" ]]; then
		simple_content=$(echo "$INPUT_CONTENT" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | grep -v '^set_output_dir' | grep -v '^set_sim_stage' | grep -v '^set_sim_define' | grep -v '^set_clock_period')
		simple_filtered=""
		while IFS= read -r ln; do
			if [[ "$ln" == set\ * ]]; then
				rest="${ln#set }"; rest="${rest# }"
				var="${rest%% *}"
				value="${rest#* }"; value="${value# }"
				[[ -n "$var" ]] && export "$var=$value"
			else
				simple_filtered="$simple_filtered$ln"$'\n'
			fi
		done <<< "$simple_content"
		simple_filtered=$(echo "$simple_filtered" | envsubst 2>/dev/null || echo "$simple_filtered")
		echo ""
		echo ">>> Running: make sim TARGET=core_shell < $INPUT_FILE (comments filtered)"
		echo "$simple_filtered" | make sim TARGET=core_shell
	else
		echo ""
		echo ">>> Running: make sim TARGET=core_shell (interactive)"
		make sim TARGET=core_shell
	fi
fi
