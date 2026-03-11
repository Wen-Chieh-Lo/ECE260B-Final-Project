# Changelog — 2025-03-10

## tb_utils / core_shell_tb Refactor

- **core_tb alignment**: Updated `core_tb` to follow the same dataflow as `core_shell_tb`, using `LoadAndWriteQ`, `LoadAndWriteK`, `ComputeAndStoreGolden`, and `VerifyPMEMGolden` instead of `LoadPatternData` + `WriteMemToCore` + `VerifyPMEM`.

- **tb_utils cleanup**: Since only `core_shell_tb` uses `tb_utils`, removed all `ifdef` guards and deleted unused tasks: `LoadFromPath`, `VerifyPMEM`, `PrintHelp`, `PrintVerifyHeader`.

- **MapModeToValue task**: Added a task to map mode strings or numeric values (0–7) to `logic [2:0]`, supporting all four modes from `params.v`: `CORE_MODE_MULT_save_to_PMEM`, `CORE_MODE_MULT_NORM_save_to_PMEM`, `CORE_MODE_MULT_NORM_save_to_KMEM`, `CORE_MODE_MULT_NORM_save_to_PMEM_and_KMEM`.

- **PrintHelpShell**: Moved from `core_shell_tb.v` to `tb_utils.v`.

- **LoadAndWriteQ**: Added output parameter `was_vdata` to simplify vdata detection in `core_shell_tb` and avoid duplicated logic.

- **CORE_MODE_MULT_save_to_KMEM**: Removed incorrect define; added support for `CORE_MODE_MULT_NORM_save_to_PMEM` and `CORE_MODE_MULT_NORM_save_to_KMEM` in `MapModeToValue`.
