#!/bin/bash
# =============================================================================
# Simulation Shell - ECE260B Final Project
# =============================================================================
# Run from project root:  ./sim_shell.sh   or   make sim-shell
#   ./sim_shell.sh              - interactive mode (stdin)
#   ./sim_shell.sh -f mingu.X   - feed X.mingu to interactive mode
#
# Shell-level commands (before fix_set): set_scope, set_output_dir, set_sim_stage, set_sim_target, set_sim_define, set_clock_period, set_dump_vcd, set <var> <value>
#   set_dump_vcd 0|1|off|on — 0/off: no VCD (compile with -DNO_DUMP_VCD); default 1 (emit waveform)
#   set_clock_period <ns0> [ns1] — fullchip: clk0 / clk1 period in ns (default ns1=ns0); passed as CYCLE/CYCLE1 + H_CYCLE0/H_CYCLE1
#   set_scope: core -> core_shell | fullchip -> fullchip_shell (same as Makefile TARGET)
#   set SCOPE core|fullchip — same as set_scope (optional; use one or the other)
#   set_sim_target: still supported; overrides set_scope (last occurrence wins)
# fix_set: lock settings, compile, start sim. After fix_set, TB commands go to vvp.
# User vars (set VAR value): use $(VAR) in later lines; substituted before passing to vvp.
# If set PATTERN sw/pattern/random<N> and qdata_0.txt is missing, sw/gen_random_patterns.sh runs automatically.
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
CLOCK_PERIOD1=""
SIM_TARGET="fullchip_shell"
FIXED=0
# 1 = dump VCD (default); 0 = compile with NO_DUMP_VCD (no $dumpfile, faster / smaller disk)
DUMP_VCD=1

# Second clock period (ns); empty => same as CLOCK_PERIOD. Half-periods for iverilog: H_CYCLE0/H_CYCLE1.
make_clock_makefile_args() {
	local c1="${CLOCK_PERIOD1:-$CLOCK_PERIOD}"
	local h0 h1
	h0=$(awk -v p="$CLOCK_PERIOD" 'BEGIN{printf "%.9g", p/2}')
	h1=$(awk -v p="$c1" 'BEGIN{printf "%.9g", p/2}')
	echo "CYCLE=$CLOCK_PERIOD CYCLE1=$c1 H_CYCLE0=$h0 H_CYCLE1=$h1"
}

parse_set_clock_period_rest() {
	local rest="$1"
	local p0 p1
	read -r p0 p1 <<< "$rest"
	[[ -n "$p0" ]] && CLOCK_PERIOD="$p0"
	CLOCK_PERIOD1="${p1:-$CLOCK_PERIOD}"
}

# Append NO_DUMP_VCD to iverilog when disabled (see core_shell_tb / fullchip_shell_tb)
dump_vcd_make_suffix() {
	[[ "${DUMP_VCD:-1}" == "0" ]] && echo " NO_DUMP_VCD"
}

parse_set_dump_vcd_rest() {
	local rest="${1#set_dump_vcd}"
	rest="${rest#"${rest%%[![:space:]]*}"}"
	read -r tok <<< "$rest"
	case "$tok" in
		0|off|OFF|false|FALSE|no|NO) DUMP_VCD=0 ;;
		1|on|ON|true|TRUE|yes|YES) DUMP_VCD=1 ;;
		"")
			echo "Error: set_dump_vcd requires 0|1|on|off" >&2
			exit 1
			;;
		*)
			echo "Error: set_dump_vcd: unknown value '$tok' (use 0|1|on|off)" >&2
			exit 1
			;;
		esac
}

# Batch mingu uses set PATTERN sw/pattern/random<N>; data is gitignored. Generate if missing.
ensure_sw_random_patterns() {
	[[ -z "${PATTERN:-}" ]] && return 0
	if [[ ! "$PATTERN" =~ random([0-9]+)$ ]]; then
		return 0
	fi
	local n="${BASH_REMATCH[1]}"
	local marker="${PROJ_ROOT}/${PATTERN}/qdata_0.txt"
	if [[ -f "$marker" ]]; then
		return 0
	fi
	local out_rel="${PATTERN#sw/}"
	echo ">>> [sim_shell] Missing ${PATTERN}/ — running sw/gen_random_patterns.sh (NUM_SETS=${n})" >&2
	( cd "$PROJ_ROOT" && sh sw/gen_random_patterns.sh --bw 8 --pr 8 --col 8 --total_cycle 8 --num_sets "$n" --out_dir "$out_rel" ) || exit 1
}

