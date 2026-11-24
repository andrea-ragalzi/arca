# Sprint 01: from one room to a playable demo route

Source audit: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) (2026-11-24, gate 625/0).

## Sprint goal

A continuous, playable route of **at least 5 minutes** for a first-time player. The route goes from the maintenance room through three new blockout areas to a final escape, with these features:

- Multiple raptors, including one sleeping encounter.
- One keycard-locked door with a backtrack.
- A raptor hit reaction and roar.
- Regina death and hit animations.
- A readable note.
- Raptor and ambience audio.

All tested systems stay intact: TPS controls, ammo economy, hatch ambush, pause/death/restart contracts. Primitive geometry is acceptable. **Gameplay over graphics.**

## Definition of done (every task)

1. One bounded feature with the acceptance criteria below met, on its own branch and worktree.
2. `bash scripts/check.sh` passes in the worktree with **zero failures**. Existing assertions are never relaxed. New behavior gets focused regression checks.
3. Every delayed action handles pause, death, restart and completion. Interactions respect distance, line of sight and one action per press.
4. The task's own `TASK.md` block and affected docs are updated **in the same commit** as the work (AGENTS.md).
5. The handoff states what ran headless, what wasn't verified, and gives F5 steps for anything visual.
6. Commits happen only when the user authorizes them. No pushes or remote changes.

## Lanes and ownership

| Lane | Agent | Tasks |
| --- | --- | --- |
| **A**: systems and integration | **Claude Code** | S1-01 → S1-04 → **S1-10 (integrator)** → S1-08 |
| **B**: predator | **Codex** | S1-02 → S1-03 → S1-07 → S1-09 hookup |
| **C**: isolated content (new files) | Codex: S1-05, S1-13. Claude Code: S1-06. Either: S1-11 | Runs alongside lanes A/B |
| **D**: assets and audio | **Third agent session** (Codex or Claude Code) | D-01 → D-02 → D-04, D-03 (parallel), D-05 (after S1-10) |
| **U**: user | User | S1-00 approval, audio source approval (D-03), Blender install decision (D-04), F5 acceptance, S1-12 |

Up to **two worktrees per lane**. Only the integrator (S1-10) touches `arca/mission_room.tscn` and `arca/mission_navigation.tres`. Workflow details are in [docs/PARALLEL_DEVELOPMENT.md](docs/PARALLEL_DEVELOPMENT.md). Each task's self-contained brief is in `docs/tasks/<ID>.md`.

### Prepared worktrees (2026-11-24)

| Task | Branch | Worktree | Lane / agent |
| --- | --- | --- | --- |
| S1-01 | `s1/01-interactions` | `../ARCA-wt/s1-01` | A / Claude Code |
| S1-02 | `s1/02-raptor-reactions` | `../ARCA-wt/s1-02` | B / Codex lane. **Implementation started** (see TASK.md) |
| S1-05 | `s1/05-areas` | `../ARCA-wt/s1-05` | C / Codex |
| S1-06 | `s1/06-regina-reactions` | `../ARCA-wt/s1-06` | C / Claude Code |
| D-01 | `s1/d01-environment-kit` | `../ARCA-wt/d-01` | D / asset agent |
| D-03 | `s1/d03-audio-prep` | `../ARCA-wt/d-03` | D / asset agent |

Later tasks get their worktree from the current `main` once their dependencies have merged, so they start from the merged APIs.

## Dependency graph

```
S1-00 ─┬─ S1-01 ── S1-04 ─────────┐
       ├─ S1-02 ─┬─ S1-03 ────────┤
       │         └─ S1-07 ────────┤
       ├─ S1-05 ──────────────────┼─ S1-10 ─┬─ S1-08 (stretch)
       ├─ S1-06 ─────────────(any time)     ├─ S1-09 hookup (needs S1-02, S1-07)
       ├─ S1-13 ──────────────────┘         ├─ S1-11 (stretch, can run parallel to S1-10)
       └─ S1-09 asset acquisition (user-gated) ───┘
                                             └─ S1-12 final playtest

Lane D (assets, no gameplay files):
S1-00 ─┬─ D-01 env kit ─┬─ D-02 props ──────────(mesh swap by S1-04/S1-08/S1-13 owners or S1-10)
       │                └─ D-04 Blender pipeline (gated on Blender install)
       ├─ D-03 audio prep ── feeds S1-09 hookup
       └─ (after S1-10) D-05 area dressing and atmosphere
```

