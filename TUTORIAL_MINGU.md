# Mingu Shell Tutorial (`sim_shell.sh`)

## 1. What is the Mingu Shell?
The `.mingu` shell is a custom lightweight simulation scripting environment developed for the ECE260B Final Project. It acts as a wrapper around the standard Verilog simulation tools (Icarus Verilog `iverilog` and Cadence Xcelium `xrun`). 

Instead of writing complex and static Verilog testbenches to cycle through hundreds of test patterns, the `.mingu` script allows you to control the testbench interactively. The `sim_shell.sh` script parses `.mingu` files, sets up the Makefile simulation environment, compiles the design, and pipes your runtime commands directly into the simulation via standard input.

## 2. How to Run
You can run a `.mingu` script in any of the workspaces (e.g., `workspace/Alpha/` or `workspace/Step6/`):

```bash
# Execute a mingu script
./sim_shell.sh -f in-n-out100-fullchip.mingu

# Or enter interactive mode
./sim_shell.sh
```

## 3. Script Structure & Syntax
A `.mingu` script is strictly divided into two phases, separated by the `fix_set` command.
1. **Pre-simulation Phase**: Configures the environment (clock, macros, output directory).
2. **Simulation Phase (Testbench Commands)**: Commands that are sent directly to the running Verilog simulation.

### 3.1 Pre-simulation Configuration (Before `fix_set`)
These commands tell `sim_shell.sh` how to invoke the simulation.

| Command | Example | Description |
|---|---|---|
| `set_scope` | `set_scope fullchip` | Sets the simulation target (`core` or `fullchip`). |
| `set_sim_stage` | `set_sim_stage post_sim` | `sim` (RTL), `gls` (Gate-level), or `post_sim` (PnR Netlist). |
| `set_clock_period` | `set_clock_period 1 1.2` | Sets the clock periods for clk0 and clk1 in nanoseconds. |
| `set_dump_vcd` | `set_dump_vcd 0` | `1` to dump VCD (default), `0` to disable for faster runs. |
| `set_sim_define` | `set_sim_define SFP_LONGDIV` | Passes macros to Verilog compilation. |
| `set_output_dir` | `set_output_dir post_sim/waveform` | Directory to save the output VCD. |
| `set` | `set PATTERN sw/pattern/random100` | Sets a variable that can be used later via `$(PATTERN)`. |

**Crucial Step:** `fix_set`  
You **must** call `fix_set` to lock the configurations. Upon reading this command, `sim_shell.sh` will compile the Verilog code and launch the simulator. Everything after `fix_set` is passed to the simulator.

### 3.2 Dynamic Features (Loops and Variables)
The Mingu shell supports variables and a single-level `for` loop to automate testing across multiple datasets.

```text
# Setting and using a variable
set PATTERN sw/pattern/random100
writeQ $(PATTERN)/qdata_0.txt

# For-loop (inclusive range)
for i = 0 to 99
    reset
    writeQ $(PATTERN)/qdata_$(i).txt
    simulate
    verifypmem
endfor
```

### 3.3 Testbench Commands (After `fix_set`)
Once the simulation is running, the following commands are piped into the Verilog string parser (e.g., inside `fullchip_shell_tb.v`).

- `reset`: Triggers a hardware reset.
- `set_exec_target <mode>`: Sets the operational mode (e.g., `CORE_MODE_MULT_save_to_PMEM`, `CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM`).
- `writeQ <file>`, `writeK0 <file>`, `writeV <file>`: Instructs the Verilog testbench to load hexadecimal data from the specified text files into the testbench SRAM buffers.
- `simulate`: Triggers the clock cycles needed for the hardware to process the loaded data.
- `verifypmem`: Instructs the testbench to compare the hardware output inside the PMEM against the golden software data.
- `exit`: Terminates the simulation gracefully.

## 4. Automatic Pattern Generation

A powerful feature of the `sim_shell.sh` script is its ability to automatically generate test patterns if they are missing.

When you define a pattern directory using the `set PATTERN` command, the shell checks if the first test vector (`qdata_0.txt`) exists in that directory. If it doesn't, and the directory name ends with `random<N>` (e.g., `random100`), the shell will automatically invoke the `sw/gen_random_patterns.sh` script to generate exactly `N` sets of patterns.

**Example:**
```text
set PATTERN sw/pattern/random100
```
If `sw/pattern/random100/qdata_0.txt` is not found, `sim_shell.sh` prints:
```bash
>>> [sim_shell] Missing sw/pattern/random100/ — running sw/gen_random_patterns.sh (NUM_SETS=100)
```
And it generates the 100 sets of data automatically before running the simulation.

*(Note: The directory name must strictly follow the `random<N>` format to trigger this feature.)*

---

## 5. Complete Example
Here is a complete `.mingu` script (`in-n-out100-fullchip-gls.mingu`) that runs 100 random tests on the post-layout netlist. If `sw/pattern/random100/` is missing, `sim_shell.sh` will even automatically generate the software patterns.

```text
# 1. Environment Setup
set PATTERN sw/pattern/random100
set_output_dir post_sim/waveform
set_sim_stage post_sim
set_scope fullchip
set_dump_vcd 0
set_clock_period 1 1.2
set_sim_define SFP_LONGDIV SFP_THRESHOLD=169503

# Lock setup and compile
fix_set

# 2. Simulation Execution
for i = 0 to 99
    reset
    
    # Test 1: Q*K^T
    set_exec_target CORE_MODE_MULT_save_to_PMEM
    writeQ $(PATTERN)/qdata_$(i).txt
    writeK0 $(PATTERN)/kdata_$(i).txt
    writeK1 $(PATTERN)/kdata_$(i).txt
    simulate
    verifypmem

    # Test 2: Norm(Q*K^T)
    set_exec_target CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM
    writeQ $(PATTERN)/qdata_$(i).txt
    writeK0 $(PATTERN)/kdata_$(i).txt
    writeK1 $(PATTERN)/kdata_$(i).txt
    simulate
    verifypmem

    # Test 3: V*Norm^T
    set_exec_target CORE_MODE_MULT_save_to_PMEM
    writeQ $(PATTERN)/vdata_$(i).txt
    simulate
    verifypmem
endfor

exit
```
