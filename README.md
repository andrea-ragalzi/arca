<div align="center">

# ARCA

**A third-person survival-action demo set aboard Continuity Station.**

Restore power, outthink a pack of predators and reach the evacuation lift with the ammunition you can find.

![Godot 4.5.1](https://img.shields.io/badge/Godot-4.5.1_Standard-478cbf?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/language-GDScript-355570)
![Renderer](https://img.shields.io/badge/renderer-Compatibility-4a6b5d)
![Platform](https://img.shields.io/badge/platform-Linux_(X11)-333333?logo=linux&logoColor=white)
![Code license](https://img.shields.io/badge/code-MIT-2f6f4f)

![Regina faces a Velociraptor breaking out of the service hatch](docs/media/hatch-ambush.jpg)

</div>

---

## Contents

- [Overview](#overview)
- [Screenshots](#screenshots)
- [Features](#features)
- [Getting started](#getting-started)
- [How to play](#how-to-play)
- [Project structure](#project-structure)
- [Quality gate](#quality-gate)
- [Development workflow](#development-workflow)
- [Documentation](#documentation)
- [Project status](#project-status)
- [Credits and licenses](#credits-and-licenses)

## Overview

ARCA is a compact survival-action slice built with **Godot 4.5.1 Standard** and typed GDScript. The player controls **Regina**, a field operative crossing the maintenance sector, security corridor, control office and exit lift of a research station after a containment failure.

Each area combines one environmental task with predator pressure. Ammunition and healing are scarce, every predator can be fought or evaded, and the route can be finished without a single kill. A typical first run lasts **5 to 10 minutes**.

The project grows from the official [Godot Third Person Shooter Demo](https://github.com/godotengine/tps-demo) (tag `4.5-90f2e38`). It keeps the tested TPS movement, camera and shooting, and adds ARCA's mission logic, predator AI, interaction system, character, environments and audio on top. See [docs/UPSTREAM.md](docs/UPSTREAM.md).

> ARCA is a non-commercial fan concept inspired by the *Dino Crisis* series. It is not affiliated with or endorsed by the rights holders of that series. See [docs/DESIGN.md](docs/DESIGN.md) for scope and direction.

## Screenshots

<table>
  <tr>
    <td width="50%"><img src="docs/media/title-screen.jpg" alt="Title screen with New Game, Pack Training, Controls and Quit"></td>
    <td width="50%"><img src="docs/media/maintenance-room.jpg" alt="Regina carries the fuse back to the power panel in the maintenance room"></td>
  </tr>
  <tr>
    <td align="center"><sub><b>Title screen.</b> Start the mission or the Pack Training drill.</sub></td>
    <td align="center"><sub><b>Maintenance room.</b> Recover the fuse and restore power.</sub></td>
  </tr>
  <tr>
    <td><img src="docs/media/security-corridor.jpg" alt="Security corridor with a station log on a crate"></td>
    <td><img src="docs/media/control-office.jpg" alt="Control office with the security keycard on the back workstation"></td>
  </tr>
  <tr>
    <td align="center"><sub><b>Security corridor.</b> Station logs record how the emergency unfolded.</sub></td>
    <td align="center"><sub><b>Control office.</b> Find the keycard, save the run at the terminal.</sub></td>
  </tr>
  <tr>
    <td><img src="docs/media/raptor-pounce.jpg" alt="A Velociraptor pounces towards Regina"></td>
    <td><img src="docs/media/raptor-knockdown.jpg" alt="Regina knocked down by a raptor"></td>
  </tr>
  <tr>
    <td align="center"><sub><b>Pounce.</b> Sidestep the windup with Q + A/D.</sub></td>
    <td align="center"><sub><b>Knockdown.</b> Press Q to break free before the next bite.</sub></td>
  </tr>
  <tr>
    <td><img src="docs/media/pack-training.jpg" alt="Pack Training bay with three Velociraptors"></td>
    <td><img src="docs/media/exit-lift.jpg" alt="Regina enters the B-04 surface transfer lift"></td>
  </tr>
  <tr>
    <td align="center"><sub><b>Pack Training.</b> Three predators that search, flank and call to each other.</sub></td>
    <td align="center"><sub><b>Exit lift.</b> Reach the cabin to complete the mission.</sub></td>
  </tr>
</table>

<sub>Captured in-engine under X11 and the Compatibility renderer on an NVIDIA RTX 3050 Laptop GPU. The scripts that produced them are listed in [Quality gate](#quality-gate).</sub>

## Features

**Mission**

- A connected four-area route: maintenance sector, security corridor, control office and exit lift.
- Objective chain: find a concealed fuse, restore power, recover the security keycard and reach the lift.
- A scripted hatch breach with a 1.4 s warning, a physical sliding hatch and a collision-aware emergence.
- An in-memory checkpoint terminal, readable station logs and a victory/defeat summary showing time, shots, damage and predator outcome.

**Predators**

- Licensed, fully animated Velociraptors with dormant, sleeping and active starts.
- Sight and hearing: gunfire draws the pack to the last audible shot. Breaking line of sight triggers search and flanking.
- Pack coordination: the lead animal gives ground after an attack while a partner closes in. Calls and replies are spatialized.
- Alert roar, interruptible bite windups, staggers with a 1.5 s cooldown, pounces, knockdowns and climbing onto surfaces.

**Player**

- Regina in a field uniform, integrated into the upstream TPS controller with camera-relative movement.
- Vertical pistol aim, lateral footwork, sidestep dodge, break-free, surface jumps, and hit and death reactions.
- Limited economy: 12 rounds loaded, 12 in reserve, a six-round backup sidearm, ammo boxes and medkits.

**Engineering**

- A single interaction contract: one script per interactable, nearest-target selection with reach and line-of-sight checks, and one action per key press.
- Pause, death, restart and completion freeze or cancel every delayed action.
- A headless regression gate of more than 3,000 checks across 20 suites.

## Getting started

### Requirements

| Requirement | Notes |
| --- | --- |
| [Godot 4.5.1 Standard](https://godotengine.org/download/archive/4.5.1-stable/) | The portable Linux binary is discovered in `~/Applications/` or on `PATH`. Do not use a different engine version. |
| Linux with X11 or XWayland | The launchers force X11 and the Compatibility renderer, matching the tested Pop!_OS setup. |
| Bash, coreutils, `grep` | Needed by the launch and check scripts. `ripgrep` is optional. |

### Run the game

```bash
git clone https://github.com/andrea-ragalzi/arca.git ARCA
cd ARCA
bash scripts/editor.sh --nvidia   # open the editor (omit --nvidia without NVIDIA PRIME offload)
```

Wait for the first import to finish, press **F5** and choose **New Game**. To run the game directly without the editor:

```bash
bash scripts/run.sh --nvidia
```

If Godot is installed elsewhere, point the scripts at it:

```bash
GODOT_BIN="/absolute/path/to/godot" bash scripts/editor.sh
```

On Wayland desktops the launchers apply two process-local workarounds for Godot 4.5.1 (input method and embedded game window). See [docs/WORKFLOW.md](docs/WORKFLOW.md#x11-startup-on-wayland-desktops).

## How to play

### Mission walkthrough

1. **Maintenance sector.** Enter the yellow **SERVICE / FUSE ACCESS** corridor framed by the starting camera. Explore behind the far screen to find the concealed fuse, then install it at the power panel.
2. **The breach.** Restored power opens the marked **SERVICE HATCH** and releases a raptor. Fight it or slip through the powered door.
3. **Security corridor.** Find the **CONTROL OFFICE** off the alcove. A sleeping raptor wakes if you linger nearby or fire.
4. **Control office.** Take the keycard from the back workstation. The checkpoint terminal saves the current run in memory.
5. **Exit lift.** Use the keycard on the far door, cross the lift hall and step onto the green marker inside the cabin.

Regina starts with 12 rounds loaded and 12 in reserve. An ammo box supplies 12 rounds and a medkit restores up to 40 HP. Killing predators is optional.

### Pack Training

From the title screen choose **Pack Training** to face three Velociraptors in a dedicated test bay. Use cover to break their line of sight, jump onto desks and platforms with **Space** while moving towards the edge, and practise sidesteps and break-frees. The drill has its own roster and does not affect mission progress.

### Controls

| Input | Action |
| --- | --- |
| <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> / mouse | Move / look |
| Right mouse / left mouse | Aim / fire while aiming |
| <kbd>Space</kbd> | Jump; in Pack Training, move towards a marked edge and jump to climb onto a surface |
| <kbd>Q</kbd> + <kbd>A</kbd>/<kbd>D</kbd> | Sidestep. Press <kbd>Q</kbd> alone while downed to break free |
| <kbd>E</kbd> | Interact with the nearest reachable object, read or close a log |
| <kbd>R</kbd> | Reload |
| <kbd>1</kbd> / <kbd>2</kbd> | Select primary or backup sidearm |
| <kbd>Backspace</kbd> | Restart the mission or drill |
| <kbd>Esc</kbd> | Pause / resume |
| <kbd>F3</kbd> | Toggle debug telemetry |

### Setting

All four interior spaces share one station finish: steel skirting, a grey-green washable band, clinical white walls, a dark resin floor and a 0.60 m panel ceiling at 2.65 m (2.50 m in the security corridor). The control office monitors the habitats and Third Energy; the security recess and freight approach show different traces of the emergency. See the [environment style guide](ENVIRONMENT_STYLE_GUIDE.md).

## Project structure

```text
ARCA/
├── arca/                     ARCA game code, scenes and assets
│   ├── mission_room.tscn/gd  Main mission: objectives, inventory, hatch sequence
│   ├── raptor_room.tscn/gd   Predator test room (parent of the mission)
│   ├── test_room.tscn/gd     Robot test room (root of the room inheritance chain)
│   ├── pack_arena.tscn/gd    Pack Training drill
│   ├── enemies/              Predator state machine, senses, navigation and melee
│   ├── interactables/        Interaction contract, fuse, panel, doors, pickups, logs
│   ├── player/               ARCA player: health, Regina integration, safe shooting origin
│   ├── areas/, components/   Modular environment kit and shared building blocks
│   ├── ui/                   Title screen and HUD
│   ├── audio/                Processed sound cues
│   ├── assets/               Licensed models, animation bakes and source notes
│   ├── tests/                Headless gameplay suites and optional capture scripts
│   └── tools/                Navigation bakes, area builders, asset checks, review captures
├── player/, enemies/         Adapted upstream TPS controller and robot opponent
├── scripts/                  Launchers and the quality gate
└── docs/                     Design, validation, workflow and task records
```

**Scene inheritance.** `mission_room.tscn` inherits `raptor_room.tscn`, which inherits `test_room.tscn`; their scripts follow the same chain. All rooms share the ARCA player scene, which installs Regina at runtime and keeps the upstream robot hidden and inert. In the mission, the hatch predator starts dormant, the corridor predator asleep and the lift predator active.

| File | Responsibility |
| --- | --- |
| `arca/ui/title_screen.tscn` | Project main scene: New Game, Pack Training, Controls, Quit |
| `arca/mission_room.gd` | Objectives, inventory, interaction and the warned hatch-entrance sequence |
| `arca/enemies/raptor.gd` | Predator state machine, navigation, melee, dormant activation and emergence |
| `arca/interactables/interaction_point.gd` | Base class for every interactable (`get_prompt`, `interact`) |
| `arca/ui/hud.gd` | Health, ammunition, objectives, prompts and pause/death/completion panels |
| `arca/player/arca_player.gd` | ARCA health, Regina installation and safe shooting origin around cover |

## Quality gate

```bash
bash scripts/check.sh
```

The gate imports assets, then runs the launcher tests and every gameplay, physics and asset suite headlessly at a fixed 60 FPS: first playable, raptor, mission, ambush, Regina, economy, multiple predators, environment kit, areas, full route, audio, checkpoint, title, predator perception, physical combat, Pack Training, props and audio assets. The last full run reported **3,151 checks and 0 failures**. Logs are written to the ignored `.artifacts/test-logs/`.

If the Godot editor is already open, run the same gate in an isolated snapshot:

```bash
bash scripts/ai_check.sh          # full gate in a source snapshot
bash scripts/ai_check.sh --mcp    # read-only MCP and engine identity check
```

Headless checks verify logic and physics, not visual quality, audio mix or GPU performance. Visual changes are reviewed with in-engine captures (`arca/tests/capture_mission.gd`, `arca/tools/capture_sprint_review.gd`, `arca/tools/review_interiors.gd`) and manual F5 playtests. The checklists are in [docs/PLAYTESTS.md](docs/PLAYTESTS.md).

## Development workflow

- **Rules.** [AGENTS.md](AGENTS.md) holds the binding project rules for people and AI agents alike: protect working code, keep scene inheritance intact, add focused regression checks and track licenses.
- **Editor.** Zed tasks in `.zed/tasks.json` open the editor, run the game, run checks and show Git status. Keep a single Godot editor instance on the main checkout. See [docs/WORKFLOW.md](docs/WORKFLOW.md).
- **AI agents.** Codex, Claude Code and the Zed Agent share `AGENTS.md` and the skills in `.agents/skills/`. The pinned Godot MCP setup is described in [docs/AI_ENVIRONMENT.md](docs/AI_ENVIRONMENT.md).
- **Parallel work.** One Git worktree and branch per task under `../ARCA-wt/<id>`. Worktrees run headless checks only. See [docs/PARALLEL_DEVELOPMENT.md](docs/PARALLEL_DEVELOPMENT.md).
- **Tracking.** [TASK.md](TASK.md) is the status board. Each task has a brief and a record in [docs/tasks/](docs/tasks/README.md). Sprint plans are in [SPRINT_01.md](SPRINT_01.md) and [SPRINT_02.md](SPRINT_02.md).

```bash
git worktree add -b s1/02-raptor-reactions ../ARCA-wt/s1-02 main
"$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" --headless --editor --import --path ../ARCA-wt/s1-02
(cd ../ARCA-wt/s1-02 && bash scripts/check.sh)
```

## Documentation

| Document | Contents |
| --- | --- |
| [docs/DESIGN.md](docs/DESIGN.md) | Direction, current playable slice and scope boundaries |
| [docs/VALIDATION.md](docs/VALIDATION.md) | Verified behavior, automated coverage and known limits |
| [docs/PLAYTESTS.md](docs/PLAYTESTS.md) | Feature notes and manual F5/F6 checklists, with accepted results |
| [docs/REGINA.md](docs/REGINA.md) | Character sources, retargeting, animation bakes and remaining visual limits |
| [ENVIRONMENT_STYLE_GUIDE.md](ENVIRONMENT_STYLE_GUIDE.md) | Station finish, materials, lighting and signage rules |
| [docs/assets/](docs/assets/) | Environment kit, props, audio plan and manifest |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | Local setup, Godot settings and the daily loop |
| [docs/PARALLEL_DEVELOPMENT.md](docs/PARALLEL_DEVELOPMENT.md) | Worktrees, file ownership and merge order |
| [docs/AI_ENVIRONMENT.md](docs/AI_ENVIRONMENT.md) | AI agents, pinned Godot MCP and isolated checks |
| [docs/UPSTREAM.md](docs/UPSTREAM.md) | What is reused from the Godot TPS demo |
| [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) | Sprint baseline audit |
| [docs/archive/](docs/archive/README.md) | Historical task records, kept verbatim |

## Project status

ARCA is a **playable prototype**, not a finished game. The full route, predator AI and combat loop are implemented and covered by the gate. Open items:

- A human free-play review of mood, combat readability, audio mix and FPS during chases.
- Regina remains a prototype integration: some shoulder and costume clipping is visible during runs, and the handgun is placeholder geometry.
- Aiming tight against a wall can clip the arm, a limitation inherited from the upstream arm offset.

Current progress is tracked in [TASK.md](TASK.md).

## Credits and licenses

- **ARCA code and original additions:** MIT, see [LICENSE_ARCA.md](LICENSE_ARCA.md).
- **Upstream TPS demo assets:** CC BY 3.0, Juan Linietsky and Fernando Miguel Calabró. See [LICENSE.md](LICENSE.md).
- **Velociraptor:** "PBR Velociraptor (Animated)" by Ferocious Industries, CC BY 4.0.
- **Regina model:** "DinoCrisisCustom - Regina" by Otherspectre, CC BY 4.0.
- **Animation:** Quaternius Universal Animation Library and Universal Animation Library 2, CC0.
- **Audio:** processed CC0 recordings from Freesound, credited Wikimedia Commons recordings, user-supplied cues and original ARCA synthesis.

The full list of sources, authors, modifications and checksums is in [ATTRIBUTIONS.md](ATTRIBUTIONS.md). Keep these files when redistributing the project.
