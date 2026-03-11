#!/bin/sh
#
# gen_random_patterns.sh -- Generate random Q/K/V-style pattern files for Alpha sim.
#
# SPEC
# ----
# - Generates num_sets pattern sets; each set has three files: qdata, kdata, vdata.
# - Format matches workspace/Alpha/sim/pattern (qdata_core0.txt, kdata_core0.txt, vdata_core0.txt):
#   one row per line, values separated by TAB; bw-bit signed [-2^(bw-1), 2^(bw-1)-1].
# - qdata: total_cycle rows x pr cols (Q).
# - kdata: col rows x pr cols (K).
# - vdata: total_cycle rows x pr cols (V^T layout for tb).
#
# USAGE (run from workspace/Alpha/sw)
# -----------------------------------
#   sh gen_random_patterns.sh --bw 8 --pr 8 --col 8 --total_cycle 8 --num_sets 100
#
#   - bw          : bitwidth of each element (e.g. 8 -> range -128..127).
#   - pr          : number of elements per row (sequence length).
#   - col         : number of K rows (K is col x pr).
#   - total_cycle : number of rows for Q and V (time steps).
#   - num_sets    : how many pattern sets to generate (default 100).
#   - out_dir     : output dir relative to script (default pattern/random100).
#
# Output: for each set idx: qdata_0.txt, kdata_0.txt, vdata_0.txt, ... qdata_99.txt, kdata_99.txt, vdata_99.txt
#

set -e

bw=""
pr=""
col=""
total_cycle=""
num_sets=100
out_dir="pattern/random100"

while [ $# -gt 0 ]; do
  case "$1" in
    --bw)          bw="$2";          shift 2 ;;
    --pr)          pr="$2";          shift 2 ;;
    --col)         col="$2";         shift 2 ;;
    --total_cycle) total_cycle="$2"; shift 2 ;;
    --num_sets)    num_sets="$2";    shift 2 ;;
    --out_dir)     out_dir="$2";     shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$bw" ] || [ -z "$pr" ] || [ -z "$col" ] || [ -z "$total_cycle" ]; then
  echo "Usage: $0 --bw 8 --pr 8 --col 8 --total_cycle 8 [--num_sets 100] [--out_dir pattern/random100]" >&2
  exit 1
fi

# resolve output dir relative to script location
script_dir="$(cd "$(dirname "$0")" && pwd)"
dest="${script_dir}/${out_dir}"
mkdir -p "$dest"

echo "[gen_random_patterns] bw=$bw, pr=$pr, col=$col, total_cycle=$total_cycle"
echo "[gen_random_patterns] Generating $num_sets sets (qdata, kdata, vdata each) into $dest"

# bw-bit signed: range = 2^bw, min = -2^(bw-1)
range=1
i=0
while [ $i -lt "$bw" ]; do range=$((range * 2)); i=$((i + 1)); done
min=$((range / 2))
min=$((-min))

# Generate one matrix file: rows x cols, seed for reproducibility
gen_matrix() {
  rows="$1"
  cols="$2"
  seed="$3"
  awk -v range="$range" -v min="$min" -v pr="$cols" -v tc="$rows" -v seed="$seed" '
    BEGIN {
      srand(seed)
      for (r = 0; r < tc; r++) {
        for (c = 0; c < pr; c++) {
          v = int(rand() * range) + min
          if (c > 0) printf " "
          # width 4 is enough for bw<=8; adjust if needed
          printf "%4d", v
        }
        printf "\n"
      }
    }
  '
}

idx=0
while [ $idx -lt $num_sets ]; do
  base="$idx"
  gen_matrix "$total_cycle" "$pr" "$((idx * 3 + 1))" > "${dest}/qdata_${base}.txt"
  gen_matrix "$col"       "$pr" "$((idx * 3 + 2))" > "${dest}/kdata_${base}.txt"
  gen_matrix "$total_cycle" "$pr" "$((idx * 3 + 3))" > "${dest}/vdata_${base}.txt"
  echo "  set $idx: qdata_${base}.txt, kdata_${base}.txt, vdata_${base}.txt"
  idx=$((idx + 1))
done
