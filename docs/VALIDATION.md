# Validation

Validated on 2026-10-17 with **Godot 4.5.1 Standard** on Linux using the Compatibility renderer. Run `bash scripts/check.sh` to reproduce the import and headless suites.

**Integrated gate: green.** The launcher passed 13 checks and the gameplay suites passed all 612 checks. The user accepted vertical aim in F5 on 2026-11-22. The user accepted the combined F5 playtest for lateral movement, economy and endings on 2026-11-24.

| Suite | Checks passed | Coverage |
| --- | ---: | --- |
| `first_playable_test.gd` | 42 | Real TPS input, movement, aiming, projectiles, cover, laser damage, death, pause and restart |
| `raptor_test.gd` | 59 | Ferocious model/source bindings, tracks, root anchoring, gait/bite timing and pause/resume; detection, navigation around cover, bite windup/dodge/occlusion, death and actual weapon hits |
| `mission_test.gd` | 61 | Mission lifecycle, real corridor traversal, restart and summary values including pause, shots, damage and both endings |
| `ambush_test.gd` | 47 | Physical hatch, emergence, lifecycle cancellation, predator evasion summaries and navigation |
| `regina_player_test.gd` | 378 | Gameplay rig, locomotion, jump, grip, aim and skinned lateral sole contact |
| `economy_test.gd` | 25 | Ammo, reload, pickup interaction, health and Backspace restart |
| **Gameplay total** | **612** | Logic and physics checks against actual scenes |

The new ambush suite restores power through the actual interaction input path. It does not require killing the predator to complete the mission. The existing raptor suite separately verifies that actual player projectiles can kill it.

Additional checks: shell syntax for all launch/check scripts; parsing of Zed JSON; repository skill frontmatter validation; scene/material UID alignment with tracked import settings; archive extraction and clean Godot import. Git caches and local outputs are excluded from the archive, while `.uid` and source-side `.import` settings are included.

Rendered captures of the actual mission before and after power restoration were inspected using a software OpenGL GPU on a virtual X11 display. These checks confirm the English HUD, room, opened door, alarm and visible predator; they are not NVIDIA performance measurements. The capture script stages mission state for inspection and is not a manual completion of the mission.

An optional visual helper is `arca/tests/capture_mission.gd`. It requires a display; run Godot with `-s res://arca/tests/capture_mission.gd -- /absolute/output/directory` after importing. `capture.gd`, `capture_raptor.gd` and `shadows_test.gd` remain optional diagnostic tools outside the standard headless command.

## Mission endings

The full `bash scripts/check.sh` gate passed with the new win and death summaries. Manual inspection of staged X11/Compatibility captures on Mesa Intel Iris Xe confirmed the ammo panel, reload label and both outcome modals fit in the rendered view. See `.artifacts/final-playtest/`. The combined F5 run covers play feel, sound and continuous transitions.

## Mission resource economy

`economy_test.gd` adds 21 passing integration checks for real firing input, an empty magazine, manual and automatic reload, frozen reload during pause, death cancellation, HUD feedback, pickup range and occlusion, medkit limits and Backspace restart. The full gate passed before work on the mission summary. The final F5 checks cover pickup readability and resource pressure.

## Interaction contract (S1-01)

`economy_test.gd` adds 10 checks (economy suite 25 → 35) for group discovery. A runtime-instanced `ammo_pickup.tscn` with `amount = 5` joins the group, is prompted as `Collect 5 rounds`, grants exactly +5 reserve on one E press and disappears, with no change to `mission_room.gd`. Two E presses in one frame, or a held E with repeat echoes, collect only one of several pickups in range. A pickup outside the room subtree is ignored. A pickup behind the real corridor partition is in range but not offered or collected. Disabling the same-frame guard makes the double-press check fail. Mission 61, ambush 47 and the original economy checks pass unchanged.

## KayKit lateral retarget trial (2026-11-22)