## Integration order

| Wave | Merge to `main`, in order | Gate after each merge |
| --- | --- | --- |
| 0 | S1-00 | Full gate on `main` |
| 1 | S1-06 → S1-01 → S1-02 → S1-05 → D-01 | Full gate, plus user F5 for S1-06 and S1-02 visuals, and a D-01 preview capture |
| 2 | S1-03 (rebased on S1-01) → S1-04 → S1-07 → S1-13 → D-02 → D-03 | Full gate |
| 3 | S1-10 → S1-09 hookup → S1-08 → S1-11 → D-05 | Full gate, plus route test |
| 4 | S1-12 | User F5 full route |

Rule: **rebase the branch onto the current `main`, re-run the full gate in the worktree, then merge.** If two branches touch `mission_room.gd` or `hud.gd`, the later one rebases and resolves the conflict, never the integrator after the fact.

---

## S1-00: Baseline checkpoint and parallel-work protocol (blocking)

**Status: complete (2026-11-24).**

- Checkpoint commit `90ae020`.
- `check.sh` falls back to `grep` when `rg` is missing.
- `TASK.md` history moved verbatim to `docs/archive/TASK_HISTORY.md`. Tasks now have per-task sections and `docs/tasks/` briefs.
- `AGENTS.md`, `CLAUDE.md`, `README.md` and the workflow docs support Codex and Claude Code worktrees.
- Wave 1 and lane D worktrees created.

**Owner:** user plus Claude Code, on `main`. **Depends on:** nothing. **Blocks:** everything.

Steps:

1. **User approves** one checkpoint commit of the accepted Phases 2–4 tree (`git status` shows 24 modified and 9 untracked files), including `TASK.md`. Without it, every worktree starts from `0497430` without ammo, medkit, reload or summary (blocker B1).
2. Make the gate runnable everywhere (B2). Either install ripgrep system-wide (`sudo apt install ripgrep`), or change `scripts/check.sh` to fall back to `grep -E` when `rg` is missing. The fallback is recommended because worktrees don't inherit `.artifacts/`.
3. Slim `TASK.md` (B3). Move the full history verbatim to `docs/archive/TASK_HISTORY.md`. Replace `TASK.md` with a sprint board that has **one pre-created `## S1-xx` section per task**, each with `Status:`, `Branch:`, `Validation:` lines. Unchanged headings between sections let parallel edits merge cleanly.
4. Update the AI tooling note in `README.md` / `docs/AI_ENVIRONMENT.md` to describe the Codex + Claude Code worktree workflow (B9), **only after the user confirms** that workflow replaces the Zed-only guidance.
5. Create the worktrees (B12):

```bash
cd /home/andrea/Workspace/ARCA
git worktree add -b s1/01-interactions ../ARCA-wt/s1-01 main
"$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" --headless --editor --import --path ../ARCA-wt/s1-01
(cd ../ARCA-wt/s1-01 && bash scripts/check.sh)
```

**Acceptance criteria:**

- `git status` on `main` is clean after the checkpoint.
- `bash scripts/check.sh` passes with 625/0 **in a freshly created worktree with no `.artifacts/`**.
- `TASK.md` is under 10 KB, and the archive holds the full previous text, byte-identical.

---

## S1-01: Interaction contract (removes the hard-coded list)

**Owner:** Claude Code. **Branch:** `s1/01-interactions`. **Depends on:** S1-00.

**Files:**

- `arca/interactables/interaction_point.gd`, `power_panel.gd`, `fuse_pickup.gd`.
- New `arca/interactables/supply_pickup.gd`, attached to `ammo_pickup.tscn` and `medkit_pickup.tscn`.
- `arca/mission_room.gd`, **only** `_find_interaction_target`, `try_interact`, `_collect_supply`, `_physics_process` (prompt text).
- `arca/tests/economy_test.gd` and `mission_test.gd` (additions only).

**Implementation:**

- `ArcaInteractionPoint` joins group `arca_interactable` in `_ready()`. `power_panel.gd` must call `super._ready()`.
- Add virtual methods `get_prompt(room) -> String` (defaults to `action_text`) and `interact(room) -> bool` (defaults to `false`).
- `supply_pickup.gd` exports `kind` (AMMO / MEDKIT) and `amount` (12 / 40, set in the scenes). It carries the existing medkit "health full" refusal.
- `mission_room.gd` discovers targets from the group (descendants of the room only) and calls `interact(self)`. Keep the `@onready` names `fuse`, `panel`, `ammo_pickup`, `medkit_pickup` because tests use them.

