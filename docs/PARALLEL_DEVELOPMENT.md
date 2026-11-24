# Parallel development with Codex and Claude Code

ARCA supports several AI agents working at the same time. Each one runs in **its own Git worktree on its own branch**. This guide is the reference for that workflow. `AGENTS.md` holds the binding rules; `SPRINT_01.md` holds the current plan.

## Agents and lanes

| Lane | Agent | Scope |
| --- | --- | --- |
| A: systems and integration | Claude Code | Cross-cutting gameplay systems; sole owner of the integration task that edits `arca/mission_room.tscn` and navigation |
| B: predator and gameplay | Codex | Raptor behavior and bounded gameplay features |
| C: isolated content | Either agent | New files only: area blockouts, notes, character reactions |
| D: assets and audio | Either agent, in a separate session | Environment kit, props, atmosphere resources, audio preparation, Blender or Godot asset automation. **Never edits gameplay scripts or room scenes** |
| U: user | User | Approvals, asset-source decisions, F5 acceptance, merges |

The built-in Zed Agent remains supported for single-folder work in the main checkout. All agents follow the same `AGENTS.md`.

## Layout

```
/home/andrea/Workspace/ARCA            main checkout, branch main; live Godot editor and MCP only here
/home/andrea/Workspace/ARCA-wt/<id>    one worktree per task, branch s1/<id>-<slug>
```

Each task has:

- a **brief** in `docs/tasks/<ID>.md` (a self-contained prompt: goal, files, acceptance, checks);
- a **section** in `TASK.md` (status board).

## Create a worktree

```bash
cd /home/andrea/Workspace/ARCA
git worktree add -b s1/02-raptor-reactions ../ARCA-wt/s1-02 main
"$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" --headless --editor --import --path ../ARCA-wt/s1-02
(cd ../ARCA-wt/s1-02 && bash scripts/check.sh)
```

- Every worktree needs its own first import: `.godot/` is ignored and not shared.
- `scripts/check.sh` uses ripgrep when installed and POSIX `grep` otherwise, so a fresh worktree needs no extra tools.
- Ignored inputs in the main checkout are **not** copied. Pass them by absolute path when a brief requires them, for example `/home/andrea/Workspace/ARCA/.artifacts/regina-locomotion/`.

## Rules inside a worktree

1. Work only on the files your brief lists. If you need another file, record why in your `TASK.md` section and keep the edit minimal and function-scoped.
2. **Headless only.** Don't open the Godot editor or connect the Godot MCP from a worktree; both are bound to the main checkout. Use `bash scripts/check.sh` or the individual suites.
3. Only the integration task edits these shared files:
   - `arca/mission_room.tscn`;
   - `arca/mission_navigation.tres` / `arca/raptor_navigation.tres`;
   - the suite list in `scripts/check.sh`;
   - `run/main_scene` in `project.godot` (front-end task only).
4. Generated resources (`gameplay.tres`, baked libraries) have **one owner per sprint**. Regenerate them; never hand-merge them.
5. Prefer extending existing test suites. A new suite file is fine, but list it in your record; the integrator registers it in `check.sh`.

## Task records and documentation

| File | Who edits it | Content |
| --- | --- | --- |
| `TASK.md` | Each branch edits **only its own `## <ID>` section** | Status, branch, latest validation line, blockers |
| `docs/tasks/<ID>.md` | The owning branch, below the `## Record` heading | Implementation notes, changed paths, actual checks, F5 steps, limits |
| `README.md`, `docs/DESIGN.md`, `docs/VALIDATION.md` | Branches append a **self-contained subsection** for player-facing changes; never rewrite shared paragraphs | Consolidated at merge time |
| `docs/archive/` | Nobody (append-only by the user or integrator) | Verbatim history |

Separate sections, with unchanged headings between them, let Git merge parallel edits to `TASK.md` without conflicts. Commit each `TASK.md` section update together with the work it describes.

## Commits, merges and pushes

- Agents commit on their own branch **only when the user authorizes it** (AGENTS.md). Leaving reviewed changes uncommitted in the worktree is fine.
- Merge order is defined in `SPRINT_01.md`. Before merging:
  1. `git rebase main` in the worktree. Conflicts in shared scripts are resolved by the later branch.
  2. Run `bash scripts/check.sh` in the worktree with zero failures.
  3. Get user F5 acceptance for visual tasks.
  4. Merge into `main` from the main checkout, then run the gate on `main`.
- **Never push**, change remotes or force-update `main` from a worktree.
- Remove a merged worktree with `git worktree remove ../ARCA-wt/<id>`, after confirming it has no uncommitted work, and delete the branch with `git branch -d`.

## Checks

| Purpose | Command |
| --- | --- |
| Full gate in the current checkout | `bash scripts/check.sh` |
| One suite | `"$GODOT" --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/<suite>_test.gd` |
| Gate while the main editor is open | `bash scripts/ai_check.sh` (isolated snapshot) |

Headless checks validate logic and physics only. State what actually ran, and give F5 steps for anything visual.
