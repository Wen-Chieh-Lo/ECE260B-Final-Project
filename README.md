# ECE260B Final Project

Verilog RTL and testbenches for single/dual-core MAC + SFP normalization. Simulated with Icarus Verilog.

## Verification checklist

- [x] MAC array TB (single-core)
- [x] SFP row TB (single-core)
- [x] SFP row TB (dual-core)
- [ ] Vproduct verification
- [ ] Core integration
- [ ] Full dual-core flow

## Requirements

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
- Optional: GTKWave (or any VCD viewer) for waveforms

## Build & Run

```bash
make [target]   # default: fullchip
make all        # run all configurations
make help       # list targets
```

| Target          | Config            | filelist (in filelists/)   |
| ---------------- | ----------------- | -------------------------- |
| `fullchip`       | fullchip          | filelist                   |
| `mac`            | mac_array         | filelist_mac               |
| `dual`           | fullchip_dual     | filelist_dual              |
| `sfp_row`        | sfp_row           | filelist_sfp_row           |
| `sfp_row_dual`   | sfp_row dual-core | filelist_sfp_row_dual      |
| `vproduct`       | Vproduct (norm)   | filelist_vproduct          |

Waveforms: `sim/waveform/*.vcd` after each run.

## Layout

- `filelists/` — iverilog filelists per config
- `verilog/` — RTL (core, fullchip, sync, sfp_row, ofifo); `mac_array_top` lives in `sim/tb/mac_array_tb.v` with TB
- `verilog/mac/` — MAC column and array
- `verilog/memory/` — SRAM, FIFO, mux
- `sim/tb/` — testbenches
- `sim/pattern/` — test vectors (kdata, mac_out, norm, etc.)
- `sim/compiled` — iverilog/vvp binary (generated)
- `sim/waveform/` — generated VCD files

## I/O delay spec (for TB result checking)

When to sample RTL outputs to compare against golden. All delays in clock cycles.

| Block           | Assert                        | Sample output for golden compare   |
| --------------- | ----------------------------- | ---------------------------------- |
| **mac_array_top** | `ofifo_rd = 1` (per row)       | `out` valid **same cycle**; sample before next posedge. |
| **sfp_row**       | `div = 1` for one cycle        | `sfp_out` valid **1 cycle after** that posedge; then sample. |

## Discussion

**Choosing the SFP shift to maximize precision**

- In `sfp_row`, the RTL **left-shifts `sfp_in` by `out_shift` then divides by sum** (`(sfp_in << out_shift) / sum_2core`) so that integer division keeps more fractional precision.
- **Trade-off:** A larger `out_shift` gives more effective fractional bits and better accuracy, but the numerator width grows (`bw_psum + out_shift`), increasing divider size and overflow risk; too small a shift hurts quantization.
- Open questions: For given `bw_psum`, sum range, and output width, derive **non-overflow conditions** and **quantization error** to choose a parameterized shift (e.g. tied to `bw_psum` or log2(col)), and validate with TB golden reference.
