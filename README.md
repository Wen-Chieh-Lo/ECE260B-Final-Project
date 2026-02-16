# ECE260B Final Project

UCSD ECE260B final project

## Project Structure

- **verilog/** — RTL source files
  - `fullchip.v` / `core.v` — single-core version
  - `fullchip_dual.v` / `core_dual.v` — dual-core version
  - Submodules: MAC array, FIFO, SRAM, SFP normalization, etc.
- **filelist** — file list for compilation
- **\*.txt** — test data (kdata, norm, qdata, vdata, etc.)


## Simulation

- **single port**
    - iverilog -o compiled -c filelist; vvp compiled
- **dual port**
    - iverilog -o compiled_dual -c filelist; vvp compiled_dual

---
*RTL origin: UCSD VVIP Lab (Prof. Mingu Kang). Do not distribute without permission.*