**Acceptance criteria:**

- All existing suites pass unchanged (mission 61, economy 25, ambush 47).
- New check: a second `ammo_pickup.tscn` with `amount = 5`, instanced at runtime in the mission, is prompted, grants exactly +5 reserve on one E press, then disappears. No edit to `mission_room.gd` is needed for this.
- New check: holding E or pressing it twice in one frame performs a single action. An occluded pickup behind the corridor partition isn't offered.

---

## S1-02: Raptor hit reaction (stagger) and alert roar

**Owner:** Codex. **Branch:** `s1/02-raptor-reactions`. **Depends on:** S1-00.

**Files:**

- `arca/enemies/raptor.gd`, `raptor.tscn`.
- `arca/assets/raptor/ferocious/bake_animations.gd`, `gameplay.tres`, `README.md`.
- `arca/enemies/ferocious_model.tscn` (only if needed).
- `arca/tests/raptor_test.gd`.

**Implementation:**

- Bake two new bindings with the existing root-hold treatment: `Ferocious_Hurt` ← `Hurt_01` (1.250 s, in place) and `Ferocious_Roar` ← `Roar_03` (1.625 s, in place, closes). Retime or trim each to fit its gameplay window and document the choice. The archived review (`docs/archive/velociraptor-review/VELOCIRAPTOR_REVIEW.md`) recommends `Hurt_01/02` and `Roar_03`. `Roar_02` travels 0.252 m and `Knocked Down` travels 0.933 m, so both are rejected for now. Add `"Hurt"` and `"Roar"` to the suffix discovery list.
- Add a `HURT` state, appended to the **end** of the enum so existing integer state values and labels stay stable.
- An accepted hit enters HURT for `stagger_duration` (export, default 0.5 s) when all of these hold:
  - state is ALERT, CHASE, WINDUP or RECOVER;
  - `stagger_cooldown` (export, default 1.5 s) has elapsed.
- HURT **cancels a pending WINDUP**, so the bite does no damage that cycle. It never triggers from DORMANT, EMERGE, ATTACK (after the hit frame) or DEAD. When it ends, the raptor returns to CHASE.
- Add a new signal `staggered`. ALERT plays the Roar binding. ALERT's 0.7 s duration is unchanged.

**Acceptance criteria:**

- All existing raptor (59), ambush (47) and mission checks pass unchanged.
- New checks:
  - a hit during WINDUP → HURT, and no player damage is dealt in that cycle;
  - five hits within 1.5 s cause at most one stagger, so no stun-lock;
  - pause freezes HURT `elapsed`;
  - a lethal hit during HURT → DEAD, `exploded` emitted once;
  - DORMANT and EMERGE never enter HURT;
  - both new bindings resolve to real source clips, and Root_02 is held.
- F5: the raptor visibly flinches on hit and roars on alert (user confirms).

---

## S1-03: Multiple predators lifecycle

**Owner:** Codex. **Branch:** `s1/03-multi-predator`. **Depends on:** S1-00. Rebase on S1-01 and S1-02 before merge.

**Files:**

- `arca/test_room.gd`, `arca/raptor_room.gd`.
- `arca/mission_room.gd`, **only** `get_mission_summary`, `_on_enemy_destroyed`, `_on_player_died`, `_on_exit_entered`, `restart_room`.
- `arca/ui/hud.gd`, **only** `_process` telemetry.
- `arca/ui/hud.tscn` (summary label only if needed).
- Tests: add to `raptor_test.gd`, or a new suite registered by the integrator.

**Implementation:**

- The room gains `get_predators() -> Array[ArcaRaptor]` from group `arca_predator`, restricted to room descendants.
- Death, completion and restart call `stop_combat()` on **every** predator.
- `enemy` stays as the primary (ambush) predator, so the hatch flow is untouched.
- Every predator's `exploded` is connected. "Predator down" notices fire per kill, but the ambush cancel applies only to the primary.
- The summary gains `kills` and `predators_total`. The `predator` field keeps its current meaning for the primary.
- HUD telemetry shows the nearest non-dormant predator.

**Acceptance criteria:**

