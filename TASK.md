# Task: close service-hatch acceptance, with targeted fixes only if needed

Status: closed through documentation only on 2026-10-17. The user confirmed that the service hatch passed the F5 checklist in `README.md`. No gameplay changes were needed or made. The supported gate passed during revalidation: 162 gameplay checks and 13 launcher checks, zero failures, using the existing local ripgrep PATH workaround. The initial task-plan changes and historical implementation record have been preserved.

## Roadmap decision

Follow `docs/DESIGN.md`, especially "Keep future work small": accepted service corridor -> readable physical hatch entrance with user F5 acceptance -> one limited ammunition/health economy experiment. At planning time, the next unfinished item was **hatch acceptance**, not hatch implementation and not the resource economy. The user has now separately accepted both the corridor and the hatch.

No deviation from the documented sequence was needed. The hatch acceptance gate is now satisfied; one limited ammunition/health economy experiment is the next candidate, not part of this closed task. The roadmap does not yet specify the economy's mechanics or tuning; leave those decisions for its own task after the hatch is accepted.

## Bounded goal and acceptance

Finish the existing hatch experiment: from the normal panel approach, the player can recognize the warning, see the hatch open and the same raptor walk out, and react without losing movement/camera control. The powered exit remains usable without killing the predator.

Completion requires explicit user F5 acceptance of the hatch's readability and reaction comfort. Automated checks and staged captures are supporting evidence, not substitutes. If the existing behavior passes, close this task through documentation only; no new gameplay implementation is required.

## Execution and conditional implementation scope

1. Run the three-step F5 checklist below against the existing implementation before changing it. Record hatch-specific feedback; do not infer a failure or acceptance from the corridor result.
2. If feedback identifies a problem, reproduce one concrete issue and make the smallest hatch-only fix. Limit changes to warning/signage visibility, hatch placement/clearance, entrance timing or a demonstrated entrance/lifecycle defect. Preserve the accepted corridor/fuse route, TPS movement/camera/shooting, combat balance, single predator and independently opening exit. Stop and re-scope if the issue requires changing those contracts.
3. Keep the existing inheritance: `mission_room` -> `raptor_room` -> `test_room`, for scenes and scripts. Use `arca/mission_room.tscn` and `arca/mission_room.gd` first; touch `arca/enemies/raptor.gd` only for a reproduced emergence defect. Re-bake `arca/mission_navigation.tres` only if static geometry changes. Save/reload open Godot scenes before external edits.
4. For a meaningful behavior fix, extend the existing `arca/tests/ambush_test.gd` coverage with a focused regression where automatable; do not add tests merely mirroring cosmetic adjustments. Preserve phase-specific pause, death, restart and completion handling, dormant immunity, obstruction safety and one activation per mission. Do not weaken existing assertions.
5. Update `README.md`, `docs/DESIGN.md`, `docs/VALIDATION.md` and this task with actual changes/checks and the user's acceptance or remaining feedback. Keep the original implementation record below as history. Do not commit unless requested.

Non-goals: ammunition limits, reloads, healing/pickups, inventory frameworks, new enemies/assets/audio, camera redesign, corridor rework or unrelated cleanup. No gameplay edit is authorized merely by preparing this task.

## Validation and stop condition

F5 checklist for the user:

1. Collect the corridor fuse, return to the panel and restore power. Check that the hatch warning is noticeable, the opening and raptor walk-out are readable, and there is enough time to react with normal controls.
2. Escape through the green exit without shooting. Restart and separately check shooting the emerging/active raptor.
3. Pause/resume during hatch opening and walk-out, then restart during the sequence. Check freezing/resuming and reset to the closed hatch/hidden predator; death or completion must prevent later entrance actions.

If gameplay changes are needed, establish the supported baseline, run focused ambush checks during iteration and finish with `bash scripts/check.sh` on Godot 4.5.1 Standard. Inspect logs for script/runtime errors, then repeat the affected F5 steps. Historical results are 162 gameplay and 13 launcher checks passed; report fresh results only after running them. For documentation-only closure, inspect the diff and run `git diff --check`; no gameplay rerun is required.

Stop when the hatch is explicitly accepted and documentation reflects that result. Only then prepare a separate bounded ammunition/health economy experiment; do not bundle it into this task.

## Execution handoff

