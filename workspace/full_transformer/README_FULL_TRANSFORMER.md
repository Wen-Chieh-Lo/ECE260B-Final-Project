# Full Transformer Workspace

This workspace is forked from `workspace/Alpha` and extends the original
dual-core attention accelerator toward a reusable transformer encoder-layer
ASIC prototype.

## Added RTL

- `verilog/transformer/transformer_top.v`
  - New top-level module for the full-transformer direction.
  - Instantiates the Alpha dual-core `fullchip` through `matrix_engine_wrapper`.
  - Exposes model-level status, phase, layer index, and matrix operand requests.
  - Supports `auto_loader_enable` so the scheduler can drive the matrix engine
    through an internal loader instead of relying only on an external testbench.

- `verilog/transformer/transformer_scheduler.v`
  - Sequences one shared matrix engine through:
    - Q projection
    - K projection
    - V projection
    - attention score
    - attention normalization
    - attention-value multiply
    - post-processing
  - Emits `matrix_lhs_sel`, `matrix_rhs_sel`, and `matrix_dst_sel` so a loader
    or future internal buffer system knows which matrices to feed into the
    engine.

- `verilog/transformer/transformer_buffer_bank.v`
  - Adds a small fixed-shape matrix buffer bank for the first prototype.
  - Host can preload rows through `host_wr_en`, `host_wr_buf`, `host_wr_bank`,
    `host_wr_addr`, and `host_wr_data`.
  - Provides LHS/RHS rows to the loader using the scheduler's matrix selectors.

- `verilog/transformer/matrix_loader.v`
  - Converts scheduler matrix requests into the original Alpha fullchip protocol.
  - Automatically performs:
    - set core mode
    - stream RHS rows into KMEM
    - stream LHS rows into QMEM
    - pulse `start0/start1`

- `verilog/transformer/matrix_result_writer.v`
  - Reads PMEM rows back out of the Alpha fullchip after each matrix operation.
  - Quantizes each `bw_psum` column result back down to `bw` bits for the
    prototype buffer format.
  - Writes core0/core1 results into the destination buffer selected by
    `matrix_dst_sel`.

- `verilog/transformer/matrix_engine_wrapper.v`
  - Wraps the existing Alpha `fullchip` as a reusable matrix engine.
  - Keeps the original fullchip load/start/mode interface intact.

- `verilog/transformer/transformer_postproc.v`
  - Adds residual, lightweight normalization, and compact FFN approximation.

## Synthesis Entry

The new synthesis filelist is:

```bash
syn/filelists/filelist_transformer
```

The Makefile now accepts:

```bash
make syn TARGET=transformer
```

On raptor, `dc_shell` is not currently installed, so the current validation is
Yosys elaboration:

```bash
files=$(awk 'NF && $1 !~ /^\/\// {print $1}' syn/filelists/filelist_transformer | tr '\n' ' ')
yosys -Q -p "read_verilog $files; hierarchy -top transformer_top; proc; check"
```

## Simulation Entry

The new top-level control-path testbench is:

```bash
sim/tb/transformer_top_tb.v
```

It preloads simple X/Wq/Wk/Wv rows through the host buffer-bank port, enables
`auto_loader_enable`, starts the model, and checks that the full scheduled
control path reaches `model_done` and produces `model_out_valid`.

Once `iverilog` and `vvp` are available, run:

```bash
make sim TARGET=transformer
```

The expected waveform is:

```bash
sim/waveform/transformer_top.vcd
```

On the current raptor setup, Yosys can still validate the synthesizable RTL, but
it cannot run this event-driven testbench. Install `iverilog`/`vvp`, Verilator,
XSim, VCS, or another Verilog simulator before expecting the testbench to
execute to `PASS`.

## Current RTL Status

The current version can preload matrices into a small internal buffer bank,
automatically feed the shared matrix engine for each scheduled phase, and read
PMEM results back into the destination buffer selected by `matrix_dst_sel`.
