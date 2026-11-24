# Local development workflow

## One working folder

Open the same folder containing `project.godot` in Zed and Godot. Keep Godot open for scene editing, asset import, and F5 playtesting. Use Zed's built-in Agent, Codex or Claude Code for source changes. Use Git commits to keep working checkpoints. For several agents at once, give each its own worktree; see [PARALLEL_DEVELOPMENT.md](PARALLEL_DEVELOPMENT.md). The main checkout stays the only folder opened in the Godot editor.

Keep one Git repository at the `ARCA` root containing `project.godot`. The `arca/` source folder belongs to that repository; do not initialize a nested repository there. For a source archive without Git history, initialize Git using the README commands. For an existing clone, keep its history and configured remote. Use your own Git identity; local history needs a separate backup or remote to protect against disk loss.

## Zed

Project settings already enable `autosave: on_focus_change` and disable automatic formatting. Tasks are in `.zed/tasks.json`; select `task: spawn` from the command palette, then an `ARCA:` task. Run the editor task once; use F5 in that editor for subsequent tests.

Set `GODOT_BIN` in your shell environment if Godot is outside `~/Applications/` and not on PATH. Start Zed from that environment when relying on the variable. The default launchers deliberately use Godot 4.5.1 Standard, Compatibility and X11.

The native Zed Agent reads `AGENTS.md` and discovers project skills under `.agents/skills/`; skill loading was verified during setup. The existing `arca-godot` workflow is complemented by focused 3D-pattern, animation-audit, debugging/regression and MCP-editor skills. Prompts are ordinary text, not invented Zed slash commands. See [AI_ENVIRONMENT.md](AI_ENVIRONMENT.md) for the pinned hybridindie Godot MCP, profile safety, installation evidence and manual activation steps. Codex and Claude Code read the same `AGENTS.md` (Claude Code through `CLAUDE.md`) and may work in parallel worktrees. Do not install a second Godot MCP.

## Godot

In **Editor > Editor Settings**, enable **Text Editor > Behavior > Auto Reload Scripts on External Change**. **Interface > Editor > Save on Focus Loss** can help save editor work when switching windows; verify the setting in your own editor because editor preferences are machine-local and are not included in the project.

Always save scenes with Ctrl+S before an agent edits `.tscn` or `.tres` files. Stop the game with F8. After external changes, switch to Godot, wait for import and choose to reload changed scenes from disk. Do not save a stale scene over agent changes. Use Git diff if you are unsure which copy contains your work.

## X11 startup on Wayland desktops

The launchers keep X11, Compatibility rendering and optional NVIDIA offload. Two Godot 4.5.1 issues were reproduced on the Pop!_OS Wayland session:

- The session selected `XMODIFIERS=@im=ibus`, but `ibus address` returned `(null)` and no XIM server was registered. `XOpenIM` then failed, followed by `XCreateIC` warnings. The editor and play launchers now select X11's local input method (`@im=none`) only when this IBus probe confirms the missing service. Running IBus services and other input-method selections are left unchanged. The fallback does not provide IBus composition; start IBus normally if you need it.
- An empty project's embedded F5 game window produced `BadWindow`, opcode `12`, during teardown. Four repeated runs without embedding were clean. In a Wayland session, the editor launcher now adds `--single-window`, which also passed four start/exit cycles with the default embedding preference. This keeps editor dialogs/docks within the main window and makes F5 games run separately; it does not alter the game's window settings. Native X11 sessions retain the previous editor behavior.

Save work, stop the game, close the editor, and relaunch with `bash scripts/editor.sh --nvidia` for these process-local workarounds to take effect. Press F5, then F8, and repeat to check the console for fresh input-method or `BadWindow` messages. Personal Godot settings and system input-method configuration are not modified. Launcher regression checks run with `bash scripts/launcher_test.sh` and as part of `bash scripts/check.sh`.

## Historical project copies

The old `ARCA_Prototipo_*_Linux/` project copies have been removed from the active tree; their tracked contents remain in Git history. Keep future backups outside the project rather than adding duplicate Godot projects or nested Git repositories. `.gitignore` alone does not exclude files from Godot's resource scanner.

Open `.import` metadata and Markdown documentation in Zed, not as Godot resources.

## Daily loop

1. Run `git status --short` and understand existing changes.
2. Stop the game and save scene work.
3. Give the agent one concrete task with a visible acceptance condition.
4. Inspect `git diff --stat` and the relevant file changes.
5. Run `bash scripts/check.sh` after gameplay changes. Do not run another import process during an active Godot import; wait for it to finish. With the editor open, `bash scripts/ai_check.sh` runs that existing gate in an isolated source snapshot; it does not capture unsaved scene buffers.
6. In Godot, press F5 and test the actual player experience.
7. Update your task's own section in `TASK.md`, and the `## Record` in `docs/tasks/<ID>.md` when one exists. Stage them with the relevant files and include them in the same checkpoint commit when the result works.

```bash
git switch -c feature/your-change
# Implement, inspect and playtest.
git diff --stat
git add arca/ docs/ TASK.md
git commit -m "Describe the resulting behavior"
```

Inspect `git status` before staging: when a change includes files outside `arca/` or `docs/`, stage those exact paths too. Avoid staging caches or secrets. `.gitignore` excludes `.godot/`, exports, logs, local outputs and `.env` files. Godot `.uid` and source-side `.import` files should remain tracked. The current assets fit normal Git; Git LFS is not required for this tree.

## Commands

| Command | Purpose |
| --- | --- |
| `bash scripts/editor.sh --nvidia` | Open the editor with NVIDIA PRIME offload |
| `bash scripts/run.sh --nvidia` | Import and launch the game directly |
| `bash scripts/check.sh` | Import and run gameplay suites (ripgrep optional) |
| `git worktree add -b s1/<id>-<slug> ../ARCA-wt/<id> main` | Create an isolated task worktree for a parallel agent |
| `git worktree list` | List active task worktrees |
| `bash scripts/ai_check.sh` | Run the same gate in an isolated source snapshot |
| `bash scripts/ai_check.sh --mcp` | Verify read-only MCP calls against an isolated 4.5.1 editor |
| `git status --short --branch` | See branch and working-tree changes |
| `git diff` | Review unstaged text changes |
| `git log --oneline -5` | See recent checkpoints |

Official references: [Zed tasks](https://zed.dev/docs/tasks), [Zed autosave](https://zed.dev/docs/reference/all-settings#autosave), [Zed skills](https://zed.dev/docs/ai/skills), [Zed MCP](https://zed.dev/docs/ai/mcp), [Godot external editors](https://docs.godotengine.org/en/4.5/tutorials/editor/external_editor.html).