The local Free 1.1 archive includes left and right running strafes on the 23-joint Medium rig. The tested lower-body and spine retarget preserved the root-motion and upper-body tracks. With the existing constant floor alignment, the higher sole minimum in each clip was **0.110915 m** (left) and **0.108579 m** (right) against the **0.02 m** criterion. Penetration, direction, facing, blend, speed and aim checks passed.

The full gate stopped with the two sole-contact failures. The trial files and logs are retained in `.artifacts/phase2-kaykit-candidate/`. The trial was set aside before testing the Quaternius UAL2 replacement.

## Source-based lateral footwork

KayKit ankle-axis and local-rest variants still left a sole above the threshold. The Quaternius UAL2 `Walk_L_Loop` and `Walk_R_Loop` replace the lateral leg, hip and spine tracks using the existing anatomical retarget and constant floor alignment. The runtime blend names, duration and root-motion curves are preserved. Both clips pass the unchanged 2 cm support and 2 mm penetration thresholds. Measured sole minima are **(0.003057, 0.000500) m** and **(0.000500, 0.001127) m**. The full headless gate passed with **378/0** Regina checks, including directional speed and aim/grip. The existing Compatibility capture helper completed for F6 idle/walk/run. The final F5 checklist covers actual lateral movement.

## Source-based Regina vertical aim (2026-11-22)

