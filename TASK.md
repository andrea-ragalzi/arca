# Prototype completion roadmap

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Ferocious raptor F5 acceptance and three checkpoint commits (AI tooling, Regina player, Ferocious raptor) | User F5 accepted and baseline reproduced. AI tooling and Regina player checkpoints recorded. Ferocious raptor checkpoint pending. |
| 1 | Source-based Regina upper aim | Pending Phase 0 |
| 2 | Source-based Regina lateral soles | Pending Phase 1. Check the KayKit Free 1.1 inventory first and stop for user direction if lateral clips are absent. The full gate must pass from this phase onward. |
| 3 | Limited ammo, reload, ammo box and medkit | Pending Phase 2 |
| 4 | Win/death mission summary | Pending Phase 3 |

---

# Preserved pending plan: Regina human pistol animation evaluation

# Task: evaluate complete human pistol animations for Regina in isolation

Status: **isolated trial implemented and evaluated; candidate fails the integration-quality gate, not accepted for the main player** (2026-10-17). Implemented following the user's explicit `implement` invocation. All six human clips were imported/retargeted and compared with the current presentation; generated data, viewer, tests, captures and a 19-second replay remain under `.artifacts/regina-pistol-evaluation/`. Only this task handoff changes in the live repository. Trial: **55 checks, 7 quality failures**. Main gate reproduces **373 checks, 3 existing failures**; focused baseline grip remains **107/0**. No robot-pose repair, source/rig edit, test weakening or main integration was performed.

## Goal and mandatory contracts

Use **Godot 4.5.1 Standard / Compatibility** and the existing Regina model to evaluate ready-made **human pistol idle, neutral/up/down aim, shoot and reload clips**, side by side with the current robot-derived presentation. Recommend integration only if the human set is clearly better after continuous visual inspection.

- Do not manually author new animations, repair robot poses again, add procedural single-bone aim/grip fixes, IK, rig/weight/rest edits or a retarget framework. Deterministic rest/anatomical-axis conversion of existing human clips is allowed; artistic pose corrections are not.
- Keep original Regina/donor files, source clips and existing source-side imports immutable. Generated retarget data belongs only to the isolated experiment until a visual decision is made.
- Preserve the calibrated wrist attachment, `WeaponSocket`, `GripPose`, gun geometry, scale, muzzle and their local transforms. Do not conceal bad human retargeting with per-clip gun offsets or projectile-direction changes.
- Before visual verification, change **no main-project scripts, scenes, assets, tests, imports or configuration**. The only live repository documentation exception is this required `TASK.md` record. Later implementation of this plan is an isolated experiment and a recommendation, not permission to promote assets into the main player.
- Keep controller, camera, collision, movement/root-motion behavior, projectile trajectory/cooldown and lifecycle unchanged. No ammunition/reload mechanic, 8-way locomotion replacement, new input bindings, purchases, commits or engine upgrades.
- Preserve all existing assertions and known failures. Headless correctness cannot establish visual superiority.

## Verified source availability in this planning pass

Quaternius Universal Animation Library **Standard** is already available at two levels:

1. Main-project subsets: `arca/assets/characters/regina/source/ual_locomotion.glb` contains only idle/walk/jog; `ual_pistol_grip.glb` contains only **`Pistol_Aim_Neutral`**, not a complete pistol set.
2. Full downloaded Standard archive: `.artifacts/regina-locomotion/AnimationLibrary_Godot_Standard.gltf` and adjacent `.bin`, with archived `LICENSE` and `README.md`. It contains **46 clips and a 53-joint humanoid donor**. The glTF is 2,459,987 bytes; the binary is 1,587,224 bytes, so direct isolated import is sufficient; no new extractor or download is needed for this trial.

Read-only inspection of exact glTF names/accessors found:

| Requested role | Actual source clip | Raw key-time range | Source interpolation / evidence |
| --- | --- | --- | --- |
| Pistol idle | `Pistol_Idle_Loop` | 0–1.666667 s | LINEAR/STEP; authored finger rotations are static while the body idles |
| Neutral aim | `Pistol_Aim_Neutral` | 0–0.166667 s | STEP; a static pose, not an authored aim sweep |
| Up aim | `Pistol_Aim_Up` | 0–0.166667 s | STEP; a static pose |
| Down aim | `Pistol_Aim_Down` | 0–0.166667 s | STEP; a static pose |
| Shoot | `Pistol_Shoot` | 0–0.625 s | LINEAR/STEP; 14 right-finger rotation channels have multiple distinct samples |
| Reload | `Pistol_Reload` | 0–1.666667 s | LINEAR/STEP; all 15 left-finger rotation channels have multiple distinct samples |

There is **no literal `Pistol_Aim` clip**; use the three real aim poses and record their imported names rather than inventing an alias silently. Each of the six clips has 159 TRS channels targeting all 53 donor joints, including 30 finger targets across both hands. Channel presence is not a visual-quality verdict. No donor node named gun/pistol/weapon/magazine was found: this source does not supply a matching weapon prop.

SHA-256 values match the existing provenance record:

- glTF: `0ff075c7ad6855c5c2c37a171592ee8f0d6ab2f58259e2be77a9b63dd8027765`.
- Binary: `6e65377d81558333c4093dbb144a48fd19019343d82b1a3a7992a98ec0e0543c`.
- Archived CC0 license: `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499`.

**Recommendation: test this existing coherent Quaternius set first.** KayKit is a conditional fallback only if required coverage or observed human-pose quality proves insufficient. Do not acquire another pack before that evidence. If needed later, verify the specific KayKit pack's official source, CC0 notice, exact pistol inventory and downloadable format; no KayKit pistol coverage or equivalence is assumed here. Stop for a decision if acquisition requires payment/account access or if the necessary clips are absent.

## Relevant files and current flow

| Files | Responsibility / constraint |
| --- | --- |
| `arca/player/arca_player.gd`, `arca_player.tscn` | Current inherited player installs Regina, creates the wrist attachment and adds robot aim plus the fixed finger/additive wrist grip layers. Baseline must retain this exact behavior. |
| `arca/player/regina_model.tscn` | Original Regina, gameplay AnimationPlayer and separate `RootMotion` proxy. Serialized wrapper yaw is 180 degrees; actual gameplay installation sets it to zero. Match the runtime +Z presentation for a fair comparison. |
| `arca/player/regina_weapon_socket.tscn`, `regina_handgun.tscn` | Calibrated socket/handle reference and unchanged primitive gun/muzzle; instance these unchanged in the trial. |
| `arca/assets/characters/regina/gameplay.tres`, `bake_gameplay.gd` | Existing robot-derived combat/aim baseline. Do not run another corrective robot bake or edit these for this evaluation. |
| `arca/assets/characters/regina/grip.tres`, `bake_grip.gd` | Existing 15-finger fixed pose plus an additive wrist half-turn compensating the robot presentation; preserve baseline, but do not blindly stack these over complete human finger/wrist animation. |
| `arca/assets/characters/regina/bake_locomotion.gd` | Existing UAL-to-Regina anatomical/rest-frame mapping, pelvis conversion and target-length preservation to reference in an experiment-only baker. Do not copy its jog retiming, seam repair or gait-speed calibration into pistol clips. |
| `arca/assets/characters/regina/source/README.md`, `ATTRIBUTIONS.md`, archived source/license | Pinned CC0 donor provenance; Regina's separate CC BY 4.0 and underlying IP limitations remain. |
| `player/player.gd`, `player/player_input.gd`, `player/player.tscn` | Existing input/camera/projectile path. `shoot()` currently triggers effects/sound/cooldown, not a skeletal firing clip; `FireCooldown` is 0.4 s. There is no gameplay reload action. |
| `arca/tests/regina_player_test.gd` | Existing skin-triangle/box probes, socket equality, input/physics and visible aim-direction assertions. Reuse their measurement approach in trial-local checks, without editing the main tests. |
| `.artifacts/regina-grip/source/diagnostics/capture_grip.gd` | Prior staged full-body/close-up capture pattern and manual AnimationTree evaluation; its robot-derived samples are not a human-pistol comparison. |
| `scripts/check.sh`, `scripts/ai_check.sh`, `docs/VALIDATION.md` | Existing import/full gate and isolated-snapshot convention. Historical main Regina-player result is **373 checks, 3 failures**, not a result rerun in this pass. |

Current baseline: input -> TPS AnimationTree/robot-derived poses -> aim layer -> robot-specific wrist compensation + fixed fingers -> evaluated wrist -> unchanged socket/grip/gun/muzzle. Projectile direction is independently computed from the cover-safe muzzle origin toward `shoot_target`. A good bullet hit therefore does not prove correct visible barrel alignment.

Candidate: imported human full-body clip -> rest-aware retarget of body, wrists and both finger chains -> Regina -> **the same unchanged physical socket/grip/gun/muzzle**. Start by evaluating complete absolute human clips, not isolated arm deltas mixed into robot poses.

## Assumptions, acceptance boundary and unresolved risks

- The user requests a **visual feasibility trial first**. This plan ends with recorded comparison evidence and an integration recommendation or rejection; promotion into the mission needs a subsequent explicit decision, even if the trial looks better.
- Preserve the socket/grip *attachment system* and its transforms, not the assumption that robot-specific wrist/fixed-finger overlays must remain active over new full human animation. In the isolated candidate only, bypass those legacy pose overlays so they cannot freeze shooting fingers, defeat the reload hand, or apply a second wrist correction. Baseline overlays remain untouched. This distinction must be visible in the report, not hidden as a rig change.
- If a mathematically consistent donor-to-target rest/palm-frame conversion cannot align the complete human poses with the unchanged socket, record the incompatibility and stop. Do not change the calibrated gun, introduce per-clip corrective offsets, force a fixed wrist/finger pose or conceal it with IK.
- Reload is **animation preview only**. The primitive gun has no animated magazine/slide/trigger assembly, and the donor supplies no weapon prop; absent prop motion must be disclosed, not “fixed” with new art or a new reload system.
- Shoot is 0.625 s versus the existing 0.4 s cooldown. Preserve authored timing during evaluation. A later integration proposal must explain interruption/retrigger/layering without making the controller wait for clip completion, adding another projectile event or changing fire rate.
- The current robot-derived baseline has no dedicated skeletal shoot or reload clips. Label those comparisons honestly: existing aim + firing effects / no reload state, rather than fabricating a robot counterpart.
- Target proportions, secondary costume/hair weights, support-hand contact and endpoint interpolation may remain limiting even with CC0 human clips. License and complete channel coverage do not establish compatibility. No source pose is accepted from its name alone.

## Implementation sequence (original plan)

1. **Freeze and isolate the baseline.** Inspect fresh Git status and fingerprint all current sources/config/tests, including prior uncommitted changes. Create a fresh ignored evaluation directory under `.artifacts/` with its own source-only project copy and `.godot` cache; do not overwrite older snapshots. Validate copy parity. Preserve Godot 4.5.1/Compatibility settings; disable the editor bridge plugin only in the trial copy if necessary to avoid competing with the live editor. Never import archived sources into the live project.
2. **Import the already present human source.** Copy the pinned complete Standard glTF/bin/license into a source directory *inside the isolated project*, verify hashes there, and let that project's importer finish. Inventory the six actual imported names, durations, loop flags, tracks and donor bones. Record `source name -> imported name -> trial clip` explicitly because Godot may trim loop suffixes. Missing clips/bones, invalid data, import/save failures or unresolved paths must produce actionable nonzero failures; never substitute idle or silently skip a required action.
3. **Make one reproducible experiment-only retarget.** Use a narrow trial baker with the existing anatomical body mapping plus explicit wrist/palm and **both 15-bone finger maps**. Transfer complete coherent human poses, resolving source/global/rest frames back into Regina's parent-local coordinates. Preserve target lengths/rests/weights; do not copy donor limb translations/scales. Handle pelvis translation in the established anatomical frame and keep controller/world/root motion out of this stationary proof, retaining legitimate local torso/pelvis motion. Preserve original timing, authored recoil and reload hand motion; do not flatten them to a neutral grip or retime to hide problems. Inspect the source mannequin separately when distinguishing donor pose from mapping error. No robot-source changes or manual new keys/poses.
4. **Build one small isolated A/B viewer and its deterministic checks.** Baseline A uses the actual current player graph, with movement/input/gameplay simulation disabled in the harness only. Candidate B uses the original Regina and unchanged socket/gun assets with the trial library; no robot pose or legacy fixed-hand override drives it. Use the same gameplay coordinate convention, scale, neutral lighting, floor references, cameras and unscaled 1x playback; provide synchronized whole-body and wrist/hand views plus pause/scrub/replay. Reuse the existing SceneTree/capture/test patterns rather than introducing a framework. Planned experiment-only files: one baker, one comparison/check harness and generated trial AnimationLibrary; none are runnable or created yet.
5. **Evaluate all six clips continuously before graph integration.** Inspect several idle cycles; neutral/up/down source poses; an unquantized blend between the three absolute aim samples; the full shoot and reload timelines and their return to idle. Keep static STEP-authored aim poses static rather than inventing an authored aim sweep. Render front/side/back and both-hand close-ups, especially recoil, finger trigger motion, left-hand reload contact, extreme wrist angles and the first/last samples. Disable/reset interpolation only for deterministic staged captures so the camera and posed skin use the same frame; do not change gameplay interpolation. Record visible hand/metal contact, body deformation, muzzle position and barrel direction numerically as well as visually.
6. **Compare and deliver the visual decision.** Capture A/B at matching camera, actor heading and intended action; use actual clip time/normalized phase appropriately rather than pretending unequal clips are identical in duration. Run real-time playback and produce a compact comparison matrix for grip/wrist/fingers/arms/barrel/transition quality, including defects and N/A baseline actions. “Clearly better” requires natural coherent action, correct up/down aim, no new severe clipping/deformation and preserved attachment, not just a nicer still. Keep the live main project unchanged and show the evidence for the user's verdict. If Quaternius fails despite a verified map, investigate KayKit only at the explicit fallback gate above; do not repair the robot or add corrective procedural bones instead.
7. **Recommend only if the trial passes.** Propose the smallest later presentation-only library/AnimationTree change using the existing player bindings, normal/aim separation and lifecycle. Explain absolute pose blending first; any future additive aim must use a matching human neutral reference, not a robot combat-idle pose. Preserve projectile creation/trajectory, 0.4 s cooldown, camera/controller and root-motion contract; do not wire animation method tracks to spawn bullets or treat preview reload as gameplay. List exact files to promote and license/docs/tests to update in a subsequent integration task. Do not perform that promotion in this trial.

## Validation and expected outcomes

### Trial-local automated and rendered checks

