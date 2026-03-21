#!/bin/bash
# =============================================================================
# Simulation Shell - ECE260B Final Project
# =============================================================================
# Run from project root:  ./sim_shell.sh   or   make sim-shell
#   ./sim_shell.sh              - interactive mode (stdin)
#   ./sim_shell.sh -f mingu.X   - feed X.mingu to interactive mode
#
# Shell-level commands (before fix_set): set_output_dir, set_sim_stage, set_sim_target, set_sim_define, set_clock_period, set <var> <value>
#   set_sim_stage: sim (default) | gls | post_sim
#     sim      - RTL sim (iverilog+vvp)
#     gls      - Gate-level sim (iverilog+vvp, syn/gate + PDK)
#     post_sim - Post-PnR sim (xrun via post_sim/run_gui; runs from post_sim/)
#   set_sim_target: core_shell (default) | fullchip_shell
# fix_set: lock settings, compile, start sim. After fix_set, TB commands go to vvp (except post_sim: runs xrun GUI).
# User vars (set VAR value): use $(VAR) in later lines; substituted before passing to vvp.
#
# For-loop (TB block only, after fix_set):
#   for <var> = <start> to <end>
#     ... TB commands; use $var or ${var} ...
#   endfor
#   Single-level only; inclusive range [start,end]. Use $(var) in body. Example: for i = 0 to 99 ... $(i) ... endfor
# =============================================================================

PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJ_ROOT" || exit 1

# Defaults (overridden by set_* before fix_set)
OUTPUT_DIR="sim/waveform"
SIM_STAGE="sim"
SIM_DEFINES="SFP_LONGDIV"
CLOCK_PERIOD="1"
SIM_TARGET="core_shell"
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
		set_sim_target)
			SIM_TARGET="$arg"
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
		set_exec_target|writeQ|writeK|writeK0|writeK1|simulate|verifypmem|verifypmem0|verifypmem1|reset|exit|help)
			echo "Error: TB command '$cmd' before fix_set. Run fix_set first." >&2
			;;
		*)
			echo "Error: unknown command '$cmd' before fix_set" >&2
			;;
	esac
	return 0
}

