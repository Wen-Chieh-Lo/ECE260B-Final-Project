# ECE260B Final Project

Verilog RTL and testbenches for single/dual-core MAC + SFP normalization.

## Project TODO checklist

### Completed
- [x] MAC array TB (single-core)
- [x] SFP row TB (single-core)
- [x] SFP row TB (dual-core)
- [x] Core integration
- [x] SFP repipelining (div_longdiv, sum8_2stage)
- [x] MAC repipelining
- [x] step1 flow (in Step1/ folder: step1.v + step1_tb.v + GLS)
- [x] step1 + core synthesis & GLS (in Step1/ folder)
- [x] Step 2 (core = step1+sfp_row) GLS

### Main steps (planned)

| Step       | Scope                 | GLS     | PnR       | 
|------------|-----------------------|---------|-----------|
| **Step 1** | step1 (in Step1/)     | ✓       | ✓        | 
| **Step 2** | core (step1+sfp_row)  | ✓       | —         |
| **Step 3** | —                     | ✓       | planned   | 
| **Step 4** | —                     | planned | planned   | 
| **Step 5** | —                     | —       | planned   |
| **Step 6** | minor RTL             | —       | tentative |

### GLS by authors

| Step    | Owner                | Deadline          | Dependency |
|---------|----------------------|-------------------|------------|
| Step 1  | Wen-Chieh Lo         | Sat/Sun 11:59pm   | —          |
| Step 2  | Chi-Han Chiu         | Sat 11:59pm       | Step 1     |
| Step 4  | Nikhita Neelakanta   | next Fri max      | Step 2     |

### PnR (vanilla, 13th)

**Owners:** Shreeya Bhonsle, Ming-Yang Wu

- [ ] Step 1 PnR
- [ ] Step 3 PnR
- [ ] Step 4 PnR
- [ ] Step 5 PnR (post-alphas)
- [ ] Step 6 PnR (minor, tentative)

### Alphas (run in parallel with PnR)

| # | Task                                                           | Owner                                           |
|--:|----------------------------------------------------------------|-------------------------------------------------|
| 1 | Minimize WNS (step1 alpha done); add pipelining where suitable | Wen-Chieh Lo, Nikhita Neelakanta, Chi-Han Chiu  |
| 2 | Long Division replace by LUT                                   | Wen-Chieh Lo                                    |
| 5 | Randomise input, increase input coverage                       | b1chiang@ucsd.edu                               |
| 6 | Control Signal                                                 | b1chiang@ucsd.edu                               |
| 7 | Optimized SRAM entry                                           |                                                 |

### Other

- [ ] fullchip protocol + integration
- [ ] SRAM pnr
- [ ] core hierarchy-pnr

**Workflow:** PnR, alphas, and Step 6 can proceed in parallel.

## Synthesis checklist

All runs below used `SYN_EFFORT=low`; re-run with `SYN_EFFORT=high` for pre-PnR quality results.

- [x] mac_array synthesized (`make syn TARGET=mac SYN_EFFORT=low`)
- [x] sfp_row synthesized (`make syn TARGET=sfp_row SYN_EFFORT=low`)
- [x] core synthesized (`make syn TARGET=core SYN_EFFORT=low`)
- [x] step1 synthesized (in Step1/ folder: `cd Step1 && make syn`)
- [x] All timing closed (see results below)

## Quick Start

```bash
make sim                          # simulate fullchip (default)
make sim TARGET=core              # simulate a specific target
make gls TARGET=core              # gate-level sim (gls/tb + syn/gate + PDK)
make syn                          # synthesize core (default, SYN_EFFORT=high)
make syn TARGET=mac               # synthesize a specific target
make syn TARGET=mac SYN_EFFORT=low  # fast mapping for quick sanity check
make all TARGET=core              # run sim + syn for the same target
make parse                        # parse syn/log/*.rep and print summary
make help                         # list all targets and options
```

Default targets, project path, and Verilog defines can be set in `USER_DEFINE_TASK_VARS`:
- `TARGET` — default sim/syn target
- `SYN_EFFORT` — low | medium | high
- `USER_DEFINES` — space-separated macros (e.g. `SFP_LONGDIV`) applied to sim and syn

## Simulation targets

| TARGET        | Description             | filelist (in sim/filelists/)  |
| ------------- | ----------------------- | ----------------------------- |
| `fullchip`    | fullchip single-core    | `filelist`                    |
| `core`        | single core             | `filelist_core`               |
| `mac`         | mac_array               | `filelist_mac`                |
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

Run `make parse` (or `bash syn/parse_reports.sh`) to print a formatted summary.
If Python has symbol/version issues, the shell script works without Python.

## Project layout

```
verilog/          RTL (core, fullchip, sync, sfp_row, ofifo)
verilog/submodules/  div, div_longdiv, sum8, sum8_2stage
verilog/mac/      MAC column and array
verilog/memory/   SRAM, FIFO, mux
sim/tb/           Testbenches
sim/filelists/    Iverilog filelists (one per simulation target)
sim/pattern/      Test vectors (kdata, mac_out, norm, etc.)
sim/waveform/     Generated VCD files
gls/              Gate-level simulation
gls/tb/           GLS testbenches (paths: gls/waveform, gls/pattern)
gls/filelists/   GLS filelists (DUT = syn/gate/*.out.v + PDK)
gls/waveform/     GLS VCD output
gls/pattern/     GLS test vectors
syn/              Design Compiler scripts (run_dc.tcl, common.sdc)
syn/filelists/    RTL filelists for synthesis (no testbench)
syn/gate/         Synthesized netlist output
syn/log/          Synthesis reports (area, timing, power)
syn/work/         DC intermediate files (alib, logs, .template)
syn/parse_reports.sh  Report summary script (no Python needed)
```

