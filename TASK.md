# Task: inspect Regina and create an isolated character test scene

Status: implemented on 2026-10-17 following the user's explicit `implement` invocation. The isolated scene, Godot inventory, TPS assessment and attribution are delivered; 93 focused checks and the clean-import gate (162 gameplay + 13 launcher checks) pass. Original-FBX comparison is blocked by unavailable source files; user F6 appearance/rig acceptance and a fresh human F5 check remain pending. No TPS integration, commit or source-GLB modification was made. Previous task records are preserved below.

## Goal and mandatory contracts

Inspect `arca/assets/characters/regina/regina.glb` in **Godot 4.5.1 Standard / Compatibility**, list the imported skeleton/bones, animation clips, materials and textures, and create a separate scene for judging scale, orientation and appearance. Assess the work needed for existing TPS movement, aiming and shooting; do not implement that integration. If missing/broken data warrants comparison, inspect the original Regina FBX without overwriting the GLB.

Acceptance:

- A documented Godot inventory distinguishes source data from importer-generated nodes, bones or RESET animations, with actual node paths, bone hierarchy, material/texture assignments and animation names/durations/looping (or explicit absence).
- `arca/character_test.tscn` opens and runs with F6, showing the skinned model under neutral lighting, a metric reference, ground and labeled axes. Record final world-space height, foot offset, facing direction and any explicit wrapper correction. Front/side/back and close-up checks establish appearance, not just successful resource loading.
- The report identifies concrete TPS blockers and a smallest follow-up, without replacing the mission player, changing controls or adding animations/IK.
- Preserve the supplied asset, uncommitted work, upstream controller, camera, weapon and mission inheritance. Keep the main scene `arca/mission_room.tscn` unchanged.
- Add attribution: **"DinoCrisisCustom - Regina"**, **Otherspectre**, <https://skfb.ly/pCKMp>, **CC BY 4.0**, <http://creativecommons.org/licenses/by/4.0/>. Describe modifications/conversion only when verified; retain embedded notices.

## Assumptions, unresolved inputs and non-goals

- An inspection scene, not a playable Regina controller, is the intended deliverable. A static camera for F6 plus the editor's viewport orbit is sufficient; no new viewer framework or runtime UI is needed.
- Initial Git status: only `?? arca/assets/characters/`. Treat this GLB as user work. No Regina `.import` or cached imported scene existed at inspection time.
- The existing Godot editor is open on ARCA. Before implementation, stop play, save open scenes and wait for imports; reload external scene changes. Do not launch a competing editor/import process.
- **Missing input:** no Regina FBX was found anywhere in the repository; the only FBX found is the unrelated raptor source. `Mesh.fbx` inside the GLB is a node name, not an available FBX file. If source comparison is needed, ask for the original FBX/archive and its textures/location. Do not download an assumed source or claim a conversion lost clips without comparison. The standalone GLB assessment can proceed while that comparison remains blocked.
- Non-goals: mission/player replacement, actual animation retargeting or authoring, new weapons, IK, controller refactoring, camera redesign, resource-economy work, asset optimization or engine/dependency changes. The user-requested asset inspection is separate from the economy candidate in `docs/DESIGN.md`.

## Read-only source findings at planning time

These baseline findings predate implementation. The verified Godot paths, imported inventory and measured posed bounds are now in `docs/REGINA.md`; do not treat the planning-time unknowns below as unresolved import results.

The 5,877,192-byte file has a consistent GLB 2 header. Its metadata identifies Sketchfab-16.75.0, Otherspectre, the model title and CC-BY-4.0; it does not establish the local conversion workflow. Source counts: **84 nodes, one unnamed skin, 69 joints/inverse-bind matrices, nine skinned meshes/surfaces, nine materials, 17 textures/images, zero animations and zero morph targets**. Mesh totals: 13,937 accessor vertices, 23,941 triangles. All images/buffers are embedded; no external URI dependencies.

