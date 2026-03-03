## Summary of Today’s Changes

- **Top scope**
  - Renamed `.backup` to `workspace/Step2`, and created `workspace/Step3` as a clean environment for hierarchical PnR. Fixed Step3 to always use its own directory as the project root (`PROJ_ROOT = $(CURDIR)`).

- **Step1**
  - Added `make pnr` to run Innovus from `workspace/Step1/pnr` using `scripts/innovus.tcl`.

- **Step3 – synthesis / GLS**
  - Added SRAM synthesis target `make syn TARGET=sram`; gate netlist is `workspace/Step3/syn/gate/sram_w16.out.v` with reports in `workspace/Step3/syn/log/`.
  - Updated `syn/filelists/filelist_core` so core treats `sram_w16` as a black box.
  - Updated `gls/filelists/filelist_core` to include `verilog/memory/sram_w16.v` with `syn/gate/core.out.v`; `make gls TARGET=core` now passes.

- **Step3 – PNR**
  - Created SRAM-only PnR flow `pnr/sram_pnr` (top `sram_w16`, using `sram_w16.sdc`).
  - Kept hierarchical PnR flow `pnr/hier_pnr` (top `core` with SRAM as a black box); Step3 `Makefile` now provides `make sram_pnr` and `make hier_pnr`.

## Future plan
- Refactor `workspace/Step3/verilog/memory/sram_w16.v` into a dedicated `sram_w8` version.

## Pitfall note
- DC can silently reuse old designs from `syn/work/` and design libraries; if these are not cleaned, modules removed from the current filelist may still be pulled in from previous runs.
