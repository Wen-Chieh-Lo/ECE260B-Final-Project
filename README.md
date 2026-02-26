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

## Requirements

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`) — simulation
- Synopsys Design Compiler (`dc_shell`) — synthesis
- Optional: GTKWave (or any VCD viewer) for waveforms

## Quick Start

```bash
make sim              # simulate fullchip (default)
make sim TARGET=core  # simulate a specific target
make syn              # synthesize core (default)
make syn TARGET=mac   # synthesize a specific target
make all TARGET=core  # run sim + syn for the same target
make help             # list all targets and options
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
```

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