- All six source/imported/retarget clips and all mapped body/wrist/finger paths resolve; durations and intended loop/one-shot behavior match the source, with finite poses and preserved bone lengths. No runtime donor in the candidate, duplicate animation driver, silent fallback clip, source-changing loop repair or new root travel.
- Sample first/intermediate/last frames and several loops. Assert socket/grip world-frame equality after evaluated wrist motion, unit scale and no frame lag. Reuse skin-triangle/metal probes with the existing **1 mm inset**, distinguishing intended handle contact from slide/barrel penetration. Check both hands and flag reload support-hand misses rather than overriding the source fingers. Fixed-pose fingerprints from the old grip test are **baseline-specific**, not a valid requirement that new human fingers stay frozen.
- Verify visible up aim is above neutral and down aim below neutral using the same **0.1 Y-direction difference** criterion as the existing test in the canonical gameplay frame; also report yaw and full barrel direction/target-angle error and reject visibly backward aiming. Repeat endpoint/hold checks so an absolute tail cannot reappear. Do not rename/swap poses merely to satisfy a label.
- Confirm source-varying shooting/reload channels remain time-varying after retargeting; show recoil and left-hand reload action in continuous playback. Return to the human idle without a held final recoil/reload pose. Pause/resume and replay must be deterministic and must not issue gameplay shots, ammo changes, input locks or callbacks in this viewer.
- Hash originals, live production scripts/scenes/resources/imports/tests and configuration before/after; only `TASK.md` and ignored experiment artifacts may change. Do not promote generated data or overwrite the live scene from the isolated editor. Separate any unrelated concurrent edits from this task.
- Keep the old three main-gate failures visible. An improved isolated human trial does not fix the live aim assertion or lateral footwork until a later integration; do not weaken tests or call the main gate passing.

### Existing baseline/regression commands for later use — not run now

The portable Godot executable and `scripts/ai_check.sh` were verified present. These repository-supported commands run from ARCA (with a bounded tool timeout):

```bash
bash scripts/ai_check.sh
```

This creates its own isolated baseline snapshot and runs the existing full gate. Compare its actual findings with the historical **373/3** Regina-player result; report differences, not an assumed count.

From the dedicated imported trial project, the existing focused baseline command remains:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_player_test.gd -- --weapon-grip-only
```

For the new experiment-only baker/viewer/check harness, record exact commands after those files exist during implementation; no invented runnable entry point is claimed here. Imports/headless checks validate structure/math, not rendering. Use interactive Compatibility playback for the visual gate and supply reproducible comparison controls/capture paths in the handoff. No main-mission F5 integration is authorized by this trial; the human verdict should be on the isolated viewer.

Planning validation is limited to read-only source/accessor/hash inspection and `git diff --check -- TASK.md`. No engine importer/runtime suite, retarget or new visual comparison was performed during this planning pass.

## Risks and stop conditions

Stop on missing/invalid required data, unverifiable license, a need for paid acquisition, inconsistent retarget axes, source/target hand-proportion mismatch requiring manual pose work, fixed socket incompatibility, wrong visible aim or unacceptable reload/shoot deformation. Preserve failed trial evidence and explain whether the fault is source pose, mapping, missing prop or existing skinning. Do not expand into rig repair, procedural compensation, a reload system, locomotive replacement or another robot correction. If all human clips are clearly better, hand off the evidence and a bounded integration recommendation—not an unreviewed main-project replacement.

---

## Implementation handoff: isolated human-pistol comparison

### Delivered files and actual scope

All experimental files are ignored, local artifacts under **`.artifacts/regina-pistol-evaluation/`**:

- `REPORT.md`: source provenance, comparison matrix, measured failures, review controls, commands and the integration decision.
- `project/`: a fresh source-only snapshot with its own import cache. Only this copy disables the editor bridge plugin; the open live editor and main configuration remain untouched.
- `project/diagnostics/bake_pistol_trial.gd` / `pistol_trial.tres`: deterministic full human retarget of all six clips, with 52 body/finger rotations plus pelvis per clip. Reuses the existing UAL body mapping and explicit anatomical/rest-frame maps for both 15-finger chains; no retiming, pose authoring, seam repair, source edits or new root travel.
- `project/diagnostics/pistol_comparison.gd` / `.tscn`: interactive A/B viewer, absolute three-pose aim blend, deterministic checks, source-reference and capture modes. Baseline is the unchanged current player graph; candidate has no robot wrist/fixed-finger overlay. Shoot/reload are preview-only and return to human idle; no ammo or projectile event is introduced.
- `project/diagnostics/hand_geometry.gd`: the existing triangle/box clearance probe reused with a left/right selector. It retains the **1 mm inset** and avoids confusing intentional handle contact with slide/barrel penetration.
- `project/diagnostics/import_inventory.json`, `trial_results.json`, `source_reference.json`: actual imported names/timing/loops, quality measurements and donor/Regina contact evidence.
- `captures/`: A/B front/side/back and both-hand close-ups, source mannequin reference sheets, and shoot/reload phase timelines. A is left, B right on the comparison sheets.
- `comparison.avi`: **19 seconds, nominal 60 fps, 1280×720**, continuously evaluated idle/aim/shoot/reload/absolute-aim-blend playback. This is an automated renderer recording, not user visual acceptance or a GPU benchmark.
- `kaykit/`: the official free archive, preserved CC0 notice and exact fallback inventory; not promoted into the trial/main assets.

### Import, pose and attachment findings

The full already archived Quaternius Standard glTF/bin/license were copied and hash-verified inside the isolated project. Godot imported `Pistol_Idle_Loop` as **`Pistol_Idle`**; neutral/up/down, shoot and reload retained their original names. Source times/loop flags are preserved: idle **1.666667 s / loop**, the three static aims **0.166667 s / non-loop**, shoot **0.625 s / non-loop**, reload **1.666667 s / non-loop**. No new Quaternius download or paid source was needed. The retarget regenerated **byte-identically**, SHA-256 `8aa467e6c641467b14afcdc7945fbf8f98c6cdb9560581cef9ab25ec6dd8f659`.

The existing wrist bone, socket/grip scene, marker transforms, gun geometry, unit scale, inverse-grip placement and muzzle are unchanged in both A/B bindings. The candidate's complete human wrist/finger tracks are evaluated directly, without double-applying the old robot-specific wrist/fixed-finger layers. This is the planned isolation of pose authority, not a change to the main attachment or rig.

A source-inventory nuance was resolved rather than adding artificial trigger motion: the 14 distinct raw shooting finger channels differ only by quaternion component noise, **at most about 4.1e-7 rad** after normalization. The source grip is effectively static while the arm recoils (forearm motion about **0.369 rad**); reload genuinely animates all 15 left finger joints (**0.095–0.829 rad**). Trial assertions now check preservation of the actual static shooting fingers, moving recoil arm and moving reload fingers; no production test or threshold was changed.

The human stance, two-hand arm motion and reload/recoil are more coherent in sampled views than the current robot-derived presentation. Nevertheless, the fixed-weapon compatibility gate fails. Maximum sampled **left-hand** skin-triangle/metal intersections are idle **50**, neutral **50**, up **28**, down **286**, shoot **50**, reload **479**; the **right hand has zero** for every clip. Counts are intersecting triangles at 13 phases, not penetration depths or a claim that each frame fails. Socket equality, evaluated attachment timing, target lengths/reference scales and finite transforms pass.

Human barrel vectors at neutral/up/down are respectively **(0.076049, 0.226375, 0.971067)**, **(0.076049, 0.986219, -0.146932)** and **(0.076049, -0.965709, 0.248239)**. Up/down pass the existing **0.1 Y-difference** criteria, but full up has a small backward Z component at a steep upward angle and fails forward-hemisphere acceptance. The continuous absolute aim sweep passes, with maximum sampled wrist step **0.084535 rad** and a genuine intermediate pose. No pose labels were swapped, camera/bullet direction changed, gun offset tuned or source rotations manually repaired to make this pass.

The original source mannequin was rendered separately to distinguish the coherent donor motion from target fit. Neutral source wrist separation is **0.109013 m**, or **0.121421 m** at the established leg-length scale, versus **0.086164 m** after the preserved-length Regina retarget. Reload midpoint is **0.213708 m** at that scale versus **0.151208 m** on Regina. These support a target proportion/reference-frame/two-hand contact mismatch, not a conclusion that the source animation is intrinsically defective. No IK, weight edit or per-bone artistic correction was attempted.

### KayKit fallback evidence

After observing the target fit failure, checked the author's official **KayKit Character Animations** page and anonymously downloaded its **Free 1.1** pack (14,858,957 bytes, no payment/account). Archive SHA-256: `65882f31f905ad2e953819648a59287cdeab8f623908d5ef701971d3758be20f`. Source: <https://kaylousberg.itch.io/kaykit-character-animations>; author Kay Lousberg; original full **CC0** license retained in the archive and local `kaykit/License.txt`.

Its available `Rig_Medium_CombatRanged.glb` has **23 joints and no finger bones**. It includes `Ranged_1H_Aiming`, `Ranged_1H_Shoot`, `Ranged_1H_Shooting`, `Ranged_1H_Reload` and other weapon styles, but no separately named neutral/up/down pistol pose set. The exact node/clip inventory is in `kaykit/inventory.json`. It was **not retargeted**: missing authored finger coverage already prevents a complete replacement under this task's constraints. No manual/fixed fingers or manufactured aim poses were added to fill that gap, and no KayKit data entered the main project.

### Actual checks and evidence limits

- Required **`bash scripts/ai_check.sh`** ran before and after the experiment. Both reproduce the same existing gate: launcher **13**, first-playable **42**, raptor **24**, mission **52**, ambush **44** pass; Regina-player **373 checks, 3 failures** (existing upper aim and two lateral soles). **The main gate does not pass.** Logs: `baseline-gate.log`, `final-gate.log`.
- Existing baseline grip command in the trial copy passes **107 checks, zero failures**; log `baseline-grip.log`.
- New isolated trial: **55 checks, 7 failures**, exit **1**. The seven are six left-hand contact assertions plus full-up forward-hemisphere acceptance. All structural/timing/pose/attachment checks, vertical aim-direction signs, static aim endpoints, authored recoil/reload motion, return to idle, pause/replay and continuous blend checks pass. Log `verify.log`; no failures were hidden or assertions relaxed.
- Godot **4.5.1 Standard** isolated import/compilation succeeds. Staged rendering uses **X11 / Compatibility / Mesa Intel Iris Xe**; existing X11 input-method warnings are not pose acceptance or a performance result. Only the inspection actor/camera interpolation is disabled; main gameplay settings are unchanged.
- A/B sheets and timeline samples were visually inspected, as were separate donor reference poses. The automated movie records full temporal playback, but **the user's continuous visual verdict is pending**. Do not represent it as human acceptance, completed combat integration or polished finger/trigger/magazine art.
- Iteration corrected harness issues, not donor poses: manual bone sampling needed a process-frame boundary before evaluating BoneAttachment transforms; the current player's camera initially stole the inspection view, so the dedicated camera is explicitly restored and its staging interpolation disabled. Final measurements/captures use the corrected harness. These changes do not touch live camera/controller code.
- A pre-experiment manifest covered **418 live files**. Before this handoff, it reported **no changes** outside ignored artifacts; after the handoff only `TASK.md` is expected to differ. No main scene/resource/import, original asset, rig, clip, test, editor configuration, controller, trajectory or cooldown was modified. No branch or commit was created.

### Review command and integration decision

From the ARCA root, run the **isolated** viewer, not main F5:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --path .artifacts/regina-pistol-evaluation/project res://diagnostics/pistol_comparison.tscn
```

Controls: **1–6** idle/neutral/up/down/shoot/reload, **Space** pause, arrows scrub, **R** replay, **V** front/side/back/right-hand/left-hand, **Tab** A/B hand focus, **B** continuous absolute aim blend, **Escape** exit. The viewer does not execute gameplay shooting or reloading. Full commands for rebake, checks, captures and the bounded tour are in the local `REPORT.md`.

**Recommendation: retain the human-animation direction, but do not integrate this complete set unchanged yet.** Right-hand attachment and coherent human motion are promising; support-hand fit and the weapon/aim-frame range still fail the fixed-socket contract. KayKit's evaluated free rig does not supply the missing complete finger/aim coverage. Stop at this demonstrated compatibility limit rather than return to robot repair, generate procedural poses, change the gun, weaken tests or silently promote assets. A later integration decision must first resolve those contact/frame constraints, preserve the existing **0.4 s** cooldown and projectile/controller/camera paths, and keep preview reload out of gameplay unless separately scoped.

---

# Previous task record: diagnose Regina's weapon grip and continuous locomotion

# Task: diagnose Regina's weapon grip and continuous locomotion

Status: **partially implemented; stopped at the animation-source/retarget quality gate, not complete or accepted** (2026-10-17). The user's explicit `implement` invocation authorized this plan. The calibrated socket/grip correction is integrated and its focused 107 checks pass. The full gate fails: Regina-player **373 checks, 3 failures** (the two prior lateral contacts and a newly exposed upper-aim direction defect). No eight-way replacement, source rig/clip edit, IK or test weakening was performed. See the implementation handoff below; the previous incomplete locomotion/jump record remains preserved.

## Goal and mandatory contracts

Diagnose the right-hand handgun intersection and stiff locomotion, then propose the smallest ordered correction using the existing inherited TPS player.

- Inspect the real runtime attachment, local transforms, bone/rest axes, animation/retarget paths and continuous movement/blend flow.
- Plan a calibrated weapon socket and compatible grip, plus continuous camera-relative locomotion using eight directional animation samples with interpolation, not eight quantized playback states.
- Keep original Regina GLB/FBX, skeleton/rests/weights, original animation clips and source-side imports unchanged. Any later pose work must be separately generated gameplay derivatives.
- Preserve camera/input conventions, root-motion-to-velocity/collision integration, original robot defaults, projectile/cover behavior and pause/death/restart/completion contracts. No broad controller/rig refactor or IK framework.
- Do not weaken, skip or relabel failing tests. No asset replacement, downloads, new dependencies or implementation is authorized by this planning pass.

## Assumptions, approval decisions and non-goals

- Preserve the previously approved **camera-facing directional policy outside aim**: normal W/S/A/D means forward/backward/side travel relative to the camera, not turn-to-travel. A relaxed turn-to-travel mode would be a separate behavioral decision, not a necessary fix for continuous blending.
- Keep normal and aimed locomotion separate in the existing graph. They can share suitable lower-body samples later, but normal movement must not enter aim to obtain strafing or a grip.
- Eight authored directional samples are the target, not proof that eight good clips are currently available. A matching humanoid directional source still needs selection and evaluation before integrating replacements.
- Exact corrected socket offsets, finger rotations, phase alignment and any new clip speed calibration cannot responsibly be selected from source names or distant stills. Approve the plan first; measure them in a saved-editor, close-up pose inspection during implementation.
- Non-goals: new movement/camera architecture, motion matching, runtime retarget framework, rig/skin repair, foot/hand IK, animation-source editing, reload/ammunition features, jump redesign, final gun art or publication. CC0 animation does not resolve Regina's existing character/IP provenance caveat.

## Inspected files and current flow

