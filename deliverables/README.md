# Deliverables layout (symlinks)

Each **step** mirrors the design flow: **synthesis (syn)** → **place & route (pnr)** → **gate-level timing sim (gate_sim)**.  
All entries are **symbolic links** into `workspace/` (no file copies).

| Folder | Typical contents (see diagram) |
|--------|--------------------------------|
| `syn/constraints` | SDC / synthesis-related constraints |
| `syn/netlist` | RTL (behavioral Verilog under `verilog/`) |
| `syn/testbench` | `sim/tb/` testbenches |
| `pnr/constraints` | PnR constraints (when present) |
| `pnr/netlist` | Gate-level netlists from DC (`syn/gate/`) |
| `pnr/timingReports` | Post-route timing / power reports (where available) |
| `gate_sim/netlist` | Post-PnR netlists for xrun (`post_sim/netlist/`, e.g. `*.pnr.v`) |
| `gate_sim/constraints` | Symlink to **`pnr/constraints`** (same PnR constraint set; `../pnr/constraints`) |
| `workspace` | Link to the full milestone tree for that step |

## Step → workspace mapping

| Step | Workspace | Notes |
|------|-------------|--------|
| `step1/` | `workspace/Step1` | Single-core baseline |
| `step2/` | `workspace/Step2` | Core + SFP (no top-level `pnr/` / `post_sim` in tree) |
| `step3/` | `workspace/Step3_norm` | Hierarchical / SRAM variants |
| `step4/` | `workspace/Step4_hier` | Dual-core / fullchip PnR |
| `step5/` | **`workspace/Alpha`** | **Alpha = Step 5** (optimized fullchip flow) |

Symlinks use **three** parent segments from `deliverables/stepN/syn|pnr|gate_sim/...` to reach the repo root, e.g.  
`syn/constraints` → `../../../workspace/Step1/pnr/constraints`.  
The top-level `stepN/workspace` link uses **two** segments: `../../workspace/...`.

If links break, regenerate from the repo root (paths are relative to each symlink location).

---

## Verification (audit)

All **41** symbolic links under `step1`–`step5` resolve to existing paths (`readlink -f`).

| Step | Notes |
|------|--------|
| **step1** | Complete: syn / pnr / gate_sim all linked. |
| **step2** | No `post_sim/` in repo → no `gate_sim/netlist` symlink; see `gate_sim/netlist/README.txt`. No top-level `pnr/constraints` in tree → no `gate_sim/constraints`. `pnr/timingReports/` is a placeholder (`README.txt`) because there is no `pnr/scripts/timingReports/`. |
| **step3** | `syn/constraints` and `pnr/constraints` both point to `pnr/hier_pnr/constraints`. `gate_sim/constraints` → `../pnr/constraints`. |
| **step4** | `gate_sim/netlist` → `post_sim/netlist`. `gate_sim/constraints` → `../pnr/constraints` (same as `pnr/constraints`). |
| **step5** (Alpha) | Complete. |
