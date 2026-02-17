# ECE260B Final Project

Verilog RTL and testbenches for single/dual-core MAC + SFP normalization. Simulated with Icarus Verilog.

## Verification checklist

- [x] MAC array TB (single-core)
- [ ] SFP row TB (single-core)
- [ ] SFP row TB (dual-core)
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
| `sfp_row_dual`   | sfp_row dual-core | filelist_sfp_row_dual       |

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
