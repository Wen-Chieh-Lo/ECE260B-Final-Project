# ECE260B Final Project

Verilog RTL and testbenches for single/dual-core MAC + SFP normalization.

## Verification checklist

- [x] MAC array TB (single-core)
- [x] SFP row TB (single-core)
- [x] SFP row TB (dual-core)
- [x] Core integration
- [ ] MAC repipelining
- [ ] SFP repipelining
- [ ] Full dual-core flow

## Synthesis checklist

All runs below used `SYN_EFFORT=low`; re-run with `SYN_EFFORT=high` for pre-PnR quality results.

- [x] mac_array synthesized (`make syn TARGET=mac SYN_EFFORT=low`)
- [x] sfp_row synthesized (`make syn TARGET=sfp_row SYN_EFFORT=low`)
- [x] core synthesized (`make syn TARGET=core SYN_EFFORT=low`)
- [ ] All timing closed (see results below)

## Quick Start

```bash
make sim                          # simulate fullchip (default)
make sim TARGET=core              # simulate a specific target
make syn                          # synthesize core (default, SYN_EFFORT=high)
make syn TARGET=mac               # synthesize a specific target
make syn TARGET=mac SYN_EFFORT=low  # fast mapping for quick sanity check
make all TARGET=core              # run sim + syn for the same target
make help                         # list all targets and options
```

Default targets and project path can be set in `USER_DEFINE_TASK_VARS` (see that file for details).

## Simulation targets

| TARGET        | Description             | filelist (in sim/filelists/)  |
| ------------- | ----------------------- | ----------------------------- |
| `fullchip`    | fullchip single-core    | `filelist`                    |
| `core`        | single core             | `filelist_core`               |
| `mac`         | mac_array               | `filelist_mac`                |
| `dual`        | fullchip dual-core      | `filelist_dual`               |
| `sfp_row`     | sfp_row single-core     | `filelist_sfp_row`            |
| `sfp_row_dual`| sfp_row dual-core       | `filelist_sfp_row_dual`       |

Waveforms are written to `sim/waveform/*.vcd` after each run.

## Synthesis targets

| TARGET        | top_module  | filelist (in syn/filelists/) | SDC         | Outputs                  |
| ------------- | ----------- | ---------------------------- | ----------- | ------------------------ |
| `core`        | core        | `filelist_core`              | common.sdc  | `gate/core.out.v`        |
| `sfp_row`     | sfp_row     | `filelist_sfp_row`           | common.sdc  | `gate/sfp_row.out.v`     |
| `mac`         | mac_array   | `filelist_mac`               | common.sdc  | `gate/mac_array.out.v`   |

Reports are written to `syn/log/<top>_area.rep`, `<top>_timing.rep`, `<top>_power.rep`.

Run `python3.6 syn/parse_reports.py` to print a formatted summary
(see [Synthesis results](#synthesis-results) at the bottom of this file).

## Project layout

```
verilog/          RTL (core, fullchip, sync, sfp_row, ofifo)
verilog/mac/      MAC column and array
verilog/memory/   SRAM, FIFO, mux
sim/tb/           Testbenches
sim/filelists/    Iverilog filelists (one per simulation target)
sim/pattern/      Test vectors (kdata, mac_out, norm, etc.)
sim/waveform/     Generated VCD files
syn/              Design Compiler scripts (run_dc.tcl, common.sdc)
syn/filelists/    RTL filelists for synthesis (no testbench)
syn/gate/         Synthesized netlist output
syn/log/          Synthesis reports (area, timing, power)
syn/work/         DC intermediate files (alib, logs, .template)
```

Report parser: `syn/parse_reports.py` — run with `python3.6` to summarize all designs in `syn/log/`.

## I/O delay spec (for TB result checking)

When to sample RTL outputs to compare against golden. All delays in clock cycles.

| Block           | Assert                   | Sample output               |
| --------------- | ------------------------ | --------------------------- |
| **mac_array**   | `ofifo_rd = 1` (per row) | `out` valid **same cycle**  |
| **sfp_row**     | `div = 1` for one cycle  | `sfp_out` valid **1 cycle after** |

## Discussion

**Choosing the SFP shift to maximize precision**

- In `sfp_row`, the RTL left-shifts `sfp_in` by `out_shift` then divides by sum (`(sfp_in << out_shift) / sum_2core`) so that integer division keeps more fractional precision.
- **Trade-off:** A larger `out_shift` gives more effective fractional bits and better accuracy, but the numerator width grows (`bw_psum + out_shift`), increasing divider size and overflow risk.
- Open questions: For given `bw_psum`, sum range, and output width, derive non-overflow conditions and quantization error to choose a parameterized shift (e.g. tied to `bw_psum` or `log2(col)`), and validate with TB golden reference.

## Synthesis results

All three designs synthesized with `SYN_EFFORT=low`, clock period 1.2 ns (TSMC 65 nm GP WC).
Run `python3.6 syn/parse_reports.py` to regenerate.

```
+--------------------------------------------------------------------------------+
|  Design: core                                                                  |
+================================================================================+
|                                                                                |
|  [ Area ]                                                                      |
|  Total cell area                    243,526.681 um2                            |
|                                                                                |
|  [ Power ]                                                                     |
|  Total Dynamic Power                53.6901 mW                                 |
|  Cell Leakage Power                 2.7489 mW                                  |
|                                                                                |
|  [ Timing - worst path ]                                                       |
|  Startpoint                         sfp_instance/fifo_inst_int/rd_ptr_reg_0_   |
|  Endpoint                           sfp_instance/sfp_out_sign6_reg_0_          |
|  Data arrival time                  24.794 ns                                  |
|  Slack (VIOLATED)                   [FAIL] -23.688 ns                          |
|                                                                                |
+--------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------+
|  Design: mac_array                                                             |
+================================================================================+
|                                                                                |
|  [ Area ]                                                                      |
|  Total cell area                    116,808.120 um2                            |
|                                                                                |
|  [ Power ]                                                                     |
|  Total Dynamic Power                10.0596 mW                                 |
|  Cell Leakage Power                 1.5810 mW                                  |
|                                                                                |
|  [ Timing - worst path ]                                                       |
|  Startpoint                         col_idx_4__mac_col_inst/key_q_reg_4_       |
|  Endpoint                           out[75] (output port clocked by clk)       |
|  Data arrival time                  2.618 ns                                   |
|  Slack (VIOLATED)                   [FAIL] -1.618 ns                           |
|                                                                                |
+--------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------+
|  Design: sfp_row                                                               |
+================================================================================+
|                                                                                |
|  [ Area ]                                                                      |
|  Total cell area                    53,864.280 um2                             |
|                                                                                |
|  [ Power ]                                                                     |
|  Total Dynamic Power                19.4076 mW                                 |
|  Cell Leakage Power                 667.9583 uW                                |
|                                                                                |
|  [ Timing - worst path ]                                                       |
|  Startpoint                         fifo_inst_int/rd_ptr_reg_0_                |
|  Endpoint                           sfp_out_sign3_reg_0_                       |
|  Data arrival time                  25.034 ns                                  |
|  Slack (VIOLATED)                   [FAIL] -23.926 ns                          |
|                                                                                |
+--------------------------------------------------------------------------------+
```