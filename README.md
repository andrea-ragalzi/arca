# ARCA

A small third-person survival-action game built with **Godot 4.5.1 Standard** and GDScript. The current playable mission is a maintenance-sector blockout: recover a fuse, restore power, survive a predator ambush, and reach the exit. Regina is the playable prototype; character, dinosaur and environment art remain temporary. Ammunition is unlimited; saves and persistent inventory are not implemented.

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

The sequence gives a 1.4-second warning, a one-second hatch opening and about 2.3 seconds of collision-aware walk-out before the existing alert/combat flow. The user confirmed that the service hatch passed this F5 checklist on **2026-10-17**, accepting hatch readability and reaction comfort. The task was closed through documentation only; no gameplay fixes were needed. This acceptance is not a GPU performance measurement.

## Gameplay raptor

The mission and predator test room now use **Ferocious Industries' PBR Velociraptor**, licensed under CC BY 4.0. It replaces the previous visible raptor; it does not add another enemy. The existing AI, collision, health, 20-HP bite, navigation and hatch lifecycle remain unchanged. Its visual wrapper selects Idle_02, Walk, Jog, Bite_02 and Death_01; the source rig and clips remain intact. See [the source/adaptation notes](arca/assets/raptor/ferocious/README.md) and [credits](ATTRIBUTIONS.md).

Press **F5**, restore power and inspect the new raptor emerging from the service hatch. Check its facing, walking/chasing, bite, death, pause and restart. Source contact/material limitations remain visible; this replacement does not resolve Regina's existing quality-gate failures.

## Inspect the Regina character

Press **F5** to play the mission as Regina. Her gameplay model, animation bake and primitive prototype handgun are integrated into the shared ARCA player; the original TPS controller, camera, collision and projectile behavior remain in use. The base `player/player.tscn` remains the unchanged visible-robot reference. For the separate idle/walk/run experiment, open **`arca/character_locomotion_test.tscn`** and press **F6**; it still inherits the static `arca/character_test.tscn` and its inspection lighting, ruler and visual corrections.

**Current F5 locomotion status:** facing and low-hop physics have been corrected. Regina now keeps a camera-forward heading outside aim too, using W forward, S backward and A/D side steps. Her hop measures about **0.324 m / 0.50 s**. However, the TPS-derived lateral poses fail the sole-contact checks (one foot remains at least 6.0–6.6 cm above ground); the full gate is **not passing**, and natural locomotion is not accepted. See `TASK.md` before treating this as complete. The original robot keeps its old turn-to-travel policy and 5 m/s jump.

**Current weapon status:** the handgun now uses a calibrated right-wrist socket, an explicit grip reference and a filtered gameplay-only finger pose. Sampled skin-triangle checks pass for slide/barrel clearance. The full gate remains failing: the TPS-derived upper aim pose still pitches the barrel below neutral, in addition to the existing lateral-foot failures. No 8-way animation replacement or rig/source-clip edit was made; close-up F5 acceptance remains pending.

**F6 controls:** `1` idle, `2` walk, `3` run; `M` switches centered/root-travel playback and resets the lane; `Space` pauses/resumes; `R` restores centered idle; `V` cycles overview/front/side/back. The camera follows travel; the 12 m lane pauses at its end rather than teleporting.

Short **F6 checklist**:

1. Select all three clips. Check human scale against the ruler, -Z facing, and smooth loops/transitions.
2. Cycle views with `V`: inspect planted feet, knee bends, shoulders/hands and attached costume/holster. Some shoulder/costume clipping remains visible during the run; this is not a final character-art acceptance.
3. Press `M` and watch travel against the floor references; check no doubled motion or loop snap. Pause/resume, then reset with `R` while paused.

The source model remains 69 bones, nine materials, 17 textures, approximately 1.799 m tall in reference pose, and **zero authored clips**. The supplied original FBX also has no animation objects/takes. The F6 proof continues to use separately retargeted **Quaternius CC0** idle/walk/run clips and its own derived root-motion proxy. The F5 player uses a separate gameplay library combining those locomotion poses with licensed TPS combat, strafe, aim and jump poses. See [the Regina report](docs/REGINA.md) for sources, mapping, validation and the remaining prototype/visual limits.

## Develop with Zed and Godot

The project includes `.zed/settings.json` with save on focus change, plus `.zed/tasks.json` with editor, play, test and Git-status tasks. Open Zed's command palette, run **task: spawn**, and select an **ARCA:** task. Keep one Godot editor instance open on this folder.

Use the **built-in Zed Agent with the existing ChatGPT subscription**, not an external Codex agent. The bootstrap prompt is in [docs/PROMPTS.md](docs/PROMPTS.md); `AGENTS.md` and `.agents/skills/` provide repository instructions and specialized Godot skills. [docs/AI_ENVIRONMENT.md](docs/AI_ENVIRONMENT.md) records the pinned Godot MCP installation, Zed settings, verified read-only checks and remaining live-editor activation steps. No custom slash-command registry or second Godot MCP is needed.

Stop the game and save scenes before an agent edits them. Reload external scene changes from disk instead of overwriting them from an old editor tab. Godot auto-reload settings and daily steps are in [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Check the project

```bash
bash scripts/check.sh
```

If Godot is already open, use `bash scripts/ai_check.sh` for the same gate in an isolated source snapshot, or `bash scripts/ai_check.sh --mcp` for a read-only MCP/4.5.1 check without touching live scenes. See [the AI environment guide](docs/AI_ENVIRONMENT.md) for logs and the existing local ripgrep fallback.

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

The mission inherits `raptor_room.tscn`, which inherits `test_room.tscn`; the corresponding scripts mirror that structure. All three rooms share the ARCA player scene, which installs Regina at runtime while keeping the inherited robot hidden and inert. The original `player/player.tscn` remains a usable robot reference. In the mission, the raptor starts dormant; the separate raptor test room starts with an active predator.

Read [docs/DESIGN.md](docs/DESIGN.md) for scope and [docs/VALIDATION.md](docs/VALIDATION.md) for verified behavior and limits. Credits and licenses are in [ATTRIBUTIONS.md](ATTRIBUTIONS.md), [LICENSE.md](LICENSE.md), and [LICENSE_ARCA.md](LICENSE_ARCA.md).