| Files | Responsibility / finding |
| --- | --- |
| `arca/mission_room.tscn`, `arca/mission_room.gd` | Mission inherits raptor/test room; uses the shared ARCA player. No mission-specific weapon or locomotion replacement is needed. |
| `arca/player/arca_player.tscn`, `arca/player/arca_player.gd` | Inherit the TPS player; `_install_regina()` creates the wrist attachment, binds muzzle/effects and overrides the existing tree locally. ARCA enables directional locomotion and the existing low hop. |
| `arca/player/regina_model.tscn` | Original GLB instance, separate `RootMotion` proxy and gameplay AnimationPlayer. Serialized Regina Y yaw is 180 degrees; installation overrides it to zero at runtime. Judge the runtime instance, not the saved wrapper alone. |
| `arca/player/regina_handgun.tscn` | Original primitive weapon geometry, grip box and `ShootFrom` marker; no dedicated grip reference marker. |
| `player/player.gd`, `player/player_input.gd`, `project.godot` | Continuous signed action strengths (including stick bindings), input smoothing, interpolated heading, graph parameters, root-motion extraction, gravity and `move_and_slide()`. |
| `player/player.tscn` | Existing AnimationTree/BlendTree: separate walk/strafe BlendSpace2D branches, transition, time scales, jump/landing and additive pitch. Preserve standalone robot defaults. |
| `arca/assets/characters/regina/bake_gameplay.gd`, `gameplay.tres` | Separate gameplay derivative: UAL idle/run plus robot-derived combat/back/side/jump/aim. Wrist mapping exists; finger mapping/tracks do not. |
| `arca/assets/characters/regina/bake_locomotion.gd`, `locomotion.tres`, `source/README.md`, `source/ual_locomotion.glb` | Preserved F6 proof and shipped CC0 subset: idle, walk and forward jog only. Not a directional/combat set. |
| `arca/tests/regina_player_test.gd`, `arca/tests/regina_test.gd`, `arca/tests/regina_locomotion_test.gd`, `scripts/check.sh` | Existing structural, direction/physics, sole-contact and source-preservation coverage; extend these rather than adding another framework. |
| `README.md`, `docs/DESIGN.md`, `docs/REGINA.md`, `docs/VALIDATION.md`, `ATTRIBUTIONS.md` | Behavior, previous measurements and source/license contracts. Update affected descriptions only during approved implementation. |

Runtime data flow: action strengths -> normalized/smoothed `motion` -> camera-facing model orientation + signed walk/strafe `blend_position` -> evaluated gameplay poses and extracted `RootMotion` -> horizontal velocity -> real collision movement. Evaluated wrist -> BoneAttachment3D -> handgun -> muzzle/effects. The hidden robot is not the animation driver for Regina.

## Weapon diagnosis

### Verified attachment and local transform

Actual runtime hierarchy (created in code, not serialized in `regina_model.tscn`):

```text
Player/PlayerModel/ReginaModel/Regina/
  Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D/
    WeaponAttachment (BoneAttachment3D: arm right wrist_021)
      ReginaHandgun (Node3D)
        Slide / Grip / Barrel
        ShootFrom (Marker3D, with reparented muzzle effects)
```

- `arm right wrist_021` is genuinely the right wrist: source skin joint index **21**, parent right elbow, with five right finger chains as children. It is neither an elbow nor a holster bone. Name lookup is checked before attachment. There is **no evidence of a wrong-bone attachment**.
- Handgun transform relative to the wrist attachment: position **(0, 0.02, 0) m**, Euler rotation **(-90, 0, 0) degrees**, scale **(1, 1, 1)**. There is no calibrated palm/socket node between them; the weapon root is not an anatomical grip point.
- Weapon-space geometry: slide center `(0, 0.025, -0.055)`, size `(0.055, 0.065, 0.22)` m; grip center `(0, -0.065, 0.025)`, local X rotation `0.24` rad, size `(0.043, 0.13, 0.055)` m; muzzle `(0, 0.01, -0.23)` m.
- Applying the installed transform puts the slide center at **(0, -0.035, -0.025)**, grip center at **(0, 0.045, 0.065)** and muzzle at **(0, -0.210, -0.010)** in wrist coordinates. The weapon's -Z barrel axis becomes wrist **-Y**. Meanwhile the middle-finger base lies approximately **(−0.0011, +0.1031, +0.0061)** m from the wrist in the original rig. These are different coordinate frames from a generic upright gun or world-facing character: a wrist rotation cannot be guessed from a conventional gun axis alone.
- Source wrist/ancestor scales are effectively unit (floating-point residuals near 1); no meaningful extra gun scale is assigned. Scale is a lower-probability cause than placement/pose, although geometry dimensions must be checked against the posed palm rather than assumed final.

### Most likely cause and retarget contribution

**Primary hypothesis: an uncalibrated wrist-to-weapon transform combined with an open, non-gripping hand.** The gun is placed near the wrist using a guessed offset/quarter-turn rather than aligning its handle to a measured palm grip frame. A socket node alone does not close fingers or correct the geometry.

Confirmed contributing defect: neither gameplay baker nor generated gameplay library contains finger tracks; both donor mappings stop at the wrist. The original model has zero authored animations. Regina's fingers retain their reference/open local poses even during robot-derived aiming. Retargeted robot arm/wrist orientation is not a human pistol grip.

Because gun and fixed finger chains share the wrist, changing upper-arm animations alone cannot repair their rigid relative placement. Retargeting can explain an unnatural arm/weapon direction, but it is not evidence that the bone attachment is wrong. A correct fixed grip also needs compatible thumb/finger posing in derived gameplay data. Exclude mesh-weight-dependent deformation and inspect pitch extremes before claiming complete clearance.

The exact penetration volume and final correction have **not** been measured in a new close-up runtime capture. Existing front/side captures show the open hand/prototype weapon, but do not establish an accepted grip. Keep this conclusion as a strongly supported diagnosis, not a claimed rendered fix.

## Locomotion diagnosis

- **Movement and playback are already continuously blended.** `PlayerInputSynchronizer` reads floating-point action strengths, not an angle enum. ARCA bounds diagonal magnitude, smooths `motion` with `lerp`, interpolates facing with quaternion `slerp`, and feeds `(motion.x, -motion.y)` directly into BlendSpace2D. No `round(angle / 45)`, nearest-direction clip switch or eight-state playback selector exists here. WASD naturally supplies eight steady input combinations; stick bindings support intermediate input values.
- **AnimationTree with BlendSpace2D already exists and should be retained.** The runtime normal branch has **five points**: idle at zero, UAL forward run at `(0, 1)`, TPS back at `(0, -1)`, and TPS sides at `(-1, 0)` / `(1, 0)`. Aim uses the inherited five-point combat idle/front/back/side graph. Neither has four dedicated diagonal clips. Default BlendSpace mode is interpolated, not discrete; baked tracks explicitly use interpolation `1` (linear), and gait clips in the current generated resource loop. Offline 60 Hz sampling is not stepped playback.
- **Most likely stiffness cause: poor and inconsistent samples/retarget, not missing blending.** Normal locomotion mixes a human forward run with mechanical robot backward/lateral poses; the latter retain incompatible footwork/proportions and do not establish a relaxed human gait. Current durations/cadences differ (UAL run about 1.3095 s versus TPS strafes about 0.8333 s), and the graph does not explicitly configure gait-phase synchronization. Different durations alone do not prove the exact visible seam, but phases/contact semantics need calibration before blending.
- Previous artifacts independently confirm the hard blocker: `strafe_left` sole minima **(0.066335, 0.000500) m**, `strafe_right` **(0.059787, 0.000500) m**. One foot never reaches the unchanged **2 cm** support criterion. Historical focused result: **301 checks, 2 failures**; it was not rerun in this planning pass. Moving the whole character down would penetrate the other sole.
- Four cardinal samples form a **diamond**, not an eight-sample ring. A normalized diagonal such as `(0.707, 0.707)` is outside that diamond and is evaluated against its boundary; its pose is a mixture of cardinal clips, not a real diagonal gait. Blended root vectors can also slow diagonal travel, and unequal source speeds can bias its direction. Existing tests check signs and an upper speed bound, not precise continuous-angle alignment or consistent diagonal speed. This is a validation gap, not proof that all intermediate angles are correct.
- Camera-facing movement in both modes can feel less like relaxed free-running, but it is the existing approved policy, not accidental direction quantization. Changing that policy would not repair the demonstrated foot-contact failures.

## CC0 animation recommendation and verified availability

**Recommend a suitable humanoid source over further broad robot-retarget repair**, without replacing Regina's rig. CC0 is a useful licensing condition, not a quality/compatibility guarantee.

Read-only inspection of the already archived `.artifacts/regina-locomotion/AnimationLibrary_Godot_Standard.gltf` found **46 clips**, including `Pistol_Idle_Loop`, `Pistol_Aim_Neutral`, `Pistol_Aim_Up` and `Pistol_Aim_Down`. Their channels include hands and finger chains. This is the existing documented Quaternius Standard source, not a newly acquired dependency. It is a plausible **grip/aim evaluation source**, not yet retargeted or visually accepted; channel presence does not prove useful finger motion or a compatible handle size.

Important limitation: that inspected Standard inventory has **no backward, lateral or diagonal ground-locomotion set**. The shipped subset has only three forward/idle clips. Do not promise that expanding this pack alone delivers 8-way movement, assume a paid edition has the missing clips, or reverse/relabel a forward run as an acceptable backward gait. Evaluate one verifiably licensed, phase-compatible humanoid eight-direction set before committing a replacement. No download, new-source choice or clip integration was made here.

## Proposed minimal solution and ordered implementation

Execute only after approval, in this order. Grip is the first bounded correction; locomotion-source feasibility is a separate gate, not permission for an extended animation refactor.

1. **Establish a saved-editor baseline.** Preserve the dirty tree and earlier failed assertions; stop play/save relevant scenes before external edits. Inspect close-up right-hand poses in neutral/aim-up/aim-down, normal idle/run and lateral movement. Record wrist, gun grip and muzzle bases after skeleton evaluation. Capture continuous direction sweeps at several camera yaws and compare input, evaluated samples/phase, actual heading and travel. Use a source-only isolated import if the live editor must stay open; no competing importer.
2. **Calibrate one rigid grip boundary.** Retain the named right-wrist BoneAttachment3D. Add one explicit `WeaponSocket` Marker3D under it and a weapon-space `GripPose` reference in the existing handgun scene. Align the desired palm/handle frames with unit scale: `T_wrist_to_gun = T_wrist_to_socket * inverse(T_gun_to_grip)`. Keep the original gun geometry and muzzle under that gun root. Store one inspectable calibrated transform instead of accumulating corrective rotations in unrelated ancestors. Do not invent final offsets in advance or use world-space per-frame gun compensation.
3. **Supply the smallest compatible hand pose.** First evaluate the existing CC0 pistol-neutral/finger data with an explicit rest-aware anatomical map. If suitable, produce a separate gameplay-only fixed right-hand grip pose (thumb/fingers, plus wrist only if demonstrated necessary), applied consistently after normal/aim base blending with an explicit bone filter. No bone-rest changes, source clip edits or new runtime retarget system. If that pose cannot fit this handle, stop with the concrete mismatch rather than forcing an offset that merely hides one view. Ensure aim pitch remains correctly additive; the present baker bases its aim delta on the first `Idlecombat` pose, so verify the neutral reference rather than assuming the stored `AIM-Center` clip drives the graph.
4. **Gate the humanoid locomotion source before replacement.** Verify license/provenance, real F/B/L/R and four diagonal samples, loop seams, left/right support phase, target proportions, facing and root/in-place semantics. Preview a derived Regina lateral pair first and require the existing sole-contact criteria to pass before investing in the full set. Keep all source clips immutable. If no suitable source exists, report the missing coverage; do not fabricate an eight-way set by duplicating names.
5. **Extend the existing ARCA-local BlendSpaces only.** Use idle plus eight genuine directional samples, interpolation (`BLEND_MODE_INTERPOLATED`) and verified consistent gait timing/support phase. Feed a continuous signed direction/magnitude in the locomotion frame, accounting for camera-to-model heading; never round to 45-degree sectors. Define sample coordinates and input radius consistently, checking polygon-boundary projection rather than blindly reusing the current diamond with unit-circle input. Add explicit phase synchronization where appropriate, but note that Godot's `sync` flag alone does not normalize unequal clip lengths/contact phases. Keep the existing root proxy, single motion extraction and physics application. Calibrate derivative root travel/retiming against preserved speeds, diagonal direction and route timing; do not solve this by changing collision, camera or globally reducing speed.
6. **Keep normal/aim separation minimal.** Retain `walk` and `strafe` branches and their consumed parameter names. Normal uses compatible relaxed locomotion; aim uses compatible pistol-ready poses or a narrowly filtered upper-body layer over proven lower-body movement. Both use the same continuous direction convention and a short validated crossfade. Grip remains stable through both branches; aim controls pitch/fire/crosshair independently. Do not restore robot turn-to-travel for Regina without a separate request, or add a new state machine for this correction.
7. **Validate, document and stop.** Extend focused regressions below, run focused/source/full suites, then perform close-up grip and continuous motion F5 inspection. Update affected docs/attributions with actual source coverage and remaining limits. Preserve the old task's failing status until its unchanged checks genuinely pass. No commit or acceptance marker without the user's instruction/verdict.

## Validation plan and expected outcomes

### Focused regression checks during implementation

- Named wrist/socket/grip/muzzle paths resolve in all inherited rooms; original robot bindings remain unchanged. World-space grip alignment equals the evaluated socket transform across neutral/pitch extremes and locomotion phases, with no one-frame lag. Scale stays unit; geometric probes distinguish intended handle contact from deep slide/barrel penetration. Visual front/side/back close-ups remain mandatory; transform equality alone does not prove skin clearance.
- Derived finger pose is actually evaluated and survives aim/non-aim transitions; unrelated bones, target rest transforms/weights and original source/import fingerprints remain unchanged. Inherited muzzle effects and real shot/cover tests continue to pass; do not rotate bullets to disguise a visibly misaligned barrel.
- Assert both locomotion nodes use interpolated mode and the intended nine points. Evaluate intermediate angles (for example 22.5/67.5 degrees, not just WASD diagonals), continuous 360-degree sweeps and analog magnitudes at camera yaw 0/90/180. Verify actual sample weights/poses, travel-angle error, no abrupt weight/pose jump, no idle drift, no root accumulation/wrap stall and intended diagonal speed. Add a precise direction assertion rather than accepting only correct signs.
- Measure phase-aware support clearance/drift/penetration over several cycles, diagonal blends and start/stop/aim transitions. Keep **2 cm support clearance / 3 cm support drift / 2 mm penetration** criteria on real support phases; keep both necessary lateral-contact assertions. Do not mark swing/flight as support or widen thresholds to conceal bad retargeting.
- Preserve low-hop physics, original robot defaults, corridor 10–20-second return, projectile/cover/mission/hatch behavior and pause/death/restart/completion cancellation/freeze. No additional player/animation driver or lifecycle callback.