- Existing suites unchanged.
- New checks with two active raptors in the raptor room:
  - both chase;
  - player death stops both attack timers, and no damage arrives afterwards;
  - pause freezes both;
  - restart yields exactly the original count;
  - completion in the mission with a second (non-ambush) raptor stops it;
  - the summary reports `kills = 1, predators_total = 2` after one kill.

---

## S1-04: Key items and locked door

**Owner:** Claude Code. **Branch:** `s1/04-key-items`. **Depends on:** S1-01.

**Files:**

- New `arca/interactables/key_item_pickup.gd/.tscn`, `locked_door.gd/.tscn`. The locked door composes the existing `sliding_door.tscn` and an interaction area; it doesn't fork it.
- `arca/mission_room.gd`, **only** inventory state, `_update_objective`, `_on_fuse_pickup_collected`, `_on_panel_powered`.
- `arca/ui/hud.gd`, **only** `set_inventory` formatting.
- Tests in `mission_test.gd`.

**Implementation:**

- The mission holds `key_items: Array[StringName]`. **No general inventory framework** (DESIGN.md).
- The fuse becomes `&"fuse"`. Keep `has_fuse` as a computed property so existing tests and the panel still work.
- `key_item_pickup` exports `item_id` and `display_name`.
- `locked_door` exports `required_item`, `consume_item`, `locked_text`.
  - Without the item, the prompt reads `[ E ] Locked - <display>` and the press shows a notice without opening.
  - With the item, one press opens the door (reusing the sliding tween) and optionally consumes the item.
- The HUD inventory line lists the carried items.

**Acceptance criteria:**

- Existing suites unchanged, including the fuse/panel flow.
- New checks in a test instance placed in the mission:
  - the door's collision blocks the player until it's opened;
  - E without the keycard doesn't open it;
  - E with the keycard opens it once, and the keycard is consumed when configured;
  - occluded or out-of-range doors aren't offered;
  - restart restores the locked door and the keycard;
  - pause during the opening tween freezes it.

---

## S1-05: Area blockouts (new files only)

**Owner:** Codex. **Branch:** `s1/05-areas`. **Depends on:** S1-00.

**Files (all new):**

- `arca/areas/security_corridor.tscn`, `arca/areas/control_office.tscn`, `arca/areas/exit_lift.tscn`.
- `arca/areas/area_kit.tres` or shared materials, if needed.
- `arca/tests/areas_test.gd` (not added to `check.sh` until S1-10).

**Specification:**

- Each scene is a `Node3D` whose **local origin is the centre of its entry doorway at floor level**, with the area extending toward **+Z**. The integrator attaches the corridor beyond the mission's `WallFront` (world z = 14).
- Suggested footprints:
  - corridor: 4 × 24 m with one side alcove;
  - office: 10 × 12 m, entered from the corridor's side alcove;
  - exit lift hall: 12 × 14 m beyond a locked door at the corridor's far end.
- Collision: `StaticBody3D` floors, walls and cover on **layer 1**. The wall height of 4.8 m matches `test_room`. Doorways are at least 1.8 m wide and 2.6 m high.
- Lighting: at most four `OmniLight3D` per area, at most one shadowed light, and dark pools between lights. Cold industrial palette, reusing `test_room.tscn` material values. `Label3D` signage only.
- Named `Marker3D` placeholders:
  - corridor: `Spawn_SleepingRaptor`, `Pickup_Ammo`, `Door_ToLift`, `Door_ToOffice`, `Note_1`;
  - office: `Pickup_Keycard`, `Pickup_Medkit`, `Checkpoint`, `Spawn_Ambush`;
  - lift: `Spawn_FinalRaptor`, `Exit_Zone`, `Pickup_Ammo`.
- No scripts, no `NavigationRegion3D`, no enemies and no interactables. Those belong to the integrator.

**Acceptance criteria:** `areas_test.gd` loads each scene headless and checks that:

- it loads without errors;
- every required marker exists;
- every doorway has an unobstructed 0.9 m-radius capsule cast;
- every `CollisionObject3D` is on layer 1;
- the light count is within budget.

One rendered still per area is captured with the existing capture pattern under X11 for user review. It's not an acceptance gate.

---

## S1-06: Regina death and hit reactions

**Owner:** Claude Code. **Branch:** `s1/06-regina-reactions`. **Depends on:** S1-00.

**Files:**

