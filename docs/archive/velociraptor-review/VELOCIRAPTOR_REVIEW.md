# Ferocious Industries Velociraptor evaluation

**Status: imported and technically evaluated in isolation; visual approval and integration remain pending.** Resumed 2026-10-17 from the user's official downloads. The other candidate (absol) is still unavailable locally and has not received a comparable visual audit; this is not a two-model winner claim.

## Recommendation for ARCA

**Keep this model as a serious candidate for the advanced-PS2 / early-PS3 direction, but do not integrate it yet.** The actual asset supplies all seven required action categories, a modest 15,098-triangle mesh, normal/AO textures and a substantial authored rig. This is a much more useful technical starting point than an animated listing with unknown coverage. The 2K/1K PBR texture setup is compatible with an early-PS3-style presentation in principle; that is an asset/specification assessment, not proof that the art already matches ARCA's final lighting and visual direction.

Start a later motion selection with `Idle_02`, `Walk`, `Jog`, `Bite_02`, `Hurt_01/02`, `Roar_03` and a deliberately chosen death. Prefer **Jog over Sprint for the first locomotion test**: Jog closes numerically and its original RM counterpart travels about 3.245 m/s, close to ARCA's current 3.2 m/s chase. Sprint has a measurable seam and a faster approximately 4.794 m/s authored RM counterpart. No controller, root-motion policy, animation retiming or art correction was changed here.

**Remaining blockers to calling it production-ready:** sprint endpoint discontinuity, sampled ground penetration, significant travel embedded in some combat/death clips, approximate spec/gloss material conversion, and a human visual verdict on the captured deformation/materials. Do not equate 26 imported entries with 26 polished moving animations.

## View the results

All paths below are inside `/home/andrea/Workspace/arca-asset-review/ARCA`.

- Preview scene: [`arca/asset_review/candidate_b.tscn`](../arca/asset_review/candidate_b.tscn).
- [Idle screenshot](../.artifacts/velociraptor-review/idle.png): `Idle_02`, 1.000 s.
- [Run screenshot](../.artifacts/velociraptor-review/run.png): **`Sprint`**, 0.250 s; not an invented clip named Run.
- [Attack screenshot](../.artifacts/velociraptor-review/attack.png): **`Bite_02`**, 0.900 s.
- [Complete 1× playback reel](../.artifacts/velociraptor-review/all_clips_1x.avi): 30 fps MJPEG AVI, **1,864 frames / 62.133 s**. All 26 entries are included; idle/walk/jog/sprint are repeated twice to expose seams. Static-pose and one-shot endpoint holds are explicit. This is an offline fixed-timestep recording, not a real-time FPS benchmark.
- [Capture manifest](../.artifacts/velociraptor-review/capture_manifest.json) and [playback manifest](../.artifacts/velociraptor-review/playback_manifest.json).
- Six `all_clips_00.png` through `all_clips_05.png` contact sheets in that same directory: alphabetical rows, 0/25/50/75/100% columns. Original full-size samples are retained, including side/front views of the three requested actions.

The captures are **1280×720**, Godot **4.5.1 Standard / GL Compatibility**, rendered on **Mesa Intel Iris Xe Graphics (ADL GT2)**. The stage has identical key/fill/rim lights, environment, metric grid and cameras for the selected idle/run/attack captures. The human-shaped primitive reference is measured from **Y=0 to Y=1.799999952 m**. The model has no scale/yaw/floor correction: native scale 1, +Y up, +Z facing, floor at Y=0. Consequently ground-contact defects are not hidden by model offsets. Source materials are used without overrides.

The reel's camera follows actual skeleton root translation for travelling clips; it does not move/recenter the model or cancel source root travel. Primary screenshots remain fixed-camera. The desktop tiles OS windows, so the preview explicitly renders to a fixed 1280×720 viewport independent of the window's physical size.

### What was and was not visually verified