- The user explicitly invoked the implement skill with conditional documentation-only closure if the existing behavior passes. After automated revalidation, the user answered "yes" when asked whether the service hatch also passed the F5 checklist in `README.md`.
- `bash scripts/check.sh` initially stopped at its prerequisite check because `rg` was absent from PATH. The existing ignored binary at `.artifacts/baseline-tools/ripgrep/usr/bin/rg` reports version 14.1.0; prepending its directory to PATH allowed the unchanged check script to complete.
- Fresh results: launcher 13/13; first-playable 42/42; raptor 24/24; mission 52/52; ambush 44/44. Import and all gameplay suites passed without script/runtime errors; this includes the repository's GDScript compilation/type gate. Logs are under ignored `.artifacts/test-logs/`.
- No reproduced defect required a gameplay edit. Updated `TASK.md`, `README.md`, `docs/DESIGN.md` and `docs/VALIDATION.md` to record acceptance and close the task. No sequence deviation, new assets, dependency changes, commits or pushes.
- No remaining acceptance blocker for this task. User F5 acceptance establishes hatch readability/reaction comfort; it is not a GPU performance measurement. The economy experiment remains unplanned and unimplemented.
- Closure is documentation-only: gameplay suites were not rerun after the earlier passing revalidation; inspect the final documentation diff and run `git diff --check`.

---

# Implementation record: predator entrance through a service hatch

Status at the implementation handoff: implemented following the user's explicit `implement` invocation against this plan. Full gameplay gate passed: 162 gameplay checks and 13 launcher checks, zero failures. Hatch reaction/readability acceptance remained pending the user's F5 playtest. Changes were uncommitted at that handoff; this is a historical record, not the current Git status.

## Recorded feedback

- On 2026-10-17, the user reported: "The service corridor works in my F5 playtest." Record the corridor as accepted by the user; it no longer blocks the hatch task.
- No human return-time measurement or separate camera/performance observations were supplied. Do not infer those from this acceptance. The earlier 19.6-second result is an automated simulated walking measurement only.
- Git status was clean before planning. Preserve the previous task records below as historical context.

## Goal and mandatory contracts

Make the existing raptor visibly emerge through an opening service hatch, with enough warning to react, using a small placeholder blockout.

Visible acceptance conditions:

- A recognizable, initially closed service hatch conceals the existing dormant raptor. Power restoration gives a readable warning, the hatch visibly opens, and that same raptor physically walks through the opening before normal combat begins. No appearance in the open room, wall clipping or second predator.
- Retain the fuse/corridor/panel/exit mission, E interaction rules, TPS controls, camera controller, shooting, current combat balance and kill-optional escape. Do not hold the exit closed until the entrance sequence finishes.
- Pause freezes every entrance phase. Death and completion cancel unfinished entrance actions; restart restores the closed hatch, hidden/non-solid/immune dormant raptor, fuse and unpowered mission. Repeated E cannot replay the sequence.
- Preserve Godot 4.5.1 Standard, Compatibility rendering and the existing scene/script inheritance. Leave changes uncommitted.

## Assumptions and non-goals

- Use a shallow enclosed service bay within the existing main-room footprint near `AmbushSpawn`, facing the main room and readable from the panel approach. It is distinct from the accepted fuse corridor and the green exit. This avoids cutting through inherited perimeter walls or expanding the level.
- Keep the existing 1.4-second warning, then add approximately one second of visible hatch opening and a short walk-out before the existing alert/windup can lead to damage. These are proposed starting values, not proof of sufficient reaction time; F5 acceptance decides readability.
- Use primitive meshes, matching solid geometry and existing materials/lights/animations. No imported art, sound pack, dependency, general hatch framework, extra enemy, camera cut, control lock, resource economy or unrelated cleanup.
- Exact bay dimensions/placement must be checked against the composed scene and the raptor's visible mesh, not only its capsule. No unresolved product question blocks this bounded plan.

## Relevant files and inspected baseline

- `arca/mission_room.tscn` inherits `raptor_room.tscn`, which inherits `test_room.tscn`; scripts mirror that chain. Keep hatch geometry in the mission scene. The current marker is `(5, 0.05, 8.5)`, close to the corridor partition at X `5.8` and the exit partition at Z `10.8`; do not cover either route with the new bay.
- `arca/mission_room.gd`: `_ready()` moves the replacement raptor to the marker and calls `prepare_ambush()`. Power consumes the fuse, opens the exit and starts `ambush_remaining`. After 1.4 seconds `_start_ambush()` immediately reveals/activates the raptor and emits `ambush_started` once. Death/completion cancel the countdown; scene reload handles restart.
- `arca/enemies/raptor.gd`: dormant state hides the predator, clears collision and ignores hits. `activate_ambush()` restores collision and enters the 0.7-second alert before chase. Reuse its imported Walk animation and collision-aware `CharacterBody3D` movement for emergence; retain the no-argument activation behavior used by existing tests/test rooms.
- `arca/enemies/raptor.tscn`: capsule radius 0.45, height 1.45; navigation radius 0.55. Visible dinosaur geometry needs additional clearance. `arca/mission_navigation.tres` supplies static mission navigation.
- `arca/tests/ambush_test.gd` inherits mission helpers and covers warning, single activation, navigation and lifecycle cancellation. Its fixed 90-frame activation wait assumes the old sequence and must become a bounded phase-aware wait, not a weakened assertion. `arca/tests/mission_test.gd` covers the accepted corridor and kill-optional exit; `arca/tests/raptor_test.gd` covers existing combat.
- `scripts/check.sh` imports and runs launcher checks plus first-playable, raptor, mission and ambush suites. `README.md`, `docs/DESIGN.md` and `docs/VALIDATION.md` currently describe an appearing predator and pending corridor acceptance.