- `arca/assets/characters/regina/source/` (a new `ual_reactions.glb` subset, its README section, an extractor option).
- New `arca/assets/characters/regina/bake_reactions.gd` and `reactions.tres` (a separate library, so `gameplay.tres` stays untouched).
- `arca/player/arca_player.gd`, **only** `_install_regina`, `take_damage`, `_on_died`.
- `arca/tests/regina_player_test.gd`, `ATTRIBUTIONS.md` (one block).

**Implementation:**

- Extract `Death01` and `Hit_Chest` from the **pinned** UAL Standard glTF. Verify the SHA-256 from `source/README.md`. The local copy lives in the main checkout's `.artifacts/regina-locomotion/`; pass it by absolute path.
- Retarget with the existing bone mapping.
- On an accepted damage packet: play a short, interruptible hit one-shot. Movement input stays live, with at most 0.3 s of visual blend and **no** movement lock.
- On death: play `Death01` and hold the final frame. Only then disable the tree or keep it holding.
- Keep the existing lifecycle contracts: input disabled, fire stopped, reload cancelled.

**Acceptance criteria:**

- All 378 regina_player checks pass unchanged.
- New checks:
  - after death, the hips height drops by at least 0.5 m within the clip length, and the pose stays held 2 s later;
  - no input moves the body after death;
  - a hit while walking doesn't reduce displacement over 1 s by more than 10 %;
  - pause freezes the death clip;
  - restart restores a standing idle pose.
- `ATTRIBUTIONS.md` and the source README record the subset and its hash.
- F5: the user confirms the death reads correctly.

---

## S1-07: Sleeping raptor encounter

**Owner:** Codex. **Branch:** `s1/07-sleeping-raptor`. **Depends on:** S1-02 (bake pipeline and `raptor.gd`).

**Files:** `arca/enemies/raptor.gd`, the Ferocious bake and `gameplay.tres`, `raptor_test.gd`.

**Implementation:**

- Bind `Sleep_Loop` and `Wake From Sleep`.
- Add an exported `start_mode` (`ACTIVE` default, `SLEEPING`) and a new `SLEEP` state appended to the enum.
- The raptor wakes when any of these happens:
  - it takes a hit;
  - the player fires within `wake_noise_radius` (default 12 m), via `shot_fired` on the `arca_player` group node;
  - the player stays within `wake_proximity` (default 2.5 m) for 1.0 s.
- Waking plays the wake clip, then roars into ALERT.
- A sleeping raptor is solid and shootable, but doesn't attack or rotate.

**Acceptance criteria:**

- Existing suites unchanged.
- New checks:
  - a sleeping raptor stays asleep while the player walks past at 4 m;
  - it wakes from a shot at 10 m, but not from a shot at 15 m without a hit;
  - it wakes from 1 s of proximity;
  - pause freezes the proximity timer;
  - restart restores the sleeping state;
  - killing it while asleep works and emits `exploded` once.

---

## S1-08: In-memory checkpoint (stretch)

**Owner:** Claude Code. **Branch:** `s1/08-checkpoint`. **Depends on:** S1-04 and S1-10.

**Implementation:**

- First, write a focused test proving that a `static var` on a `class_name` script survives `reload_current_scene()` in 4.5.1. If it doesn't, store the snapshot with `Engine.set_meta`. **No new autoload** either way.
- A checkpoint interaction (terminal at `Checkpoint`) records:
  - health, magazine and reserve;
  - key items;
  - mission flags (power, opened doors);
  - collected pickup and killed predator node paths;
  - the spawn transform.
- The death modal offers **Retry from checkpoint** and **Restart mission**. Backspace still restarts the whole mission and clears the snapshot.

**Acceptance criteria:**

- After recording, dying, then retrying: Regina is at the checkpoint with the recorded health and ammo, collected pickups are absent, killed predators are absent, the opened doors are open, the hatch ambush doesn't replay, and the mission clock continues.
- "Restart mission" restores the pristine state, matching the existing restart assertions.

---

## S1-09: Audio pass

**Owner:** user for sources, Codex for the hookup. **Branch:** `s1/09-audio`. **Depends on:** S1-02 and S1-07 for the hookup. Acquisition can start immediately.

**Acquisition:**

- The user approves the sources before anything is downloaded. Prefer **CC0** packs.
- Needed sounds:
  - raptor: roar ×2, bite, hurt, death, footsteps (2–3), breathing or sleep loop;
  - environment: ambience loop, alarm loop, door servo, keycard accept/deny.
- Record every file in `ATTRIBUTIONS.md` with URL, author, license and hash.

