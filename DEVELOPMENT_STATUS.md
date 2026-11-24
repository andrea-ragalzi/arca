# ARCA development status

Audit date: 2026-11-24. Target: a playable **5–10 minute** survival-horror demo in the spirit of Dino Crisis, built on the existing Godot 4.5.1 / GDScript / Compatibility project. The sprint plan built on this audit is in [SPRINT_01.md](SPRINT_01.md).

## Evidence labels

| Label | Meaning |
| --- | --- |
| **[T]** | Verified by an automated suite **run during this audit** (headless, logic and physics only) |
| **[U]** | Accepted by the user in an F5 playtest, as recorded in `TASK.md`/`README.md`. Not re-observed in this audit |
| **[C]** | Confirmed by reading the code only. Not exercised |
| **[A]** | Assumption or inference. Needs verification |

## 1. Repository snapshot

- Branch `main` at `0497430` ("Retarget Regina vertical aim from Quaternius pistol poses"), with `origin/main` configured.
- **24 modified and 9 untracked files are uncommitted.** They contain Phases 2–4, which the user accepted on 2026-11-24: UAL2 lateral walks, limited ammo/reload, ammo box, medkit and the win/death summary. `TASK.md` says "The phase checkpoints remain uncommitted."
- An extra worktree `/home/andrea/Workspace/arca-asset-review/ARCA` is detached at the old commit `305a5cc`. It is stale relative to `main`.
- `.artifacts/` (ignored) holds **2.6 GB**, including nine full `ai-check-*` project snapshots.
- `TASK.md` is **224 KB**: about 780 lines of history from earlier tasks.
- Godot editor was **not running** during the audit, so `scripts/check.sh` was used directly. MCP servers were running, but no live editor bridge was used.

## 2. What actually ran in this audit

Godot `~/Applications/Godot_v4.5.1-stable_linux.x86_64`, `--headless --audio-driver Dummy --fixed-fps 60`.

| Command / suite | Result | Notes |
| --- | --- | --- |
| `bash scripts/check.sh` (first attempt) | **Failed immediately** | `The check command requires timeout (coreutils) and rg (ripgrep).` No `rg` binary exists on the bash PATH (see blocker B2) |
| `bash scripts/check.sh` with `PATH=.artifacts/baseline-tools/ripgrep/usr/bin:$PATH` | **Pass, exit 0, 28 s** | Full gate below |
| launcher | 13 checks, 0 failures | Script stubs, no engine |
| import | Pass | Headless editor import, no errors |
| first_playable | 42 / 0 | TPS controller, robot test room, cover, shooting |
| raptor | 59 / 0 | Ferocious mappings, AI, navigation, bite, death, pause, restart |
| mission | 61 / 0 | Corridor route, fuse, panel, exit, summary |
| ambush | 47 / 0 | Hatch warning, opening, emergence, plus pause/death/restart/completion during each phase |
| regina_player | 378 / 0 | Directional locomotion, sole contact, aim, hop, lifecycle |
| economy | 25 / 0 | Magazine, reload, dry fire, pickups, medkit, restart |
| **Gate total** | **625 checks, 0 failures** | Logs: `.artifacts/test-logs/` |
| `regina_test.gd` (outside the gate) | 93 / 0 | Standalone character inspection scene |
| `regina_locomotion_test.gd` (outside the gate) | 68 / 0 | F6 locomotion lane |
| `shadows_test.gd` (outside the gate) | **Timed out (124) after 120 s** | Expected: it awaits `frame_post_draw`, which never fires headless. Documented as display-only |

**Not verified in this audit:** rendering, materials, lighting, GPU frame rate, audio output, mouse feel, camera comfort, and every visual judgment. These remain **[U]** or open.

## 3. Completed and working systems