All 17 PNGs passed chunk CRC and IDAT decompression checks. Inverse-bind entries are finite; joint indices fit the 69-joint skin; there are no zero-total-weight vertices, and maximum weight-sum error is below 0.00000009. These checks do **not** establish correct bind/rest poses, normals, deformation or rendered appearance.

### Skeleton and bones

Source hierarchy above the joints: `Sketchfab_model -> Mesh.fbx -> RootNode -> Armature -> Object_4 -> _rootJoint`. The skin's skeleton root is `_rootJoint`; Godot's `Skeleton3D` name/path and any name sanitation remain to be inspected. Complete source joint hierarchy below (original spelling preserved):

```text
_rootJoint
  root ground_01
    root hips_02
      spine lower_03
        spine middle_04
          spine upper_05
            head neck lower_06
              head neck upper_07
                head jaw_08
                head hair upper_09
                head hair back 1_010
                  head hair back 2_011
                head hair right 1_012
                  head hair right 2_013
                head hair left 1_014
                  head hair left 2_015
                head hair front middle 1_016
                  head hair front middle 2_017
            arm right shoulder 1_018
              arm right shoulder 2_019
                arm right elbow_020
                  arm right wrist_021
                    arm right finger 5a_022
                      arm right finger 5b_023
                        arm right finger 5c_024
                    arm right finger 4a_025
                      arm right finger 4b_026
                        arm right finger 4c_027
                    arm right finger 3a_028
                      arm right finger 3b_029
                        arm right finger 3c_030
                    arm right finger 2a_031
                      arm right finger 2b_032
                        arm right finger 2c_033
                    arm right finger 1a_034
                      arm right finger 1b_035
                        arm right finger 1c_036
            arm left shoulder 1_037
              arm left shoulder 2_038
                arm left elbow_039
                  arm left wrist_040
                    arm left finger 5a_041
                      arm left finger 5b_042
                        arm left finger 5c_043
                    arm left finger 4a_044
                      arm left finger 4b_045
                        arm left finger 4c_046
                    arm left finger 3a_047
                      arm left finger 3b_048
                        arm left finger 3c_049
                    arm left finger 2a_050
                      arm left finger 2b_051
                        arm left finger 2c_052
                    arm left finger 1a_053
                      arm left finger 1b_054
                        arm left finger 1c_055
          boob right 1_00
            boob right 2_056
          boob left 1_057
            boob left 2_058
      leg right thigh_059
        leg right knee_060
          leg right ankle_061
            leg right toes_062
      leg left thigh_063
        leg left knee_064
          leg left ankle_065
            leg left toes_066
      belt holser_067
```

### Animation clips

**None in the GLB.** A generated Godot RESET clip would not supply locomotion or prove lost source animations. Original-FBX comparison is needed to determine whether the source also lacks clips.

### Materials and embedded textures

Exact source material names are below. For each material, texture filenames use that name plus `_baseColor.png` and `_normal.png`; eyelashes have only `_baseColor.png`. Filenames are stored as buffer-view labels, not external files. This accounts for all **nine albedos and eight normals**.

| Material | Base color | Normal | Alpha / special data |
| --- | --- | --- | --- |
| `24_costume.reginadtga_0.25_0_0` | 1024 x 1024 | 1024 x 1024 | Opaque; roughness 0 |
| `24_holster.holsterdtga_1_0_0` | 256 x 512 | 256 x 512 | Opaque |
| `24_eyetga_1_0_0` | 256 x 256 | 256 x 256 | Opaque; specular extension |
| `24_facedtga_0.25_0_0` | 1024 x 1024 | 1024 x 1024 | Opaque |
| `24_reginau1v1u1v1tga_0.25_0_0` | 1024 x 1024 | 1024 x 1024 | Opaque |
| `25_4tga_0.25_0_0` | 512 x 512 | 2 x 2 | Opaque; tiny normal map is present, not evidence of corruption |
| `25_hair2dtga_0.25_0_0` | 512 x 512 RGBA | 512 x 512 | MASK cutoff 0.771057; specular extension |
| `25_hairdtga_0.25_0_0` | 512 x 1024 RGBA | 512 x 1024 | MASK cutoff 0.136372 |
| `7_eyelashtga_0.1_0_0` | 256 x 128 RGBA | None | MASK cutoff 0.778979 |