### Existing commands for later implementation validation — not run in this pass

From the validated project/snapshot after imports finish:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_player_test.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_locomotion_test.gd
PATH=/home/andrea/Workspace/ARCA/.artifacts/baseline-tools/ripgrep/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin GODOT_BIN=/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 bash scripts/check.sh
git diff --check
```

The Godot and local ripgrep executables were verified present. The full gate includes import and all gameplay suites; it must pass without relaxing assertions before calling implementation complete. A grip-only correction is not expected to clear the pre-existing lateral-contact failures. Regeneration, if approved, must use the derivative baker associated with the chosen source; no speculative runnable command for a not-yet-written baker is claimed.

Manual F5: close-up neutral/up/down grip and barrel direction; normal and aimed idle/WASD/diagonal motion, slow continuous stick/camera turns, several gait loops and start/stop transitions; then real fire near cover, pause/resume and restart/death/completion. Report human visual acceptance separately from headless logic/physics results.

## Evidence and remaining limits of this planning pass

Performed repository/code/resource reads, Python standard-library read-only GLB/glTF/TRES inspection and local transform arithmetic, inspection of two existing rendered pose captures and the historical focused log. Confirmed a Godot editor is open on ARCA. No Godot process/import/test/bake or new render was launched, and no archived result is presented as a new run. Only `TASK.md` is edited; all prior dirty/untracked work remains in place.

Main risks: unmatched humanoid directional-source coverage, incompatible contact phases/proportions, open-hand geometry versus pistol pose, aim-reference/filter mistakes, blend-domain/root-vector speed distortion and stale editor overrides. Stop at a demonstrated source/rig limitation rather than adding IK, rewriting the controller or weakening tests.

---

## Implementation handoff: socket/grip delivered; source quality blocked

### Changes and measured decisions

- Preserved the initial dirty tree in `.artifacts/regina-grip/baseline/`; used `.artifacts/regina-grip/source/` for imports, bakes, tests and staged renders while Godot remained open. Existing scene files were not overwritten. Unrelated concurrent editor/tooling changes are not part of this implementation.
- Added `arca/player/regina_weapon_socket.tscn`, wrapping the unchanged `regina_handgun.tscn` to expose `WeaponSocket` and `GripPose` without risking an unsaved existing scene. This is the small justified deviation from adding the marker directly to the old handgun scene. `arca_player.gd` instances it under the named right wrist and uses `gun.transform = inverse(grip.transform)`.
- Socket calibration: wrist-local **(0, 0.07, -0.032) m**, X **1.8107963 rad**; weapon grip reference **(0, -0.065, 0.025) m**, X **0.24 rad**. The original trial at socket Z -0.04 m produced 35 skin-triangle/metal intersections; an 8 mm clearance adjustment removed them. No weapon dimension, source weight or test tolerance changed.
- Extended `source/extract_locomotion.py` with an optional `--pistol-grip` mode, preserving default extraction byte-for-byte. New `source/ual_pistol_grip.glb` contains only the immutable CC0 neutral-pistol clip/mannequin from the already pinned Standard inputs, with its own tracked import. Source/license hashes and regeneration are documented beside it; no new download or paid source was used for the delivered assets.
- Added offline `bake_grip.gd` / `grip.tres`: 15 right-finger rotations mapped through anatomical palm frames, plus a separate rest-relative additive wrist half-turn. The first fixed-wrist trial was rejected because it did not preserve animated aim. The delivered filtered Add2 wrist correction plus opposite gun quarter-turn preserves the evaluated baseline barrel direction; a filtered Blend2 supplies the fingers. Both remain inside the existing AnimationTree and lifecycle hooks.
- Corrected two directly reproduced aim-encoding bugs in `bake_gameplay.gd` / regenerated `gameplay.tres`: encode deltas with target rest rotation and remove the unconverted absolute endpoint from static aim poses. The combat-idle base remains the actual additive reference. Testing the separate source `AIM-Center` as the base was not retained because that is not the graph's neutral base. These are derivative repairs, not original clip edits or a full aim-retarget replacement.
- Expanded `regina_player_test.gd` with triangle/box SAT probes (vertices alone missed the original skin-face intersection), original-defect reproduction, socket/pose/scale/frame-lag and barrel-basis checks, constant aim endpoint checks, and genuine visible aim-direction assertions. Default full-gate coverage retains all previous assertions. `--weapon-grip-only` is a focused iteration mode, not a skip in `scripts/check.sh`.
- Updated affected README/design/Regina/validation/source/attribution documentation. No commit or branch was created.

### Actual validation

- Focused grip: **107 checks, zero failures**, including 16 state/phase combinations, neutral/up/down additive amounts, wrist/socket/grip equality, 15 posed fingers, unit scale, original barrel-basis preservation and no slide/barrel surface penetration beyond the unchanged 1 mm inset. The deliberately restored original attachment fails the same geometric clearance probe, as required by its positive-control assertion.
- Required `bash scripts/check.sh` in the isolated snapshot, with the documented Godot/ripgrep overrides: launcher **13**, first-playable **42**, raptor **24**, mission **52**, ambush **44** pass. Regina-player **373 checks, 3 failures**. The gate **does not pass**. Import/GDScript compilation succeeds; source/locomotion suites pass separately **93/68**.
- Current failing measurements: `strafe_left` sole minima **(0.066335, 0.000500) m**, `strafe_right` **(0.059787, 0.000500) m** (unchanged 2 cm criterion). New upper-aim assertion: neutral barrel **(-0.078545, +0.055167, +0.995383)**, up-aim **(-0.079946, -0.197449, +0.977048)**. The arm/hand pose still fails the intended visible pitch despite the repaired additive encoding. Projectile/cover/hit suites still pass; their targeting does not certify visual barrel alignment.
- Final diagnostics for `arca_player.gd`, `bake_grip.gd`, `bake_gameplay.gd` and `regina_player_test.gd` are clean. `git diff --check` passes. Both derivative bakes repeat byte-identically and match the working resources; the new pistol subset also reproduces byte-identically. Protected original/F6 fingerprints are unchanged, and validated application files match the working files.
- Staged X11/Compatibility/Mesa Intel Iris Xe baseline and corrected close-ups were rendered in ignored `before/` and `after/` directories. The staging helper disables interpolation on the frozen actor so close-up cameras and manually sampled poses use the same frame; gameplay interpolation settings were not changed. Checked the open-hand/metal defect and corrected hand contact, plus normal movement and neutral/pitch-extreme aim samples. This is not a continuous human playtest, polished trigger/finger acceptance or GPU-performance measurement.
- Iteration failures were corrected rather than suppressed: one graph wiring order initially attempted to give `eye_blend` two consumers; the output is now disconnected before inserting the two filtered nodes. A validation-sync invocation used the wrong working directory and therefore ran a stale snapshot; it is not the final gate. The final synchronized run above includes the new aim-quality assertion.

### Concrete stop condition and remaining work

The existing CC0 Standard archive has pistol poses but **no backward/lateral/diagonal locomotion set**. The author's public library page was checked; its broad eight-direction advertisement spans separate Standard/Pro/Source tiers and does not prove availability of the missing clips in the obtained free files. No suitable eight-way source is available in this repository, so do not fabricate coverage or integrate a nine-point graph using duplicate/renamed samples. Steps 4–6 remain blocked before locomotion replacement, gait-phase calibration and continuous-angle quality acceptance.

The mechanical aim donor also remains unsuitable for the tested upper-pitch result. Stop here rather than add procedural upper-arm correction, reweight the hand, replace rigs or expand the task into a retarget framework. A separately scoped suitable humanoid directional/pistol source evaluation/acquisition is the next required decision. The existing normal/aim branches and camera-facing policy remain unchanged. Preserve all three failing assertions until genuine compatible poses pass them.

Remaining human F5 checks: right-hand contact/trigger appearance from both sides in idle/run/aim, continuous camera-relative turns and several gait loops, aim extremes, actual fire/cover, pause/resume, restart, death and completion. Do not mark either this task or the earlier locomotion correction accepted from headless or sampled-render results.

---

# Preserved active task record — incomplete locomotion/jump correction

/im# Task: correct Regina locomotion and jump

Status: **partially implemented; stopped at the planned animation-quality blocker, not complete or accepted**. The user explicitly invoked `implement` against this plan, including camera-facing directional movement outside aim. Facing, continuous directional selection, bake root/loop separation and the measured low-hop physics are integrated, preserving robot defaults and prior uncommitted work. The expanded suite has **301 checks, 2 failures**: one sole never reaches support height in each TPS-derived lateral clip (minimum 6.63 / 5.98 cm against the unchanged 2 cm criterion). Existing gameplay suites and 93/68 source/locomotion checks pass, but the required full gate fails on those contact assertions. No new animation source, IK/rig repair, scene-file overwrite or user F5 acceptance is claimed. See the implementation handoff before the previous task below.

## Goal and mandatory contracts

Make Regina's movement visually consistent with actual camera-relative travel and give her a restrained, measurable survival-horror hop, without replacing the inherited TPS controller.

- W uses forward travel/pose, S genuine backward travel/pose, A left and D right, with correct diagonals and idle transitions. Preserve actual camera-relative controls and RMB aim. Do not invert WASD to conceal an orientation/animation error.
- Diagnose and measure **physical displacement**, **anatomical visual facing**, and **selected/evaluated animation** independently. A passing displacement-only test does not prove correct facing or gait.
- Physical standing-jump apex: **0.25–0.40 m above the settled takeoff position**, measured on `CharacterBody3D`, not guessed from a screenshot. Keep natural gravity, one takeoff per press, a perceptible non-bouncing landing, and synchronized available poses.
- Keep the source Regina GLB/import/rests/materials, standalone robot defaults, F6 inspection/locomotion proof, camera transforms/input, capsule, `move_and_slide()`, weapons, enemies and mission logic unchanged unless a small shared-controller extension is directly required here. No addon, controller copy, IK system or new animation download.
- Preserve the existing corridor and its 10–20-second automated forward-return target. Do not change route assertions or rebalance movement speed simply to make tests pass.

## Proposed behavior decision for approval

**Recommended interpretation of the requested S/A/D behavior:** Regina faces the camera-relative forward heading in both ground modes, with actual backward and side-step clips outside aim as well as during aim. Do not make her enter the aiming state just to obtain strafing.

This deliberately changes the current **non-aim turn-to-travel** policy: today every non-aim direction turns the body and uses the same forward-run blend. A wrapper-yaw fix alone cannot provide a true non-aim S-backward/A-left/D-right gait. Approval should confirm this camera-facing directional policy. If the user instead wants to keep free-running turns outside aim, clarify that contract before implementation; do not silently claim that forward-running after a turn is a backward animation.

Keep the existing small free-jump action for this correction. The current mission route has no tested requirement to jump and no contextual traversal action/system. A vault/step-over could be a later design choice, but implementing one now would expand this bug fix and require obstacle detection/animation contracts not currently established.

## Read-only diagnosis and actual affected flow

### Hierarchy and coordinate frames

- `arca/mission_room.tscn` inherits `arca/raptor_room.tscn`, which inherits `arca/test_room.tscn`; the latter instances `arca/player/arca_player.tscn`, inheriting the original `player/player.tscn` CharacterBody3D and `Player` script.
- At runtime `arca/player/arca_player.gd::_install_regina()` installs `Player/PlayerModel/ReginaModel`. It contains sibling `RootMotion` and `Regina` nodes plus an AnimationPlayer. Regina's Skeleton3D is under `Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D`.
- `arca/player/regina_model.tscn` rotates `Regina` **180 degrees around Y**, retaining the inspection scene's -Z presentation and Y offset -0.0112332 m. The extracted motion proxy is outside this rotated subtree.
- The legacy camera does not face the same way as an unrotated Camera3D: `player/player.tscn`'s SpringArm3D contains approximately 180-degree yaw and a downward viewing pitch. At zero camera-base yaw, its projected viewing forward is **+Z** and screen-right is **-X**, while `PlayerInputSynchronizer.get_camera_rotation_basis()` returns **CameraRot**, not the final Camera3D basis. Do not change the camera or assume these two bases are identical.
- `player/player.gd` applies extracted motion through `orientation`, horizontal displacement/delta, gravity and `move_and_slide()`, then overwrites `PlayerModel.global_transform.basis`. Any model correction belongs below that controlled pivot.

### Identified incompatibilities and hypotheses to verify

1. **Strong static explanation for reversed-looking non-aim movement:** `bake_gameplay.gd` deliberately flips the UAL run proxy from -Z to **+Z** for this TPS controller. The gameplay wrapper still presents Regina toward -Z. The physical root and visible forward are therefore opposed under the existing pivot convention. First verify anatomical facing in rendered front/side views; the candidate minimal correction is to remove the gameplay-only Y half-turn while keeping its foot offset. Do not also flip proxy signs/input/camera as an additional correction. Leave the separate -Z F6 wrapper/library unchanged.
2. **Non-aim directional selection is absent:** `Player.animate(WALK)` writes only `Vector2(motion.length(), 0)` into the walk blend. `apply_input()` turns orientation with `Basis.looking_at(target)`. There is no backward/left/right selection in this branch today.
3. **Aim BlendSpace labels are not reliable semantic evidence:** current `parameters/strafe/blend_position` is `(motion.x, -motion.y)`. The inherited graph has `strafe_left` at (+1, 0), `strafe_right` at (-1, 0), `strafe_back` at (0, -1), and `strafe_front` at (0, +1). In the generated resource their lateral root signs are respectively -X/+X and longitudinal signs -Z/+Z. With the legacy final camera basis these may already be physically correct. Render/evaluate each clip before changing that mapping; a raw left/right source name is not grounds for swapping input or tracks.
4. **Confirmed bake loop defect:** `bake_gameplay.gd::run()` changes source duplicates to `LOOP_NONE` for sampling; `_bake_clip()` copies that modified loop flag to the result. The generated TPS directional/combat clips are non-looping, unlike UAL idle/run. Continuous movement must be tested beyond one clip duration.
5. **Root/pose contamination to verify numerically:** `_bake_clip()` writes donor root displacement to `RootMotion`, but also derives hip position from `bone_transform()` global thigh centers, which include that donor root travel. Root displacement is not explicitly removed before computing the pelvis pose. Also, `root_origin` is captured before seeking each clip's first sample. This can produce duplicated skin travel, per-clip starting offsets, sliding and exaggerated visual jump motion. Measure proxy, hips and skinned soles independently before correcting the bake.
6. **Jump impulse is excessive for the new goal:** `player/player.gd` hardcodes `JUMP_SPEED = 5.0`; `get_gravity()` supplies acceleration and project settings contain no custom gravity magnitude. Assuming the Godot default 9.8 m/s², ballistic rise is 1.276 m (about 1.234 m with the current semi-implicit 60 Hz step), before any extra visual pelvis movement. These are calculations, not a runtime apex measurement.
7. **Jump integration checks needed:** airborne branches currently retain the last grounded `root_motion` instead of sampling/resetting it explicitly. `land()` plays sound and requests the falling branch, but never fires the graph's existing `parameters/land/request` OneShot. The current 0.1-second airborne grace, duration threshold for landing, 0.2-second transition and 0.25-second landing fades must be checked against a much shorter hop; do not assume current authored clip durations synchronize automatically.
8. **Held-button protection already exists:** `player_input.gd` sets jumping only on `Input.is_action_just_pressed("jump")`; `apply_input()` consumes it. Preserve that edge-triggered contract and add regression coverage rather than introducing a second input path.

### Relevant files and responsibilities

- `arca/player/regina_model.tscn`: gameplay-only visual correction; do not edit `regina.glb` or F6 scenes.
- `arca/assets/characters/regina/bake_gameplay.gd` / `gameplay.tres`: root/hip separation, original loop flags, directional pose/travel calibration and hop-phase retiming; regenerate, do not hand-patch baked keys.
- `arca/player/arca_player.gd` / `arca_player.tscn`: ARCA-only settings, local graph overrides, non-aim directional blend and existing lifecycle integration. Preserve weapon installation and health/cover behavior.
- `player/player.gd`: only the small opt-in needed to use camera-facing directional WALK selection and a configurable jump impulse with robot-compatible defaults; retain the physics/root-motion pipeline. Keep actual aim/fire gating independent of locomotion mode.
- `player/player.tscn` and `player/player_input.gd`: inspect/reference; prefer no edits. Existing graph has walk, strafe, jumpup/jumpdown and hardland/land nodes, and consumed parameter names must remain compatible.
- `arca/tests/regina_player_test.gd`: expand the existing registered suite (currently structural/resource checks only). Reuse `arca/test_room.tscn` as the test arena, disabling enemies in the harness only; no new level needed.
- `arca/tests/first_playable_test.gd`, `mission_test.gd`, `raptor_test.gd`, `ambush_test.gd`: existing controller, route, projectile and lifecycle regressions. Keep their assertions, including the synthetic aim reset and route timing.
- `README.md`, `docs/DESIGN.md`, `docs/REGINA.md`, `docs/VALIDATION.md`, and this task: update actual behavior, measurements, known limits and user acceptance during implementation. Update attribution only if derivative-source/modification descriptions change.

## Proposed minimal implementation order

1. **Reproduce before fixes.** Preserve the dirty tree. With saved editor work, use an isolated ignored source snapshot if Godot remains open, not a competing live importer. Capture the original robot and Regina at the same camera yaw with W/S/A/D, aim off/on, plus standing/moving jumps. Log final-camera projected forward/right, body delta/velocity, pivot and anatomical forward, current graph state/blend/clip phase, extracted root and hip displacement. Record signed baseline speeds, pose seams and measured body apex/flight. Show a failure for the reported mismatch before changing signs.
2. **Correct one gameplay coordinate boundary.** Verify the candidate removal of Regina's gameplay-only Y half-turn, retaining the Y foot offset and inherited pivot/camera. If actual pose/basis measurements contradict it, correct only the demonstrated boundary and document the reason. A visual correction must not reverse physical WASD travel or alter source/F6 assets.
3. **Repair the derivative bake where evidence confirms it.** Seek/reset to a deterministic start before taking each root reference; convert donor root into controller coordinates once. Remove donor root travel from pelvis-pose sampling in the same coordinate frame so the skin retains only local gait/crouch/bob. Keep vertical ballistic jump translation controller-owned. Preserve original cyclic flags for gait/idle; sample endpoints without losing runtime looping; retain appropriate non-looping takeoff/landing. Prove clean pose seams/root accumulation across repeated loops and repeatable generation. Missing required source clips/bones or save failures remain actionable nonzero errors, not silently skipped data.
4. **Implement the approved directional ground policy without duplicating the controller.** Add one ARCA opt-in with original robot turn-to-travel as the default. Outside aim, face camera-relative forward and feed signed directional input into an ARCA-local WALK BlendSpace: UAL forward/idle and the distinct TPS-derived backward/lateral poses already present. Map by verified motion/anatomical direction, not source labels; retain the current aim graph unless measured evidence shows a separate mapping defect. Bound diagonal blend input without altering WASD bindings or global input behavior. Keep acceleration smoothing, gravity, collision and consumed parameter/state names. Do not fake `aiming` or enable shots/pitch/crosshair merely to side-step.
5. **Calibrate the hop through existing physics.** Expose the existing impulse with default **5.0 m/s** for the robot and ARCA initial **2.6 m/s**. Retain `get_gravity()` and global gravity; confirm actual magnitude at runtime. At 9.8 m/s² this predicts 0.345 m continuous rise, approximately **0.323 m at 60 Hz**, and about **0.53 s** flight. Start here, then tune only from measured body apex to stay within 0.25–0.40 m. Retain edge-triggered jump. If moving-jump tests reproduce stale root reuse, make the existing takeoff horizontal momentum explicit during flight, without adding new air steering. Clear transient motion on landing/restart/death as required.
6. **Synchronize available jump poses and landing.** Fit takeoff to roughly the first 0.2–0.25 s, keep the falling pose until actual contact, and start the existing landing OneShot once on a genuine landing rather than on a timer or startup settling. Initial landing duration about 0.2 s with short (~0.05 s) blends is a trial, not an accepted visual result. Keep physics out of the pose clips; preserve capsule/contact handling and sound behavior. Do not add an artificial rebound or a new recovery/input lock. Verify pause/death/completion cannot leave a pending landing effect or frozen wrong state.
7. **Validate, render, document.** Extend the existing registered Regina-player suite with independent physical/facing/animation assertions, then run the focused and full gates below. Inspect staged front/side/back motion and complete the F5 checklist separately. Record actual baseline/final values, chosen coordinate boundary, directional policy, contact windows/tolerances and remaining retarget defects. Do not call the task accepted until the user gives the visual verdict; do not commit unless asked.

## Acceptance tests and validation

### Focused automated checks to add to the existing suite

- At camera yaw 0°, 90° and 180°: W/S/A/D plus all four diagonals, aim off and on, with several consecutive gait loops and transitions to/from idle. Compare body travel against the **actual Camera3D's horizontally projected** viewing axes, not an assumed unrotated -Z or raw CameraRot axis. Inputs must have the correct signs; selected/evaluated poses must match the approved directional policy and established anatomical-facing reference.
- Independently verify grounded visual facing (after the existing turn interpolation settles), correct evaluated clip/BlendSpace weights, signed root extraction, no duplicate model travel, no non-looping stall, no wrap reversal/spike and no unintended diagonal speed boost beyond the corresponding blend's intended speeds. Idle must settle without drift. Preserve forward-route speed rather than using a global speed change to hide the visual defect.
- Use actual CPU-skinned sole vertices, as in the isolated locomotion test, with phase windows measured for each gameplay gait. Distinguish planted contact from swing, toe-off and flight. Use the existing proof's **3 cm support drift / 2 cm support clearance / 2 mm penetration** as initial contact criteria on genuine flat-support windows; do not simply reuse forward-run phases for backward/sideways clips or widen tolerances to conceal failure. Record failures/animation feasibility limits rather than silently adding IK or changing sources.
- Stationary and moving jumps on a settled level floor: body apex **0.25–0.40 m**, initial expected flight approximately **0.45–0.65 s** at 60 Hz, one ascent then descent, one genuine landing, no rebound, capsule not penetrating the floor, no extra ballistic lift copied into the visible hips. Distinguish body-root height from pose crouch/leg-tuck and report both where relevant. Include a low-ceiling collision check.
- Hold Space longer than two predicted flights: exactly one takeoff. Release/repress after landing: one new takeoff. Press while airborne: no double jump or unrequested queued hop. Check jump from idle and while moving/aiming, pause/resume in flight, restart/death in flight, and restoration of correct grounded blend/momentum.
- Keep structural/source/bone/weapon checks, original robot model/bindings, robot default jump setting and turn policy, walls/collision, actual shots/cover, mission interactions and 10–20-second corridor-return assertions. Existing reset helpers must release inputs and clear the synthetic aim-toggle state so a headless test does not unintentionally enter aim.

### Implementation commands (not run during this planning pass)

From the validated implementation project/snapshot after imports finish:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --path . -s res://arca/assets/characters/regina/bake_gameplay.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_player_test.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_locomotion_test.gd
bash scripts/check.sh
git diff --check
```

