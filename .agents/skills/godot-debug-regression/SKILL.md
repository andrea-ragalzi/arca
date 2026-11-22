---
name: godot-debug-regression
description: Diagnose ARCA Godot 4.5.1 errors, distinguish existing Regina failures from regressions, select headless tests and measure 3D performance appropriately. Use for reproductions, test interpretation and evidence-based debugging rather than speculative gameplay fixes.
---

# Debug with evidence

This is a corrected adaptation of debugging/performance topics in [vl4dt/godot-skills](https://github.com/vl4dt/godot-skills). See `docs/AI_ENVIRONMENT.md` for the reviewed revision and `../LICENSE_GODOT_SKILLS.txt` for its MIT notice. Use `arca-godot` for repository workflow.

1. Capture the existing Git state, exact failing command, engine version and first relevant error before editing. Read `TASK.md` and `docs/VALIDATION.md` for known failures.
2. Separate import/parse failures, runtime exceptions, failed behavior assertions and visual-quality failures. Godot can exit zero while printing a script error; inspect the log, not just the exit status.
3. Reproduce with the smallest existing suite or read-only MCP inspection. Change code only after isolating a cause, then run the focused regression and the existing full gate.
4. Run `bash scripts/check.sh` with the existing real-binary discovery. If the live editor is open, use `bash scripts/ai_check.sh` to check an isolated source snapshot instead of running a competing importer on the live `.godot` cache. This wrapper is documented in `docs/AI_ENVIRONMENT.md`.
5. Keep logs under ignored `.artifacts/`. Preserve failing assertions; never hide errors or broaden tolerances to claim success. The two existing Regina lateral contact failures are not an MCP regression.

## Version-safe diagnostics

- Use `print("value: %s" % value)`, `push_warning()` and `push_error()` for targeted evidence; there is no GDScript `printf()`.
- Prefer `ResourceLoader.load()` for ordinary loads and `load_threaded_request()` / status / get when asynchronous loading is actually needed. Do not copy the Godot 3 `load_interactive()` example.
- Use the editor debugger's Remote tree for running nodes. `get_node()` on the local tree does not magically fetch a remote process's nodes.
- Check lifecycle and teardown: disconnect/free owned resources, stop animations where needed, and account for pause, death, restart and completion in delayed actions.
- Do not install gdUnit4/GUT or another framework for an existing ARCA regression; reuse `arca/tests/` and `scripts/check.sh`.

## Performance

Profile a reproducible workload on the target machine with Compatibility rendering. Separate script/physics time, draw calls, CPU/GPU bottlenecks, memory/resource growth and import/startup costs. Compare before/after at the same resolution, renderer, scene and hardware. Headless fixed-fps time and software-rendered screenshots do not establish GPU frame time or player-perceived smoothness. Do not introduce pooling, MultiMesh, threading or new framework code without a measured bottleneck in the current task.
