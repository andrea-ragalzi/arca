# Local development workflow

## One working folder

Open the same folder containing `project.godot` in Zed and Godot. Keep Godot open for scene editing, asset import, and F5 playtesting; use Zed and its Codex agent for source changes. Work in one folder and use Git commits to keep working checkpoints.

The archive includes no `.git` folder and no remote. Initialize your repository using the README commands, then use your own Git identity. A remote can be added later; local Git already provides history, but a copy on another disk or a remote is needed to protect against disk loss.

## Zed

Project settings already enable `autosave: on_focus_change` and disable automatic formatting. Tasks are in `.zed/tasks.json`; select `task: spawn` from the command palette, then an `ARCA:` task. Run the editor task once; use F5 in that editor for subsequent tests.

Set `GODOT_BIN` in your shell environment if Godot is outside `~/Applications/` and not on PATH. Start Zed from that environment when relying on the variable. The default launchers deliberately use Godot 4.5.1 Standard, Compatibility and X11.

Codex can use `AGENTS.md` and the repository skill under `.agents/skills/arca-godot/`. Discovery depends on the installed agent/ACP adapter; the bootstrap prompt explicitly names both files so the workflow also works without automatic skill discovery. Prompts are ordinary text, not invented Zed slash commands.

## Godot

In **Editor > Editor Settings**, enable **Text Editor > Behavior > Auto Reload Scripts on External Change**. **Interface > Editor > Save on Focus Loss** can help save editor work when switching windows; verify the setting in your own editor because editor preferences are machine-local and are not included in the project.

Always save scenes with Ctrl+S before an agent edits `.tscn` or `.tres` files. Stop the game with F8. After external changes, switch to Godot, wait for import and choose to reload changed scenes from disk. Do not save a stale scene over agent changes. Use Git diff if you are unsure which copy contains your work.

## Daily loop

1. Run `git status --short` and understand existing changes.
2. Stop the game and save scene work.
3. Give the agent one concrete task with a visible acceptance condition.
4. Inspect `git diff --stat` and the relevant file changes.
5. Run `bash scripts/check.sh` after gameplay changes. Do not run another import process during an active Godot import; wait for it to finish.
6. In Godot, press F5 and test the actual player experience.
7. Stage the relevant files and make a checkpoint commit when the result works.

```bash
git switch -c feature/your-change
# Implement, inspect and playtest.
git diff --stat
git add arca/ docs/
git commit -m "Describe the resulting behavior"
```

Inspect `git status` before staging: when a change includes files outside `arca/` or `docs/`, stage those exact paths too. Avoid staging caches or secrets. `.gitignore` excludes `.godot/`, exports, logs, local outputs and `.env` files. Godot `.uid` and source-side `.import` files should remain tracked. The current assets fit normal Git; Git LFS is not required for this tree.

## Commands

| Command | Purpose |
| --- | --- |
| `bash scripts/editor.sh --nvidia` | Open the editor with NVIDIA PRIME offload |
| `bash scripts/run.sh --nvidia` | Import and launch the game directly |
| `bash scripts/check.sh` | Import and run gameplay suites |
| `git status --short --branch` | See branch and working-tree changes |
| `git diff` | Review unstaged text changes |
| `git log --oneline -5` | See recent checkpoints |

Official references: [Zed tasks](https://zed.dev/docs/tasks), [Zed autosave](https://zed.dev/docs/reference/all-settings#autosave), [Codex skills](https://learn.chatgpt.com/docs/build-skills), [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [Godot external editors](https://docs.godotengine.org/en/4.5/tutorials/editor/external_editor.html).