`scripts/check.sh` already registers `regina_player`; extend that suite rather than adding a second test framework. Godot import/GDScript compilation and relevant editor diagnostics are the static/type gate. If shell discovery remains unchanged, use the existing local overrides from the project/snapshot root:

```bash
PATH=/home/andrea/Workspace/ARCA/.artifacts/baseline-tools/ripgrep/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin GODOT_BIN=/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 bash scripts/check.sh
```

Expected: regenerated data is reproducible, original GLB/import/F6 library remain unchanged, focused direction/jump assertions and the full gate pass with no script/runtime errors. The previous 213 gate checks and 93/68 source/locomotion results are **historical**, not validation of this correction. This planning pass used repository reads and read-only arithmetic/text inspection only; no Godot importer, runtime suite or new rendered inspection was run.

### Manual F5 checklist after implementation

1. On clear floor, test W/S/A/D, diagonals, several complete cycles, stop/start and camera yaw 90°/180°. Check anatomical facing, true backward/side footwork, planted-foot sliding, smooth turns/blends and no skin/root doubling. Repeat while aiming; existing weapon/camera behavior must remain usable.
2. Jump from idle and moving: judge the measured low hop, takeoff/apex/descent/landing timing, no extra mesh lift or rebound. Hold Space through landing, release and jump again. Pause/resume and restart during flight; check grounded recovery and no deferred jump/landing.
3. Complete the fuse/return/panel/hatch/exit loop; check cover/fire and death/restart/completion. Report the visual verdict separately from headless results, including existing shoulder/costume and primitive-weapon limits.

## Animation limits, risks and stop conditions

- Original Regina GLB contains **no authored clips**. The UAL source subset has idle/walk/jog only. Distinct TPS backward/left/right, jump/fall/land clips do exist, but are robot-derived and their human footwork/contact quality is not accepted. Do not reverse or relabel the UAL forward run as a credible backward gait. Reusing TPS combat steps outside aim is the smallest available directional prototype, not an assertion that dedicated relaxed backward/side animations exist.
- Fixing the gameplay wrapper yaw must be validated with pitch/muzzle/aim because the attachment inherits the skeleton. Do not compensate by changing projectile aiming, camera orientation or gun transforms unless a directly reproduced regression makes it necessary and is reported.
- The bake's root conversion, hips contamination and looping defects interact; a yaw-only patch is not proof of correct strafing or jump height. A source-name-only BlendSpace swap is likewise insufficient.
- No per-frame foot clamp, mesh/weight repair, rig replacement, new assets or contextual traversal is authorized. If available poses cannot meet reasonable contact/visual criteria with the bounded bake/retiming changes, stop and present the specific clip/measurement limitation for a separate decision.
- Preserve current unsaved editor work and all unrelated uncommitted changes. If the editor stays open, use an isolated snapshot for imports/runs and confirm source parity. Implementation must not silently close the previous integration's pending visual acceptance.

## Implementation handoff: partial correction and measured stop condition

Implemented following the explicit user `implement` invocation; no approval marker was invented and no commit/branch was created. Prior integration changes and task records remain intact.

### Resulting changes

- `arca/player/arca_player.gd` replaces the gameplay instance's wrapper yaw with zero below the controlled pivot, matching the actual +Z TPS convention. Existing `.tscn` files were not externally rewritten while Godot was open. It creates a local signed directional WALK BlendSpace with separate UAL forward/idle and TPS backward/lateral clips, keeps aim/fire independent, opts into the 2.6 m/s hop, shortens local transition/landing fades and arms the existing landing OneShot only after real airborne/jump activity.
- `player/player.gd` adds ARCA opt-in directional ground facing/blending and a configurable impulse defaulting to the existing 5 m/s value. Diagonal requests are normalized only in the opted-in mode. Airborne ARCA travel carries actual horizontal velocity rather than a stale animation-frame root delta. Camera, input bindings, collision pipeline, project gravity and original robot turn-to-travel behavior remain unchanged.
- `arca/assets/characters/regina/bake_gameplay.gd` / `gameplay.tres` seek deterministic clip starts, remove donor world-root travel from pelvis sampling, keep proxy Y/ballistic jump travel zero, preserve gait loops, keep takeoff/landing non-looping, apply a constant per-clip sole offset and retime takeoff/landing to 0.25/0.20 s. No source GLB, skeleton lengths, weights or F6 asset was changed. Two consecutive bake runs were byte-identical.
- `arca/tests/regina_player_test.gd` expands the existing registered suite, not the runner/framework. Structural checks still instantiate all inherited rooms. For continuous direction/diagonal physics it uses a **test-only large primitive floor** rather than the obstructed room floor; this bounded deviation lets several root-motion loops run without walls contaminating the measurement. It also measures hop physics/input/collision/pause/death and actual skinned sole minima. Playback is stopped on cleanup; a short wall-clock drain avoids racing the Dummy audio mixer at unthrottled fixed-fps exit.
- `README.md`, `docs/DESIGN.md`, `docs/REGINA.md`, `docs/VALIDATION.md`, `ATTRIBUTIONS.md` and this record describe actual behavior and the failed quality gate. The pre-existing `/im` prefix is preserved.

### Actual validation and measurements

Used a fresh source-only isolated import in `.artifacts/regina-motion/source/`, not a competing import on the live editor project. The original and corrected probes used the same real inherited player scenes and physics floor.

| Measurement | Before | After |
| --- | ---: | ---: |
| Standing body-root hop apex | 1.234900 m | 0.324067 m |
| Moving body-root hop apex | not measured in baseline | 0.323358 m |
| Standing flight | 1.000 s | 0.500 s |
| Forward steady travel | 4.100 m/s | 4.100 m/s |
| Aim directional travel after one clip | stalled at 0 m/s | continuous 2.160 m/s |
| Automated corridor return | 13.47 s (prior integration) | 13.47 s |

- `bash scripts/check.sh` with the documented literal Godot/ripgrep overrides: launcher **13**, first-playable **42**, raptor **24**, mission **52**, ambush **44** checks pass. Godot import/compilation succeeds. **The command fails overall:** Regina-player **301 checks, 2 failures**. Do not call this a passing gate.
- Expanded direction checks cover all eight directions at yaw 0/90/180 in both aim modes over multiple loops: signed physical travel, continuous motion, visible anatomical-axis alignment, signed normalized graph parameters, zero visual proxy accumulation, speed bounds and idle recovery pass. The original robot default mode/impulse checks pass.
- Standing/moving body apex, 0.50 s flight, held-Space single takeoff/landing, release/repress, landing OneShot, low-ceiling collision, pause/death in flight and fresh-instance state checks pass. Gravity is measured at **9.8 m/s²**. These are physics checks, not final pose-quality acceptance.
- Separate unchanged suites pass **93 static** and **68 locomotion** checks. Source assets/isolated proof remain intact. Changed GDScript diagnostics are clean. An early indentation error caused a probe timeout and was corrected; that failed attempt is not a passing result.
- X11/Compatibility/Mesa Intel Iris Xe startup and sampled front/side captures were inspected under `.artifacts/regina-motion/rendered/`. Corrected startup facing is visible; sampled lateral steps remain elevated/robotic and the landing donor pose is not polished. No human F5 acceptance or GPU-performance claim is made.