# Expand for loops in TB block: "for var = start to end" ... "endfor" -> repeated body with set var
# Single-level only; no nesting. Inclusive range [start,end].
expand_for_loops() {
	local content="$1"
	local out=""
	local in_for=0
	local loop_var="" start_val="" end_val=""
	local body_lines=""

	while IFS= read -r line; do
		line_trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

		if [[ $in_for -eq 1 ]]; then
			if [[ "$line_trimmed" == "endfor" ]]; then
				if [[ ! "$start_val" =~ ^-?[0-9]+$ ]] || [[ ! "$end_val" =~ ^-?[0-9]+$ ]]; then
					echo "Error: for loop requires integer start/end (got start=$start_val end=$end_val)" >&2
					exit 1
				fi
				if [[ "$start_val" -gt "$end_val" ]]; then
					echo "Error: for loop start ($start_val) > end ($end_val)" >&2
					exit 1
				fi
				local i="$start_val"
				while [[ "$i" -le "$end_val" ]]; do
					out="$out${out:+$'\n'}set $loop_var $i"
					while IFS= read -r bl; do
						[[ -z "$bl" ]] && continue
						out="$out${out:+$'\n'}$bl"
					done <<< "$body_lines"
					i=$((i + 1))
				done
				in_for=0
				body_lines=""
			elif [[ "$line_trimmed" =~ ^for[[:space:]] ]]; then
				echo "Error: nested for not supported" >&2
				exit 1
			else
				body_lines="$body_lines${body_lines:+$'\n'}$line_trimmed"
			fi
			continue
		fi

		if [[ "$line_trimmed" =~ ^for[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(-?[0-9]+)[[:space:]]+to[[:space:]]+(-?[0-9]+)[[:space:]]*$ ]]; then
			loop_var="${BASH_REMATCH[1]}"
			start_val="${BASH_REMATCH[2]}"
			end_val="${BASH_REMATCH[3]}"
			in_for=1
			body_lines=""
		else
			out="$out${out:+$'\n'}$line_trimmed"
		fi
	done <<< "$content"

	if [[ $in_for -eq 1 ]]; then
		echo "Error: unclosed for loop (missing endfor)" >&2
		exit 1
	fi

	echo "$out"
}

# Build make args from current state
make_args() {
	local args="TARGET=$SIM_TARGET"
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
			set_sim_target) SIM_TARGET="${line#* }" ;;
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
		after_fix=$(echo "$content" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | grep -v '^set_output_dir' | grep -v '^set_sim_stage' | grep -v '^set_sim_target' | grep -v '^set_sim_define' | grep -v '^set_clock_period' | grep -v '^set ')
	else
		after_fix=$(echo "$content" | awk '/^[[:space:]]*fix_set[[:space:]]*$/{f=1;next}f' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')
	fi

	# Expand for loops (for var = start to end ... endfor) in TB block
	after_fix=$(expand_for_loops "$after_fix")

	# Path compatibility: post_sim runs from post_sim/, so PATTERN needs ../ prefix
	[[ "$SIM_STAGE" == "post_sim" ]] && [[ "${PATTERN}" != ../* ]] && export PATTERN="../${PATTERN}"

	# Process "set VAR value" in after_fix (export for envsubst) and remove from output.
	# Do envsubst per-line so loop vars (set i 0; writeQ ...$i...; set i 1; ...) get correct values.
	after_fix_filtered=""
	while IFS= read -r ln; do
		if [[ "$ln" == set\ * ]]; then
			rest="${ln#set }"; rest="${rest# }"
			var="${rest%% *}"
			value="${rest#* }"; value="${value# }"
			[[ -n "$var" ]] && export "$var=$value"
		else
			# Convert $(var) to ${var} for envsubst; unified syntax
			ln_norm=$(echo "$ln" | perl -pe 's/\$\(([A-Za-z_][A-Za-z0-9_]*)\)/\${\1}/g')
			substed=$(echo "$ln_norm" | envsubst 2>/dev/null || echo "$ln_norm")
			after_fix_filtered="$after_fix_filtered$substed"$'\n'
		fi
	done <<< "$after_fix"
	after_fix="$after_fix_filtered"

	# Run: make sim/gls, or post_sim (xrun with fullchip_shell_tb for batch mingu)
	# Use temp file for sim/gls stdin to avoid pipe/newline issues.
	if [[ "$SIM_STAGE" == "post_sim" ]]; then
		POST_SIM_DIR="$PROJ_ROOT/post_sim"
		if [[ -f "$POST_SIM_DIR/run_batch" ]]; then
			echo ">>> Running post_sim/run_batch (xrun + fullchip_shell_tb) from $POST_SIM_DIR"
			TMP_MINGU=$(mktemp) && printf '%s\n' "$after_fix" > "$TMP_MINGU"
			(cd "$POST_SIM_DIR" && ./run_batch < "$TMP_MINGU")
			rm -f "$TMP_MINGU"
		elif [[ -f "$POST_SIM_DIR/run_gui" ]]; then
			echo ">>> Running post_sim/run_gui (xrun GUI, no batch) from $POST_SIM_DIR"
			(cd "$POST_SIM_DIR" && ./run_gui)
		else
			echo "Error: post_sim/run_batch or run_gui not found" >&2
			exit 1
		fi
	elif [[ "$SIM_STAGE" == "gls" ]]; then
		TMP_MINGU=$(mktemp) && printf '%s\n' "$after_fix" > "$TMP_MINGU"
		make gls TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" CYCLE="$CLOCK_PERIOD" USER_DEFINES="$SIM_DEFINES" < "$TMP_MINGU"
		rm -f "$TMP_MINGU"
	else
		TMP_MINGU=$(mktemp) && printf '%s\n' "$after_fix" > "$TMP_MINGU"
		make sim TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" CYCLE="$CLOCK_PERIOD" USER_DEFINES="$SIM_DEFINES" < "$TMP_MINGU"
		rm -f "$TMP_MINGU"
	fi
}

# Main
if [[ -n "$INPUT_FILE" && ! -f "$INPUT_FILE" ]]; then
	echo "File not found: $INPUT_FILE"
	exit 1
fi

# Read input once
INPUT_CONTENT=$(read_input)

# Auto-run make gen-patterns when mingu uses sw/pattern/random100 and files are missing
if echo "$INPUT_CONTENT" | grep -qE 'set[[:space:]]+PATTERN[[:space:]]+sw/pattern/random100|sw/pattern/random100'; then
	if [[ ! -f "$PROJ_ROOT/sw/pattern/random100/qdata_0.txt" ]]; then
		echo ">>> PATTERN=sw/pattern/random100 but pattern files missing; running make gen-patterns"
		make gen-patterns
	fi
fi

# If input has fix_set, do two-phase; else simple
if echo "$INPUT_CONTENT" | grep -q '^[[:space:]]*fix_set[[:space:]]*$'; then
	run_with_fix_set "$INPUT_CONTENT"
else
	# Simple mode: no fix_set, parse set_*, set VAR, filter, substitute, then run
	if [[ -n "$INPUT_FILE" && -f "$INPUT_FILE" ]]; then
		# Parse set_* from input (before filtering) to update SIM_TARGET etc.
		while IFS= read -r ln; do
			ln=$(echo "$ln" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
			[[ -z "$ln" || "$ln" == \#* ]] && continue
			case "${ln%% *}" in
				set_output_dir) OUTPUT_DIR="${ln#* }" ;;
				set_sim_stage)  SIM_STAGE="${ln#* }" ;;
				set_sim_target) SIM_TARGET="${ln#* }" ;;
				set_sim_define) SIM_DEFINES="${ln#* }" ;;
				set_clock_period) CLOCK_PERIOD="${ln#* }" ;;
			esac
		done <<< "$INPUT_CONTENT"
		simple_content=$(echo "$INPUT_CONTENT" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | grep -v '^set_output_dir' | grep -v '^set_sim_stage' | grep -v '^set_sim_target' | grep -v '^set_sim_define' | grep -v '^set_clock_period')
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
		# Path compatibility: post_sim runs from post_sim/, so PATTERN needs ../ prefix
		[[ "$SIM_STAGE" == "post_sim" ]] && [[ "${PATTERN}" != ../* ]] && export PATTERN="../${PATTERN}"
		simple_filtered=$(echo "$simple_filtered" | perl -pe 's/\$\(([A-Za-z_][A-Za-z0-9_]*)\)/\${\1}/g')
		simple_filtered=$(echo "$simple_filtered" | envsubst 2>/dev/null || echo "$simple_filtered")
		echo ""
		if [[ "$SIM_STAGE" == "post_sim" ]]; then
			POST_SIM_DIR="$PROJ_ROOT/post_sim"
			if [[ -f "$POST_SIM_DIR/run_batch" ]]; then
				echo ">>> Running post_sim/run_batch (xrun) from $POST_SIM_DIR"
				TMP_MINGU=$(mktemp) && printf '%s\n' "$simple_filtered" > "$TMP_MINGU"
				(cd "$POST_SIM_DIR" && ./run_batch < "$TMP_MINGU")
				rm -f "$TMP_MINGU"
			elif [[ -f "$POST_SIM_DIR/run_gui" ]]; then
				echo ">>> Running post_sim/run_gui (xrun) from $POST_SIM_DIR"
				(cd "$POST_SIM_DIR" && ./run_gui)
			else
				echo "Error: post_sim/run_batch or run_gui not found" >&2
				exit 1
			fi
		elif [[ "$SIM_STAGE" == "gls" ]]; then
			echo ">>> Running: make gls TARGET=$SIM_TARGET < $INPUT_FILE"
			TMP_MINGU=$(mktemp) && printf '%s\n' "$simple_filtered" > "$TMP_MINGU"
			make gls TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" CYCLE="$CLOCK_PERIOD" USER_DEFINES="$SIM_DEFINES" < "$TMP_MINGU"
			rm -f "$TMP_MINGU"
		else
			echo ">>> Running: make sim TARGET=$SIM_TARGET < $INPUT_FILE (comments filtered)"
			TMP_MINGU=$(mktemp) && printf '%s\n' "$simple_filtered" > "$TMP_MINGU"
			make sim TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" CYCLE="$CLOCK_PERIOD" USER_DEFINES="$SIM_DEFINES" < "$TMP_MINGU"
			rm -f "$TMP_MINGU"
		fi
	else
		# Interactive (no file): parse set_* from stdin content
		while IFS= read -r ln; do
			ln=$(echo "$ln" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
			[[ -z "$ln" || "$ln" == \#* ]] && continue
			case "${ln%% *}" in
				set_output_dir) OUTPUT_DIR="${ln#* }" ;;
				set_sim_stage)  SIM_STAGE="${ln#* }" ;;
				set_sim_target) SIM_TARGET="${ln#* }" ;;
				set_sim_define) SIM_DEFINES="${ln#* }" ;;
				set_clock_period) CLOCK_PERIOD="${ln#* }" ;;
			esac
		done <<< "$INPUT_CONTENT"
		echo ""
		if [[ "$SIM_STAGE" == "post_sim" ]]; then
			POST_SIM_DIR="$PROJ_ROOT/post_sim"
			if [[ -f "$POST_SIM_DIR/run_gui" ]]; then
				echo ">>> Running post_sim/run_gui (xrun, interactive) from $POST_SIM_DIR"
				(cd "$POST_SIM_DIR" && ./run_gui)
			else
				echo "Error: post_sim/run_gui not found" >&2
				exit 1
			fi
		elif [[ "$SIM_STAGE" == "gls" ]]; then
			echo ">>> Running: make gls TARGET=$SIM_TARGET (interactive)"
			make gls TARGET="$SIM_TARGET"
		else
			echo ">>> Running: make sim TARGET=$SIM_TARGET (interactive)"
			make sim TARGET="$SIM_TARGET"
		fi
	fi
fi
