# Task: repository cleanup

Status: repository cleanup implemented, integrity checks passed and changes staged for review. The full staged whitespace check reports existing whitespace in the unchanged third-party license; see validation below. No commit or push authorized by this cleanup task.

## Goal and acceptance conditions

- Keep one Git repository at the `ARCA` root and preserve its existing `origin` remote.
- Replace the `arca` gitlink with normally tracked source files, so the main repository contains the playable project without a separate remote.
- Preserve every gameplay file, source-side `.import`, `.uid`, license and attribution without content changes.
- Preserve the nested repository's complete Git metadata and history locally at `.git/arca-repository-backup`; do not delete or rewrite history.
- Keep generated files ignored, update Git guidance and include this task update with the cleanup changes whenever they are committed.

## Implementation and validation

- The working trees were clean at the start. The old project copies had already been removed in commit `95e012f`; this task does not repeat or revert that cleanup.
- Moved `arca/.git` into the local backup above, saved its original tracked-file manifest at `.git/arca-cleanup-index-before`, and replaced the root gitlink with staged source files. The local backup is not published or included in future clones.
- Updated `README.md` and `docs/WORKFLOW.md` to describe one root repository and commit `TASK.md` alongside task changes.
- Passed integrity checks: all 62 staged source files match the nested repository's original paths, modes and blob hashes; working-file hashes are unchanged; `arca/` resolves to the root repository; no nested `.git`, gitlinks or tracked generated outputs remain; the staged tree serializes successfully and the history backup is readable.
- Whitespace validation: the full `git diff --cached --check` reports pre-existing trailing whitespace at line 9 and a blank line at EOF at line 12 in `arca/assets/raptor/LICENSE_QUATERNIUS.txt`. The license is byte-for-byte unchanged and retained as supplied. Documentation-only and unstaged whitespace checks passed.
- Existing root history and the `origin` URL remain unchanged. No gameplay suite was run because this cleanup changes only Git tracking and documentation.
- Gameplay behavior is unchanged. No new F5 acceptance is required for Git metadata changes; the previous corridor playtest remains pending as recorded below.

---

# Previous task: service corridor and return route

Status: approved for implementation, including the route-and-camera experiment below. Leave changes uncommitted for the user's F5 playtest.

## Goal and mandatory contracts

Make the next documented design candidate playable: a physically separate service corridor containing the fuse, requiring an outward trip and a return to the maintenance room before restoring power.

Visible acceptance conditions:

- The corridor entrance is recognizable from the starting area.
- The fuse is concealed from the main room, requiring actual exploration.
- Target roughly 10–20 seconds of ordinary walking from the fuse back to the panel; verify during playtesting, not just by estimating distance.
- Treat this increment as a route and camera experiment: evaluate visibility, exploration, turning space and camera clearance in the blockout while retaining the existing camera implementation.

- From the existing start, the player can identify and enter a service corridor, collect the yellow fuse with E, and return to the existing power panel.
- Solid partition geometry separates the corridor from the main room; the fuse cannot be collected through the partition or reached by an unintended shortcut over it.
- The powered exit remains the existing exit. Restoring power still consumes one fuse, opens the door and schedules one warned predator ambush; escape does not require a kill.
- Both player and predator can traverse the corridor entrance without getting stuck. The third-person camera remains usable there.
- Pause, death, restart and completion retain their current behavior. Restart restores the corridor pickup and the unpowered mission.
- Preserve Godot 4.5.1 Standard, Compatibility rendering, scene/script inheritance, TPS movement, camera implementation and shooting.

## Assumptions, approval question and non-goals

- The user asked to plan the next change without naming a feature. The proposed choice follows the first candidate in `docs/DESIGN.md`; approval of this plan confirms that choice.
- “Return route” means backtracking through one corridor entrance, not adding a second loop or a new exit. This is the smallest playable interpretation.
- Build the corridor by partitioning part of the existing room footprint, avoiding expansion of the inherited test room. Exact placement and dimensions must accommodate existing cover and camera clearance; do not choose coordinates without inspecting those nodes in the editor.
- Keep the panel, exit and ambush marker at their current locations where possible. Do not change ambush timing or combat balance to compensate for layout issues.
- No service-hatch animation, extra enemy, new inventory/resource economy, save system, new assets/dependencies, camera-controller replacement or base-room redesign.
- Pre-existing Git changes include extensive deletions under an older project folder. Leave all unrelated changes untouched; no cleanup, commits or repository migration is part of this task.

## Relevant files and current flow

- `arca/mission_room.tscn`: inherits `raptor_room.tscn`, which inherits `test_room.tscn`. Adds the fuse and pedestal at `(2, -6)` in X/Z, panel at `(-8.8, 6.5)`, exit partition/door near Z `10.8`, exit zone at Z `12.4`, and ambush marker at `(5, 8.5)`. Overrides the navigation mesh.
- `arca/test_room.tscn`: inherited floor is 22 by 28 units, with boundary walls and cover. Inspect it for placement constraints, but keep corridor-specific changes in the mission scene.
- `arca/mission_room.gd`: E selects the nearest available fuse/panel; pickup sets `has_fuse`; panel activation consumes it, opens the door and starts the ambush countdown; powered/open exit completes and pauses the mission. Several HUD messages currently say the fuse is near the entrance.
- `arca/mission_navigation.tres`: static baked navigation using physics geometry on collision layer 1 and agent radius 0.6. It must reflect the new partition and accessible corridor floor.
- `arca/tests/mission_test.gd`: checks interactions, occlusion, door physics, completion and reset. Pickup positions and a temporary occlusion wall are hard-coded around the current fuse location; navigation checks use elapsed frames and distance progress.
- `arca/tests/ambush_test.gd`: inherits mission test helpers, but `restore_power()` also hard-codes the pickup position. Covers activation, navigation, cancellation and kill-optional completion.
- `scripts/check.sh`: imports the project, runs launcher checks and the first-playable, raptor, mission and ambush suites. No new test runner is needed.
- `README.md`, `docs/DESIGN.md`, `docs/VALIDATION.md`: describe the current route, scope and verified coverage.