### Concrete blocker and remaining work

The focused suite independently skins actual sole vertices across each entire lateral clip. `strafe_left` minima are **(0.066335, 0.000500) m**; `strafe_right` **(0.059787, 0.000500) m**. One foot never reaches the required 2 cm support height at **any** phase. This is a necessary-condition failure, not mislabeling swing/flight as planted support. Lowering the whole character sufficiently would penetrate the other foot. The 2 mm penetration checks pass, and the contact assertions remain failing in the standard gate.

Stop here as required by this plan's pose-feasibility limit. The current mechanical donor/target retarget still does not deliver credible humanoid lateral footwork after bounded root/loop/constant-height fixes. Do not widen tolerances, reverse/rename a forward run into a backward clip, or silently add IK, weight/rig repair or downloads. **Recommended next decision:** separately scope evaluation of a suitable licensed humanoid directional animation source; targeted retarget repair is another explicit scope decision, not implicitly authorized by this correction.

Still incomplete: phase-aware contact/sliding acceptance across all gameplay blends, continuous rendered movement/jump/aim/fire review, the complete restart/aim-jump/lifecycle checklist and user F5 verdict. Existing projectile/cover/mission/hatch suites pass, but those do not certify natural footwork or final landing quality. Keep this task open and the full-gate failure visible until the animation limitation is resolved.

---

# Previous task: replace the playable robot with Regina

Status: **implementation is integrated and automated checks pass; visual/user acceptance is pending**. Regina now replaces the visible robot at runtime in the shared ARCA player, with the TPS controller/camera/collision/projectile pipeline retained, a separate 15-clip gameplay animation bake and an original primitive wrist-mounted handgun. The original standalone robot player retains its default model and weapon bindings. Validation in the ignored isolated snapshot passed the full gate: launcher 13, first-playable 42, raptor 24, mission 52, ambush 44 and Regina-player 38 checks; Regina static/locomotion checks passed 93/68. The mission return measured 13.47 simulated seconds. A staged startup capture visibly shows Regina and no robot body; shoulder/costume intersections and open-hand posing remain visible prototype limits. Godot remains open, so no competing import was run in the working project. Do not mark this task accepted: live F5 inspection/playtest of movement, aim/strafe/fire, cover, lifecycle and appearance remains for the user. Earlier isolated-locomotion work and its pending F6 acceptance are preserved below.

## Goal and mandatory requirements

Make **Regina the visible, animated, playable character in F5**, using Godot **4.5.1 Standard / Compatibility** on Linux. This is a first playable character integration, not a final character-art pass.

Acceptance:

- The mission starts with one Regina player at the existing spawn, at the established approximately 1.799 m reference height, facing/moving correctly. No robot body, floating robot weapon/effects or duplicate character is visible, including shadows.
- Preserve WASD/mouse movement, camera-relative facing, acceleration/turning behavior, RMB aim, directional aim-strafing, LMB projectiles, Space jump, E interactions, damage, pause, death, restart and mission completion. Keep existing weapon cooldown/damage and unlimited ammunition.
- Preserve the root-motion-to-horizontal-velocity controller, capsule, gravity, jump physics, spring arm, camera input and cover-safe projectile origin. Character integration is not authorization to rewrite movement or camera behavior or rebalance route speed.
- Regina has coherent idle/movement, aim/strafe and jump/fall/landing poses, with visible pitch response while aiming and an attached prototype handgun/muzzle. Do not use unarmed running for every state, a T-pose for missing clips, or an invisible animated robot as the runtime movement/weapon driver.
- Keep the accepted fuse route, 10–20-second automated return target, hatch sequence and kill-optional exit. Original robot `player/player.tscn` remains usable as a reference with unchanged default behavior.
- Preserve the original Regina GLB, rest transforms, skin weights, nine mesh/material bindings, source-side import settings and existing isolated static/locomotion scenes and library. Preserve licenses and document any new derivatives.
- Headless regression checks and rendered/F5 inspection must be reported separately. Existing shoulder/costume clipping is a disclosed prototype limit, not pre-approved visual acceptance.

## Assumptions, approval decisions and non-goals

- Scope proposal: update the shared **ARCA player** in `arca/player/arca_player.tscn`, so mission, raptor room and base test room exercise the same integrated Regina. The base test room's enemy remains the robot. Do not duplicate the player/controller or change the room inheritance chain.
- Use the current Regina asset and existing licensed animation sources. Keep the isolated three-clip proof unchanged; create a separate gameplay animation library with gameplay-relative track paths. The request authorizes planning integration despite pending earlier F6 acceptance; it does not imply that acceptance was given.
- A small **original primitive placeholder handgun**, attached to the right wrist, is sufficient for this prototype. The robot GLB has skinned cannon geometry, not a verified reusable standalone handgun; Regina's holster is not an assumed usable gun. No download, purchase or new dependency is planned. Approval of this plan includes this temporary weapon choice.
- Preserve existing gameplay speeds as the baseline rather than adopting the viewer's different measured speeds. Reuse/retime locomotion poses to the preserved physical travel, and measure actual contact/loop quality; changing the route timing or loosening tests is not a substitute for correct integration.
- Missing combat/jump pose quality is a **feasibility risk**, not an already solved contract. Trial the existing TPS source in a separate gameplay bake first. If the required states need major rig repair, new IK or a new animation acquisition, stop and present the specific blocker for a separate decision before switching the shared player.
- Non-goals: ammunition/reload/health economy, inventory/saves, additional protagonists, new inputs, camera redesign, networking features, new runtime retargeting framework, mesh/weight/material repair, hair/cloth simulation, polished finger/recoil animations, final gun art, engine upgrades or public distribution. Existing character/IP provenance caveats still apply.

## Read-only findings and relevant files

- `arca/mission_room.tscn` inherits `arca/raptor_room.tscn`, which inherits `arca/test_room.tscn`. Only `test_room.tscn` instances `arca/player/arca_player.tscn`; changing that shared player reaches all three rooms without spawning a replacement actor in mission code.
- `arca/player/arca_player.tscn` inherits `player/player.tscn`, adds health and uses `arca/player/arca_player.gd`. The latter inherits `Player`, adds health/death and a chest-to-muzzle cover sweep at 1.4 m. Room scripts retain `player: Player` and bind its existing health component.
- `player/player.gd` reads `parameters/state/transition_request`, `parameters/aim/add_amount`, `parameters/strafe/blend_position` and `parameters/walk/blend_position`. Its root-motion extraction feeds `orientation`, horizontal displacement/delta and `move_and_slide()`. It overwrites `PlayerModel`'s world basis every physics tick. Visual yaw correction must therefore live **below** that pivot.
- `player/player.tscn` supplies the walk/strafe/jump/additive-aim graph, time scales 1.3 for walk and 1.2 for strafe, a robot root extraction track, 1.6 m camera pivot, collision shapes, particles, sounds and 0.4-second fire timer. Its eye filters, aim filters and AnimationPlayer paths are robot-specific.
- `player/player.gd` also hardcodes `Robot_Skeleton/Skeleton3D/GunBone/ShootFrom` in its on-ready muzzle lookup and both firing-particle lookups. All three need a narrow configurable binding with the original paths as defaults, not a copied shooting controller. Keep existing RPC/cooldown/sound/shake behavior.
- `player/player_input.gd` owns mouse/camera input, aim toggle/hold, camera animations/crosshair and target projection. Preserve it and the camera animation resources unchanged.
- `arca/character_test.tscn` applies a 180-degree yaw and Y -0.0112332 m below `ModelPivot`; imported Regina scale remains 1. `arca/character_test.gd` and `arca/assets/characters/regina/locomotion.tres` prove idle/walk/run using a scene-axis `RootMotion` proxy, not the robot skeleton's root track.
- `arca/assets/characters/regina/bake_locomotion.gd` maps only UAL idle/walk/jog with an explicit anatomical mapping and rest/global-to-local conversion. Preview walk/run are 1.208183/4.361937 m/s, before the TPS tree's time scales. The three-clip donor subset contains no strafe/jump/aim clips. `docs/REGINA.md` records the earlier TPS trial's proportion/shoulder defects and conditional compatibility verdict.
- Existing `player/model/player.glb` contains licensed TPS combat idle, directional strafes, jump/fall/land and aim poses. They are candidate pose donors, not verified Regina animations. Full mechanical joint chains and rest axes must be accounted for; do not substitute bone names or copy robot limb translations/scales.
- Current lifecycle hooks disable player physics/input and the existing AnimationTree on death, stop animation/audio on restart, and pause the scene tree after stopping animation/audio on completion. Prefer one integrated AnimationTree so these hooks remain sufficient; inspect and test any new processing explicitly.
- `arca/tests/first_playable_test.gd` exercises actual movement, camera, projectiles/cover and death/restart. `mission_test.gd` walks the corridor and asserts a 10–20-second return. `raptor_test.gd` and `ambush_test.gd` validate actual weapon hits and predator/mission lifecycle.
- `scripts/check.sh` imports and runs first-playable, raptor, mission and ambush suites; the static and locomotion Regina suites are currently separate. `docs/VALIDATION.md` documents the ignored local ripgrep workaround. The portable Godot executable and local ripgrep executable exist; `rg`/`godot` were not found by `command -v` in this planning shell. A Godot process is running; save scenes, stop play and wait for imports before implementation/validation.

## Proposed minimal solution and ordered implementation

1. **Establish the baseline and resolve the pose feasibility gate before switching the player.** Save/reload editor work, recheck Git status and run current focused/full checks safely. Measure original straight movement/strafe velocities, heading, jump displacement and muzzle/aim behavior with fixed inputs and physics steps. Record these as comparison values, not guessed constants. Inspect actual imported clip tracks, loop flags, audio/method events and aim-center/reference semantics. Preview Regina's current clips as part of this integration review without marking prior user acceptance complete.
2. **Generate one separate gameplay animation library reproducibly.** Add an asset-specific offline `arca/assets/characters/regina/bake_gameplay.gd` and `gameplay.tres`. Reuse the existing anatomical bake approach/data where applicable without converting it into a framework or changing `locomotion.tres`. Use UAL-derived idle/run for ordinary movement, phase/retiming-calibrated to the preserved travel contract; retain walk only if the actual input blend uses it. Adapt only TPS combat idle, four strafes, aim-up/down relative to a correctly established center pose, and jump/fall/landing plus any armed movement branch actually retained by the graph. Resolve complete donor chains, preserve target lengths/reference locals and document source clips/modifications. No blanket transfer of robot scale or position tracks. Measure feet, knees, shoulders, wrists and loop/transition continuity before accepting the bake. Required unresolved tracks/bones, bad source clips or save failures must produce actionable errors and nonzero baker exit; do not silently skip them.
3. **Separate movement travel from Regina's visual correction.** Bake/rebind gameplay tracks under the controlled `PlayerModel` using a canonical `RootMotion` proxy outside the yaw-corrected Regina subtree. Convert the original movement root curves into controller coordinates, accounting for donor ancestor scale/orientation exactly once, to preserve baseline travel while retiming the visible gait. Aim-only pose layers must contribute no root travel; gravity/jump displacement remain controller-owned. Validate signed lateral/backward extraction, loop wraps, blend transitions and absence of duplicate mesh/body movement. If contact quality and baseline timing cannot both be met in scope, report the discrepancy rather than silently rebalancing motion.
4. **Integrate via the existing inherited ARCA scene.** Add a small `arca/player/regina_model.tscn` containing the original Regina instance, its visual correction, motion proxy/AnimationPlayer arrangement and weapon attachment; keep the graph/library in focused local resources as needed. In `arca_player.tscn`, retain `PlayerModel`, camera, collision, input, timers, audio and health; instance Regina below the controlled pivot and override the AnimationTree root/player/extraction bindings and graph. Preserve every parameter/state name used by `Player.animate()`, and applicable time scales. Replace robot aim filters with explicitly selected Regina bones; remove robot eye-only processing rather than inventing fake eye tracks. Hide inherited robot geometry/shadows and disable its unused animation playback; any nodes retained solely by scene inheritance must be inert, not a hidden driver. Do not copy the base scene/controller just to remove inherited nodes.
5. **Bind a real visible muzzle and preserve shooting.** Add the primitive handgun under a `BoneAttachment3D` for `arm right wrist_021`, using the verified bone name rather than relying on an index alone. Set an explicit local grip/barrel transform and muzzle at the barrel tip; include the existing particle resources/effects at that muzzle. Add only the few model-specific configurable NodePath bindings needed in `player/player.gd`, defaulting to the robot paths and overridden by the ARCA scene. Validate them at initialization. No changes to projectile trajectory/targeting, damage, cooldown, sound, camera shake or `arca_player.gd`'s cover sweep. Check aim-center/up/down and diagonal strafes with the weapon attached; reuse a minimal fixed grip pose if needed, not a general hand IK system.
6. **Add focused playable-character regressions and run the full gate.** Create `arca/tests/regina_player_test.gd` using the existing SceneTree PASS/FAIL/RESULT pattern and nonzero failure exit. Exercise the actual inherited ARCA scenes and input, not the viewer. Add the new gameplay suite to `scripts/check.sh`; preserve existing assertions, including route timing and cover. Keep the unchanged original robot scene covered by a focused smoke/comparison in the new suite, since ARCA's existing gameplay suites will now run Regina. See validation below.
7. **Render, playtest and document the actual result.** Update `README.md`, `docs/DESIGN.md`, `docs/REGINA.md`, `docs/VALIDATION.md`, `ATTRIBUTIONS.md` and this task to distinguish playable Regina, the preserved isolated proof and remaining prototype limits. Correct the viewer's now-stale English statement that F5 still uses the robot without changing its behavior. Record gameplay bake reproduction, sources/licenses and original primitive weapon authorship. Report actual automated results, rendered observations and the manual checklist separately. No commit or branch unless requested.

## Tests and validation

Focused automated acceptance for the new suite:

- Main mission, raptor room and base test room instantiate the same single Regina player; original robot scene still initializes and moves/fires through unchanged default bindings. No active robot animation driver or visible robot geometry/shadows in ARCA scenes.
- All gameplay tracks, graph parameter paths, extraction proxy, target bones, muzzle and particle bindings resolve; source GLB/import hashes and isolated libraries stay unchanged. Required graph states have usable poses, not aliases to idle/rest. No source mannequin is instantiated at runtime.
- Idle stays still; camera-relative motion and turning match the measured original baseline under the same inputs. Forward/back/left/right and diagonal aim-strafing have the correct signs and expected speeds; root displacement is applied once through real physics and walls block motion.
- Jump rises/falls/lands with the unchanged capsule/gravity behavior; entering/leaving aim or movement states does not create a root spike or reset-facing snap. Validate repeated loop/transition cycles and preserve reference bone lengths/finite skin bounds.
- Use phase-aware actual sole measurements, as in the existing locomotion suite, to expose gait/travel mismatch. Preserve existing viewer tolerances/tests unchanged; record gameplay contact phases and proposed tolerances from reference data before treating the new bake as passing. Do not interpret swing or airborne feet as planted contacts or relax a failed assertion to hide sliding.
- Aim pitch changes the visible upper-body/weapon pose; wrist attachment follows the evaluated skeleton without a stale-frame muzzle. Center/up/down/left/right target shots hit through the existing projectile path; barrel direction remains visually consistent with projected aim. Near cover, chest-to-muzzle obstruction still prevents spawning bullets beyond a thin wall.
- Pause freezes body, visible pose and effects; death and completion prevent later input/shots/pose motion. Restart during locomotion, aim/fire, jump and pause restores a single player, correct pose, HP, bindings and mission state without stale root accumulation or callbacks. Existing suites continue to cover hatch cancellation.

Commands for **implementation validation**, not executed in this planning pass. Run from ARCA after imports finish, with a bounded tool timeout. These existing Regina scripts are available now:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_locomotion_test.gd
```

This new focused command becomes runnable **only after implementation creates the script**:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_player_test.gd
```

Full existing gate and whitespace check:

```bash
bash scripts/check.sh
git diff --check
```

If shell discovery is still unchanged, use the existing literal local overrides (no package/launcher edits):

```bash
PATH=/home/andrea/Workspace/ARCA/.artifacts/baseline-tools/ripgrep/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin GODOT_BIN=/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 bash scripts/check.sh
```

Expected: unchanged static/locomotion regressions and all gameplay suites pass, including the new playable-character checks, with no script/import/runtime errors. Regenerate the separate gameplay library and verify semantic reproducibility and unchanged source assets. If a working editor/importer must remain active, validate a fresh ignored source-only snapshot and verify source parity as in the prior task; do not launch a competing import on the live project. Historical check counts are not new results.

### Manual F5 acceptance after implementation

1. Confirm Regina alone is visible, at human scale, including idle, several movement/turning cycles, jump/fall/landing and camera views near the service corridor. Check feet, knees, shoulders/costume, attached parts, no severe skin collapse and no robot/shadow remnants. Existing small clipping must be disclosed for the user's verdict.
2. Aim and strafe in all directions, pitch up/down, then fire at the raptor and from near cover. Check visible grip/muzzle/particles follow the weapon, shots align convincingly with the crosshair and the unchanged camera remains usable. Prototype weapon/pose acceptance is not final art acceptance.
3. Complete the fuse/panel/hatch/exit loop, separately fighting and evading. Pause/resume while moving/aiming/jumping, restart during those states, and check death/completion stop controls and animation correctly. Confirm the initial service entrance framing and route remain readable. Record the user's verdict; do not infer it from headless results.

## Risks and stop conditions

- This is more than a visual GLB substitution: the supplied rig has no original clips, the available UAL subset lacks combat/jumps, and the earlier robot retarget trial already exposed proportion/shoulder issues. Required TPS-derived pose quality must be proven before the shared scene is switched. Do not promise a complete combat set merely because the source has similarly named clips.
- Additive aim must be rebased against the correct center/reference pose; directly adding absolute retargeted rotations can twist the arm/neck and detach the weapon visually. Wrong root-axis/ancestor-scale conversion changes speed or doubles travel; correcting the controlled pivot itself is overwritten by the controller.
- Reusing movement curves does not itself guarantee human foot contact. Retiming poses, root-loop continuity, diagonal blending and the accepted corridor timing must all be checked together. Stop for a concrete scope decision if this needs a new animation source or a different locomotion design.
- Inherited-scene edits cannot casually remove imported children. Verify serialized overrides, editable paths and one active animation driver after editor reload. Preserve unsaved editor work and tracked UID/import/license files.
- The proposed handgun is temporary original geometry; no claim is made that Regina's existing hip accessory is a detachable licensed weapon asset. Underlying character/IP provenance remains unverified beyond the existing attribution; this task does not authorize publishing.
- Stop when the playable prototype, focused/full check results, rendered inspection and manual acceptance handoff are delivered. If correctness requires mesh repair, IK, a controller rewrite or unverifiable licensing, report that specific blocker without silently expanding scope or presenting an incomplete swap as finished. Human acceptance remains pending until the user reports it.

---

# Previous task: prove Regina locomotion in the isolated character test scene

Status: **implemented following the user's explicit `implement` invocation**. Delivered an isolated inherited idle/walk/run preview and reproducible licensed animation bake. Clean-import validation passes: 68 locomotion + 93 static Regina + 162 gameplay + 13 launcher checks. The source FBX has no animation data; TPS adaptation was trialed first, then Quaternius CC0 motion was selected. Root-motion compatibility is conditional on a later explicit player integration. Small shoulder/costume clipping remains during run; user F6 acceptance and a fresh human F5 check are pending, not marked approved. Prior task records are preserved below.

## Goal and mandatory contracts

Demonstrate licensed **idle, walk and run** playback on Regina in `arca/character_test.tscn`, using Godot **4.5.1 Standard / Compatibility** on Linux. Inspect the supplied original FBX and assess the existing TPS animations **before** introducing another animation source.

Acceptance:

- Retain human scale (approximately 1.799 m in the reference pose), +Y up and visible **-Z forward** in the isolated scene. Document all wrapper/root-axis corrections; do not copy the donor robot's dimensions or scale onto Regina.
- Feet remain grounded during stance without obvious sliding, knees bend consistently, and shoulders/hands remain stable through full cycles and idle/movement transitions. Distinguish intended swing-foot lift and pelvis bob from defects.
- All nine skinned parts remain attached, including costume and holster; no severe stretching, collapsed limbs or exploding geometry. Inspect front, side and back, not only the default camera.
- Demonstrate both centered playback and a short root-motion-driven translation test. Report displacement, direction, speed, loop continuity and compatibility limits against the real TPS controller contract. An in-place visual loop alone does not prove controller compatibility.
- Preserve both source GLBs, Regina's skin/rest/material data, the upstream controller/animation imports, camera/shooting, mission inheritance and `project.godot` main scene. F5 continues to use the robot.
- Document animation authors, source URLs, license/version, selected original/imported clip names and modifications. Add focused automated coverage and a short manual F6 checklist; do not claim visual acceptance from headless tests.

## Assumptions, unresolved questions and non-goals

- Reusing the already licensed TPS clips satisfies obtaining an animation set **if the retarget actually meets acceptance**; a download is not required merely to introduce something new. Include its existing unarmed walk as well as run, since both are available at no additional licensing cost.
- The supplied directory `/home/andrea/Downloads/dinocrisiscustom-regina/` is source-comparison input, not a dependency that runtime or clean-import tests may require. Do not modify/extract over the user's download or replace the supplied Regina GLB.
- The practical TPS retarget result is unresolved until imported rests and sampled playback are examined. Reuse is a justified first experiment, not a promised success. A poor robot-to-human gait must be reported rather than declared compatible.
- No consequential user question blocks this plan. If TPS adaptation fails for a concrete reason, identify **one** alternative with verifiable animation redistribution/adaptation rights before acquiring it. Stop for clarification if license/account terms or required asset repair remain unresolved; do not assume an arbitrary download or account-gated service is acceptable.
- Non-goals: mission player replacement; aim/fire/grip/weapon work; strafing, jumping or combat clips; IK/foot-lock systems; cloth/hair simulation; mesh/weight repair; controller refactoring; new camera architecture; engine upgrades or a general retargeting framework. Do not fix locomotion defects by silently expanding into those tasks.
- Initial Git status was clean. One Godot editor is open on ARCA. During planning, `arca/character_test.tscn` changed externally (UIDs, serialization and property formatting consistent with an editor save); the agent did not edit or revert it. Preserve that work and re-read the latest scene before implementation. Stop play, save scenes and finish imports; coordinate reloads and avoid a competing importer on the live project.

## Read-only findings from this planning pass (2026-10-17)

### Original source is now available, but contains no animation data

- The supplied `source/Test.zip` contains `Test/Mesh.fbx` (1,077,468 bytes), `Test/xps.xps`, texture files and additional specular maps. No license/readme/credit document was found in the archive. Preserve the existing user-supplied Sketchfab attribution and its underlying-IP/provenance caveat; extra files do not establish extra rights.
- FBX SHA-256: `e0eb57188b9a8a0abdcaea75d4af57b6a8cb75c50c45041fafcf9fc79dbfba09`.
- Parsed the binary FBX 7400 node/property structure directly from the ZIP in memory, without extraction or import. `Objects` contains 69 NodeAttributes, 70 Models, one Geometry, one Pose, 69 Deformers, nine Materials, 25 Textures and 24 Videos. There are **zero AnimationStack, AnimationLayer, AnimationCurveNode or AnimationCurve objects**. `Takes` contains only an empty `Current`, with no `Take` records or animation keys. Bind `Pose` data is not an animation.
- Its 68 `LimbNode` models use the same recognizable anatomical chains as the GLB, without the GLB's numeric suffixes; an `Armature` null and one mesh account for the other two Models. This is a structural source comparison, not a Godot FBX import or full skin-equivalence check. The GLB's 69-joint count includes `_rootJoint`; counts alone do not imply a missing anatomical joint.
- Conclusion: **this supplied FBX has no authored clips to recover**. The lack of GLB clips is not evidence that this conversion lost locomotion. Do not reconvert or vendor the FBX merely to search for absent animations. Document the source result and remove the stale source-unavailable blocker during implementation.

### Existing TPS source is licensed and has useful locomotion, with important rig differences

- `player/model/player.glb` contains a 145-joint robot skin and the following source clips: `Idle-cycle` (15 s), `walking_nogun-cycle` (1.25 s), `running_nogun-cycle` (approximately 0.833333 s). The controller already references imported `Idle` and `running_nogun`; verify the actual imported walk name and loop flags rather than assuming source names are runtime names.
- Raw root translations per cycle: idle `(0, 0, 0)`, walk approximately `(0, 0, +2.176640)`, run approximately `(0, 0, +3.316785)`, in **donor skeleton coordinates before ancestor scale/orientation**. `Robot_Skeleton` has uniform scale approximately 0.8039915. These numbers are not Regina displacement or controller speed measurements.
- Each source clip contains translation, rotation and scale channels for all 145 joints. Do not transfer mechanical scaling or limb-position keys indiscriminately onto Regina's anatomy.
- The donor has `thigh -> knee -> shin -> foot -> toe`, extra forearm segments and an asymmetric right `forearmslider -> hand` chain. Regina has `thigh -> knee -> ankle -> toes` and `shoulder 1 -> shoulder 2 -> elbow -> wrist`. Simply copying local quaternions or choosing bones solely by name can lose intermediate transforms and destabilize knees/hands.
- Donor spine/head and finger chains also differ. Regina's neck chain has no explicitly named head; inspect rest positions and skin influence before assigning a humanoid Head. Keep unmatched hair, chest-secondary, fingers and holster bones in their correct local reference pose unless deliberately mapped; they must still inherit parent movement.
- License already recorded in `ATTRIBUTIONS.md` / `LICENSE.md`: TPS art/animations, Copyright (c) 2018 Juan Linietsky and Fernando Miguel Calabró, **CC BY 3.0**, <https://creativecommons.org/licenses/by/3.0/>. Upstream: <https://github.com/godotengine/tps-demo/tree/4.5-90f2e38>. Do not mistake the MIT code license for the animation license.
- Assessment: **worth a bounded retarget attempt before another source**, because unarmed idle/walk/run and translated roots are present and licensed. The mechanical intermediate joints, proportions and rest axes prevent claiming drop-in compatibility. Final practicality depends on deformation/contact results, not just track resolution.

## Relevant files and current control/data flow

- `arca/character_test.tscn`: currently static; original Regina instance under `ModelPivot`, yaw 180 degrees and Y -0.0112332 m, scale 1; neutral lighting, metric references, -Z marker and fixed camera. This remains the experiment entry point.
- `arca/assets/characters/regina/regina.glb` and `.import`: unchanged animation-free source and import settings; imported skeleton path is `Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D`. Keep its nine mesh bindings and materials intact.
- `player/model/player.glb` and `.import`: donor animations; shared by the working player. Do not change their import settings for the experiment.
- `player/player.tscn`: the AnimationTree extracts `Robot_Skeleton/Skeleton3D:root`; walk blending uses `Idle` / `running_nogun`, with walk time scale 1.3. Bone-specific aim filters are outside this task.
- `player/player.gd`: AnimationTree position/rotation deltas feed `orientation`; horizontal displacement divided by physics delta drives `move_and_slide()`, gravity controls vertical motion, and the controller overwrites `PlayerModel`'s world basis. A future visual-axis correction belongs below that controlled pivot. Zero root translation means no ordinary horizontal movement with this controller.
- `arca/tests/regina_test.gd`: source/import inspection and CPU-skinned bounds, currently expects the source asset to have zero clips. Preserve that correct assertion; new wrapper playback must not be confused with authored GLB clips.
- `arca/tests/first_playable_test.gd` and `scripts/check.sh`: existing actual robot movement/aim/shoot/lifecycle regression coverage; the gate runs first-playable, raptor, mission and ambush suites.
- `docs/REGINA.md`, `README.md`, `ATTRIBUTIONS.md`, `docs/VALIDATION.md`: affected findings, credits, F6 instructions and honest validation record. Only `TASK.md` is edited during planning.

## Proposed minimal solution and implementation order