## Approved implementation sequence

1. After approval, inspect Git status again, stop play and save/reload any open Godot scene before external edits. Wait for active imports and establish the supported check baseline.
2. Add a mission-only shallow bay: back/sides/frame, closed sliding hatch mesh with matching collision, an interior start marker and an outside clearance marker. Reposition the existing ambush marker only as needed. Keep the bay separated from the fuse alcove and powered exit; check a sightline from the panel approach. Reuse alarm/signage, placing the warning at the hatch.
3. In the mission script, extend the single power-triggered sequence with explicit warning/opening/emergence/active progression. Animate the hatch panel and its collider together; begin emergence only after the opening is clear. Use scene-bound, pause-aware motion and explicitly cancel pending motion/callbacks on death/completion. Guard callbacks against cancellation, restart and duplicate starts. Preserve `ambush_started` as a once-only successful predator activation signal, now at the start of visible emergence.
4. Add the smallest opt-in emergence behavior to the existing raptor script: reveal the same instance inside the bay, restore its normal collision, play Walk, and move toward the outside marker with real physics. Do not chase, turn toward a player behind the wall or bite until clear. Then hand off to the existing ALERT/CHASE flow. Keep normal activation unchanged outside this mission path. Dormant immunity ends on emergence; being shot/killed or `stop_combat()` must stop the movement without a later callback reviving combat. Include an appropriate telemetry label for the added state.
5. Bake mission navigation for the new static bay/frame and clear hatch opening, excluding the movable closed leaf from the traversable bake where necessary. Closed-leaf physics still blocks passage. Do not alter base-room resources or create a route through the unpowered exit. Verify actual emergence and subsequent navigation, not just a nonempty path.
6. Extend the existing ambush suite with focused phase/physics/lifecycle checks below. Retain corridor, controls and combat assertions. Update the three affected docs with user acceptance, the implemented entrance and actual verification results; keep this task's status and remaining F5 validation current.

## Tests and validation

Extend `arca/tests/ambush_test.gd` to verify:

- Initially the hatch physically blocks its opening and the sole raptor is dormant, invisible, non-solid and immune to stray hits. Power starts one warning; no early reveal, movement or player damage occurs.
- The hatch mesh/collider moves visibly over time, blocks while closed and clears before emergence. The same raptor moves from inside to outside through the opening over multiple physics frames, without teleporting or intersecting bay walls. No attack/damage before clearance; normal alert/chase and meaningful navigation progress follow.
- Pause separately during warning, opening and emergence: countdown, hatch position and raptor movement freeze, then resume once. Death/restart/completion during each unfinished phase prevent delayed movement, activation or combat; restart restores closed/dormant state.
- Repeated E produces one `ambush_started` signal and one predator. Killing the exposed raptor during emergence prevents later chase. The powered exit remains usable without a kill, including completion before the entrance finishes.
- Use bounded phase-aware waits and sample real position/collision changes. Preserve existing progress, occlusion and cancellation assertions; do not merely replace old frame counts with larger arbitrary delays. A player blocking the threshold must not cause clipping, teleportation or an attack before clearance.

Supported final command from the ARCA root (also use for the baseline):

```sh
bash scripts/check.sh
```

For focused iteration after imports, use the executable resolved by `scripts/godot_common.sh` with the existing runner arguments: `--headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/ambush_test.gd`. Set `GODOT_BIN` for the full check if discovery fails; inspect missing tools before relying on the historical local ripgrep workaround. Expect all suites to pass with no script/runtime errors; report actual counts only after running them. Also inspect `git diff --check` for touched files and the final diff/status. Do not commit.

### Short F5 checklist after implementation

1. Collect the corridor fuse, return to the panel and restore power. Confirm a clear warning, a visibly opening hatch and the same raptor walking out, with time to react and no control/camera takeover.
2. Evade through the green exit without firing; restart, then separately confirm shooting the emerging/active raptor still works.
3. Pause/resume during opening and walk-out; restart during the sequence. Check that motion freezes/resumes correctly and restart restores a closed hatch and no visible predator. Verify death/completion produces no later entrance action.

## Risks and remaining validation