Rendered geometry visibility, full-body camera framing for the selected actions, image dimensions, exact reference height, complete timeline execution and finite poses were checked automatically. **The agent's image-reading tool cannot open files in this external worktree**, so no subjective frame-by-frame visual sign-off or claim of absence of visible clipping is made. The actual screenshots and reel are provided for the user's visual decision. Numerical findings below are not a substitute for judging silhouette, skin detail, mouth deformation, planted feet and the impact of the fast death animations in those captures.

## Source identity and license

Identified **both** packages in `~/Downloads` by ZIP contents, CRC validation, metadata and matching exact model ID—not just similar filenames:

1. `pbr-velociraptor-animated.zip`: original package, containing `source/RaptorSF.zip` plus loose textures. The nested archive supplies `Raptor/Raptor_Animated_FBX.fbx` and 12 texture files, including all five `Raptor_PatternA` through `Raptor_PatternE` albedos.
2. `pbr_velociraptor_animated.zip`: Sketchfab conversion, containing `scene.gltf`, `scene.bin`, eight textures and `license.txt`.

The conversion's `license.txt` and embedded `asset.extras` both name **Ferocious Industries**, exact ID **`8f1744af7b0847a2aabe3df90be802f0`**, and **CC BY 4.0**, agreeing with the official API and user's credit:

> "PBR Velociraptor (Animated)" (https://skfb.ly/oHoUE) by Ferocious Industries is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).

Attribution permits commercial use/adaptation subject to credit, license link, indicating changes and no additional restrictions. Keep the source notice and attribution when sharing derivatives/screenshots. Underlying ownership is not independently guaranteed by that license label. The original nested archive contains no separate contradictory license notice; preserve the matching download notice with both formats.

The top-level original package includes a suspicious loose `Raptor_Scales_NormalA.png` with the same SHA-256 as `Raptor_Scales_AlbedoA.png`. It was **not used as a normal map**. The intact nested FBX package and self-contained licensed glTF package are the imported sources; no loose-name guessing or texture relabeling was performed.

Original archives are preserved outside the Godot resource scan at `/home/andrea/Workspace/arca-asset-review/source-archives/`. Downloads remain untouched. [`VELOCIRAPTOR_FILE_MANIFEST.json`](VELOCIRAPTOR_FILE_MANIFEST.json) pins archive and extracted-source hashes. Original notices are retained in `arca/asset_review/candidate_b/LICENSE_CC_BY_4.txt` and the glTF directory. Only this worktree's `ATTRIBUTIONS.md` was updated.

## Mesh, skeleton and textures actually inspected

| Property | Result |
| --- | --- |
| Imported triangles | **15,098** = 10,566 body + 4,532 other parts, both FBX and glTF |
| Imported/accessor vertices | **9,495** = 6,468 + 3,027; not interchangeable with the public listing's 8,332 vertex statistic |
| Mesh/material layout | glTF: two skinned meshes, one surface each; FBX: one skinned mesh, two surfaces; **two materials** |
| Topology/count discrepancy | Listing description says 15,144 triangles; measured glTF/FBX triangulation supports 15,098, matching the API face count |
| Vertex attributes | Positions, normals, tangents, UVs, joints and weights present; glTF UV0/UV1 reference the same accessor, not a distinct lightmap unwrap |
| Skin validation | All joint indices/triangle indices in range, finite accessor data, weight-sum error below 0.000001; at most four body influences / three on other parts |
| Skeleton | glTF **137 joints/bones**; FBX **136 bones**. The conversion adds `_rootJoint`; includes head/jaw/eyes, detailed toes/fingers, long tail and helper/IK/end bones |
| Morph targets | Five per glTF mesh, also present in FBX; morph-weight channels were retained and evaluated, not mistaken for skeletal-only animation |
| Native size in `Idle_02` first sample | Approximately **1.052 m wide × 1.740 m high × 3.375 m long** |
| Native size in `Idle_01` first sample | Approximately **1.380 × 1.992 × 3.423 m**; pose-dependent size, not a different scale |
| glTF textures | Four body maps at **2048²**, four other-part maps at **1024²**: diffuse, specular/glossiness, normal and AO |
| Material workflow | Required `KHR_materials_pbrSpecularGlossiness`; Godot imports/derives metallic-roughness maps, with an explicit warning that conversion may not be 100% accurate |
| glTF material flags | Body is double-sided; other parts back-face culled. Normal and AO maps are enabled. Source diffuse tint factors are preserved through import conversion |
| FBX material difference | Original import resolves PatternA albedo and normal maps, but AO is not automatically enabled; this differs from the Sketchfab Green presentation. F switches source without silently making the two material setups identical |
| LODs | Godot's default `generate_lods` import option remains enabled; no authored LOD chain was established and no performance benchmark is claimed |

Full bones/rests/skin binds/material slots and pose samples: [`VELOCIRAPTOR_IMPORT_AUDIT.json`](VELOCIRAPTOR_IMPORT_AUDIT.json). Source accessor/channel/texture inventory and original FBX take names: [`VELOCIRAPTOR_SOURCE_AUDIT.json`](VELOCIRAPTOR_SOURCE_AUDIT.json).

## Are the advertised 26 animations present and usable?

**All 26 glTF entries are physically present and import successfully. They comprise 25 moving clips plus one static `Action_Pose`.** Its source time range is zero; Godot gives it a 0.001 s minimum duration. It must not be counted as a usable animated action.

Every imported track target and bone resolved, no method/audio tracks can trigger gameplay, and all bone transforms sampled in the audits and full glTF playback were finite. Full timelines were captured at original 1× timing. These checks establish import/playback usability, **not final animation polish**. The original FBX contains **34 takes**, also all imported: the same motion family, **seven additional `_RM` alternatives**, and an additional static `Standard_Pose` (0.041667 s). There are therefore 32 moving FBX takes and two static poses, not 34 distinct polished actions.

| Required role | Real glTF entries | Assessment / limits |
| --- | --- | --- |
| Idle | `Idle_01`, `Idle_02` | Present; in-place, numerically closed endpoints. Start review with the longer Idle_02. |
| Walk | `Walk` | Present; in-place and numerically closed. Original RM equivalent covers 2.9 m in 1.292 s (~2.245 m/s), so ARCA's 1.6 m/s emergence would need a later gait-speed decision. |
| Run | `Jog`, `Sprint` | Both present; no literal glTF clip named Run. Jog closes; Sprint has ~0.138 m maximum rig endpoint displacement / ~18.3° maximum endpoint rotation mismatch. |
| Attack | `Bite_01`, `Bite_02`; also `Leap_01/02`, `Tackle` | Present. Bite_02 returns numerically to its initial rig pose and is the initial stationary-attack lead. Leap/Tackle contain substantial root travel. |
| Hit | `Hurt_01`, `Hurt_02`, `Knocked Down` | Present. Hurt clips need a deliberate return/blend; Knocked Down has ~0.933 m backward root travel. |
| Roar | `Roar_01`, `Roar_02`, `Roar_03` | Present. Roar_03 is in-place and closes; Roar_02 has ~0.252 m forward root travel. |
| Death | `Death_01`, `Death_02` | Both present, short 0.833/0.917 s actions. Root travels ~1.800 m backward / 1.895 m forward; endings need ground-contact/collision review. Preview holds final pose rather than restarting. |

**None of the seven requested categories is missing.** No animation has been synthesized, renamed to fake coverage, retargeted, retimed, loop-repaired or replaced. `Sleep_Loop` becomes `Sleep` through Godot's standard name-suffix import handling; that mapping is explicit.

### Motion-quality findings and caveats

- Idle_01/02, Walk and Jog have essentially coincident start/end bone positions in the sampled imported rig. Sprint does not. The seam metric is the maximum over all rig bones, including helpers, **not a measured tear between skin triangles**. The unchanged wrap is deliberately visible in the two-cycle reel.
- Most source clips import with loop flag off. The viewer repeats only explicitly selected idle/locomotion/sleep actions without editing the Animation resources. Bite, Hit, Roar and Death remain one-shots. A future integration must choose loop/blend policies deliberately.
- At nine phase samples and native Y=0, posed whole-mesh minima reach approximately **-0.082 m (Jog), -0.066 m (Sprint), -0.128 m (Bite_02)**. Death terminal minima are about **-0.091 m / -0.124 m**. These are skinned/morphed mesh bounds, not assertions that a particular foot alone penetrates by that amount. Close-up contact review is required; no compensating per-clip offsets or IK were added.
- glTF `Leap_01/02` move the root approximately **6.380 m forward**, and `Tackle` approximately **3.550 m**. The FBX includes both ordinary and `_RM` variants for these and locomotion. Do not apply source root travel on top of controller movement, or discard it silently while claiming equivalent motion.
- Some one-shots intentionally end in a different pose. The existing gameplay attack hit time cannot be assumed correct for these bites; attack/contact timing is only an integration concern to be scoped after visual approval.
- No GPU performance, planted-foot perfection, rig repair or final visual-quality acceptance is claimed. Some deformation/material concerns may be artistic rather than importer faults; both source formats are retained to distinguish them.

## Full glTF inventory

Durations are original glTF time ranges; channel/track counts distinguish source channels from Godot's imported track organization/optimization. Godot clamps the zero-duration pose to 0.001 s.

| Source name | Imported name | Seconds | Source channels / Godot tracks | Motion notes |
| --- | --- | ---: | ---: | --- |
| `Sniff` | `Sniff` | 2.917 | 228 / 122 | In-place root |
| `Eat Prey` | `Eat Prey` | 1.958 | 307 / 122 | In-place root |
| `Drink` | `Drink` | 2.458 | 132 / 122 | In-place root |
| `Call_Alert` | `Call_Alert` | 2.542 | 163 / 122 | In-place root |
| `Go to Sleep` | `Go to Sleep` | 1.250 | 328 / 122 | In-place root |
| `Sleep_Loop` | `Sleep` | 1.250 | 119 / 122 | In-place root; Godot imports as Sleep with loop flag |
| `Wake From Sleep` | `Wake From Sleep` | 1.833 | 328 / 122 | In-place root |
| `Idle_01` | `Idle_01` | 1.292 | 147 / 122 | In-place root |
| `Idle_02` | `Idle_02` | 4.042 | 140 / 122 | In-place root |
| `Roar_01` | `Roar_01` | 2.333 | 310 / 122 | In-place root |
| `Roar_02` | `Roar_02` | 1.417 | 264 / 122 | Travels +0.252 m on Z |
| `Roar_03` | `Roar_03` | 1.625 | 133 / 122 | In-place root |
| `Bite_01` | `Bite_01` | 2.333 | 307 / 122 | In-place root |
| `Bite_02` | `Bite_02` | 1.958 | 139 / 122 | In-place root |
| `Leap_01` | `Leap_01` | 1.000 | 320 / 122 | Travels +6.380 m on Z |
| `Leap_02` | `Leap_02` | 1.208 | 320 / 122 | Travels +6.380 m on Z |
| `Tackle` | `Tackle` | 1.458 | 317 / 122 | Travels +3.550 m on Z |
| `Hurt_01` | `Hurt_01` | 1.250 | 306 / 122 | In-place root |
| `Hurt_02` | `Hurt_02` | 1.292 | 306 / 122 | In-place root |
| `Knocked Down` | `Knocked Down` | 2.208 | 261 / 122 | Travels -0.933 m on Z |
| `Death_01` | `Death_01` | 0.833 | 318 / 122 | Travels -1.800 m on Z |
| `Death_02` | `Death_02` | 0.917 | 313 / 122 | Travels +1.895 m on Z |
| `Walk` | `Walk` | 1.292 | 144 / 122 | In-place root |
| `Jog` | `Jog` | 1.000 | 294 / 122 | In-place root |
| `Sprint` | `Sprint` | 1.000 | 185 / 122 | In-place root; endpoint mismatch |
| `Action_Pose` | `Action_Pose` | 0.000 | 68 / 122 | Static pose, not a moving action |

## Full original FBX take inventory

For readability, names below show the distinguishing fourth `|`-separated component. The exact unshortened source/imported names are preserved in the JSON inventories; the source names themselves were not changed.

| Original take component | Imported seconds | Motion notes |
| --- | ---: | --- |
| `Raptor_Action_Pose` | 0.042 | Static pose |
| `Raptor_Bite1_Anim` | 2.333 | In-place root |
| `Raptor_Bite2_Anim` | 1.958 | In-place root |
| `Raptor_Call1_Anim` | 2.542 | In-place root |
| `Raptor_Death1_Anim` | 0.833 | Root Z -1.800 m |
| `Raptor_Death2_Anim` | 0.917 | Root Z +1.895 m |
| `Raptor_Drink_Anim` | 2.458 | In-place root |
| `Raptor_EatPrey_Anim` | 1.958 | In-place root |
| `Raptor_GoToSleep_Anim` | 1.250 | In-place root |
| `Raptor_Hit1_Anim` | 1.250 | In-place root |
| `Raptor_Hit2_Anim` | 1.292 | In-place root |
| `Raptor_Hit3_Anim_RM` | 2.208 | Root Z -0.933 m |
| `Raptor_Hit3_Anim` | 2.208 | In-place root |
| `Raptor_Idle1_Anim` | 1.292 | In-place root |
| `Raptor_Idle2_Anim` | 4.042 | In-place root |
| `Raptor_Leap1_Anim_RM` | 1.000 | Root Z +6.380 m |
| `Raptor_Leap1_Anim` | 1.000 | In-place root |
| `Raptor_Leap2_Anim_RM` | 1.208 | Root Z +6.380 m |
| `Raptor_Leap2_Anim` | 1.208 | In-place root |
| `Raptor_Roar1_Anim` | 2.333 | In-place root |
| `Raptor_Roar2_Anim` | 1.417 | Root Z +0.252 m |
| `Raptor_Run1_Anim_RM` | 1.000 | Root Z +3.245 m |
| `Raptor_Run1_Anim` | 1.000 | In-place root |
| `Raptor_Run2_Anim_RM` | 1.000 | Root Z +4.794 m |
| `Raptor_Run2_Anim` | 1.000 | In-place root |
| `Raptor_Screech1_Anim` | 1.625 | In-place root |
| `Raptor_SleepLoop_Anim` | 1.250 | In-place root |
| `Raptor_SniffGround_Anim` | 2.917 | In-place root |
| `Raptor_Tackle_Anim_RM` | 1.458 | Root Z +3.550 m |
| `Raptor_Tackle_Anim` | 1.458 | In-place root |
| `Raptor_WakeFromSleep_Anim` | 1.833 | In-place root |
| `Raptor_Walk_Anim_RM` | 1.292 | Root Z +2.900 m |
| `Raptor_Walk_Anim` | 1.292 | In-place root |
| `Standard_Pose` | 0.042 | Static pose |

## Reproduce and inspect

Open **the worktree**, not `/home/andrea/Workspace/ARCA`, in a separate Godot editor if desired. Run `arca/asset_review/candidate_b.tscn` with **F6**, not the mission with F5.

Controls: **1** Idle_02, **2** Walk, **3** Jog, **4** Sprint, **5** Bite_02, **6** Hurt_01, **7** Roar_03, **8** Death_01; **[ / ]** cycle all clips; **Space** pause; **R** replay; **V** fixed views; **F** switch glTF/FBX; **C** toggle root-follow camera; arrows or slider scrub. Number shortcuts refer to glTF only; use the dropdown for original FBX names. Native travelling clips can leave a fixed camera: enable C to follow without altering motion.

Commands actually used (bounded by the agent terminal; close the interactive viewer yourself when launching it manually):

```bash
python3 /home/andrea/Workspace/arca-asset-review/ARCA/arca/asset_review/audit_source.py

env XMODIFIERS=@im=none /home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --path /home/andrea/Workspace/arca-asset-review/ARCA -s res://arca/asset_review/audit_import.gd

env XMODIFIERS=@im=none /home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --path /home/andrea/Workspace/arca-asset-review/ARCA -s res://arca/asset_review/preview_test.gd

env XMODIFIERS=@im=none /home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --path /home/andrea/Workspace/arca-asset-review/ARCA -s res://arca/asset_review/capture_review.gd

env XMODIFIERS=@im=none /home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --path /home/andrea/Workspace/arca-asset-review/ARCA --write-movie /home/andrea/Workspace/arca-asset-review/ARCA/.artifacts/velociraptor-review/all_clips_1x.avi --fixed-fps 30 -s res://arca/asset_review/capture_review.gd -- --movie
```

## Validation and scope

- ZIP CRC/path safety, source identity/license/hash checks; finite glTF accessors, ordered animation keys, valid indices, normalized skin weights and existing textures: **passed**.
- Both source imports; 26 glTF entries / 34 FBX takes, resolved track and skin targets, sampled poses/bounds: **passed**, with the documented spec/gloss conversion warning.
- Display-backed preview tests: **94 checks, zero failures**, covering framing, visible render difference, pause/resume/replay, death endpoint, both source inventories and camera-only root follow. Rendered human height verified separately.
- **139 full-size screenshots + six contact sheets**, and a complete 26-entry 1× reel generated. Primary images are verified 1280×720.
- Detached baseline `scripts/check.sh`: launcher 13, first-playable 42, raptor 24, mission 52, ambush 44 checks (**175 total, zero failures**) plus Godot import. The documented local ripgrep fallback was used; no dependency was installed. This gate does not validate or fix the dirty live Regina checkout.
- Early exploratory headless skin baking failed because the dummy renderer could not register/expose the required skin/morph data. The audit now uses CPU skinning with imported bind/morph arrays and explicitly requires a display-backed Compatibility context; its final run is clean. The headless error is not classified as a broken source rig.
- Early framing checks caught desktop tiling changing capture aspect; fixed-size offscreen viewport rendering corrected this, and all deliverable images/reel were regenerated. No camera or model workaround was applied to source assets.

The task was narrowed by the user to the supplied Ferocious Industries candidate. No fake A comparison was generated. All assets, scripts, tests, reports and ignored captures remain in the detached worktree; no main-project/Regina/AI/controller/mission changes and no commits or integration are authorized by this evaluation. Human visual acceptance and any later choice of integration behavior remain open.

### Final preservation/static checks

All six new GDScript files passed Godot `--headless --check-only --script`; the Python source-audit script parsed successfully. `git diff --check` passed. Hash verification confirmed **25 source files and three archives unchanged**, and **all 418 tracked/nonignored live files, live Git status and HEAD/main refs unchanged** against the fresh pre-resume manifest. Only `ATTRIBUTIONS.md` and `TASK.md` differ among pre-existing tracked worktree files; added assets/tools/reports are confined to this review. An attempted comparison against live Regina task history was rejected as an invalid invariant: that live task had advanced before this resume, whereas the worktree deliberately retains its earlier historical snapshot. Neither history was synchronized or overwritten. See `VELOCIRAPTOR_VALIDATION.json`.