| System | Key files | Evidence |
| --- | --- | --- |
| TPS movement, camera, spring arm, jump, aim and fire (upstream demo, adapted) | `player/player.gd`, `player/player_input.gd` | [T] first_playable, regina_player; [U] |
| Regina as the playable character: model, wrist socket, primitive handgun, grip pose, camera-forward directional locomotion, UAL2 lateral walks, vertical aim overlay, 0.32 m hop | `arca/player/arca_player.gd`, `arca/player/regina_*.tscn`, `arca/assets/characters/regina/*.tres` | [T] 378 checks; [U] 2026-11-22/24 |
| Cover-safe shot origin (chest-to-muzzle sweep) | `arca_player.gd:get_shoot_origin` | [T] |
| Health component: damage packets, hit cooldown, single death signal, heal | `arca/components/health_component.gd` | [T] |
| Ammo component: 12-round magazine, 12 reserve, 1.5 s reload, dry fire with automatic reload, pause freezes it, death/completion cancel it | `arca/components/ammo_component.gd` | [T] economy; [U] |
| Interaction: area overlap plus line of sight, nearest target, one action per press, ignores echo | `arca/interactables/interaction_point.gd`, `mission_room.gd` | [T] |
| Mission objective chain: find fuse → install at panel → exit opens → escape | `arca/mission_room.gd/.tscn` | [T] mission; [U] 2026-10-17 |
| Hatch ambush: 1.4 s warning, 1.0 s hatch opening, about 2.3 s physical emergence, then combat. Pause/death/restart/completion handled in every phase | `mission_room.gd:_advance_ambush`, `raptor.gd:emerge_from_hatch` | [T] ambush 47; [U] |
| Raptor AI: WAIT/ALERT/CHASE/WINDUP/ATTACK/RECOVER/DEAD/DORMANT/EMERGE, NavigationAgent3D chase, LOS-gated 20 HP bite, 6 HP | `arca/enemies/raptor.gd/.tscn` | [T] raptor 59; [U] |
| Ferocious Industries raptor visuals (CC BY 4.0) with six baked bindings: idle, walk, jog, bite, death, leap | `arca/enemies/ferocious_model.tscn`, `arca/assets/raptor/ferocious/` | [T]; [U] 2026-11-22 |
| HUD: health bar, damage flash, objective, inventory line, prompt, notices, ammo/reload, pause/death/victory modals with summary (time, shots, damage, predator outcome), F3 telemetry | `arca/ui/hud.gd/.tscn` | [T]; [U] |
| Pause (Esc), restart (Backspace, full scene reload), quit | `test_room.gd`, `hud.gd` | [T] |
| Baked navigation for mission and raptor rooms, with offline bake tools | `arca/tools/bake_*_navigation.gd`, `arca/*_navigation.tres` | [T] (chase works) |
| Validation tooling: `check.sh`, isolated `ai_check.sh` snapshot gate, launcher test, Zed tasks | `scripts/` | [T] (with B2 workaround) |

## 4. Partially implemented systems