Report parser: `make parse` or `bash syn/parse_reports.sh` — summarizes all designs in `syn/log/`.

## I/O delay spec (for TB result checking)

When to sample RTL outputs to compare against golden. All delays in clock cycles.

| Block           | Assert                   | Sample output               |
| --------------- | ------------------------ | --------------------------- |
| **mac_array**   | `ofifo_rd = 1` (per row) | `out` valid **same cycle**  |
| **sfp_row**     | `div = 1` for one cycle  | `sfp_out` valid **~8 cycles after** (div_longdiv latency) |

With `SFP_LONGDIV` defined, the divider uses `div_longdiv` (FSM, ~8 cycles). TBs use `sfp_div_lat` and `sfp_acc_lat` parameters to align sampling.

## Discussion

**Choosing the SFP shift to maximize precision**

- In `sfp_row`, the RTL left-shifts `sfp_in` by `out_shift` then divides by sum (`(sfp_in << out_shift) / sum_2core`) so that integer division keeps more fractional precision.
- **Trade-off:** A larger `out_shift` gives more effective fractional bits and better accuracy, but the numerator width grows (`bw_psum + out_shift`), increasing divider size and overflow risk.
- Open questions: For given `bw_psum`, sum range, and output width, derive non-overflow conditions and quantization error to choose a parameterized shift (e.g. tied to `bw_psum` or `log2(col)`), and validate with TB golden reference.

## Synthesis results

All three designs synthesized with `SYN_EFFORT=high`, clock period 1 ns (TSMC 65 nm GP WC).
Run `make parse` to regenerate the summary.

### Analysis summary

| Design        | Before repipelining                          | After repipelining                    |
|---------------|----------------------------------------------|---------------------------------------|
| **core**      | 243.5k um² · 24.8 ns · VIOLATED (-23.7 ns)   | 175.8k um² (-28%) · 0.95 ns · MET     |
| **mac_array** | 116.8k um² · 2.62 ns · VIOLATED (-1.6 ns)    | 69.5k um² (-40%) · 0.968 ns · MET     |
| **sfp_row**   | 53.9k um² · 25 ns · VIOLATED (-23.9 ns)      | 24.7k um² (-54%) · 0.97 ns · MET      |

**Conclusion:** Repipelining (div_longdiv, sum8_2stage) breaks the critical path from combinational divider/sum into multiple register stages, reducing data arrival from ~25 ns to under ~1 ns and meeting the 1.2 ns clock. Area changes with pipeline registers: core and mac_array shrink due to logic restructuring; sfp_row shrinks significantly as div_longdiv replaces the combinational divider.

#### Before repipelining
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

#### After repipelining
``` 
+--------------------------------------------------------------------------------+
|  Design: core                                                                  |
+================================================================================+
|                                                                                |
|  [ Area ]                                                                      |
|  Total cell area                                                 175820.762 um2|
|                                                                                |
|  [ Power ]                                                                     |
|  Total Dynamic Power                                                 72.0683 mW|
|  Cell Leakage Power                                                   1.2643 mW|
|                                                                                |
|  [ Timing - worst path ]                                                       |
|  Startpoint                               sfp_instance/div0_divisor_fix_reg_10_|
|  Endpoint                                   sfp_instance/div0_remainder_reg_18_|
|  Data arrival time                                                     0.950 ns|
|  Slack (MET)                                                   [PASS] +0.000 ns|
|                                                                                |
+--------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------+
|  Design: mac_array                                                             |
+================================================================================+
|                                                                                |
|  [ Area ]                                                                      |
|  Total cell area                                                  69490.440 um2|
|                                                                                |
|  [ Power ]                                                                     |
|  Total Dynamic Power                                                 18.8235 mW|
|  Cell Leakage Power                                                 584.1715 uW|
|                                                                                |
|  [ Timing - worst path ]                                                       |
|  Startpoint                             col_idx_1__mac_col_inst_query_q_reg_38_|
|  Endpoint                          ...ol_inst_mac_8in_instance_product4_reg_12_|
|  Data arrival time                                                     0.968 ns|
|  Slack (MET)                                                   [PASS] +0.000 ns|
|                                                                                |
+--------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------+
|  Design: sfp_row                                                               |
+================================================================================+
|                                                                                |
|  [ Area ]                                                                      |
|  Total cell area                                                  24698.160 um2|
|                                                                                |
|  [ Power ]                                                                     |
|  Total Dynamic Power                                                 11.9368 mW|
|  Cell Leakage Power                                                 144.8709 uW|
|                                                                                |
|  [ Timing - worst path ]                                                       |
|  Startpoint                                                         sfp_in[151]|
|  Endpoint                                               sum8_inst_s67_r_reg_17_|
|  Data arrival time                                                     0.968 ns|
|  Slack (MET)                                                   [PASS] +0.000 ns|
|                                                                                |
+--------------------------------------------------------------------------------+
``` 
# ECE260B
# ECE260B
