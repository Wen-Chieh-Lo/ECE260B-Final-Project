# High-Performance Attention Engine

An open-source, configurable, and high-performance hardware attention mechanism engine (including MAC Array and Softmax/Normalization SFP Row) implemented in Verilog. This project provides complete RTL, Testbenches, and a physical design flow (Synthesis, PnR, GLS) optimized for the 65nm process.

---

## 📖 Table of Contents
- [Project Overview](#-project-overview)
- [Project Architecture](#-project-architecture)
- [How to Use This Project](#-how-to-use-this-project)
- [Quick Start](#-quick-start)
- [Developer Guide (How to Extend)](#-developer-guide-how-to-extend)
- [Synthesis & PnR Flow](#-synthesis--pnr-flow)
- [Deliverables & Stages](#-deliverables--stages)
- [Waveform & Design Assets](#-waveform--design-assets)

---

## 🌟 Project Overview

This project implements a scalable hardware architecture for the attention mechanism commonly found in Transformer models, consisting primarily of:
1. **MAC Array**: High-throughput Multiply-Accumulate array.
2. **SFP Row (Softmax/Normalization)**: Utilizes an optimized hardware divider (`div_longdiv`) and a tree-adder structure for precise and high-speed normalization.
3. **Core**: Integration of the MAC Array and SFP Row.
4. **Fullchip**: Multi-core integration, including SRAM and control logic.

**Key Achievements**:
Through aggressive repipelining, the critical path was reduced from ~25ns to `< 1ns`, allowing the design to easily meet a 1.2ns clock period in the TSMC 65nm GP process.

---

## 🏗 Project Architecture

```text
├── deliverables/        # Release snapshots for each development stage (symlinked to actual workspaces)
├── workspace/           # Working environments for various project stages
│   ├── Step1/           # Single-core baseline
│   ├── Step2/           # Core + SFP integration
│   ├── Step3_norm/      # Hierarchical / SRAM variants
│   ├── Step4_hier/      # Dual-core / Fullchip PnR
│   └── Alpha/           # Optimized fullchip flow (Step 5/6)
└── (A single workspace typically contains the following standard structure):
    ├── verilog/         # RTL source code
    ├── sim/             # RTL simulation and testbenches
    ├── syn/             # Design Compiler (Synthesis) scripts and reports
    ├── pnr/             # Innovus (Place & Route) scripts and reports
    └── gls/             # Gate-Level Simulation
```

---

## 🚀 How to Use This Project

### Prerequisites
- **Simulation**: Icarus Verilog (`iverilog`) or Cadence Xcelium (`xrun`)
- **Synthesis**: Synopsys Design Compiler (DC)
- **Place & Route (PnR)**: Cadence Innovus
- **Process Node**: TSMC 65nm GP (If using other PDKs, please modify `common.sdc` and library paths)

### 🐚 The `.mingu` Shell (Interactive Simulation)
This project uses a custom scripting shell named **Mingu Shell** to run thousands of testbenches efficiently without recompiling.
👉 **[Read the Mingu Shell Tutorial (sim_shell.sh)](TUTORIAL_MINGU.md)** for detailed usage and syntax.

### Quick Start (RTL Simulation & Synthesis)
Navigate to a specific workspace (e.g., `workspace/Alpha/`) to execute commands.

```bash
# 1. Run fullchip simulation
make sim TARGET=fullchip

# 2. Run simulation for a specific sub-module
make sim TARGET=core

# 3. Execute synthesis (High optimization effort)
make syn TARGET=core

# 4. Execute gate-level simulation (after synthesis or PnR)
make gls TARGET=core

# 5. Parse and print synthesis reports (Area, Power, Timing)
make parse
```

*Note: Default targets and macros can be customized in the `USER_DEFINE_TASK_VARS` file under each workspace.*

---

## 🛠 Developer Guide (How to Extend)

This project was built iteratively from `Step1` to `Alpha`. If you wish to contribute or extend this architecture (e.g., adding new activation functions or a customized SRAM controller), please follow these development guidelines:

### 1. Extending the RTL (`verilog/`)
- Place new modules in `verilog/submodules/` (for small utility modules) or `verilog/` (for major blocks).
- **Repipelining Rule**: This architecture relies on deep pipelining to maintain a 1GHz+ clock. If you add complex combinational logic (such as non-linear functions), **you must split it into multiple pipeline stages**.
- Update the instantiation declarations in top-level modules (e.g., `core.v` or `fullchip.v`).

### 2. Updating File Lists (`sim/filelists/` & `syn/filelists/`)
Whenever you create a new `.v` file:
- Add the file path to the corresponding simulation list (`sim/filelists/filelist_<target>`).
- Add the file path to the corresponding synthesis list (`syn/filelists/filelist_<target>`).

### 3. Creating Testbenches (`sim/tb/`)
- Write a testbench (`tb_<module>.v`).
- Set up output verification logic. **This project has strict timing specifications**:
  - `mac_array`: When `ofifo_rd = 1`, the output is valid in the **same cycle**.
  - `sfp_row`: When `div = 1`, the output is valid about **8 cycles later** (constrained by the latency of `div_longdiv`). Use `sfp_div_lat` and `sfp_acc_lat` parameters in the TB to align your golden outputs.
- Waveforms will automatically be output to `sim/waveform/`.

### 4. Creating New Milestones (Workspaces)
If you are making significant architectural changes:
1. Copy the most stable current workspace (e.g., copy `workspace/Alpha` to `workspace/Beta`).
2. Make your RTL changes in `workspace/Beta/verilog/`.
3. Verify functionality via `make sim` and check synthesis results/timing via `make syn`.
4. Proceed to `workspace/Beta/pnr/` to complete the physical design.

---

## 📈 Synthesis & PnR Flow

### Synthesis
Synthesis is executed via a unified Makefile calling Synopsys DC.
- **Constraints**: Defined in `syn/common.sdc`, with a default clock period of 1ns.
- **Outputs**: Synthesized netlists are saved to `syn/gate/*.out.v`.
- **Reports**: Timing, area, and power reports are located in `syn/log/`. Use `make parse` to view a quick dashboard in the terminal.

### Place and Route (PnR)
PnR is performed using Cadence Innovus.
- Related scripts are located in `pnr/scripts/`.
- **Flow**: Floorplanning -> Power Planning -> Placement -> CTS -> Routing -> Post-Route Optimization.
- **Hierarchical PnR**: `Step3` and `Step4` demonstrate a hierarchical PnR flow, where cores are pre-hardened as macros before top-level routing.

---

## 📦 Deliverables & Stages

We maintain a symlink structure in the `deliverables/` folder, accurately reflecting the state of each Tape-out / milestone. This is highly beneficial for regression testing and CI/CD pipelines.

| Stage (Step) | Scope | Actual Workspace Path | Status / Notes |
|---|---|---|---|
| **Step 1** | Single-core baseline | `workspace/Step1` | Synthesis & PnR Complete. |
| **Step 2** | Core (MAC + SFP) | `workspace/Step2` | Synthesis Complete. No PnR. |
| **Step 3** | Hierarchical PnR | `workspace/Step3_norm` | Cores have been hardened into macros. |
| **Step 4** | Dual-core Fullchip | `workspace/Step4_hier` | Dual-core PnR and top-level integration. |
| **Alpha** (Step5) | Optimized Fullchip | `workspace/Alpha` | Final fully optimized RTL and PnR. |
| **Step 6** | Further Fixes & Optimization | `workspace/Step6` | Advanced optimized RTL and PnR. |

*To verify the integrity of deliverables, please check the audit logs in `deliverables/README.md`.*

---

## 📊 Waveform & Design Assets

The table below compiles the detailed locations of Verilog files, Testbenches (TB), Waveforms (VCD), and Layout Scripts (ENC) for the core across all stages. This is crucial for handovers, debugging, and regression testing.

### Step 1 (Single-core Baseline)
| Category | Type | File Path |
|---|---|---|
| **Behavioural** | Verilog | [`workspace/Step1/verilog/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Step1/verilog) |
| | Pattern | [`workspace/Step1/sim/pattern/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Step1/sim/pattern) |
| | Testbench | [`workspace/Step1/sim/tb/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Step1/sim/tb) |
| | VCD | [`workspace/Step1/sim/waveform/step1.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step1/sim/waveform/step1.vcd) |
| **Post-layout GLS** | Verilog | [`workspace/Step1/post_sim/netlist/core.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step1/post_sim/netlist/core.pnr.v) |
| | Testbench | [`workspace/Step1/gls/tb/step1_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step1/gls/tb/step1_tb.v) |
| | VCD | [`workspace/Step1/gls/waveform/step1.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step1/gls/waveform/step1.vcd) |
| | ENC | [`workspace/Step1/pnr/scripts/route.enc`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step1/pnr/scripts/route.enc) |

### Step 2 (Core + SFP Integration)
| Category | Type | File Path |
|---|---|---|
| **Behavioural** | VCD | [`workspace/Step2/sim/waveform/core.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step2/sim/waveform/core.vcd) |

### Step 3 (Hierarchical PnR)
| Category | Type | File Path |
|---|---|---|
| **Post-layout GLS** | Verilog | [`workspace/Step3_norm/post_sim/netlist/core.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step3_norm/post_sim/netlist/core.pnr.v) <br> [`workspace/Step3_norm/post_sim/netlist/sram_160b_w16.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step3_norm/post_sim/netlist/sram_160b_w16.pnr.v) <br> [`workspace/Step3_norm/post_sim/netlist/sram_w16.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step3_norm/post_sim/netlist/sram_w16.pnr.v) |
| | Testbench | [`workspace/Step3_norm/post_sim/netlist/core_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step3_norm/post_sim/netlist/core_tb.v) |
| | VCD | [`workspace/Step3_norm/gls/waveform/core.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step3_norm/gls/waveform/core.vcd) |
| | ENC | [`workspace/Step3_norm/pnr/hier_pnr/scripts/route.enc`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step3_norm/pnr/hier_pnr/scripts/route.enc) |

### Step 4 (Dual-core Fullchip)
| Category | Type | File Path |
|---|---|---|
| **Behavioural** | Verilog | [`workspace/Step4_hier/verilog/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Step4_hier/verilog) |
| | Pattern | [`workspace/Step4_hier/sim/pattern/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Step4_hier/sim/pattern) |
| | Testbench (Non-lockstep) | [`workspace/Step4_hier/sim/tb/fullchip_sepclk_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/sim/tb/fullchip_sepclk_tb.v) |
| | VCD (Non-lockstep) | [`workspace/Step4_hier/sim/waveform/fullchip_sepclk.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/sim/waveform/fullchip_sepclk.vcd) |
| | Testbench (Lockstep) | [`workspace/Step4_hier/sim/tb/fullchip_lockstep_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/sim/tb/fullchip_lockstep_tb.v) |
| | VCD (Lockstep) | [`workspace/Step4_hier/sim/waveform/fullchip_lockstep.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/sim/waveform/fullchip_lockstep.vcd) |
| **Post-layout GLS** | Verilog | [`workspace/Step4_hier/post_sim/netlist/core.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/core.pnr.v) <br> [`workspace/Step4_hier/post_sim/netlist/fullchip.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/fullchip.pnr.v) <br> [`workspace/Step4_hier/post_sim/netlist/sram_w16.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/sram_w16.pnr.v) <br> [`workspace/Step4_hier/post_sim/netlist/sram_160b_w16.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/sram_160b_w16.pnr.v) |
| | Testbench | [`workspace/Step4_hier/post_sim/netlist/core_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/core_tb.v) <br> [`workspace/Step4_hier/post_sim/netlist/fullchip_lockstep_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/fullchip_lockstep_tb.v) <br> [`workspace/Step4_hier/post_sim/netlist/fullchip_sepclk_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/post_sim/netlist/fullchip_sepclk_tb.v) |
| | VCD | [`workspace/Step4_hier/gls/waveform/fullchip_lockstep_tb.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/gls/waveform/fullchip_lockstep_tb.vcd) <br> [`workspace/Step4_hier/gls/waveform/fullchip_sepclk.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/gls/waveform/fullchip_sepclk.vcd) |
| | ENC | [`workspace/Step4_hier/pnr/core_pnr/scripts/route.enc`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step4_hier/pnr/core_pnr/scripts/route.enc) <br> [`workspace/Step4_hier/pnr/core_pnr/scripts/route.enc.dat/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Step4_hier/pnr/core_pnr/scripts/route.enc.dat) |

### Step 5 / Alpha (Optimized Fullchip)
| Category | Type | File Path |
|---|---|---|
| **Behavioural** | Verilog | [`workspace/Alpha/verilog/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Alpha/verilog) |
| | Pattern | [`workspace/Alpha/sim/pattern/`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/tree/main/workspace/Alpha/sim/pattern) |
| | Testbench | [`workspace/Alpha/sim/tb/fullchip_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/sim/tb/fullchip_tb.v) |
| | VCD | [`workspace/Alpha/sim/waveform/fullchip.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/sim/waveform/fullchip.vcd) |
| **Post-layout GLS** | Verilog | [`workspace/Alpha/post_sim/netlist/fullchip.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/post_sim/netlist/fullchip.pnr.v) |
| | Testbench | [`workspace/Alpha/post_sim/netlist/fullchip_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/post_sim/netlist/fullchip_tb.v) <br> [`workspace/Alpha/post_sim/netlist/fullchip_shell_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/post_sim/netlist/fullchip_shell_tb.v) |
| | VCD | [`workspace/Alpha/gls/waveform/fullchip.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/gls/waveform/fullchip.vcd) |
| | ENC | [`workspace/Alpha/pnr/scripts/route.enc`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Alpha/pnr/scripts/route.enc) |

### Step 6
| Category | Type | File Path |
|---|---|---|
| **Post-layout GLS** | Verilog | [`workspace/Step6/post_sim/netlist/fullchip.pnr.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step6/post_sim/netlist/fullchip.pnr.v) |
| | Testbench | [`workspace/Step6/post_sim/netlist/fullchip_shell_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step6/post_sim/netlist/fullchip_shell_tb.v) <br> [`workspace/Step6/post_sim/netlist/fullchip_tb.v`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step6/post_sim/netlist/fullchip_tb.v) |
| | VCD | [`workspace/Step6/gls/waveform/fullchip.vcd`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step6/gls/waveform/fullchip.vcd) |
| | ENC | [`workspace/Step6/pnr/scripts/route.enc`](https://github.com/Wen-Chieh-Lo/ECE260B-Final-Project/blob/main/workspace/Step6/pnr/scripts/route.enc) |

---
*Maintained by the ECE260B Project Team (UC San Diego).*
