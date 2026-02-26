#!/usr/bin/env python3.6
"""
Parse Design Compiler synthesis reports from syn/log/ and print a summary.

Usage:
    python3 syn/parse_reports.py [log_dir]

    log_dir  Path to the directory containing *_area.rep, *_power.rep,
             *_timing.rep files.  Defaults to syn/log/ relative to the
             script location.
"""

import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

def parse_area(path):
    text = path.read_text()
    m = re.search(r"Total cell area:\s+([\d.]+)", text)
    return {"total_cell_area": float(m.group(1)) if m else None}


def parse_power(path):
    text = path.read_text()
    dyn  = re.search(r"Total Dynamic Power\s*=\s*([\d.e+\-]+)\s*(mW|uW|nW)", text)
    leak = re.search(r"Cell Leakage Power\s*=\s*([\d.e+\-]+)\s*(mW|uW|nW)",  text)

    def to_mw(val, unit):
        factors = {"mW": 1.0, "uW": 1e-3, "nW": 1e-6}
        return float(val) * factors[unit]

    return {
        "dynamic_mw":   to_mw(*dyn.groups())  if dyn  else None,
        "dynamic_unit": dyn.group(2)           if dyn  else None,
        "leakage_mw":   to_mw(*leak.groups())  if leak else None,
        "leakage_unit": leak.group(2)          if leak else None,
    }


def parse_timing(path):
    text = path.read_text()
    sp  = re.search(r"Startpoint:\s+(.+)",                          text)
    ep  = re.search(r"Endpoint:\s+(.+)",                            text)
    arr = re.search(r"data arrival time\s+([\d.]+)",                text)
    slk = re.search(r"slack \((VIOLATED|MET)\)\s+([-\d.]+)",        text)
    return {
        "startpoint":  sp.group(1).strip()  if sp  else None,
        "endpoint":    ep.group(1).strip()  if ep  else None,
        "arrival_ns":  float(arr.group(1))  if arr else None,
        "slack_ns":    float(slk.group(2))  if slk else None,
        "status":      slk.group(1)         if slk else None,
    }


# ---------------------------------------------------------------------------
# Box printer (pure ASCII)
# ---------------------------------------------------------------------------

W = 82  # total width including the two border chars

def _border(left, fill, right):
    print(left + fill * (W - 2) + right)

def _row(label, value, lw=34):
    content = "  {:<{}} {}".format(label, lw, value)
    pad = W - 2 - len(content)
    print("|" + content + " " * max(pad, 0) + "|")

def _title(text):
    pad = W - 2 - len(text)
    print("|" + text + " " * max(pad, 0) + "|")

def _blank():
    print("|" + " " * (W - 2) + "|")

def _fmt_power(val_mw, orig_unit):
    factors = {"mW": 1.0, "uW": 1e3, "nW": 1e6}
    v = val_mw * factors.get(orig_unit, 1.0)
    return "{:.4f} {}".format(v, orig_unit)


def print_design(name, area, power, timing):
    _border("+", "-", "+")
    _title("  Design: {}".format(name))
    _border("+", "=", "+")

    # Area
    _blank()
    _title("  [ Area ]")
    cell_area = area.get("total_cell_area")
    _row("Total cell area",
         "{:,.3f} um2".format(cell_area) if cell_area is not None else "N/A")

    # Power
    _blank()
    _title("  [ Power ]")
    dyn_mw = power.get("dynamic_mw")
    lk_mw  = power.get("leakage_mw")
    _row("Total Dynamic Power",
         _fmt_power(dyn_mw, power["dynamic_unit"]) if dyn_mw is not None else "N/A")
    _row("Cell Leakage Power",
         _fmt_power(lk_mw, power["leakage_unit"])  if lk_mw  is not None else "N/A")

    # Timing
    _blank()
    _title("  [ Timing - worst path ]")

    def _clip(s, maxlen=W - 22):
        return ("..." + s[-(maxlen - 3):]) if len(s) > maxlen else s

    sp  = timing.get("startpoint")
    ep  = timing.get("endpoint")
    arr = timing.get("arrival_ns")
    slk = timing.get("slack_ns")
    sts = timing.get("status")

    _row("Startpoint",       _clip(sp)  if sp  else "N/A")
    _row("Endpoint",         _clip(ep)  if ep  else "N/A")
    _row("Data arrival time",
         "{:.3f} ns".format(arr)        if arr is not None else "N/A")
    if slk is not None:
        tag = "[FAIL]" if sts == "VIOLATED" else "[PASS]"
        _row("Slack ({})".format(sts), "{} {:+.3f} ns".format(tag, slk))
    else:
        _row("Slack", "N/A")

    _blank()
    _border("+", "-", "+")
    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    script_dir = Path(__file__).resolve().parent
    log_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else script_dir / "log"

    if not log_dir.is_dir():
        print("Error: directory not found: {}".format(log_dir))
        sys.exit(1)

    designs = sorted(
        p.name.replace("_area.rep", "")
        for p in log_dir.glob("*_area.rep")
    )

    if not designs:
        print("No *_area.rep files found in {}".format(log_dir))
        sys.exit(0)

    print()
    for name in designs:
        area_f   = log_dir / "{}_area.rep".format(name)
        power_f  = log_dir / "{}_power.rep".format(name)
        timing_f = log_dir / "{}_timing.rep".format(name)

        area   = parse_area(area_f)     if area_f.exists()   else {}
        power  = parse_power(power_f)   if power_f.exists()  else {}
        timing = parse_timing(timing_f) if timing_f.exists() else {}

        print_design(name,
                     area   or {"total_cell_area": None},
                     power  or {"dynamic_mw": None, "dynamic_unit": None,
                                "leakage_mw":  None, "leakage_unit":  None},
                     timing or {"startpoint": None, "endpoint": None,
                                "arrival_ns": None, "slack_ns":  None,
                                "status":     None})


if __name__ == "__main__":
    main()