All materials are double-sided and metallic 0. There are no dedicated roughness/metallic/occlusion maps; roughness is scalar. Inspect Godot's handling of `KHR_materials_specular`, hair/eyelash cutouts, normal maps and the glossy costume before proposing material changes.

Combined raw POSITION accessor bounds are approximately X [-0.793, 0.793], Y [0.011, 1.810], Z [-0.082, 0.196]. These are **unskinned mesh-local** bounds, not a verified 1.8 m standing character. Several ancestor transforms rotate axes; measure the actual imported posed model before choosing scale/yaw or modifying any transform.

## Existing TPS flow and integration assessment

Relevant existing files:

- `player/player.gd`: camera-relative input selects walk/strafe/jump; `AnimationTree` root motion supplies horizontal velocity to `CharacterBody3D.move_and_slide()`. The model's world basis is set every physics frame, so a future visual correction must live below that controlled pivot.
- `player/player.tscn`: `AnimationTree` uses `PlayerModel/AnimationPlayer` and `Robot_Skeleton/Skeleton3D:root` as its root-motion track. It references `Idle`, `Idlecombat`, `running_nogun`, `running_gun`, four strafe clips, three jump/fall/landing clips, `AIM-Up`, `AIM-Down` and `eyes`. Aim/eye filters name robot-specific bones. `GunBone` attaches to `hand.R`.
- `player/player_input.gd`: existing mouse/aim camera blend, crosshair raycast and world-space shoot target. Preserve these behaviors.
- `arca/player/arca_player.tscn` inherits `player/player.tscn`; `arca/player/arca_player.gd` adds health, death handling and a chest-to-muzzle cover sweep. The latter assumes a chest height of 1.4 m; camera pivot is currently 1.6 m. Model scale needs comparison against these existing references, not an immediate controller change.
- `player/player.gd` resolves the muzzle at `PlayerModel/Robot_Skeleton/Skeleton3D/GunBone/ShootFrom`; `shoot()` also hard-codes particle paths beneath it. Shooting uses that origin toward the existing camera target, then starts particles, cooldown, sound and shake.
- `arca/tests/first_playable_test.gd` already exercises actual movement, aim/fire, cover-safe muzzle origin and lifecycle. `scripts/check.sh` imports and runs first-playable, raptor, mission and ambush suites.

Assessment to confirm in Godot: this is **not a drop-in mesh swap**. No source clips exist to drive horizontal root motion; swapping the robot animation library would stop movement. A later integration needs a verified humanoid bone/rest-pose map (including shoulder/neck differences), compatible retargeted or newly authored idle/run/strafe/jump animations with usable root translation, and aim poses/filters rebuilt for Regina. Bone renaming alone does not retarget transforms. Map a potential humanoid head to the upper-neck joint only after inspecting its rest pose; there is no explicitly named head joint.

A later weapon setup needs a right-wrist `BoneAttachment3D`, a verified/licensed weapon visual and muzzle marker/effects, plus minimal handling of the robot-specific paths while retaining camera-target direction and cover safety. No source joint is named gun/muzzle; holster geometry is not evidence of a usable gun. This task documents those needs, not a solution framework. Reuse the existing controller rather than duplicating it. Recommend the next bounded step only after asset/import findings and missing animation/source availability are known.

## Proposed minimal implementation sequence