# Map scope keyword to make TARGET (core_shell | fullchip_shell)
map_scope_to_target() {
	local s="${1%% *}"
	case "$s" in
		core|Core|CORE) SIM_TARGET="core_shell" ;;
		fullchip|Fullchip|FULLCHIP) SIM_TARGET="fullchip_shell" ;;
		*)
			echo "Error: scope must be 'core' or 'fullchip' (got '$1')" >&2
			exit 1
			;;
	esac
}

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
		set_scope)
			map_scope_to_target "$arg"
			;;
		set_sim_define)
			SIM_DEFINES="$arg"
			;;
		set_clock_period)
			parse_set_clock_period_rest "${line#set_clock_period }"
			;;
		set_dump_vcd)
			parse_set_dump_vcd_rest "$line"
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
	if [[ -n "$CLOCK_PERIOD" ]]; then
		args="$args $(make_clock_makefile_args)"
	fi
	[[ -n "$SIM_DEFINES" ]] && args="$args USER_DEFINES=\"$SIM_DEFINES$(dump_vcd_make_suffix)\""
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
			set_scope)      map_scope_to_target "${line#set_scope }" ;;
			set_sim_define) SIM_DEFINES="${line#* }" ;;
			set_clock_period) parse_set_clock_period_rest "${line#set_clock_period }" ;;
			set_dump_vcd) parse_set_dump_vcd_rest "$line" ;;
			set)
				rest="${line#set }"; rest="${rest# }"
				var="${rest%% *}"
				value="${rest#* }"; value="${value# }"
				[[ -n "$var" ]] && export "$var=$value"
				if [[ "$var" == "SCOPE" || "$var" == "scope" ]]; then
					map_scope_to_target "$value"
				fi
				;;
		esac
	done <<< "$content"

	# Collect lines after fix_set (or all TB commands if no fix_set)
	if [[ $found_fix -eq 0 ]]; then
		after_fix=$(echo "$content" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | grep -v '^set_output_dir' | grep -v '^set_sim_stage' | grep -v '^set_sim_target' | grep -v '^set_scope' | grep -v '^set_sim_define' | grep -v '^set_clock_period' | grep -v '^set_dump_vcd' | grep -v '^set ')
	else
		after_fix=$(echo "$content" | awk '/^[[:space:]]*fix_set[[:space:]]*$/{f=1;next}f' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')
	fi

	# Expand for loops (for var = start to end ... endfor) in TB block
	after_fix=$(expand_for_loops "$after_fix")

	# Process "set VAR value" in after_fix (export for envsubst) and remove from output.
	# Do envsubst per-line so loop vars (set i 0; writeQ ...$i...; set i 1; ...) get correct values.
	after_fix_filtered=""
	while IFS= read -r ln; do
		if [[ "$ln" == set\ * ]]; then
			rest="${ln#set }"; rest="${rest# }"
			var="${rest%% *}"
			value="${rest#* }"; value="${value# }"
			[[ -n "$var" ]] && export "$var=$value"
			if [[ "$var" == "SCOPE" || "$var" == "scope" ]]; then
				map_scope_to_target "$value"
			fi
		else
			# Convert $(var) to ${var} for envsubst; unified syntax
			ln_norm=$(echo "$ln" | perl -pe 's/\$\(([A-Za-z_][A-Za-z0-9_]*)\)/\${\1}/g')
			substed=$(echo "$ln_norm" | envsubst 2>/dev/null || echo "$ln_norm")
			after_fix_filtered="$after_fix_filtered$substed"$'\n'
		fi
	done <<< "$after_fix"
	after_fix="$after_fix_filtered"

	ensure_sw_random_patterns

	# Run make (sim or gls) with params; stdin to vvp
	if [[ "$SIM_STAGE" == "gls" ]]; then
		echo "$after_fix" | make gls TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" $(make_clock_makefile_args) USER_DEFINES="$SIM_DEFINES$(dump_vcd_make_suffix)"
	else
		echo "$after_fix" | make sim TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" $(make_clock_makefile_args) USER_DEFINES="$SIM_DEFINES$(dump_vcd_make_suffix)"
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
				set_scope)      map_scope_to_target "${ln#set_scope }" ;;
				set_sim_define) SIM_DEFINES="${ln#* }" ;;
				set_clock_period) parse_set_clock_period_rest "${ln#set_clock_period }" ;;
				set_dump_vcd) parse_set_dump_vcd_rest "$ln" ;;
				set)
					rest="${ln#set }"; rest="${rest# }"
					var="${rest%% *}"
					value="${rest#* }"; value="${value# }"
					[[ -n "$var" ]] && export "$var=$value"
					if [[ "$var" == "SCOPE" || "$var" == "scope" ]]; then
						map_scope_to_target "$value"
					fi
					;;
			esac
		done <<< "$INPUT_CONTENT"
		simple_content=$(echo "$INPUT_CONTENT" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | grep -v '^set_output_dir' | grep -v '^set_sim_stage' | grep -v '^set_sim_target' | grep -v '^set_scope' | grep -v '^set_sim_define' | grep -v '^set_clock_period' | grep -v '^set_dump_vcd' | grep -v '^set ')
		simple_filtered=""
		while IFS= read -r ln; do
			if [[ "$ln" == set\ * ]]; then
				rest="${ln#set }"; rest="${rest# }"
				var="${rest%% *}"
				value="${rest#* }"; value="${value# }"
				[[ -n "$var" ]] && export "$var=$value"
				if [[ "$var" == "SCOPE" || "$var" == "scope" ]]; then
					map_scope_to_target "$value"
				fi
			else
				simple_filtered="$simple_filtered$ln"$'\n'
			fi
		done <<< "$simple_content"
		simple_filtered=$(echo "$simple_filtered" | perl -pe 's/\$\(([A-Za-z_][A-Za-z0-9_]*)\)/\${\1}/g')
		simple_filtered=$(echo "$simple_filtered" | envsubst 2>/dev/null || echo "$simple_filtered")
		ensure_sw_random_patterns
		echo ""
		echo ">>> Running: make sim TARGET=$SIM_TARGET < $INPUT_FILE (comments filtered)"
		echo "$simple_filtered" | make sim TARGET="$SIM_TARGET" OUTPUT_DIR="$OUTPUT_DIR" $(make_clock_makefile_args) USER_DEFINES="$SIM_DEFINES$(dump_vcd_make_suffix)"
	else
		echo ""
		echo ">>> Running: make sim TARGET=$SIM_TARGET (interactive)"
		make sim TARGET="$SIM_TARGET"
	fi
fi