**Hookup:**

- `AudioStreamPlayer3D` nodes in `raptor.tscn`, driven by `state_changed` and `staggered`. No new audio framework.
- Door sounds go in `sliding_door.tscn` and `locked_door.tscn`. The ambience player goes in the mission and is added by the integrator.

**Acceptance criteria:**

- Headless with the Dummy driver:
  - each state change starts the matching player;
  - `stop_audio()` on restart, death or completion silences every new player;
  - pause stops playback progression.
- F5: the user confirms the mix is audible and not clipping.

---

## S1-10: Demo route integration (integrator)

**Owner:** Claude Code. **Branch:** `s1/10-integration`. **Depends on:** S1-01, S1-03, S1-04, S1-05 and S1-07. S1-13 if merged.

**Files:**

- `arca/mission_room.tscn`, `arca/mission_room.gd` (route wiring), `arca/mission_navigation.tres`, `arca/tools/bake_mission_navigation.gd`.
- `scripts/check.sh` (register new suites).
- `mission_test.gd`, `ambush_test.gd`, `economy_test.gd` fixtures.
- New `arca/tests/route_test.gd`.
- `README.md`, `docs/DESIGN.md`, `docs/VALIDATION.md`.

**Implementation:**

- Open the inherited `WallFront` **in `mission_room.tscn` only**, using overrides: hide the inherited mesh, disable its collision, add mission-local wall segments with a doorway behind the existing exit door. Don't edit `test_room.tscn` (B7).
- Instance the three areas and place content at their markers:
  - a sleeping raptor in the corridor;
  - the keycard, medkit, note and checkpoint in the office;
  - the locked door to the lift;
  - a final raptor;
  - the extra ammo.
- Move the victory `ExitZone` to the lift hall. The existing exit door now leads onward.
- Update objectives: 04 find access → 05 keycard → 06 lift.
- Rebake navigation with the existing tool.

**Acceptance criteria:**

- All prior mission, ambush and economy assertions still pass. Only fixtures (positions, completion zone) change, and every changed fixture is listed in the handoff.
- First-playable and raptor suites prove the base rooms are unchanged.
- A new `route_test.gd` walks the full route headless with predators stopped: fuse → panel → corridor → office keycard → locked door → lift exit. It asserts victory and reports simulated walking time. **Target: at least 150 s of pure walking.**
- Every raptor reaches Regina via navigation in every area (path exists, `is_navigation_finished` reached within N frames).
- F5 checklist provided.

---

## S1-11: Title and end screens (stretch)

**Owner:** either agent. **Branch:** `s1/11-front-end`. **Depends on:** S1-00. Merge after S1-10.

**Files:** new `arca/ui/title_screen.tscn/.gd`, `project.godot` (`run/main_scene` only), `arca/ui/hud.gd` (`show_success` text and a "Return to title" button).

**Acceptance criteria:**

- F5 opens the title, which has New Game, Controls and Quit.
- New Game loads `mission_room.tscn` with the mouse captured.
- The victory modal reads "DEMO COMPLETE" and offers Return to title.
- A headless check drives the title to the mission and back.
- Mission tests that load the mission directly are unaffected.

---

## S1-13: Readable notes

**Owner:** Codex. **Branch:** `s1/13-notes`. **Depends on:** S1-01.

**Files:** new `arca/interactables/note.gd/.tscn`, `arca/ui/hud.gd` (a new `show_note` function and a modal variant), `hud.tscn`, tests.

**Implementation:**

- The note exports `title` and multiline `body`.
- E opens a modal that pauses the game through the room's pause path; E or Esc closes it and resumes. The note stays re-readable.
- Content: one short station log introducing the Continuity Station breach. English, original text.

**Acceptance criteria:**

- While open, the mission clock and predators are frozen.
- The close press doesn't also trigger another interaction (one action per press).
- Death can't occur while it's open.
- Restart closes it.

---

## S1-12: Full-route playtest and tuning list

**Owner:** user plus Claude Code. **Depends on:** everything merged.

**Steps:**

1. The user plays F5 from title to exit twice: once fighting, once evading.
2. Record the **mission clock** from the victory panel, deaths, ammo left, and every confusing moment.
3. Record results in `TASK.md` and produce `SPRINT_02.md` from the findings.

**Acceptance criteria:**

- At least one complete run takes **5–10 minutes**.
- No soft-lock.
- The full gate is green on `main`.