| System | What exists | What's missing for the demo |
| --- | --- | --- |
| **Level** | One 22 × 28 m maintenance room plus a service corridor and hatch bay, all in one inherited scene | Only about 1.5–3 minutes of content [A]. No additional rooms, no backtracking loop, and no area separation. The exit vestibule ends at the solid inherited `WallFront` at z = 14 |
| **Inventory** | `has_fuse: bool` plus a text line on the HUD | No key-item set (keycards, codes). DESIGN.md rules out a general inventory framework, so a small key-item list is the right scope |
| **Interactables** | Base `ArcaInteractionPoint`, fuse, power panel, ammo box, medkit, scripted sliding door | `mission_room.gd` hard-codes the candidate list `[fuse, panel, ammo_pickup, medkit_pickup]` and an `if/elif` dispatch. Pickup amounts (`12`, `40`) are literals in the mission script. Doors can't be locked or player-operated |
| **Enemies** | One raptor per room | `test_room.gd`, `raptor_room.gd`, `hud.bind()`, `_on_enemy_destroyed`, `get_mission_summary` and `stop_combat` calls all assume **one `enemy`**. The group `arca_predator` already exists but isn't used for lifecycle |
| **Raptor behavior** | Chase and bite only | No hit reaction or stagger (the source has `Hurt_01/02` and `Knocked Down`), no roar (`Roar_01–03`), no sleeping/idle-patrol encounter (`Sleep_Loop`, `Wake From Sleep`, `Sniff`), no lose-track or return behavior. Bullets do 1 damage with no visual feedback on the dinosaur |
| **Regina feedback** | Camera shake and HUD flash on damage | On death the `AnimationTree` is just disabled, so **Regina freezes in her last pose** [C]. There's no hit reaction and no reload animation. Pinned CC0 UAL clips exist for all three (section 6) |
| **Audio** | `pickup.wav`, `power.wav`, gun shot/step/jump/land, robot sounds | **No raptor sounds at all** (no roar, bite, footsteps or hurt). No ambience, door or alarm loops. This matters a lot for horror |
| **Progress** | Full scene reload on restart or death | No checkpoint. Dying at minute 8 would restart a 10-minute demo from zero |
| **Front end** | Main scene boots straight into the mission | No title or start screen, and no "demo complete" credits screen beyond the victory modal |
| **Narrative** | HUD notices only | No readable files or terminals. Regina/Dylan/Paula setting exists only in DESIGN.md |

## 5. Bugs, risks and technical blockers

No functional regression reproduced: the whole gate is green. The issues below block or slow the demo and parallel development. Severity: **P0** must fix before parallel work, **P1** must fix within Sprint 01, **P2** later.