- A hatch over an unchanged solid wall is not an entrance. Build a real recess/opening, size it for the visible mesh, and check moving collision/physics synchronization before activation.
- Navigation must reflect static walls without treating the closed movable hatch as a permanent obstruction. Keep the existing exit collision contract and accepted corridor route intact.
- Camping at the opening can obstruct the predator; never solve this by teleporting through the player or enabling premature melee. Test obstruction and recovery when the player moves away.
- Added phases introduce late-callback hazards, especially death/completion during opening or emergence and shooting the raptor before handoff. Explicit cancellation and state guards are required.
- Implementation and automated checks are complete; hatch F5 acceptance remains pending. Headless logic/physics cannot establish visual readability, reaction comfort or GPU performance.

## Implementation handoff

- `arca/mission_room.tscn`: added a shallow service bay facing the panel side, a matching mesh/collider sliding hatch, readable signage/light and an outside clearance marker. The accepted corridor partition supplies the bay's back wall; no redundant new wall or base-scene change is needed. Navigation is rebaked in `arca/mission_navigation.tres`.
- `arca/mission_room.gd`: explicit warning/opening/emergence/active/cancelled phases. The one-second leaf animation is stepped in physics rather than a Tween: mesh/collision move together, pause naturally freezes it, and cancellation leaves no delayed callbacks. The original 1.4-second warning and independently opening exit remain.
- `arca/enemies/raptor.gd`: opt-in EMERGE state walks the same shootable instance through the opening at 1.6 units/second, then hands off to the existing alert/chase. It cannot bite, chase, teleport through an obstruction or revive after death during emergence. Existing no-argument activation and normal combat are unchanged.
- `arca/tests/ambush_test.gd`: 44 focused phase/physics/lifecycle checks, including obstruction recovery and death during emergence. Existing corridor, controls and combat suites are unchanged. `arca/tests/capture_mission.gd` now stages the entrance phases as well as corridor views.
- `README.md`, `docs/DESIGN.md` and `docs/VALIDATION.md`: recorded corridor F5 acceptance, described the hatch and remaining visual acceptance, and documented checks/navigation rebaking.
- Validation: baseline gate passed 135 gameplay + 13 launcher checks; implementation gate passed 162 + 13, using the already available ignored local ripgrep binary in PATH. Focused raptor, mission and ambush runs also passed after fixing implementation-time issues. Godot import/full-suite compilation is the repository's GDScript syntax/type gate. No engine, dependency, controller, combat-balance or base-room changes.
- Rendered X11/Compatibility captures used Mesa llvmpipe software OpenGL, showing the closed/partially open hatch and the same raptor inside/outside. Artifacts are ignored under `.artifacts/hatch-captures/`; they are not manual acceptance or GPU performance results. See `docs/VALIDATION.md` for known bake/display warnings.
- Remaining: run the short F5 checklist above to assess reaction comfort, readability and optional combat/escape. No commits or pushes were made.

---

# Previous task: repository cleanup

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
- Gameplay behavior is unchanged. No new F5 acceptance is required for Git metadata changes. The corridor playtest was pending at this cleanup handoff; the user subsequently accepted it on 2026-10-17, as recorded in the current task above.

---

# Previous task: service corridor and return route

Status: implemented and subsequently accepted by the user in an F5 playtest on 2026-10-17: "The service corridor works in my F5 playtest." The plan and original handoff below are retained as history; no human return-time measurement was supplied.

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

The automated return route measured about 19.6 simulated seconds with real root-motion walking and brief waypoint settling. Automated checks and staged software-rendered captures are recorded in `docs/VALIDATION.md`. At the original handoff, manual route-and-camera acceptance and human walking timing were pending. The user subsequently accepted the corridor on 2026-10-17; human walking timing was not reported.

## Commit handoff

`AGENTS.md` now requires the current task, implementation status and remaining validation to stay documented in `TASK.md`. Every commit of task changes must include the corresponding `TASK.md` update in the same commit, never as a separate follow-up. This does not authorize automatic commits. The corridor's subsequently reported F5 acceptance is recorded above.

## Risks and edge cases

- The room inherits decorative walls and cover: a corridor that looks clear may contain inherited collision. Inspect the composed scene before finalizing placement.
- A narrow opening may fit the player but reject the navigation agent or cause camera clipping. Widen the blockout rather than changing the controller or predator radius.
- Baked navigation can disagree with physics geometry or include isolated surfaces. Validate actual traversal, not only resource serialization or path existence.
- The closed sliding exit must remain a real barrier after rebaking; escape must still require restored power and a fully opened door.
- Relocating the fuse invalidates hard-coded positions in tests and any visual capture helper. Inspect affected helpers and update only location-dependent setup if needed; do not mistake staged captures for gameplay acceptance.
- Headless checks cannot establish route readability, camera comfort or rendered quality. Manual F5 review is required before calling the layout accepted.