---

# Lane D: assets and audio (third independent workstream)

This lane produces assets that gameplay lanes can adopt without waiting, and it never blocks them.

**Hard boundaries:**

- The lane **never edits** gameplay scripts (`arca/*.gd`, `arca/enemies/`, `arca/player/`, `arca/components/`, `arca/interactables/*.gd`), room scenes (`arca/*_room.tscn`), navigation or tests of gameplay behavior.
- **Paths it owns:** `arca/assets/environment/**`, `arca/assets/props/**`, `arca/audio/**` (new subfolders only), `arca/tools/assets/**`, `tools/blender/**` (with `.gdignore`), `docs/assets/**`, and its own block in `ATTRIBUTIONS.md`.
- Every asset has a known source and license. Generated assets are ARCA MIT additions. Downloads need the user's approval of the exact source first.

**Tool facts (audited 2026-11-24):**

- **Blender, ffmpeg and sox aren't installed.** Python 3 and Godot 4.5.1 are.
- So the default automation is **Godot-headless generation** (`SceneTree` scripts that build meshes and materials and save `.tres`/`.tscn`, or export `.glb` through `GLTFDocument`), plus Python stdlib `wave` for PCM audio checks.
- A Blender pipeline is optional and gated on installing a portable Blender LTS in `~/Applications` (D-04).

## D-01: Modular environment kit (Godot-generated)

**Branch:** `s1/d01-environment-kit`. **Worktree:** `../ARCA-wt/d-01`. **Depends on:** S1-00.

**Deliverables:**

- `arca/tools/assets/build_environment_kit.gd`, a headless generator. It must be deterministic: re-running it produces identical resources apart from UIDs.
- The output goes to `arca/assets/environment/kit/`:
  - materials: wall panel, floor plate, hazard trim, pipe, emissive light strip, dark glass;
  - pieces: wall 4 m, wall 2 m, doorway frame (1.8 × 2.6 m opening), floor tile 4 × 4 m, ceiling-height pillar, pipe run, cable tray, light-strip fixture, vent grille, crate/console blocks.
- Each piece is a `.tscn` with `MeshInstance3D` plus `StaticBody3D` on collision **layer 1** (where solid), origin at its floor centre, and dimensions on a 0.5 m grid.
- The palette matches `arca/test_room.tscn` materials (cold industrial) and stays Compatibility-safe: no SSR, SDFGI or volumetrics, and emissive pieces use plain emission.
- `arca/assets/environment/kit/kit_preview.tscn` lays out every piece. `docs/assets/ENVIRONMENT_KIT.md` gives the piece catalogue, dimensions and usage.

**Acceptance criteria:**

- A headless check (`arca/tests/environment_kit_test.gd`) loads every piece and verifies:
  - no errors;
  - AABB dimensions on the 0.5 m grid;
  - collision layer 1 on solids;
  - the doorway opening is at least 1.8 × 2.6 m;
  - the triangle budget is at most 2,000 per piece.
- Re-running the generator yields no diff in mesh data.
- One X11/Compatibility capture of `kit_preview.tscn` goes into `.artifacts/` for the user. It's not a gate.

## D-02: Gameplay prop set

**Depends on:** D-01 materials.

**Deliverables:** `arca/assets/props/`:

- `keycard`, `checkpoint_terminal`, `note_clipboard`, `locked_door_frame` (status light node `StatusLight`), `lift_doors`, `ammo_box`, `medkit_case`, `fuse`.
- Each prop is **visual only**: root `Node3D`, a child `Mesh` (or `Meshes`), and optional named `StatusLight` / `Screen` nodes. No scripts and no collision except the door frame.
- The node contract is documented in `docs/assets/PROPS.md` so S1-04, S1-08 and S1-13 owners, or S1-10, can swap visuals by instancing a prop under an existing interactable without changing behavior.

**Acceptance criteria:**

- A headless check loads each prop and verifies the named contract nodes and size bounds. For example, the keycard is at most 0.12 m and the terminal fits 0.8 × 1.6 × 0.6 m.
- Props are readable at gameplay distance: a capture is provided for user review.

## D-03: Audio preparation

**Branch:** `s1/d03-audio-prep`. **Worktree:** `../ARCA-wt/d-03`. **Depends on:** S1-00. **User gate:** source approval before any download.

**Steps:**