1. **Confirm imported donor behavior and establish the reference.** Inventory the three selected imported clips, track types/paths, loop modes and skeleton/rest/global transforms. Preserve source hashes. Compare donor and Regina rest positions, bone axes and segment lengths; record an explicit anatomical mapping, including how intermediate knee/forearm transforms are accounted for. Verify the source FBX finding above in the report; a separate Godot FBX import is unnecessary unless a concrete discrepancy needs it.
2. **Retarget only unarmed idle/walk/run.** Prefer Godot 4.5.1's native humanoid mapping/rest-normalization tools in experiment-local resources, then retain a reproducible, Regina-targeted AnimationLibrary and the minimal mapping/bake resources or script needed to regenerate it. Do not alter the upstream donor import or normalize Regina rests without preserving its skin binding. Account for complete donor chains in global/rest-relative space before resolving target local rotations; track-name substitution is not retargeting. Preserve Regina bone lengths and unit scale; transfer calibrated root/hips translation separately, discard robot mechanical scale/limb-translation channels, and leave unmatched target bones inheriting their reference locals. Check a few leg/arm poses before processing all clips. Keep derived resources under `arca/assets/characters/regina/`; do not commit imported caches or duplicate a full donor model unnecessarily.
3. **Make the source decision from evidence.** Preview the TPS-derived clips and record knee/foot/shoulder/hand behavior and any required correction. Use the set only if it meets the bounded locomotion acceptance without new IK, weight repair or a custom retargeting framework. If it cannot, document the precise failed contract before selecting one independently licensed humanoid idle/walk/run set, verify its adaptation and redistribution terms, and reuse the same minimal target mapping/playback path. No unverified fallback is selected in this plan. If neither path meets acceptance within this scope, report the blocker rather than presenting a broken proof as complete.
4. **Extend the existing isolated scene, not the TPS player.** Add a small `arca/character_test.gd` and derived animation resources, an AnimationPlayer/AnimationTree for just these clips, clip selection, pause/reset and front/side/back views with short English instructions. Start in idle; expose centered playback and a short translating preview. Use the same retained root track for extraction and apply horizontal/rotation deltas exactly once to an experiment-local motion wrapper; retain pelvis bob in the pose. Centered mode must remove accumulated travel without flattening the gait. Provide a clear reset for the bounded lane, not a hidden teleport presented as a continuous loop. No input capture or changes to global mission controls.
5. **Prove the root-motion contract separately from pose quality.** Use the preview's AnimationTree extraction to measure idle drift, walk/run travel and heading at fixed physics steps over several cycles. Calibrate displacement for Regina's proportions/contact and the donor ancestor scale; transform source +Z into the scene's -Z convention once, not twice. Check extraction removes visual root travel, loop wrap does not reverse/pop, and speed matches stance-foot contact. Record native versus retargeted meters/cycle, playback rate and resulting m/s, including the existing controller's 1.3 walk time scale. Assess whether `root ground_01` is a suitable extraction track beneath `_rootJoint`; never assert that just from its name. Give a clear compatible / conditionally compatible / incompatible verdict for locomotion, with the exact future track/path/pivot requirements. Do not claim this supplies strafe/jump/aim/weapon readiness or integrate the mission player.
6. **Add focused tests and update documentation.** Add `arca/tests/regina_locomotion_test.gd` using the repository's SceneTree PASS/FAIL/RESULT pattern and nonzero failure exit. Reuse the existing CPU skin measurement pattern locally without a broad test-framework refactor. Update `docs/REGINA.md` with the FBX evidence, map/rest corrections, clip inventory, source choice, licenses, quantitative motion results, deformation observations and controller verdict. Update credits for derived animations with original clip names and modifications, README F6 controls and `docs/VALIDATION.md` / this task with actual results and remaining manual acceptance.

## Focused tests and expected outcomes

- Source isolation: supplied GLBs/hashes, shared import settings, mission main scene and upstream player files unchanged; original Regina still has zero authored clips, while the test wrapper has the intended three playable clips.
- Resource/mapping checks: every animation track resolves; all required anatomical targets exist; rest/unit scale, finite normalized poses and complete nine-part skin bindings persist; no mechanical-scale or unmapped robot tracks leak into the target library. Invalid maps/resources fail visibly and stop playback rather than silently skipping required limbs.
- Playback: sample full clips and repeated loops at fixed physics steps, including idle-to-walk/run and back; verify all selected clips advance, required joints actually move, reference lengths remain stable, and all skinned parts have finite sensible bounds. Check pose/rotation continuity at loop boundaries after subtracting intentional root travel; bounds alone do not prove good deformation.
- Root motion: near-zero idle horizontal drift, positive -Z walk/run displacement with consistent heading, repeatable per-cycle displacement/speed, no duplicated mesh/body travel or reset spike, and pause freezes both pose and motion. Reset restores idle, lane origin and animation/extraction history. Compare centered versus translated poses at the same animation phase.
- Contact/deformation: measure foot/boot ground clearance and stance drift in translating mode over identified contact phases; inspect knee direction, shoulder/hand trajectories and costume/holster attachment. Establish and document metric tolerances from the reference anatomy/contact phases before calling the test passing; do not weaken them after observing a defect. Use rendered front/side/back playback to judge collapse, shoulder twist, hands and detached clothing. Automated finite/bounds checks cannot certify these visual conditions.

Commands **for implementation**, after imports finish (not run in this planning pass):

```bash
# Existing static/source regression; command is available now.
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd

# Planned focused suite; runnable only after the new script exists.
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_locomotion_test.gd

# Existing import/gameplay/launcher gate.
bash scripts/check.sh

git diff --check
```

Use terminal timeouts. `rg` is currently absent from PATH; use the existing literal local PATH workaround documented in `docs/VALIDATION.md` or the documented prerequisite, without editing launchers. If the working editor remains open, run clean-import validation in an ignored source-only copy as for the prior task, verify its sources match, and state this deviation. Do not run a competing importer or claim historical 93/162/13 checks as new results.

### Short F6 visual checklist after implementation

1. Open `arca/character_test.tscn`, press **F6**, select idle/walk/run and inspect against the ruler/-Z marker: human scale, correct facing and no pose/loop/transition pop.
2. Use front/side/back views and several cycles: stance feet do not skate/sink, knees do not flip, shoulders/hands do not twist or jump, and costume/holster remain attached without severe deformation.
3. Switch between centered and root-motion preview: travel follows -Z at the measured gait speed without double movement or a loop snap. Pause/resume and reset; pose and travel must freeze/reset together. Record any visible defect; this is not F5 player-replacement acceptance.

## Risks and stop condition

Mechanical intermediate transforms, mismatched rest axes/proportions, the extra Regina root and mixed source/global scales can produce plausible-looking tracks but wrong feet or displacement. Root removal must preserve pelvis height/bob; one-time foot alignment is not permission to pin Y every frame. Extra source specular maps and unresolved underlying character/IP rights remain outside locomotion scope. No automatic passing result can replace rendered inspection and user F6 acceptance.

Stop when licensed idle/walk/run playback, measured root-motion assessment, focused/full check results, source/license documentation and the short F6 handoff are delivered. If acceptance requires mesh repair, IK, major retarget infrastructure or unverifiable licensing, stop and report that precise blocker for re-scoping. No commit, branch, new animation source or application change was made by the planning pass; the implementation handoff below supersedes its baseline status.

## Implementation handoff

- Added `arca/character_locomotion_test.tscn`, **inheriting** the user's `arca/character_test.tscn`, with a small `arca/character_test.gd` viewer. This is a justified plan adjustment: the parent's F6 instance remained running and the user continued saving it, so no parent scene changes were made by the agent. The static reference and its user edits are preserved. F6 controls: 1/2/3 clips, M centered/travel with lane reset, Space pause, R centered idle reset, V view. Camera follows a finite 12 m lane that pauses rather than auto-teleports; F5 remains the robot mission.
- Original `Test/Mesh.fbx` in the supplied ZIP has no animation objects, keys or takes. Documented hash/counts and resolved the old missing-source blocker without extracting over the user's download, reconverting Regina or claiming full FBX skin/material parity.
- Trialed existing TPS idle/walk/run with full mechanical chains before adding a source. Segment proportions and shoulder posture made it a poorer first fit. The final library contains **only** Quaternius UAL Standard CC0 idle/walk/jog, not TPS-derived motion. Added a pinned 767,524-byte three-clip donor subset, standard-library extraction script, source/license README, original CC0 notice and tracked import settings under `arca/assets/characters/regina/source/`.
- Added `bake_locomotion.gd` and `locomotion.tres`: explicit 22-bone map, rest/global-to-local rotation handling, anatomical pelvis-center/leg-ratio translation, preserved target lengths/skins/materials, unchanged secondary reference locals, small seam closure, constant per-clip floor correction and 0.7 run retiming. Native local/global modifier constraints were inspected; a narrow offline rotation bake avoids moving bones to donor lengths or normalizing a duplicate character skin. No runtime retarget framework, IK, weight/geometry repair or new engine dependency.
- Derived travel uses a scene-space **RootMotion proxy** outside the rotated skeleton, not an assumed compatible `root ground_01` track. Authored source clips are in-place. Measured preview speeds: idle 0; walk **1.208183 m/s**; run **4.361937 m/s**. Documented cycle distances, root-coordinate conversion, effect of TPS 1.3 time scale, and exact later path/pivot/extraction requirements. No mission/player integration or authored turn/strafe/jump/aim/grip readiness is claimed.
- Added `arca/tests/regina_locomotion_test.gd` (68 checks) and optional `capture_regina_locomotion.gd`. Contact regression uses actual skinned sole vertices: max clearance/drift idle **2.57/2.97 mm**, walk **14.88/14.21 mm**, run **19.38/6.00 mm** in identified flat-support phases. All sampled soles stay above approximately 0.5 mm; swing, toe-off and run flight are not mistaken for planted support. Tests cover repeat loops, no scale/length transfer, joint continuity, skin bounds, root extraction/travel, transitions and real input/lifecycle.
- Fresh source-only import under ignored `.artifacts/regina-locomotion/clean-project/`: unchanged `regina_test.gd` **93/93**; new locomotion **68/68**; `bash scripts/check.sh` **162 gameplay + 13 launcher checks**, all passing. Used the existing ripgrep PATH workaround and portable Godot 4.5.1, not a live competing editor/import. Import/gameplay logs contain no script/runtime errors or warnings. The source subset reproduces byte-for-byte; regenerated derived animation/key data has an identical semantic fingerprint. New GDScript diagnostics are clean.
- Inspected staged Compatibility / X11 / Intel Iris Xe front/side/back poses for all three clips. No detached parts or exploding/severely stretched skin in sampled views. **Small run shoulder/costume clipping, open hands and unsimulated secondary hair remain**; source specular limitations remain unchanged. These observations are not continuous human F6 acceptance or GPU benchmarking. Diagnostic logs/captures are ignored, not committed.
- Updated `README.md`, `docs/REGINA.md`, `docs/VALIDATION.md`, `ATTRIBUTIONS.md` and source provenance/reproduction instructions. Credits distinguish Quaternius CC0 motion, Otherspectre CC BY 4.0 rig/reference data, and MIT code; no underlying character/IP-rights claim. Preliminary failed checks and their focused fixes are recorded in `docs/VALIDATION.md`, not hidden as passing runs.
- Remaining: user runs the three-step **F6 checklist in `arca/character_locomotion_test.tscn`**, particularly judging shoulder/costume quality, and optionally verifies unchanged F5 controls. A later TPS replacement or mesh-weight repair needs separate scope. No commit or branch was created.

---

# Previous task: inspect Regina and create an isolated character test scene

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

---

# Tooling task: configure the ARCA AI development environment

Status (2026-10-17): **installation/configuration complete; standalone and native Zed end-to-end verification passed against an isolated ARCA editor; activation in the already-open working editor remains manual and unverified**. This tooling-only handoff is appended to preserve the concurrently edited Regina task records above. It does not accept, modify or supersede any gameplay/animation work.

## Result and scope

- Kept Godot 4.5.1 Standard/Compatibility and the built-in Zed Agent with the existing ChatGPT subscription. No gameplay/source model/controller/animation changes, engine upgrade, second Godot MCP, new test framework, commit or push were made by this task.
- Installed hybridindie MCP outside ARCA at `/home/andrea/Workspace/tools/godot-mcp` using frozen uv runtime dependencies. Current upstream failed 4.5.1 compilation on `EditorInterface.get_unsaved_scenes()`; pinned both server and the unmodified `addons/godot_mcp/` to compatible revision `ba5026d2a34073e8e4b68874cb8b03b691f04636` (package/addon 2026.09.19), retaining MIT notices and UIDs.
- Backed up native `/home/andrea/.config/zed/settings.json` to `settings.json.before-arca-ai-20261017.bak`, added the stdio `godot` server with absolute executable/project paths and loopback bridge, and populated explicit profile allowlists. Build permits the pinned 191 tools; Plan/Review/Diagnose permit only 77 read-only tools. Existing subscription, model, permissions and other settings are preserved; inactive Flatpak settings were not changed.
- Retained `arca-godot`; added four focused native skills for 3D patterns, animation audits, debugging/regressions and MCP operation. Evaluated both requested repositories, excluded incompatible/incorrect examples and the overlapping bridge, and retained the adapted source's MIT notice.
- Added `scripts/ai_check.sh` and `scripts/mcp_smoke.py`, plus Zed snapshot-check tasks. Checks use the real installed Godot and the existing local ripgrep fallback without importing into the open editor's cache. MCP smoke enables the addon only in its fresh isolated snapshot and uses port 19080.
- Updated `AGENTS.md`, README, workflow/prompts, attributions and `docs/AI_ENVIRONMENT.md` with exact pins, safety boundaries, evidence, known failures and manual completion. The live `project.godot` and existing scenes were not rewritten.

## Validation and remaining limits

- Godot reports `4.5.1.stable.official.f62fdbde1`; the live GDScript LSP answered a real initialization request on port 6005. Existing uv 0.13.1, gdtoolkit 4.5.0 and GDScript extension 0.9.0 are available.
- Pinned addon import/compilation passed. Real standalone MCP stdio calls returned bridge-connected health, ARCA project identity, active mission, `ArcaMissionRoom` hierarchy, script variables, `Floor.collision_layer=1` and `Player.position` approximately `(0, 0.05, -9)`. Captured stdout was valid JSON-RPC; no MCP mutation tools were invoked. `bash scripts/ai_check.sh --mcp` passed in `.artifacts/ai-check-on7bjr1c/`.
- Initial baseline snapshot full gate passed launcher 13 and gameplay 42/24/52/44 checks; Regina-player reproduced the existing **301 checks, 2 sole-contact failures**, unchanged. Concurrent later Regina edits were detected and preserved. A later `bash scripts/ai_check.sh` run in `.artifacts/ai-check-smsh8fzw/` passed the same launcher/gameplay suites and reported **369 Regina checks with the same 2 failures**. Each result describes its copied state, not subsequent concurrent edits.
- Non-writing gdlint/gdformat checks run successfully as tools but report existing mission-script style findings (12 lint issues; formatter would change the file). No mass formatting or unrelated fixes were made.
- **Native Zed verification passed:** the Zed-owned server (parent is the running Zed editor) returned connected health, ARCA/4.5.1 project identity, the active mission, its depth-1 hierarchy and `Floor.collision_layer=1` through actual native tool calls. The verified editor was the isolated `.artifacts/ai-check-on7bjr1c/project/` copy. An initial short-lived probe expired between calls; a longer bounded retry passed. That temporary editor was stopped; the Zed server and original working editor were left running.
- **Only manual completion remaining:** enable **Godot MCP** in the existing ARCA editor's Project Settings → Plugins, then repeat native health/project identity calls and require the live path `/home/andrea/Workspace/ARCA/`. No Zed restart is currently required. Live-project activation remains unverified, distinct from the successful native isolated-editor end-to-end test.
- Full setup report and repeatable commands: `docs/AI_ENVIRONMENT.md`. Logs/snapshots are ignored local artifacts. No rendered-quality, GPU-performance or gameplay acceptance claim is made.
