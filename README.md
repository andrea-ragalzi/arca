# ARCA

A small third-person survival-action game built with **Godot 4.5.1 Standard** and GDScript. The current playable mission is a maintenance-sector blockout: recover a fuse, restore power, survive a predator ambush, and reach the exit. Characters, dinosaur art and environment are temporary. Ammunition is unlimited; saves and persistent inventory are not implemented.

## Start here

1. Extract the archive once into your development folder, for example `~/Projects/ARCA`.
2. Open that entire folder in Zed, and open a terminal there.
3. Run `bash scripts/editor.sh --nvidia`. It finds the portable Godot executable in `~/Applications/` or Godot on your PATH.
4. Wait for import, then press **F5** to play. **F6** runs only the scene currently open in Godot.

If your executable is elsewhere:

```bash
GODOT_BIN="/absolute/path/to/godot" bash scripts/editor.sh --nvidia
```

Use `bash scripts/editor.sh` without `--nvidia` on a computer without NVIDIA offload. The Linux launchers use X11 and the Compatibility renderer, matching the tested Pop!_OS setup.

## Start Git once

If you downloaded a source archive without Git history, initialize Git once in the `ARCA` folder containing `project.godot`. If you cloned an existing repository, skip this step and keep its configured remote. The `arca/` source directory is a normal tracked folder, not a separate repository; do not run `git init` inside it.

```bash
git init -b main
git add .
git commit -m "Initialize ARCA with power restoration and predator ambush"
```

If Git asks for your identity, set your own name and email locally with `git config user.name "Your Name"` and `git config user.email "you@example.com"`, then retry the commit. No GitHub account is required for local history. See [the workflow guide](docs/WORKFLOW.md) for branches and checkpoints.

Keep this same `ARCA` folder for future work. Commits identify changes; folder and project names do not contain release numbers. Godot and upstream dependency versions remain pinned for reproducibility.

## Play the mission

1. Find the yellow **SERVICE / FUSE ACCESS** entrance framed by the starting camera. Enter the corridor, follow the floor stripe and explore around the far screen to find the concealed fuse. Collect it with **E**.
2. Retrace the corridor into the maintenance room and install the fuse at the power panel with **E**.
3. Power returns and the exit opens, but containment fails. Watch the marked **SERVICE HATCH**: a red warning precedes it sliding open, then the existing raptor walks out before normal combat begins.
4. Fight it or evade it and cross the green exit marker. Killing the predator is optional.

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Right mouse / left mouse | Aim / fire while aiming |
| Space | Jump |
| E | Interact with the nearest reachable object |
| R | Restart the whole mission |
| Escape | Pause / resume |
| F3 | Toggle debug telemetry |

### Route and camera playtest

This blockout increment is a route-and-camera experiment, not a new camera controller. From the starting area, the service entrance should be recognizable while the fuse itself remains concealed. The corridor uses a screened alcove, a return sign and the existing third-person spring arm; one inherited crate is repositioned in the mission only to reveal the entrance.

The user accepted the service corridor in an F5 playtest on **2026-10-17**: "The service corridor works in my F5 playtest." The target remains **roughly 10–20 seconds of ordinary walking from fuse to panel**; the automated root-motion route measured **19.6 simulated seconds**, including brief waypoint settling. No human timing measurement was reported.

### Service hatch F5 checklist

1. Restore power and look toward the marked hatch beside the green exit. Check the red warning, visible sliding hatch and raptor walking through the opening, with enough time to react. Movement and camera control remain yours.
2. Evade through the green exit without shooting. Restart and separately check that shooting the emerging/active raptor still works.
3. Pause/resume during opening and walk-out, then restart during the sequence. Check that motion freezes/resumes and restart restores the closed hatch and hidden predator; death/completion must prevent later entrance movement.

The sequence gives a 1.4-second warning, a one-second hatch opening and about 2.3 seconds of collision-aware walk-out before the existing alert/combat flow. Hatch reaction/readability acceptance is pending your F5 playtest; headless checks and staged captures cannot establish game feel.

## Develop with Zed and Godot

The project includes `.zed/settings.json` with save on focus change, plus `.zed/tasks.json` with editor, play, test and Git-status tasks. Open Zed's command palette, run **task: spawn**, and select an **ARCA:** task. Keep one Godot editor instance open on this folder.

Use the bootstrap prompt in [docs/PROMPTS.md](docs/PROMPTS.md) for your first Codex conversation. `AGENTS.md` contains project instructions; `.agents/skills/arca-godot/SKILL.md` contains the optional reusable workflow. If the agent does not discover these automatically, explicitly ask it to read those paths. No custom slash commands or extra MCP server are needed.

Stop the game and save scenes before an agent edits them. Reload external scene changes from disk instead of overwriting them from an old editor tab. Godot auto-reload settings and daily steps are in [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Check the project

```bash
bash scripts/check.sh
```

Requires Godot 4.5.1, Bash, `timeout` (coreutils) and `rg` (ripgrep). It imports assets and runs the actual gameplay/physics suites. Logs go to ignored `.artifacts/test-logs/`. On Pop!_OS, install missing ripgrep with `sudo apt install ripgrep`.

## Understand the code

| File | Responsibility |
| --- | --- |
| `arca/mission_room.tscn` | Main playable scene: service corridor, concealed fuse, panel, exit and physical service-hatch bay |
| `arca/mission_room.gd` | Objectives, inventory, interaction and warned hatch-entrance sequence |
| `arca/enemies/raptor.gd` | Predator state machine, navigation, melee, dormant activation and physical emergence |
| `arca/interactables/` | Reusable interaction points, fuse, panel and sliding door |
| `arca/ui/hud.gd` | Health, objectives, prompts, notices and pause/death/completion panels |
| `arca/player/arca_player.gd` | ARCA health and safe shooting origin around cover |
| `player/`, `enemies/red_robot/` | Adapted official TPS controller and robot test opponent |
| `arca/tests/` | Gameplay integration suites; capture/shadow scripts are optional visual tools |

The mission inherits `raptor_room.tscn`, which inherits `test_room.tscn`; the corresponding scripts mirror that structure. The robot is replaced at runtime. In the mission, the replacement raptor starts dormant; the separate raptor test room still starts with an active predator.

Read [docs/DESIGN.md](docs/DESIGN.md) for scope and [docs/VALIDATION.md](docs/VALIDATION.md) for verified behavior and limits. Credits and licenses are in [ATTRIBUTIONS.md](ATTRIBUTIONS.md), [LICENSE.md](LICENSE.md), and [LICENSE_ARCA.md](LICENSE_ARCA.md).
