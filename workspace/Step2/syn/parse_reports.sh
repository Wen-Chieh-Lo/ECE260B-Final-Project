#!/bin/bash
# Parse Design Compiler synthesis reports from syn/log/ and print a summary.
# Usage: ./syn/parse_reports.sh [log_dir]
# Fallback when Python has symbol/version issues on the system.

LOG_DIR="${1:-$(dirname "$0")/log}"

if [[ ! -d "$LOG_DIR" ]]; then
    echo "Error: directory not found: $LOG_DIR"
    exit 1
fi

shopt -s nullglob
designs=("$LOG_DIR"/*_area.rep)
shopt -u nullglob

if [[ ${#designs[@]} -eq 0 ]]; then
    echo "No *_area.rep files found in $LOG_DIR"
    exit 0
fi

for areaf in "${designs[@]}"; do
    name=$(basename "$areaf" _area.rep)
    powerf="$LOG_DIR/${name}_power.rep"
    timingf="$LOG_DIR/${name}_timing.rep"

    # Parse area (Total cell area: 24698.160008)
    cell_area=$(grep "Total cell area:" "$areaf" 2>/dev/null | head -1 | awk '{print $NF}')

    # Parse power (portable: sed/awk, no grep -P)
    dyn_line=$(grep "Total Dynamic Power" "$powerf" 2>/dev/null | head -1)
    leak_line=$(grep "Cell Leakage Power" "$powerf" 2>/dev/null | head -1)
    dyn_val=$(echo "$dyn_line" | sed -n 's/.*=\s*\([0-9.e+-]*\).*/\1/p')
    dyn_unit=$(echo "$dyn_line" | sed -n 's/.*\(mW\|uW\|nW\).*/\1/p')
    leak_val=$(echo "$leak_line" | sed -n 's/.*=\s*\([0-9.e+-]*\).*/\1/p')
    leak_unit=$(echo "$leak_line" | sed -n 's/.*\(mW\|uW\|nW\).*/\1/p')

    # Parse timing
    startpoint=$(grep "Startpoint:" "$timingf" 2>/dev/null | head -1 | sed 's/Startpoint:[[:space:]]*//')
    endpoint=$(grep "Endpoint:" "$timingf" 2>/dev/null | head -1 | sed 's/Endpoint:[[:space:]]*//')
    arrival=$(grep "data arrival time" "$timingf" 2>/dev/null | head -1 | awk '{print $NF}')
    slack_line=$(grep "slack (VIOLATED\|MET)" "$timingf" 2>/dev/null | head -1)
    slack_status=$(echo "$slack_line" | sed -n 's/.*slack (\(VIOLATED\|MET\)).*/\1/p')
    slack_ns=$(echo "$slack_line" | awk '{print $NF}')

    # Box: W=80 chars between | and |, total line 82
    _line() { printf "|  %-33s %44s|\n" "$1" "$2"; }
    _blank() { printf "|%80s|\n" ""; }
    _title() { printf "|%-80s|\n" "  $1"; }

    echo ""
    echo "+--------------------------------------------------------------------------------+"
    printf "|  Design: %-70s|\n" "$name"
    echo "+================================================================================+"
    _blank
    _title "[ Area ]"
    if [[ -n "$cell_area" ]]; then
        _line "Total cell area" "$(printf '%.3f um2' "$cell_area")"
    else
        _line "Total cell area" "N/A"
    fi
    _blank
    _title "[ Power ]"
    if [[ -n "$dyn_val" ]]; then
        _line "Total Dynamic Power" "${dyn_val} ${dyn_unit}"
    else
        _line "Total Dynamic Power" "N/A"
    fi
    if [[ -n "$leak_val" ]]; then
        _line "Cell Leakage Power" "${leak_val} ${leak_unit}"
    else
        _line "Cell Leakage Power" "N/A"
    fi
    _blank
    _title "[ Timing - worst path ]"
    sp_short="${startpoint:0:44}"
    [[ ${#startpoint} -gt 44 ]] && sp_short="...${startpoint: -41}"
    ep_short="${endpoint:0:44}"
    [[ ${#endpoint} -gt 44 ]] && ep_short="...${endpoint: -41}"
    _line "Startpoint" "${sp_short:-N/A}"
    _line "Endpoint" "${ep_short:-N/A}"
    if [[ -n "$arrival" ]]; then
        _line "Data arrival time" "${arrival} ns"
    else
        _line "Data arrival time" "N/A"
    fi
    if [[ -n "$slack_ns" ]]; then
        if [[ "$slack_status" == "VIOLATED" ]]; then
            _line "Slack (VIOLATED)" "[FAIL] ${slack_ns} ns"
        else
            _line "Slack (MET)" "[PASS] $(printf '%+.3f' "$slack_ns") ns"
        fi
    else
        _line "Slack" "N/A"
    fi
    _blank
    echo "+--------------------------------------------------------------------------------+"
done
echo ""