1. **Import and inspect without replacing assets.** Save the active editor's scenes, finish pending imports, import the supplied GLB using Godot 4.5.1, and inspect warnings and Advanced Import settings. Retain source-side `.import` and any generated source resources/UIDs needed for reproducibility; do not track `.godot/` or logs. Confirm actual skeleton paths, bone hierarchy/rest transforms, mesh skin bindings, material/texture mapping and animation inventory. If a material extension is unsupported, record the exact limitation rather than silently dropping it.
2. **Create `arca/character_test.tscn`.** Use a standalone `Node3D`, neutral environment/light, plain ground, a one-meter reference/height ruler, labeled +X/+Y/+Z axes and Godot -Z forward marker, a fixed three-quarter camera, and the original GLB instance under `ModelPivot`. Start with identity corrections; only apply an explicit, documented wrapper scale/rotation/foot offset if measured import behavior requires it. Do not edit/bake the GLB, drive TPS scripts, add mission nodes or auto-play nonexistent clips. Inspect front/side/back in the editor and rendered F6 view; no extra runtime controller is required.
3. **Resolve concrete discrepancies.** Verify skin/rest alignment and small temporary editor bone rotations without saving altered poses. If missing animations or bad geometry/materials warrant comparison, obtain the original Regina FBX and matching textures, import it separately, compare counts/poses/clips/assignments and record results. Keep the supplied GLB intact. Stop for re-scoping before a conversion repair, animation production or new dependency; if source is unavailable, report the blocked comparison explicitly rather than claiming success.
4. **Add one focused inspection/smoke script, `arca/tests/regina_test.gd`.** Follow the existing `SceneTree` PASS/FAIL/RESULT pattern, exit nonzero on failure, instantiate the new scene and emit the actual imported inventory. Check the source joints have corresponding imported bones (accounting for documented importer renaming/additions), all nine mesh parts have valid skin/material bindings, all 17 expected texture mappings resolve with dimensions, transforms/bounds are finite and nonempty, and the scene has a current camera. Report zero authored clips as valid for this asset; distinguish RESET if generated. Do not add brittle pixel assertions or fabricate movement tests for a static model. Leave the existing gameplay gate unchanged; run this focused tool separately.
5. **Document and hand off.** Put verified findings, full imported inventory, source-vs-Godot differences, measured transforms, FBX availability/comparison and concrete TPS blockers in `docs/REGINA.md`; add a short F6 entry to `README.md`; add the supplied credit to `ATTRIBUTIONS.md`. Review its blanket statement about no Dino Crisis assets against the actual provenance: a CC credit for a fan model does not establish ownership of underlying character/IP or prove independent/extracted origin. Make no unsupported provenance claim. Update `TASK.md` and `docs/VALIDATION.md` with only checks actually run and remaining manual/source limits. Keep the mission placeholder status accurate; do not change the gameplay roadmap.

## Validation and expected outcomes

During implementation, after the editor's imports finish (do not run these during this planning pass):

- Run the new focused script with the discovered engine: `/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd` (command becomes runnable after the script exists). Expect a readable imported inventory, all resource/binding smoke checks passing, a clean exit and no script/runtime errors. Headless results cannot establish skin appearance, alpha quality or GPU performance.
- Run `bash scripts/check.sh` with Godot 4.5.1, using `GODOT_BIN` if needed. Its import step must succeed, and existing movement/aim/shoot/cover and mission suites must stay green. Historical baseline is 162 gameplay checks and 13 launcher checks, not a fresh result. `rg` is currently absent from PATH; the documented local workaround is `.artifacts/baseline-tools/ripgrep/usr/bin/`, or install the README prerequisite. Do not change the launcher to hide the missing prerequisite.
- Manual **F6**: open `arca/character_test.tscn`, verify visible full model/metric reference, measured feet/ground alignment and facing axes; inspect skin/hair/eyelashes/eyes/holster and front/side/back under Compatibility. Compare rest pose and temporary joint deformation in the editor. Report whether any visible defect is present, with reproduction details.
- Manual **F5**: confirm the mission still starts with the existing robot and unchanged movement, camera, aim/fire and pause/restart. Do not infer visual acceptance from headless checks.
- Run `git diff --check` and review final status/diff; no application edits in the planning pass and no commits unless requested.

## Risks and stop condition

Root-axis rotations, bind/rest mismatch and import name sanitation can mislead raw bounds and bone mapping. Embedded PNG validity does not prove texture colors, normal orientation or alpha thresholds are correct; imported materials may approximate source specular behavior. Generated RESET is not locomotion. CC BY metadata is an attribution requirement, not verification of underlying third-party rights. Do not expand an inspection into asset repair or full TPS integration.