| ID | Severity | Issue | Evidence | Fix direction |
| --- | --- | --- | --- | --- |
| B1 | ~~P0~~ **Resolved** (commit `90ae020`) | Accepted Phases 2–4 are **uncommitted**. `git worktree add` branches from `0497430`, so every worktree would **lack ammo, medkit, reload, summary and the UAL2 strafe**, and would diverge from F5-accepted behavior | `git status`, `TASK.md` | User-approved checkpoint commit (or commits) of the current tree, including `TASK.md`, before creating any worktree |
| B2 | ~~P0~~ **Resolved** (`check.sh` falls back to `grep`; ripgrep is also now installed system-wide) | `scripts/check.sh` fails without a system `rg`. Only `ai_check.sh` adds the local fallback, and that fallback lives in ignored `.artifacts/`, so **it won't exist in new worktrees** | First gate run failed; `docs/AI_ENVIRONMENT.md:117` | Install ripgrep (`sudo apt install ripgrep`) on the machine, or make `check.sh` fall back to `grep -E`. Either way every worktree can run the gate |
| B3 | ~~P0~~ **Resolved** (history in `docs/archive/TASK_HISTORY.md`; per-task board) | `TASK.md` is 224 KB of history, and AGENTS.md requires updating it in the same commit as each task. Two parallel branches will **always conflict on TASK.md**, and every agent pays the context cost of reading it | `wc -c TASK.md` | Move history to `docs/archive/TASK_HISTORY.md`. Keep TASK.md as a short sprint board where each task owns one row or block (see SPRINT_01 protocol) |
| B4 | P1 | Single-enemy architecture (see section 4) | `test_room.gd:5,14-17`, `mission_room.gd:get_mission_summary` | Lifecycle over group `arca_predator`, keeping `enemy` as the primary ambush predator for backward compatibility |
| B5 | P1 | Hard-coded interaction list and dispatch in `mission_room.gd`. Every new pickup or door edits the same function, so it **conflicts across parallel branches** | `mission_room.gd:_find_interaction_target`, `try_interact` | Group-based discovery plus a polymorphic `interact()` on each point |
| B6 | P1 | `mission_room.tscn` and `mission_navigation.tres` are single shared files. Parallel scene edits are not mergeable in practice | Inheritance chain test → raptor → mission | New geometry goes into separate area sub-scenes. Only the integrator instances them and rebakes navigation |
| B7 | P1 | Extending the map requires opening the inherited `WallFront` (z = 14, defined in `test_room.tscn`). Editing it in the base would change the robot and raptor test rooms | `test_room.tscn:487` | Override in `mission_room.tscn` only (hide the mesh, disable the collision, add mission-local wall segments), then re-run the first_playable and raptor suites |
| B8 | P1 | Regina freezes on death. That reads as a bug in a horror demo | `arca_player.gd:_on_died` | Play the UAL `Death01` clip before disabling the tree |
| B9 | ~~P2~~ **Resolved** (AGENTS.md, README, `docs/PARALLEL_DEVELOPMENT.md`) | Docs say "use the built-in Zed Agent, not an external Codex agent" (`README.md`, `AGENTS.md`), which contradicts the new Codex + Claude Code worktree plan | README "Develop with Zed and Godot" | Update the AI tooling docs once the user confirms the workflow |
| B10 | P2 | `shadows_test.gd` hangs forever headless (no internal timeout) | This audit | Leave it outside the gate. Optionally add a `DisplayServer.get_name() == "headless"` early exit |
| B11 | P2 | 2.6 GB of `.artifacts/` and a stale `arca-asset-review` worktree | `du`, `git worktree list` | See section 10. Nothing has been deleted |
| B12 | P2 | Each new worktree needs its own first Godot import (`.godot/` isn't shared) [A: about 1–3 min] | — | Run `godot --headless --editor --import --path <wt>` once per worktree before testing |

**Lower-risk code observations [C]:** after first sight, the raptor chases forever and never gives up. Bullets do a flat 1 damage, with a 0.15 s raptor hit cooldown against the 0.4 s fire cooldown, so no shots are lost. The medkit prompt is offered at full health and correctly refuses. None of these break the current mission.

## 6. Assets you can reuse immediately

All of these are already in the repo, licensed and attributed unless noted otherwise.

| Asset | Location | License | Immediate use |
| --- | --- | --- | --- |
| Regina model plus baked gameplay library (idle, run, strafe ×3, aim up/down, TPS combat/jump poses) | `arca/assets/characters/regina/` | Model "DinoCrisisCustom - Regina" by Otherspectre, CC BY 4.0; animations CC0 UAL plus CC BY 3.0 TPS-demo poses | Protagonist, as-is |
| **Ferocious raptor: 25 source clips**, six baked so far | `arca/assets/raptor/ferocious/source/scene.gltf` | CC BY 4.0 | **Unused, ready to bake:** `Hurt_01`, `Hurt_02`, `Knocked Down`, `Roar_01–03`, `Call_Alert`, `Sniff`, `Sleep_Loop`, `Go to Sleep`, `Wake From Sleep`, `Eat Prey`, `Tackle`, `Sprint`, `Death_02`, `Leap_02`. Covers stagger, alert roar, sleeping-raptor encounter, feeding-raptor scare and a second death |
| Quaternius UAL Standard (pinned SHA, CC0), full library | Pinned public mirror (README in `regina/source/`). A local copy exists only in ignored `.artifacts/regina-locomotion/` | CC0 | **`Death01`, `Hit_Chest`, `Hit_Head`, `Pistol_Reload`, `Pistol_Shoot`, `Interact`, `PickUp_Table`**, crouch, roll. Same rig mapping already used by `extract_locomotion.py` and the bake scripts |
| Old Quaternius velociraptor FBX | `arca/assets/raptor/source/Velociraptor.fbx` (gdignored) | CC0 | Fallback or second dinosaur silhouette (not imported) |
| Interactable scenes: fuse, power panel, ammo box, medkit, sliding door | `arca/interactables/` | Project | Templates for keycard, terminal and locked door |
| Hatch sequence (warning light, sliding leaf, emergence) | `mission_room.gd/.tscn` | Project | Reusable pattern for vent or ceiling ambushes |
| Primitive environment kit: walls, ribs, light strips, cover blocks, floor seams, signage `Label3D`, materials | `arca/test_room.tscn` sub-resources | Project | Copy into area blockouts for a consistent cold-industrial look |
| Audio: `pickup.wav`, `power.wav`, `shoot.wav`, `step.wav`, robot `charge/hit/explosion/walk.wav` | `arca/audio/`, `player/audio/`, `enemies/red_robot/audio/` | ARCA sounds MIT (original synthesized); TPS-demo sounds per ATTRIBUTIONS (CC BY 3.0) | Robot `charge` could serve as an alarm and `walk` as a door servo, pitched |
| HUD modal and notice system | `arca/ui/` | Project | Notes and terminal text, title and end panels |
| Red robot enemy (laser, parts, effects) | `enemies/red_robot/` | Upstream | Not Dino-Crisis-themed. Keep only as the test reference |

**Not available:** dinosaur sounds, ambience, environment art meshes, readable-document UI and a second human character. Audio needs a new sourced pack (CC0 preferred). That's a user-approved acquisition (SPRINT_01 S1-09).

## 7. Gap to a 5–10 minute demo

A plausible demo route, built from existing parts plus Sprint 01 work:

| Segment | Content | Estimated time [A] |
| --- | --- | --- |
| Maintenance room and service corridor (existing) | Fuse, ammo, panel, hatch ambush | 2–3 min |
| Security corridor (new) | Sleeping raptor, stealth or fight, locked door | 1–2 min |
| Control office (new) | Keycard, medkit, terminal note, checkpoint | 1–2 min |
| Backtrack plus a second ambush (new) | Raptor follows into the corridor | 1–2 min |
| Exit lift (new) | Final encounter, escape, end screen | 1 min |

Minimum systems to reach that: multiple areas, key items with a locked door, multiple predators, a raptor hit reaction, raptor audio, Regina death/hit animation and one in-memory checkpoint. Graphical polish isn't required.

## 8. Readiness for parallel development

**Ready once P0 is fixed:** small composed scenes, components wired by signals, deterministic headless suites (28 s full gate), an isolated snapshot gate, and clear inheritance.

**Conflict hotspots:**

| File | Why it conflicts | Rule |
| --- | --- | --- |
| `arca/mission_room.tscn`, `arca/mission_navigation.tres` | Single inherited scene and single navigation bake | Integrator only (S1-10) |
| `arca/mission_room.gd` | Every feature is wired here | Each task edits only the functions listed in its SPRINT_01 entry |
| `TASK.md`, `README.md`, `docs/VALIDATION.md` | Every task documents itself | Each task edits only its own block. Integrator reconciles prose |
| `arca/assets/*/gameplay.tres` | Generated, large and unmergeable | One owner per file per sprint. Regenerate rather than merge |
| `project.godot` | Input map and main scene | Only S1-11 (title) may change the main scene |

**Worktree constraints:** headless checks only in worktrees. The live editor and Godot MCP stay bound to the main checkout. Every worktree must run its own import first.

## 9. Open assumptions to verify

- [A] Current mission length is about 1.5–3 minutes for a first-time player. No human timing exists; the automated fuse→panel route takes 19.6 simulated seconds.
- [A] Rendering cost of two or three animated Ferocious raptors (15k triangles and 137 joints each) is acceptable on the user's GPU under Compatibility. Never measured.
- [A] The Ferocious `Hurt`, `Roar` and `Sleep` clips are usable after the same root-hold treatment as the current six. The README notes ground penetration in unselected clips.
- [A] The UAL `Death01`/`Hit_*` clips retarget cleanly onto Regina through the existing mapping, as locomotion and pistol poses did.
- [A] Static script variables survive `reload_current_scene()` in Godot 4.5.1, which would allow a checkpoint without a new autoload. Verify with a focused test before relying on it (S1-08).

## 10. Cleanup report (2026-11-24, nothing deleted)

### Old worktree `/home/andrea/Workspace/arca-asset-review/ARCA` (413 MB)

Detached at `305a5cc`. Its tracked files are older copies of `main`. The unique content and its status:

| Content | Size | Unique? | Status |
| --- | --- | --- | --- |
| `docs/VELOCIRAPTOR_*.md/json` (untracked) | 0.7 MB | Yes: the full Ferocious evaluation | **Copied unchanged** to `docs/archive/velociraptor-review/` |
| Uncommitted `TASK.md` / `ATTRIBUTIONS.md` edits | 130 KB diff | Yes | **Preserved** as `docs/archive/velociraptor-review/worktree-uncommitted.diff` |
| `arca/asset_review/candidate_b/gltf/` | 21 MB | No: SHA-256 identical to `arca/assets/raptor/ferocious/source/` | Safe to remove |
| `arca/asset_review/candidate_b/original/` (FBX tree) | 64 MB | No: the official archives are in `~/Downloads/` (`pbr_velociraptor_animated.zip` matches the pinned `110add9c…`; the FBX zip is `pbr-velociraptor-animated.zip`) | Safe to remove **while the Downloads copies are kept** |
| `arca/asset_review/*.gd/.py/.tscn` (preview, audit and capture tools) | small | Yes, but superseded by the integrated wrapper | Optional: copy to the archive if you want the viewer back |
| `.artifacts/velociraptor-review/` (per-clip frames for all 26 clips, `all_clips_1x.avi`) | 177 MB | Regenerable but costly | **Useful for S1-02/S1-07 clip choice.** Keep until S1-07 is accepted, or move outside the repo |
| `.godot/` | 85 MB | No (import cache) | Safe to remove |

**Safe removal, once you approve:** after the documents were archived, `git worktree remove --force /home/andrea/Workspace/arca-asset-review/ARCA` (force is needed because of untracked files). Keep `.artifacts/velociraptor-review/` elsewhere first if you want it.

### Main `.artifacts/` (2.6 GB, ignored)

| Category | Entries | Size | Recommendation |
| --- | --- | --- | --- |
| Isolated gate snapshots | 9 × `ai-check-*` | ~1.30 GB | **Safe to remove.** Full project copies of committed or since-superseded trees. Some VALIDATION.md lines cite their logs as historical evidence; keep the `*.log` files if you want those citations to resolve |
| Evaluation project copies | `project/`, `clean-project/`, `source/`, `baseline/`, `validation-project/` under `ai-setup`, `regina`, `regina-grip`, `regina-locomotion`, `regina-motion`, `regina-pistol-evaluation`, `regina-player-baseline` | ~0.98 GB | **Safe to remove** (subfolders only). Keep each parent's `REPORT.md`, logs and captures |
| Pinned animation sources | `regina-locomotion/AnimationLibrary_Godot_Standard.{gltf,bin}` (SHA-256 verified against the pinned values), `phase2-ual2/UAL2.{gltf,bin,glb}` and its License/README | ~45 MB | **Keep.** Required to re-bake Regina and for S1-06. Consider moving to a stable folder such as `~/Workspace/arca-sources/` |
| `regina-pistol-evaluation/kaykit/free-1.1.zip` | 1 | 15 MB | Keep (KayKit CC0 source of the rejected trial) or remove; nothing uses it |
| Tooling | `baseline-tools/` (local ripgrep) | 6.7 MB | Keep: the `ai_check.sh` fallback. Optional now that ripgrep is installed |
| Evidence and logs | `test-logs/`, `*-captures/`, `final-playtest/`, `raptor-replacement/`, `phase*.log`, probes | ~70 MB | Keep: cited by docs and small |

Estimated reclaimable space: **about 2.3 GB** in `.artifacts/` and **about 0.4 GB** from the old worktree.
