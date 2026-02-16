# ECE260B Final Project

Verilog RTL and testbenches for single/dual-core MAC + SFP normalization. Simulated with Icarus Verilog.

## Requirements

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
- Optional: GTKWave (or any VCD viewer) for waveforms

## Build & Run

```bash
make [target]   # default: fullchip
make all        # run all configurations
make help       # list targets
```

| Target                  | Config            |
| ----------------------- | ----------------- |
| `filelist`              | fullchip          |
| `filelist_mac`          | mac_col           |
| `filelist_dual`         | fullchip_dual     |
| `filelist_sfp_row`      | sfp_row           |
| `filelist_sfp_row_dual` | sfp_row dual-core |

Waveforms: `sim/waveform/*.vcd` after each run.

## Layout

- `filelists/` — iverilog filelists per config
- `verilog/` — RTL (core, fullchip, sync, sfp_row, ofifo)
- `verilog/mac/` — MAC column and array
- `verilog/memory/` — SRAM, FIFO, mux
- `sim/tb/` — testbenches
- `sim/pattern/` — test vectors (kdata, mac_out, norm, etc.)
- `sim/compiled` — iverilog/vvp binary (generated)
- `sim/waveform/` — generated VCD files