Stop when the isolated scene and verified inventory/integration assessment are delivered and checks/manual results are recorded. If the original FBX remains unavailable, explicitly leave source comparison unresolved. Approval of this plan does not approve a character-controller replacement.

## Implementation handoff

- Added `arca/character_test.tscn`: standalone scene, original GLB under a visual wrapper, neutral environment/lights, ground, 2 m ruler/0.5 m ticks, 1 m reference, world axes, -Z forward marker and fixed F6 camera. The measured upright character is 1.798599 m tall; native facing is +Z and feet start at Y 0.011233 m. The instance uses yaw 180 degrees and Y -0.0112332 m, scale 1. No GLB/bone/material edits or gameplay script changes.
- Godot confirms one `Skeleton3D`, all 69 unchanged bone names/parents, nine mesh/material parts, 17 texture mappings and no `AnimationPlayer`/clips/RESET. The existing editor completed import before inspection; retain `regina.glb.import`, extracted `regina_0.png` through `regina_16.png` and their `.import` settings. The GLB SHA-256 is recorded in `docs/REGINA.md`.
- Added `arca/tests/regina_test.gd` and its engine-generated `.uid`; it emits the inventory and checks actual hierarchy, bindings/weights, materials/textures, alpha behavior, finite posed bounds, feet/scale/current camera, unchanged main scene and reversible wrist deformation. CPU skin measurement avoids unavailable Dummy-renderer bake registration; rendered pose bakes agree within about 0.00003 m. Editor diagnostics: no errors/warnings.
- Focused checks: 93/93 against the working project and a clean-import copy. Full supported `bash scripts/check.sh`: launcher 13/13; first-playable 42/42; raptor 24/24; mission 52/52; ambush 44/44. No import/GDScript compilation errors/warnings or gameplay script/runtime errors. Used the existing local ripgrep PATH workaround, not a dependency/launcher edit.
- Justified validation deviation: the working Godot editor stayed open, so a source-only copy under ignored `.artifacts/regina/validation-project/` ran the import/gameplay gate without a competing import into the live project. The tested application/script sources match the working source. Diagnostic logs/captures stay ignored. Preliminary diagnostic/test failures and their fixes are recorded in `docs/VALIDATION.md`, not hidden as passing results.
- Inspected actual X11/Compatibility/llvmpipe captures: overview/front/side/back, face close-up and temporary elbow bend. No obvious missing texture, detached part or exploded rest skin in those views. Bright hair/specular and skin shading remain appearance considerations. The source's two `KHR_materials_specular` factors become Godot's default 0.5 scalar; documented, not arbitrarily repaired. Software-display input-method/V-Sync warnings remain; captures are not a human playtest or GPU benchmark.
- Added `docs/REGINA.md` with the complete imported bone/material/texture inventory, measurements, FBX blocker and concrete root-motion/aim/weapon-path requirements. Updated `README.md`, `ATTRIBUTIONS.md` and `docs/VALIDATION.md`. Credit uses the user's exact title/creator/source/CC BY 4.0 links. Replaced the previous blanket no-Dino-Crisis-assets assertion with an explicit fan-model provenance limit; no underlying rights or independent creation is claimed.
- Final review: `git diff --check` and new-file whitespace checks passed. All 121 application/asset files compared against the clean-validation snapshot are byte-identical; the supplied GLB SHA-256 is unchanged. Final status contains only the planned docs, scene, smoke script/UID and untracked character asset/import files. No commits or branches were created.
- Remaining: supply the original Regina FBX/archive plus textures for comparison; `Mesh.fbx` is only a GLB node name. User should inspect F6 scale/appearance/bones and F5 unchanged robot movement/aim/fire/pause/restart. No source conversion loss, full deformation readiness, user acceptance or integration success is claimed. Recommended next bounded action is obtaining the original source, not rewriting the controller.

---

# Previous task: close service-hatch acceptance, with targeted fixes only if needed

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