1. Write `docs/assets/AUDIO_PLAN.md`. It holds the required cue list with the naming contract `arca/audio/<category>/<cue>_<nn>.wav`. Categories are `raptor`, `env`, `ui` and `door`. Cues:
   - raptor: roar ×2, bite, hurt ×2, death, footstep ×3, breath/sleep loop;
   - environment: ambience loop, alarm loop;
   - door: servo open, locked deny;
   - UI: keycard accept, note open.
   The plan also gives the target format (WAV PCM 16-bit, 44.1 or 48 kHz, mono for 3D cues), loudness targets (peak at most −1 dBFS; loops seamless) and loop flags.
2. Propose a **shortlist of CC0 (preferred) or CC BY sources** with exact URLs, authors and licenses. **Stop for user approval.** Synthesized original sounds (procedural Python/Godot generation, MIT) are an approved fallback for UI, door and alarm cues that needs no download.
3. After approval, stage the downloads outside tracked paths (`.artifacts/audio-staging/`). Convert, trim and normalize with `arca/tools/assets/prepare_audio.py` (stdlib `wave`/`audioop`-free implementation, or ffmpeg if the user installs it). Commit only the final files with their `.import` settings: loop on for loops, and 3D-ready mono.
4. Record every file in `ATTRIBUTIONS.md` (URL, author, license, SHA-256 of the original) and in `docs/assets/AUDIO_MANIFEST.md` (cue → file → duration → loop → peak).

**Acceptance criteria:**

- A headless check verifies that every manifest entry exists, imports, has the declared loop mode and a duration within bounds, and that the peak is at most −1 dBFS (measured from PCM).
- No unlicensed file is committed.
- S1-09 can wire cues by name without renaming anything.

## D-04: Optional Blender automation pipeline

**Depends on:** D-01. **User gate:** install portable Blender LTS (for example 4.2 LTS) to `~/Applications/` and pin its version.

**Deliverables:**

- `tools/blender/` with a `.gdignore` and headless scripts (`blender --background --factory-startup --python ...`) that generate kit variants or props as `.glb`, with deterministic seeds, applied transforms, meters, +Y up for Godot import, and no embedded absolute paths.
- `scripts/blender_build.sh` discovers the pinned Blender like `godot_common.sh` does and refuses other versions.
- Generated `.glb` files plus source-side `.import` are committed. `.blend` files are committed only if small and needed.

**Acceptance criteria:**

- Running the build twice produces byte-identical `.glb` files.
- Godot imports them without errors.
- If Blender isn't installed, the lane continues with D-01's Godot generator and D-04 stays parked; nothing else waits on it.

## D-05: Area dressing and atmosphere

**Depends on:** S1-10 merged, and D-01/D-02.

**Deliverables:**

- Replace primitive boxes in `arca/areas/*.tscn` with kit pieces, keeping collision footprints and marker positions identical.
- Add `arca/assets/environment/atmosphere/*.tres`: `Environment` resources with Compatibility-safe fog, ambient and tonemap per area mood, and light presets.

**Acceptance criteria:**

- `areas_test.gd`, `route_test.gd` and the full gate pass unchanged.
- Navigation is rebaked only if a collision footprint changed; footprints are meant to stay identical.
- The user accepts the mood in F5.
- The frame-rate check with F3 is recorded in S1-12.

---

## Explicitly out of scope for Sprint 01

- Final art, materials or lighting polish.
- Fixed or cinematic camera.
- New traversal (crouch, climb).
- Dylan/Paula characters.
- Persistent save files.
- Crafting or a general inventory.
- New enemy species.
- Engine upgrade or new autoloads.
- A second Godot MCP.

## Risks

| Risk | Mitigation |
| --- | --- |
| Ferocious Hurt/Roar/Sleep clips penetrate the ground or snap | Same root-hold bake. Fall back to `Hurt_02` or `Call_Alert`. User F5 is the visual gate |
| Three animated raptors cost too much on the user's GPU | Sleeping and final raptors only process inside their areas. Measure FPS in S1-12 with F3 telemetry |
| UAL reaction retarget looks wrong on Regina | Keep the death clip mandatory and the hit reaction optional. Fall back to camera and HUD feedback only |
| Integration conflicts in `mission_room.gd` and `hud.gd` | Function-level ownership, mandatory rebase before merge, integrator-only scene edits |
| Walking time is too short for 5 minutes | `route_test` reports it early. Lengthen the backtrack or add a second keycard in Sprint 02 rather than padding with enemies |