- The initial regression run reproduced upper barrel Y −0.197449 against neutral +0.055167. After the bake the barrel direction in player space is **(−0.536926, +0.260033, +0.802554)** at full up and **(−0.324596, −0.147854, +0.934225)** at full down. Both extremes have zero right or left hand skin-triangle intersections against the slide/barrel boxes inset by 1 mm. The visible barrel arc differs from the camera arc.
- Both pinned donor hashes match the provenance record. The repeated gameplay bake produced byte-identical output. The generated diff changes only the two vertical aim clips.
- `bash scripts/check.sh` exited 1 with the two known lateral sole failures (0.066335 m and 0.059787 m against 0.02 m). Launcher 13, first-playable 42, raptor 59, mission 52 and ambush 44 all pass. The user F5 checklist in [README.md](../README.md#vertical-aim-f5-checklist) covers the continuous sweep, lateral aiming and fire around cover.

## Ferocious Industries gameplay replacement (2026-10-17)

Phase 0 recheck on 2026-11-22 with `bash scripts/check.sh`: launcher 13/0, first-playable 42/0, raptor 59/0, mission 52/0 and ambush 44/0 (checks/failures). Regina-player ran 373 checks with the same 3 failures described below.

The user explicitly authorized replacing the existing raptor, not adding another enemy. Promoted only the audited official glTF, textures and notice, plus a derived presentation library and visual wrapper. `arca/enemies/raptor.gd`, mission/controller/Regina code, collision and combat values are unchanged. The previous Quaternius asset is retained as a source/reference, not instantiated as another predator.

- Saved the clean active raptor scene before editing. Reloaded only that scene after integration and confirmed the new wrapper is active and the source AnimationPlayer is disabled through read-only editor inspection.
- Baseline `bash scripts/ai_check.sh`: `.artifacts/ai-check-xecv7u8k`; first-playable 42, raptor 24, mission 52, ambush 44 pass; Regina-player **373 checks, 3 failures**.
- Final post-change full gate: `.artifacts/ai-check-kzqb11kb` (an earlier equivalent pass/failure result is retained at `.artifacts/ai-check-vqxa_bn4`); launcher **13**, first-playable **42**, expanded raptor **59**, mission **52**, ambush **44** pass. Regina-player remains **373 checks, the same 3 failures** with the same aim/sole measurements. The full command still fails overall; no assertion was weakened or unrelated failure repaired.
- New model checks cover all six authentic source mappings, original rig/root/jaw, valid finite tracks, no animation damage callbacks, source-driver exclusion, -Z facing/native scale, fixed root translation, calibrated walk/jog timing, unchanged 0.833333 s attack cycle, jaw opening/closure around the existing 0.24 s damage check, and pause/resume. Existing weapon, dodge, occlusion, navigation, death/restart and physical hatch tests still pass.
- Reproducible offline baker produces the separate derived six-binding AnimationLibrary; source data and notices are preserved. Bite's preparation prefix is trimmed and presentation retimed rather than changing damage timing or recovery. World/root travel is held in the derived binding rather than applied on top of CharacterBody3D movement.
- Rendered the actual staged mission/hatch sequence with **X11 / Compatibility / Mesa Intel Iris Xe** and inspected the new model in opening/emergence/after-emergence captures. Outputs: `.artifacts/raptor-replacement/`. Source material conversion warnings and contact limitations remain; no GPU performance, manual F5 acceptance or final art-quality verdict is claimed.
- Preservation check caught Godot's scene-save operation also reserializing cached Regina libraries. Compared all animation keys, times and track layout against exact pre-task hash-matching snapshots: no pose/timing changes. Restored only those serialization side effects to their original bytes and repeated the full gate above. Regina/player/mission/AI/project sources are unchanged from the initial manifest.
- User F5 acceptance recorded on 2026-11-22. To repeat: restore power, watch the new raptor walk through the hatch and chase, evade/bite/shoot it, inspect death, then pause/restart. Confirm only one predator and unchanged mission flow. Head/tail remain visual geometry around the unchanged collision capsule.

## Regina socket/grip follow-up (2026-10-17)

Used the source-only isolated project `.artifacts/regina-grip/source/` while the live Godot editor remained open. No competing import or existing scene-file overwrite was performed. The new socket scene wraps the existing handgun; the original GLB, source imports/clips, original gun geometry and isolated F6 library are preserved.

- Focused command: `godot --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_player_test.gd -- --weapon-grip-only` (using the documented literal 4.5.1 executable): **107 checks, zero failures**. Covers inherited room bindings, original robot defaults, 15 finger tracks plus additive wrist, evaluated socket/grip equality, unit scale, preservation of the prior barrel basis, and skin-triangle/metal clearance in 16 state/phase combinations. The same geometry probe detects the original clipping configuration. This is not a proof of final trigger/finger art quality.
- Full `bash scripts/check.sh`, with the existing Godot/ripgrep overrides: launcher **13**, first-playable **42**, raptor **24**, mission **52**, ambush **44** pass. Regina-player: **373 checks, 3 failures**. The command fails overall; do not report a passing gate.
- Failures: prior lateral sole minima **0.066335 / 0.059787 m** against **0.02 m**, plus newly checked upper aim: barrel Y **-0.197449** versus neutral **+0.055167**. This exposes an existing robot-to-human pose incompatibility after correcting additive rest/endpoint encoding; it is not a failed projectile/cover test.
- Separate unchanged source/locomotion suites: **93/68 checks**, zero failures. Default subset extraction reproduces the existing locomotion GLB byte-for-byte; new pistol subset source hashes match the pinned Standard inputs.
- Staged X11 / Compatibility / Mesa Intel Iris Xe close-ups and body views cover idle, run, neutral/up/down aim and a lateral pose. Captures are ignored under `.artifacts/regina-grip/after/`; baseline open-hand clipping is under `before/`. The first fixed-wrist trial was rejected because it changed evaluated aim; the delivered additive wrist correction preserves the original animated wrist/barrel relation. Extreme aim still has the documented donor-pose defect. Existing X11 input-method warnings remain; no GPU performance or human F5 acceptance is claimed.

Stop at the source gate: no suitable eight-way set is present in the obtained CC0 Standard inventory; no paid acquisition, fabricated clip coverage, IK or threshold relaxation was performed. Manual F5 must still inspect the grip from both sides, aim extremes, start/stop and continuous directional movement, real fire near cover, pause/restart/death/completion.

## Local baseline checkpoint

Rechecked on 2026-10-16 with `/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64`, reporting `4.5.1.stable.official.f62fdbde1`. All four suites above passed again: **111 checks, zero failures**. No gameplay scripts or test assertions were changed.

Reviewed and retained the editor/import changes:

- `project.godot`: expanded E/R input-event serialization preserves physical E/R bindings and default device/modifier values. Omitted window-mode and 3D-scaling settings still resolve to `0` (windowed and bilinear). Compatibility rendering is unchanged. A headless settings probe confirmed the effective values and bindings.
- The 15 texture `.import` files reflect Godot's 3D detection: lossless storage changes to lossy VRAM/S3TC compression, mipmaps are enabled, and the one-time 3D-detection callback is disabled. The format/path metadata describes the resulting imported resources; it is not just a cosmetic rename. Compression can introduce block artifacts, while mipmaps reduce distant shimmer and add mip-level storage. Source dimensions, size limits, texture UIDs and quality-slider values are unchanged.
- Three normal maps now explicitly enable normal-map compression. The robot/player normal textures disable their own roughness processing; their ORM textures reference the associated normal maps for roughness mip generation. Corrected the two ORM `roughness/mode` values from out-of-range `8` to `3` (Green), matching the materials' green roughness channel. Godot 4.5.1's texture importer defines modes `0–6`; see the [pinned importer source](https://github.com/godotengine/godot/blob/4.5.1-stable/editor/import/resource_importer_texture.cpp).

The first check attempt stopped because ripgrep was missing. Without changing system packages, Ubuntu's `ripgrep` 14.1.0 package was downloaded and extracted under ignored `.artifacts/baseline-tools/`. The successful command was:

```bash
PATH="$PWD/.artifacts/baseline-tools/ripgrep/usr/bin:$PATH" bash scripts/check.sh
```

The extracted tool, settings probe and test logs are local artifacts, not checkpoint content. For the normal check command without a PATH override, install ripgrep as described in the README. Headless checks do not establish rendered texture quality, visual polish or GPU performance; manual F5 verification remains required.

## Service corridor: route and camera experiment

Implementation adds a mission-only partition, screened fuse alcove, yellow entrance/return signage and floor guide. The initial camera heading frames the entrance. One inherited crate is moved only in the mission, and a thin colliding wall lining keeps the existing spring arm ahead of inherited decorative wall panels. Movement, camera-controller code, shooting and ambush timing are unchanged.

Focused regression coverage now includes initial entrance framing/sightline, fuse concealment from sampled main-room positions, blocked interaction through the actual partition while within pickup range, player movement against the partition, actual root-motion walking from spawn through the corridor and around the screen, the walked return and panel activation, camera clearance at the alcove, and raptor travel into and out of the corridor. These are logic/physics checks, not proof of universal visibility or camera comfort.

Rechecked with Godot 4.5.1 after the corridor changes: **135 gameplay checks and 13 launcher checks passed with zero failures**, using the documented local ripgrep PATH workaround. `git diff --check` passed in both the ARCA root and the nested `arca` Git worktree. No commits were made in either worktree.

The scripted ordinary-walking return measured **19.6 simulated seconds**, including brief settling at six waypoints. On **2026-10-17**, the user reported: "The service corridor works in my F5 playtest." The corridor is accepted by the user. No human timing measurement or separate camera/performance observations were supplied; do not treat the automated timing or staged captures as those measurements.

Software-OpenGL staged captures were generated using `capture_mission.gd` and inspected for the initial view, entrance, alcove screen and fuse. The helper now captures those corridor views as well as the original start/ambush views. Captures are local ignored artifacts under `.artifacts/corridor-captures/`; they do not establish human route timing, GPU performance or final visual acceptance. The rendered run reports existing X11 input-method/V-Sync warnings on this software display, not gameplay script errors. The navigation bake reports its existing agent-height voxel-rounding warning.

## Physical service-hatch entrance

Implemented on 2026-10-17 with mission-only primitive bay/hatch geometry, existing warning lights/signage and the existing raptor Walk clip. The bay reuses the corridor partition as its back wall. Power starts a 1.4-second warning, one second of physical hatch opening, then about 2.3 seconds of collision-aware emergence before the existing alert/combat flow. The exit opens independently and needs no kill.

`bash scripts/check.sh` passed using the existing local ripgrep PATH workaround: **162 gameplay checks and 13 launcher checks, zero failures**, with no script/runtime errors. The unchanged first-playable (42), raptor (24) and mission (52) suites passed, including real projectile kills and corridor traversal. The extended ambush suite passed **44 checks** covering:

- Closed/moving/cleared hatch collision; sign sightline above cover from the panel approach; hidden, non-solid and immune dormancy.
- The same raptor revealed inside the bay, continuous physics movement through the opening, Walk animation/telemetry, no wall contact or early bite damage, and real subsequent navigation progress.
- Separate pause freezes during warning, opening and emergence; death, restart and kill-optional completion cancellation during each phase; no duplicate activation or predator.
- A player obstructing the threshold blocks emergence without clipping or bites; moving away allows handoff. Weapon hits can kill the emerging raptor without a later revival/movement callback.

Mission navigation was rebaked against static bay geometry with the movable leaf clear/excluded. To reproduce in the editor, temporarily raise `ServiceHatch/Leaf` from Y `1.5` to `4.8`, bake/save the mission navigation resource, then restore the leaf to Y `1.5` before saving the scene. Keep the bay walls and closed powered-exit barrier in the bake. The bake reports agent-height voxel rounding and, in the temporary headless bake helper, navigation-map cell-size/height mismatch warnings; the normal gameplay gate reports no script/runtime errors. No navigation settings or warning suppression was changed.

`capture_mission.gd` now stages the panel sightline, closed hatch, partially open hatch, raptor inside the open bay and raptor outside, as well as the accepted corridor views. Rendered using X11/Compatibility and Mesa llvmpipe software OpenGL; captures are ignored under `.artifacts/hatch-captures/`. X11 input-method and unsupported V-Sync warnings remain on this software display. These captures are visual inspection aids, not a human F5 playtest or GPU performance measurement.

Editor diagnostics for the changed mission, raptor and ambush GDScript files report no errors or warnings. The aggregate editor report is not clean: it also attempts to parse Markdown as GDScript (for example, README prose produces "Unexpected identifier ... in class body") and reports Markdown line-length warnings. These are separate from the passing Godot import/gameplay gate; no editor/language-server configuration was changed.

Revalidated the unchanged implementation on 2026-10-17 during the hatch-acceptance task: **162 gameplay checks and 13 launcher checks passed, zero failures**, including all 44 ambush checks. Import and the full gameplay gate reported no script/runtime errors. The plain `bash scripts/check.sh` invocation first stopped because `rg` was absent from PATH; rerunning with the existing `.artifacts/baseline-tools/ripgrep/usr/bin/` directory prepended passed. No gameplay, test, engine or dependency changes were needed.

Manual acceptance completed on 2026-10-17: the user answered "yes" when asked whether the service hatch also passed the three-step F5 checklist in `README.md`. Record the hatch as accepted, including its readability/reaction comfort. The task is closed through documentation only, with no gameplay fixes needed. This is user-reported F5 acceptance, separate from the automated revalidation and staged captures; no human timing or GPU performance measurements were supplied.

## Regina character inspection

On 2026-10-17, inspected the supplied Regina GLB using Godot 4.5.1 Standard / Compatibility and added the isolated `arca/character_test.tscn`. No player/controller, weapon, mission, project-setting or gameplay-suite changes were made. The full imported inventory, scale/orientation, material translation difference, TPS blockers and F6 instructions are in [REGINA.md](REGINA.md).

- `arca/tests/regina_test.gd`: **93 checks, zero failures**, against both the working project and a fresh source-only import under ignored `.artifacts/regina/validation-project/`. It validates source/import bone hierarchy, named skin bindings, normalized weights, all nine material/17 texture mappings, alpha cutoffs, finite posed bounds, scale/feet, camera and reversible wrist deformation. Zero authored animations is the actual source state, not a failing assertion.
- `bash scripts/check.sh` ran in that isolated copy to avoid competing with the open working editor. Clean import/GDScript compilation passed with no errors/warnings; **162 gameplay and 13 launcher checks passed**, zero failures. The gate used the existing ignored ripgrep binary via a literal PATH override; no dependency or launcher changes were made.
- Rendered overview/front/side/back, face close-up and temporary elbow-bend captures were generated and inspected with X11, Compatibility and Mesa llvmpipe. No obvious missing texture, detached mesh or exploded rest skin was seen. CPU-skinned world bounds agree with Godot's rendered pose bake within about 0.00003 m. Captures/logs are ignored under `.artifacts/regina/`; they are not GPU benchmarks or user acceptance. The successful capture run has existing X11 input-method and unsupported V-Sync warnings, no script/runtime errors.
- The initial headless diagnostic bake could not register a render skin, caused a null-result script error and timed out at 20 seconds. The final smoke script instead measures skin matrices on the CPU; a separate rendered bake verified the result. The first smoke run also exposed JSON numeric-type membership in its new hierarchy comparison, fixed with typed integer child comparison; the GLB did not need modification. Subsequent focused checks pass, and editor diagnostics for the new GDScript report no errors/warnings.
- At that initial inspection, user F6 appearance/rig acceptance and a fresh human F5 controller check were not reported, and the original FBX was unavailable. The later locomotion task resolves its animation inventory below. Godot's default specular scalar does not preserve the two source `KHR_materials_specular` factors; no shading repair was made.

## Regina isolated locomotion

Implemented on 2026-10-17 in `arca/character_locomotion_test.tscn`, inherited from the user's static inspection scene. The parent scene's existing/ongoing editor changes were not overwritten. No mission, TPS controller, camera/shooting foundation, project settings or standard gate changes were made.

- **Original FBX:** read-only binary FBX 7400 traversal of the supplied `Test.zip/Test/Mesh.fbx` found no animation stacks/layers/curves/keys or takes. SHA-256 and object inventory are in `REGINA.md`. No source conversion or source-file modification was needed.
- **Source selection:** inspected and trialed the licensed CC BY 3.0 TPS idle/walk/run first. Its mechanical segment proportions and shoulder posture were a poorer fit. The final library uses only Quaternius UAL Standard `Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop`, CC0, with pinned mirror/input hashes and the original full license. Regenerated the three-clip source subset with Python's standard library and verified it byte-identical. Regenerated the derived library and verified identical animation/key-data fingerprint `48a00f5081e73fe5c2f6464d1a12b74c75a78cba29e9e7211afbe9f495d503d6` (resource identifiers are not the semantic contract).
- **Focused validation:** `regina_locomotion_test.gd` passes **68 checks**, including source hashes, resolvable finite tracks/closed loops, reference lengths/scales, 60 Hz joint continuity, root extraction across three loops, no double travel, actual skinned sole contacts, all nine finite bound mesh parts, transitions, pause/resume/reset/lane end, real key events and echo rejection. `regina_test.gd` still passes its unchanged **93 static/source checks**.
- **Clean import/full gate:** ran both focused suites and `bash scripts/check.sh` against `.artifacts/regina-locomotion/clean-project/`, a fresh source-only snapshot **without a pre-existing `.godot` cache**. Import/GDScript compilation succeeded; **162 gameplay and 13 launcher checks passed**, with no import/gameplay script errors or warnings. Used the existing ignored ripgrep via a literal PATH and `GODOT_BIN` override, not a launcher/dependency change. This isolates validation from the open working editor/importer.
- **Motion/contact measurements:** walk 1.610911 m / 1.333333 s = **1.208183 m/s**; run 5.712060 m / 1.309524 s = **4.361937 m/s** after 0.7 source retiming; idle zero travel. Both are straight -Z extraction from a canonical proxy, not original authored root translation. Minimum sampled sole Y approximately +0.5 mm. Maximum flat-support clearance/drift: idle 2.57/2.97 mm; walk 14.88/14.21 mm; run 19.38/6.00 mm. Contact windows, toe-off/flight exclusions and tolerances are documented in `REGINA.md`; no per-frame ground clamp or IK was added.
- **Rendered observations:** staged front/side/back views at phases 0/25/50/75 percent for all clips, using X11 / Compatibility / **Mesa Intel Iris Xe**. No detached parts or exploding/severely stretched skin was observed in those sampled views. Small shoulder/costume intersections during run arm swings remain visible; hands stay open and secondary hair motion is not simulated. These are staged pose observations, not user F6 acceptance, continuous human playtesting or a GPU benchmark. Logs/captures remain ignored under `.artifacts/regina-locomotion/`. The successful render reports existing XOpenIM/XCreateIC warnings, no script/runtime errors.
- **Development failures, resolved:** the new baker initially hit a typed-Array conditional assignment, and the new suite initially compared incompatible list types (followed by a corrected indentation edit). A scale assertion wrongly assumed the source jaw was exactly unit scale; it now checks preservation of the actual reference scale. A strict run-continuity failure exposed the authored jog's abrupt initial knee flexion; retiming the gait to 0.7 fixed it without relaxing the angular threshold. An extra zero-step initialization was tried and removed after evidence showed reset was correct. The input test needed the viewport's first process frame before its first injected key. The optional capture-grid helper had an image-format mismatch during early diagnostics and later an aspect-ratio correction; final captures preserve proportions. These preliminary runs are not reported as passing validation.
- **Remaining acceptance:** use the short F6 checklist in `README.md` / `REGINA.md`, especially run shoulder/costume clipping. Human acceptance and a fresh human F5 check are pending. Root-motion verdict is **conditionally compatible for locomotion after explicit track/path/pivot integration**; no collision-driven Regina controller, strafe/jump/aim/grip or full TPS replacement is claimed.

## Regina playable-character integration

Validated on 2026-10-17 in ignored `.artifacts/regina-player-baseline/source/` while the working project remained open in Godot. The snapshot was imported and exercised independently; the generated gameplay animation resource matched the tracked `gameplay.tres` byte-for-byte.

- `regina_player_test.gd`: **38 checks** across the shared base test, raptor and mission rooms, plus the unchanged original robot scene. It verifies Regina model/skeleton presence, hidden inherited robot, room enemy, active AnimationTree/root-motion proxy, all 15 gameplay clips, wrist handgun/muzzle/effect bindings, and inherited camera/capsule.
- Full `scripts/check.sh`: **13 launcher + 42 first-playable + 24 raptor + 52 mission + 44 ambush + 38 Regina-player checks** passed. The existing mission route's automated return measured **13.47 simulated seconds**. No assertions were loosened. Test setup explicitly resets the simulated aim-toggle state after room setup; `Input.action_release("aim")` otherwise creates an unintended brief toggle in headless runs.
- Unchanged Regina source and locomotion checks: **93 static + 68 locomotion** checks passed. Editor diagnostics for the changed player/test GDScript report no warnings or errors; `git diff --check` passed.
- A staged X11/Compatibility capture of the mission start rendered on Mesa Intel Iris Xe and showed Regina with no visible robot body. Shoulder/costume clipping and an open-hand pose remain visible. The distant still does not establish animation, aim/fire quality or weapon visibility; it is not an F5 user acceptance.

**Still required:** with the existing Godot editor, reload the saved external changes and press F5. Check movement/turning, aim pitch and four-direction strafing, weapon grip/muzzle/particles and shots near/away from cover, then the mission route, pause, restart, death and completion. Report the visual verdict separately from the passing headless suites.

## Regina locomotion/jump follow-up: gate incomplete

Validation used a new source-only import under `.artifacts/regina-motion/source/` to avoid a competing live importer while Godot remained open. The runtime probe first reproduced reversed visual facing, non-looping aim steps stopping after one clip, and a **1.234900 m / 1.000 s** body jump. The corrected measurements are **0.324067 m** standing, **0.323358 m** moving, and **0.500 s** flight at unchanged 9.8 m/s² gravity. Original robot movement/default jump were compared and retained. Repeated gameplay bakes produced byte-identical resources; the working resource matches the validated snapshot.

- Full `scripts/check.sh`: launcher **13**, first-playable **42**, raptor **24**, mission **52**, ambush **44** checks pass. Mission return remains **13.47 simulated seconds**. Import/GDScript compilation succeeds.
- Expanded `regina_player_test.gd`: **301 checks, 2 failures**. It exercises eight directions at three camera yaws in both aim modes, multiple motion loops, signed blend/facing/root extraction, speed bounds and idle recovery; stationary/moving hop apex/flight, held input and release/repress, ceiling collision, pause/death in flight and fresh-instance state. A test-only large floor isolates continuous physics travel from room obstacles, while the original structural tests still load all three inherited ARCA rooms.
- The two failures independently skin actual reference sole vertices over full lateral cycles: `strafe_left` minima **(0.066335, 0.000500) m**, `strafe_right` **(0.059787, 0.000500) m**. A sole that never comes within the unchanged **2 cm** support criterion cannot supply a planted contact. Whole-model lowering would penetrate the other foot. The existing 2 mm penetration checks pass; no assertion was removed/relaxed. Detailed phase-aware sliding acceptance remains unfinished because this necessary contact condition fails first.
- Separate unchanged static/locomotion suites still pass **93 / 68** checks. Changed GDScript diagnostics are clean. A parser indentation error in an early new branch was corrected after the first probe timed out; that attempt is not validation. The test harness now stops playback before freeing actors and lets the wall-clock Dummy audio mixer drain; the final focused run no longer reports the earlier `land.wav` resource leak.
- X11/Compatibility startup and sampled front/side pose captures were inspected on Mesa Intel Iris Xe. They confirm corrected facing and show the remaining elevated/robotic lateral steps. No user F5 acceptance, complete gameplay stance-drift result, GPU measurement or final humanoid landing-pose quality is claimed.

The required gate remains incomplete. Stop at the planned pose-feasibility limit; choose a separately scoped humanoid directional source or targeted retarget repair before treating locomotion as finished. Do not use the historical passing integration checks as evidence that footwork is natural.

## S1-02 raptor hit reaction and alert roar (2026-11-24)

- Ran in worktree `../ARCA-wt/s1-02`: `bash scripts/check.sh` passed launcher 13, first_playable 42, **raptor 83**, mission 61, ambush 47, regina_player 378 and economy 25, for **649 checks and 0 failures**.
- The 24 new raptor checks cover:
  - two extra real source bindings, with finite poses and a held root;
  - hurt and roar lengths matching the stagger and alert windows;
  - the roar jaw opening above 45° at 0.23 s and closing below 10°;
  - a wait-state hit still alerting;
  - the alert playing the roar;
  - a windup hit staggering and cancelling the bite;
  - recovery into the hunt;
  - five hits causing one stagger, plus re-stagger after the cooldown;
  - pause freezing the stagger and its cooldown;
  - a lethal hit during the stagger;
  - committed bite, dormant and emerging exclusions.
- Mutation checks: disabling the stagger made 8 checks fail, and a zero cooldown made both cooldown checks fail. Both mutations were reverted.
- Rebaking with the original baker was byte-identical. After the change, the six earlier bindings are unchanged in `gameplay.tres`.
- Not verified headless: how the flinch and roar read visually, blend quality, and ground contact during `Hurt_01`. These need the README F5 checklist.

## Known limits

- The hatch is a primitive sliding panel and shallow bay, not bespoke dinosaur breach animation, final environment art or new sound design.
- Art, character, sound design and level geometry remain temporary; the enemy is not a scientific species reconstruction.
- Inventory and progress reset on restart. No save/load system exists.
- Zed settings/tasks were syntax checked, not exercised in the user's installed Zed/ACP version. Explicit file-reading prompts provide a fallback if agent or skill auto-discovery differs.
- Hatch F5 acceptance does not establish broader aiming comfort, final polish or frame rate on the user's PC.

## Sprint route integration

The full gate includes the area collision and doorway checks and a route suite that walks the real controller from spawn to victory. The route also checks shared navigation and executes a cross-sector pursuit for each raptor. The automated walk measured 59.17 seconds of movement input against the 150-second target. First-run exploration and combat, camera readability and FPS are verified in S1-12.