## Minimal solution and implementation order

1. Inspect the full inherited layout and applicable gameplay skill before implementation. Stop play and save Godot scenes before external scene edits. Establish the existing suite baseline once imports are idle.
2. In the mission scene only, add a small group of static partition meshes/colliders using existing blockout materials. Create one clearly readable corridor entrance and a fuse alcove beyond it. Use sufficient wall height to prevent jumping over the separation, while leaving enough width and turning space for the player, raptor and camera. Keep the starting area, panel access and escape route unobstructed.
3. Move the existing fuse instance and pedestal into the corridor; retain their node names and signal contracts. Keep a clear interaction approach without placing the pedestal across the walkable route. Do not add mission state or scripted route triggers: geometry should require the journey.
4. Update only location-dependent objective/notice text in `mission_room.gd` to direct the player into the service corridor and back to the panel. Preserve interaction distance/line-of-sight checks and the existing power/ambush/completion sequence.
5. Re-bake and save `mission_navigation.tres` against the changed mission geometry. Verify the region includes the corridor and entrance, respects the partition, and does not introduce a route through the closed exit. Retain the existing navigation resource reference.
6. Update location-dependent mission and ambush test setup. Use a small shared pickup-approach helper in the existing inherited mission test harness if needed to avoid duplicating the new approach coordinates. Move the temporary occlusion wall with the pickup; do not delete its assertion. Add focused layout/physics/navigation regressions below, without relaxing existing behavioral assertions.
7. Update README play instructions and design description. Update validation coverage/results only after actually running checks; do not predeclare pass counts. Leave the hatch and resource-economy candidates deferred.

## Tests and validation

Automated checks to add or adapt in the existing suites:

- The fuse cannot be collected from the opposite side of the actual corridor partition, even at interaction range; collection from the valid corridor approach succeeds through real E input exactly once.
- A player movement attempt into the partition is blocked, and actual movement through the opening succeeds in both directions. Do not use teleport-only setup as evidence of corridor traversal.
- An active raptor follows a player between the main room and corridor around the partition. Assert meaningful progress and arrival through the available entrance, not merely a non-empty navigation path. Bound waits and use geometry-appropriate targets rather than weakening existing progress checks.
- Existing missing-fuse feedback, pause/death interaction restrictions, fuse consumption, closed/open door collision, warning timing, single activation, restart reset and completion cancellation still pass.
- Update existing fuse-target navigation checks to account for the longer legitimate route; maintain an explicit no-stuck outcome. Keep the ambush suite's fast-completion cancellation test: it tests a lifecycle contract, not the duration of the new walking route.

Commands from the ARCA root during implementation:

```sh
bash scripts/check.sh
```

This is the supported baseline and final check: expect successful import and all four gameplay suites with zero failures and no script/runtime errors. Godot must be 4.5.1; set `GODOT_BIN` if discovery fails. The script also requires `timeout` and `rg`; `docs/VALIDATION.md` records a local ripgrep workaround if it is still needed. Do not install packages or change the environment as part of planning.

Manual F5 acceptance playtest:

1. Follow the HUD from spawn to the corridor, collect the fuse and walk back to the panel without debug teleporting. Check entrance visibility, camera clearance, pedestal access, wall collision and jump shortcuts.
2. Restore power, verify the warning and ambush, and escape alive without killing the raptor. Separately lure it toward/into the corridor to check doorway navigation.
3. Pause during the warning, resume, die/restart, and finish/restart; verify normal mission state reset and no delayed activation after death/completion.

## Implementation handoff

Implemented the mission-only corridor and screened alcove, concealed fuse/pedestal relocation, entrance/return signs and lighting, floor guide, initial camera framing and corridor wall lining. One inherited crate is repositioned in the mission only to reveal the entrance. Reused the existing scene/script inheritance, interactions and mission lifecycle; rebaked navigation and extended existing tests/capture helpers. No controller, movement speed, shooting, ambush timing or base-room changes.

The automated return route measured about 19.6 simulated seconds with real root-motion walking and brief waypoint settling. Automated checks and staged software-rendered captures are recorded in `docs/VALIDATION.md`. Manual route-and-camera acceptance and human walking timing remain pending the user's F5 playtest. Leave all changes uncommitted.

## Commit handoff

`AGENTS.md` now requires the current task, implementation status and remaining validation to stay documented in `TASK.md`. Every commit of task changes must include the corresponding `TASK.md` update in the same commit, never as a separate follow-up. This does not authorize automatic commits or change the pending F5 acceptance above.

## Risks and edge cases

- The room inherits decorative walls and cover: a corridor that looks clear may contain inherited collision. Inspect the composed scene before finalizing placement.
- A narrow opening may fit the player but reject the navigation agent or cause camera clipping. Widen the blockout rather than changing the controller or predator radius.
- Baked navigation can disagree with physics geometry or include isolated surfaces. Validate actual traversal, not only resource serialization or path existence.
- The closed sliding exit must remain a real barrier after rebaking; escape must still require restored power and a fully opened door.
- Relocating the fuse invalidates hard-coded positions in tests and any visual capture helper. Inspect affected helpers and update only location-dependent setup if needed; do not mistake staged captures for gameplay acceptance.
- Headless checks cannot establish route readability, camera comfort or rendered quality. Manual F5 review is required before calling the layout accepted.
