# Regina asset inspection

Inspected on 2026-10-17 with **Godot 4.5.1 Standard**, Linux and the **Compatibility** renderer. This is an isolated visual/rig test, not a playable character replacement. The mission still uses the original TPS robot.

## Open the test scene

For locomotion, open **`arca/character_locomotion_test.tscn`** and press **F6**. Controls: `1` idle, `2` walk, `3` run; `M` centered/root travel (resets the lane); `Space` pause/resume; `R` centered idle/reset; `V` overview/front/side/back. The 12 m lane explicitly pauses at its end. The follow camera and controls belong only to this experiment; there is no mouse capture or TPS replacement.

The locomotion scene inherits `arca/character_test.tscn`, which remains a **static reference inspection** scene with neutral lighting, ground, a 2 m ruler/0.5 m ticks, a separate 1 m reference, labeled axes and a -Z marker. The user's saved changes to that parent scene were preserved; its running F6 instance was not stopped or overwritten. **F5** still starts `arca/mission_room.tscn` with the original robot.

Measured from the **posed/skinned vertices**, not raw mesh bounds:

| Property | Result |
| --- | --- |
| Native scale | 1.0; no scale correction needed |
| Native up / facing | +Y up, +Z facing |
| Native lowest vertex | Y = 0.011233 m |
| Test wrapper | `ModelPivot`: yaw 180 degrees, Y = -0.0112332 m |
| Test facing / feet | -Z; lowest vertex approximately Y = 0 |
| Posed width / height / depth | 1.585733 / **1.798599** / 0.277606 m |
| Test world bounds | X approximately [-0.792867, 0.792867], Y [0, 1.798599], Z [-0.195792, 0.081814] |

The wrapper corrects only the test instance. The GLB, skeleton rests, mesh data and imported materials are unchanged. Ancestor axis rotations make raw mesh-instance AABBs misleading: skin bind matrices restore the upright character. CPU skin measurements and Godot's rendered `bake_mesh_from_current_skeleton_pose()` bounds agree to about 0.00003 m in the inspected rest pose.

## Source and import

Asset: `arca/assets/characters/regina/regina.glb`, 5,877,192 bytes.

SHA-256: `54e1da324e570ac7eb16712377e819f2fd823fb15a4791f17f56e929da0db75e`.

The embedded metadata names **"DinoCrisisCustom - Regina"**, **Otherspectre**, Sketchfab-16.75.0 and CC BY 4.0. See [ATTRIBUTIONS.md](../ATTRIBUTIONS.md). The local FBX-to-GLB workflow is not known; the generator metadata does not prove a particular local conversion.

Godot imported the supplied file using `regina.glb.import`: root scale 1, named skins, animation import enabled, 30 fps, no rest-as-RESET, no external material overrides, glTF naming version 2 and extracted embedded images. The importer generated `regina_0.png` through `regina_16.png` alongside the GLB, with source-side `.import` files. Keep those generated PNGs/settings with the asset; `.godot/` is only a rebuildable cache. Texture settings include mipmaps and VRAM compression after 3D detection; normal maps are imported as normals. No import errors/warnings were reported by the isolated clean-import gate.

Source counts: one scene, 84 glTF nodes, one unnamed skin, **69 joints**, nine mesh primitives/materials, 17 textures/images, **zero animations**, zero morph targets. Mesh totals are 13,937 accessor vertices and 23,941 triangles. PNG CRC/decompression and source skin-weight/index checks passed during planning; all data is embedded, with no external texture/buffer URI dependencies.

## Imported skeleton and complete bone list

The imported root is `Sketchfab_Scene` (named `Regina` by the test instance). Relative to that instance, the skeleton is:

```text
Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D
```

`Mesh.fbx` becomes `Mesh_fbx`; it is a node name, not an original FBX file. All **69 bone names and parent relationships survive unchanged**, with finite rest transforms. The source skin root `_rootJoint` becomes bone 0. There are no added bones. Godot also creates an internal `PhysicalBoneSimulator3D` helper at runtime; it is not an authored bone, ragdoll setup or animation.

Each line below is `bone index: name`; indentation gives parentage. Original spelling, including `belt holser_067`, is preserved.

```text
0: _rootJoint
  1: root ground_01
    2: root hips_02
      3: spine lower_03
        4: spine middle_04
          5: spine upper_05
            6: head neck lower_06
              7: head neck upper_07
                8: head jaw_08
                9: head hair upper_09
                10: head hair back 1_010
                  11: head hair back 2_011
                12: head hair right 1_012
                  13: head hair right 2_013
                14: head hair left 1_014
                  15: head hair left 2_015
                16: head hair front middle 1_016
                  17: head hair front middle 2_017
            18: arm right shoulder 1_018
              19: arm right shoulder 2_019
                20: arm right elbow_020
                  21: arm right wrist_021
                    22: arm right finger 5a_022
                      23: arm right finger 5b_023
                        24: arm right finger 5c_024
                    25: arm right finger 4a_025
                      26: arm right finger 4b_026
                        27: arm right finger 4c_027
                    28: arm right finger 3a_028
                      29: arm right finger 3b_029
                        30: arm right finger 3c_030
                    31: arm right finger 2a_031
                      32: arm right finger 2b_032
                        33: arm right finger 2c_033
                    34: arm right finger 1a_034
                      35: arm right finger 1b_035
                        36: arm right finger 1c_036
            37: arm left shoulder 1_037
              38: arm left shoulder 2_038
                39: arm left elbow_039
                  40: arm left wrist_040
                    41: arm left finger 5a_041
                      42: arm left finger 5b_042
                        43: arm left finger 5c_043
                    44: arm left finger 4a_044
                      45: arm left finger 4b_045
                        46: arm left finger 4c_046
                    47: arm left finger 3a_047
                      48: arm left finger 3b_048
                        49: arm left finger 3c_049
                    50: arm left finger 2a_050
                      51: arm left finger 2b_051
                        52: arm left finger 2c_052
                    53: arm left finger 1a_053
                      54: arm left finger 1b_054
                        55: arm left finger 1c_055
          56: boob right 1_00
            57: boob right 2_056
          58: boob left 1_057
            59: boob left 2_058
      60: leg right thigh_059
        61: leg right knee_060
          62: leg right ankle_061
            63: leg right toes_062
      64: leg left thigh_063
        65: leg left knee_064
          66: leg left ankle_065
            67: leg left toes_066
      68: belt holser_067
```

Meshes `Object_75` through `Object_83` are children of this `Skeleton3D`. Each has one surface, a named `Skin` with 69 valid bindings, normalized weights and finite nonempty posed bounds. Mesh normals/UVs exist; eyelashes have no source tangents, which the import is configured to generate. The smoke script prints complete local bone rest transforms for inspection.

## Animation clips

**None.** The GLB's animation array is absent/empty, Godot imports **zero `AnimationPlayer` nodes**, and there is **no RESET clip** with the current settings. Consequently there are no clip durations, loops or tracks to list. Animation import is enabled; disabling import is not the explanation.

This describes the original Regina asset, not the separately generated locomotion library below. The supplied original FBX has now also been inspected and contains no animation objects/takes; no missing source clips were recovered.

## All materials and textures

All nine Godot resources are `StandardMaterial3D`, double-sided (`CULL_DISABLED`), metallic 0. Mesh/material order and all 17 albedo/normal assignments match the source. Source embedded texture labels use the material name plus `_baseColor.png` or `_normal.png`; Godot numbers the extracted files as listed below, under `arca/assets/characters/regina/`.

| Mesh | Exact material name | Base color file / pixels | Normal file / pixels | Roughness | Alpha |
| --- | --- | --- | --- | --- | --- |
| `Object_75` | `24_costume.reginadtga_0.25_0_0` | `regina_0.png` / 1024 x 1024 | `regina_1.png` / 1024 x 1024 | 0 | Opaque |
| `Object_76` | `24_holster.holsterdtga_1_0_0` | `regina_2.png` / 256 x 512 | `regina_3.png` / 256 x 512 | 0.392 | Opaque |
| `Object_77` | `24_eyetga_1_0_0` | `regina_4.png` / 256 x 256 | `regina_5.png` / 256 x 256 | 0.392 | Opaque |
| `Object_78` | `24_facedtga_0.25_0_0` | `regina_6.png` / 1024 x 1024 | `regina_7.png` / 1024 x 1024 | 0.392 | Opaque |
| `Object_79` | `24_reginau1v1u1v1tga_0.25_0_0` | `regina_8.png` / 1024 x 1024 | `regina_9.png` / 1024 x 1024 | 0.392 | Opaque |
| `Object_80` | `25_4tga_0.25_0_0` | `regina_10.png` / 512 x 512 | `regina_11.png` / 2 x 2 | 0.392 | Opaque |
| `Object_81` | `25_hair2dtga_0.25_0_0` | `regina_12.png` / 512 x 512 RGBA | `regina_13.png` / 512 x 512 | 0.213233 | Scissor 0.771057 |
| `Object_82` | `25_hairdtga_0.25_0_0` | `regina_14.png` / 512 x 1024 RGBA | `regina_15.png` / 512 x 1024 | 0.323203 | Scissor 0.136372 |
| `Object_83` | `7_eyelashtga_0.1_0_0` | `regina_16.png` / 256 x 128 RGBA | None | 0.301209 | Scissor 0.778979 |

There are no separate roughness, metallic, occlusion or emissive textures. Roughness is scalar. The 2 x 2 normal image is present and valid, not a missing-file substitute invented by ARCA.

**Known material translation difference:** source `KHR_materials_specular.specularFactor` is approximately 0.975287 for eyes (`Object_77`) and 0.406584 for the inner hair (`Object_81`), with white specular color. Both import with `metallic_specular = 0.5`, as do the other materials. Thus those extension values are not carried through to the imported scalar. Do not claim exact Sketchfab/FBX shading parity. No arbitrary material correction or warning suppression was applied.

## Initial rendered observations and original FBX

Rendered overview, front, side, back, face close-up and temporary right-elbow bend views were inspected using X11, Compatibility and Mesa llvmpipe software OpenGL. The model is upright and textured, with red cutout hair, visible eyes/eyelashes, dark costume and hip/holster accessories. No obvious detached mesh, missing texture or exploded rest skin was observed in those views. Hair highlights are bright and the costume has source roughness 0; skin/shoulder shading and hair cutout edges remain visible quality considerations, not proof of a conversion defect. A small temporary elbow rotation moves the bound limb without an obvious detached part in the staged view; the automated wrist test also deforms/restores the body bounds. These are limited pose checks, not animation-ready deformation certification.

Captures/logs are ignored local artifacts under `.artifacts/regina/`, not redistributed asset variants. X11 input-method and unsupported V-Sync warnings occur on the software display; no script/runtime errors occurred in the successful rendered run. This is not user F6 acceptance, a manual editor pose session or a GPU performance result.

**Original FBX checked on 2026-10-17:** the supplied `/home/andrea/Downloads/dinocrisiscustom-regina/source/Test.zip` contains `Test/Mesh.fbx` (1,077,468 bytes), `Test/xps.xps` and textures, including additional specular maps. A read-only binary FBX 7400 structure/property traversal directly in the archive found **zero AnimationStack, AnimationLayer, AnimationCurveNode or AnimationCurve objects**, no animation keys and no `Take` records. `Takes/Current` is empty. A bind `Pose` is not an animation. Thus this copy of the original FBX also supplies no clips; the animation-free GLB is not evidence of lost conversion data.

FBX SHA-256: `e0eb57188b9a8a0abdcaea75d4af57b6a8cb75c50c45041fafcf9fc79dbfba09`. Object inventory: 69 NodeAttributes, 70 Models (68 anatomical LimbNodes, Armature null, one mesh), one Geometry, one Pose, 69 Deformers, nine Materials, 25 Textures, 24 Videos. The anatomical names match the recognizable GLB chains without numeric suffixes; the GLB additionally has `_rootJoint`. This was a structural source comparison, not a full Godot FBX import or proof of identical skins/shading. No archive license/readme was found; the supplied credit and underlying-IP caveat still apply. Neither the download nor either supplied GLB was overwritten or reconverted.

## Isolated locomotion experiment

### TPS-first source decision

The existing official TPS asset was inspected **before** obtaining another source. It is already licensed under CC BY 3.0 (Juan Linietsky/Fernando Miguel Calabró; upstream tag `4.5-90f2e38`). Imported `Idle`, `walking_nogun` and `running_nogun` all loop; durations are 15 s, 1.25 s and approximately 0.833333 s. Raw root travel is 0, +2.176640 and +3.316785 along donor-local Z, before its approximately 0.8039915 ancestor scale.

A trial bake evaluated complete donor chains rather than renaming tracks. Its 145-joint robot includes `thigh -> knee -> shin -> foot`, extra forearm segments and an asymmetric right forearm slider. Measured left leg segments are approximately 0.289/0.442 m versus Regina's 0.442/0.482 m; a uniform leg-length ratio of approximately 1.264 cannot correct that segment-ratio mismatch. Its shoulder/clavicle reference pose and unarmed idle produced an exaggerated shrug on this skin. Preliminary trial feet floated by roughly 0.05–0.20 m before height calibration. Those observations do not prove that all TPS retargeting is impossible, but it was not a practical first accepted set without more gait-specific corrections. The trial is an ignored diagnostic, not part of the delivered animation library.

Selected replacement: **Quaternius Universal Animation Library — Standard, CC0 1.0**. The author's page explicitly states CC0. Only `Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop` are retained from the pinned free Standard mirror; Godot imports them as `Idle`, `Walk`, `Jog_Fwd`. Full notice, author/original/mirror links, hashes and extraction instructions are in [`source/README.md`](../arca/assets/characters/regina/source/README.md) and `ATTRIBUTIONS.md`. No paid/account-gated asset or new engine/runtime dependency was introduced. The small source mannequin is only an offline donor, never a second runtime character.

### Mapping, pose and regeneration

`arca/assets/characters/regina/bake_locomotion.gd` is a narrow offline baker, not a runtime retarget framework. Its explicit 22-bone mapping is authoritative. The two source GLBs, Regina import settings, bone names/rests, lengths, skin weights and materials remain unchanged.

| UAL bone(s) | Regina target(s) | Treatment |
| --- | --- | --- |
| `DEF-hips` | `root hips_02` | Rest-relative global rotation; anatomical thigh-center translation |
| `DEF-spine.001/.002/.003` | `spine lower_03`, `spine middle_04`, `spine upper_05` | Rest-relative global rotation |
| `DEF-neck`, `DEF-head` | `head neck lower_06`, `head neck upper_07` | Neck/head pivot mapping, not mapping the head to jaw/hair |
| `DEF-shoulder.L/R` | `arm left/right shoulder 1` (full suffixed names in script) | Preserve target reference orientation while transferring global rotational motion |
| `DEF-upper_arm.L/R` | `arm left/right shoulder 2` | Anatomical shoulder-to-elbow frames |
| `DEF-forearm.L/R` | `arm left/right elbow` | Elbow-to-wrist frames |
| `DEF-hand.L/R` | `arm left/right wrist` | Hand-to-middle-finger-base frames |
| `DEF-thigh.L/R`, `DEF-shin.L/R` | `leg left/right thigh`, `leg left/right knee` | Thigh/knee/ankle segment frames |
| `DEF-foot.L/R`, `DEF-toe.L/R` | `leg left/right ankle`, `leg left/right toes` | Rest-relative global rotation; keep target foot geometry |

Rest-relative global rotations are resolved back into Regina's parent-local axes. Limb frames use anatomical endpoint directions with a rest-calibrated twist reference; this avoids copying incompatible A/T-pose local rotations. Hips translation uses the **thigh-center** reference, because Regina's named hips pivot lies below its thigh origins, unlike the donor. Translation scaling comes from leg length: **0.924238 / 0.829790 = 1.113822**. Only hips translate; mechanical scale/limb-position channels are not copied. Unmapped jaw, hair, fingers, secondary chest and holster bones retain their reference locals and inherit their parents. Hands remain open: this does not establish weapon grip or finger-animation readiness. The source jaw's slight reference scale (`Z ≈ 0.99994`) is preserved, not forced to 1.

Godot's native `RetargetModifier3D` was considered: local-pose transfer ignores missing intermediate parents, while global-pose transfer also moves bone positions and expects matching lengths. The focused offline frame/rotation bake preserves Regina's rest/skin without normalizing a duplicate character import or introducing a general retargeting system.

Small source endpoint residuals are removed progressively across one cycle (jog approximately 3.15 degrees at the worst mapped joint and 0.026 m hip displacement before correction). The original 60 Hz jog changed one knee about 26.8 degrees on its first step. Retiming it to **70%** brings the tested maximum below the unchanged 0.35 rad/frame continuity threshold and produces a more moderate run speed; no test threshold was relaxed. Pose data is sampled before retiming at 60 Hz. A **constant**, offline per-clip hips-height correction places the lowest sampled sole about 0.5 mm above ground: idle +3.432 mm, walk +3.103 mm, run +9.492 mm. There is no live Y clamp, foot-lock system or IK; pelvis bob, foot roll and the run's flight phase remain.

The source subset extractor reproduces its 767,524-byte GLB byte-for-byte from the pinned inputs. The baker saves only `locomotion.tres`; regeneration commands are in the source README. F6 loads the derived library directly, not the source mannequin or baker.

### Root-motion verdict: conditionally compatible for locomotion

**Unmodified UAL clips are in-place:** their root has zero net translation. They would not move the current root-motion-driven TPS player. ARCA adds a constant-speed **`RootMotion` Node3D position track**, already in scene/TPS convention **-Z forward**, calibrated from the actual skinned sole's backward speed during flat support. This proxy is outside the rotated skeleton. AnimationTree extracts it; centered playback discards the delta, translating playback applies it **once** to `ModelPivot`. The proxy itself stays at zero, so the skin does not receive duplicate travel.

| Derived clip | Source duration / retiming | Delivered duration | Travel/cycle | Preview m/s | m/s at existing TPS 1.3 time scale |
| --- | --- | ---: | ---: | ---: | ---: |
| `idle` | 2.5 s / 1× | 2.500000 s | 0 m | 0 | 0 |
| `walk` | 1.333333 s / 1× | 1.333333 s | 1.610911 m | **1.208183** | 1.570638 |
| `run` | 0.916667 s / 0.7× | 1.309524 s | 5.712060 m | **4.361937** | 5.670518 |

The proxy has **identity root rotation**; these are straight locomotion clips, not authored turns. The existing controller still owns facing. `root ground_01` is not treated as a drop-in extraction track: it sits beneath `_rootJoint` in the rotated imported skeleton, and neither original model authors motion there. Keeping it/rests untouched and using a canonical proxy makes the conversion explicit. A later integration must add/rebind the proxy beneath the controller's animation root, rebind Regina track paths, select the proxy as `root_motion_track`, retain the visual yaw below the controlled model pivot and apply the delta in controller coordinates without rotating/scaling it twice.

The preview proves extraction, loop continuity and straight translation—not `CharacterBody3D` collision, camera-relative turning, blend-tree parity or a working Regina TPS replacement. The old tree also expects strafes, jumps, aim poses and robot-specific weapon paths; those remain outside this task. **Conditional** means the delivered travel can feed the same horizontal displacement/delta contract after that explicit integration, not that swapping a model works unchanged.

### Measured contacts, rendered limits and F6 acceptance

The focused suite samples actual CPU-skinned reference sole vertices over full cycles, including swing/flight. Flat support is identified separately from heel-strike/toe-off: walk phases L 0.12–0.30 / R 0.62–0.80; run L 0.06–0.12 / R 0.56–0.62. Calibration uses these intervals too; the regression samples more of the skin independently through actual playback/extraction. Tolerances: floor penetration at most 2 mm over the full cycle; flat-support clearance at most 2 cm and drift at most 3 cm. These checks do not promise contact locking during crossfades, toe-off, swing or run flight.

| Clip | Minimum sole Y | Maximum flat-support clearance | Maximum horizontal support drift |
| --- | ---: | ---: | ---: |
| Idle | +0.50 mm | 2.57 mm | 2.97 mm |
| Walk | +0.50 mm | 14.88 mm | 14.21 mm |
| Run | +0.50 mm | 19.38 mm | 6.00 mm |

Staged front/side/back captures at four phases per clip were inspected using **X11 / Compatibility / Mesa Intel Iris Xe** (not the earlier software display). There are no detached costume/holster parts or exploding/severely stretched meshes in these sampled views; legs, shoulders and hands follow the gait. **Small shoulder/costume intersections and bright shoulder/skin shading remain visible during run arm swings**, especially from behind; open hands and rigid secondary hair are also visible. This is a bounded locomotion proof, not final skinning/cloth quality. No weight, geometry or material repair was attempted. The source files and nine bindings/material parts are retained. User F6 visual acceptance, particularly those shoulder/costume details, is **pending**; automated bounds/rotation checks cannot certify it.

Short **F6 checklist** (`arca/character_locomotion_test.tscn`):

1. Use `1`/`2`/`3`: judge human scale, -Z facing and loop/idle-transition continuity against the ruler.
2. Use `V` for front/side/back. Inspect planted feet, knee bends, shoulders/hands and attached costume/holster, including the documented run shoulder clipping. Reject any severe deformation or unacceptable sliding.
3. Press `M`: check forward travel without double motion or a wrap snap. `Space` must freeze/resume pose and travel; `R` must reset while paused. The lane pauses visibly at 12 m, never auto-teleports.

## Connecting to the existing TPS later

The current input/physics/weapon flow is:

```text
player/player_input.gd: move/aim input + camera crosshair target
  -> player/player.gd: AnimationTree walk/strafe/jump and additive aiming
  -> animation root translation/rotation -> horizontal velocity -> move_and_slide()
  -> aiming + shooting -> muzzle-to-target projectile + existing effects/cooldown
arca/player/arca_player.gd: health/death + cover-safe chest-to-muzzle sweep
```

A direct `PlayerModel` replacement still breaks robot-specific paths and animation contracts. The derived locomotion library supplies a separately calibrated travel proxy, not a complete replacement for the player model or AnimationTree. Keep the existing controller, camera, projectile, health and mission inheritance; this experiment does not modify them.

| Area | Existing contract | Work needed before replacement |
| --- | --- | --- |
| Locomotion | `AnimationTree` uses `Robot_Skeleton/Skeleton3D:root` root motion | This experiment supplies isolated idle/walk/run with a canonical `RootMotion` proxy. Rebind paths/tree/root extraction in a later integration; strafe/jump/fall/land remain missing. See the conditional root-motion verdict below |
| Rig | Robot names/rest orientations and animation track paths | Explicit humanoid map and rest-pose alignment; compare both shoulder joints, spine, neck/head and finger chains, rather than renaming bones. There is no explicitly named head joint; inspect upper-neck/head geometry before mapping |
| Aim | `AIM-Up`/`AIM-Down`; filters target `neck.001` and `upper_arm.R` | Retarget/author aim poses and rebuild filters for Regina; keep camera pitch, strafe facing and crosshair target behavior |
| Shooting | `GunBone` on `hand.R`, `ShootFrom` marker and two particle paths | Attach an appropriate weapon/muzzle to right wrist (bone 21), establish grip/forward axis and adapt the few model-specific paths. Hip accessories are visible but there is no separate named gun/muzzle node or firing clip; identify/separate usable geometry or supply a suitable licensed weapon, not an assumed working gun |
| Scale/cover | 1.6 m camera pivot and 1.4 m chest sweep in the existing player | Evaluate the measured 1.799 m character against the unchanged capsule/camera/chest references in a later playable test. Keep the visual axis correction below the pivot whose world basis the controller overwrites |
| Lifecycle | Existing death disables animation/input/fire; pause/restart freeze/reset gameplay | Preserve these contracts and repeat existing cover/shoot/lifecycle integration tests after any eventual replacement |

Current blend resources require `Idle`, `Idlecombat`, `running_nogun`, `running_gun`, `strafe_left`, `strafe_right`, `strafe_back`, `strafe_front`, `jump_2_upwards`, `jump_4_falling`, `jump_5_hardlanding`, `AIM-Up`, `AIM-Down` and `eyes`. Regina supplies none. Eye/hair/finger extra bones do not substitute for those animations. Bone names alone are not a retarget: local axes, rest orientation and root displacement must agree.

**Next acceptance action:** run the three-step F6 checklist below. This task does not authorize a playable-character replacement, weight/cloth repair or an IK system.

## Reproduce checks

After importing, from the ARCA project root (set `GODOT_BIN` in launch/check workflows if the engine is not discovered):

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_locomotion_test.gd
bash scripts/check.sh
```

The focused script emits the actual skeleton/rest hierarchy, mesh bounds, material mappings and animation inventory, and exits nonzero on failed assertions. It checks real source/import correspondence, bindings, texture sizes, alpha settings, skin weights, camera, feet/scale and reversible wrist deformation. It is separate from the unchanged gameplay gate.

Initial static-inspection results: **93 Regina checks passed** in both the live project and an isolated clean-import source copy; **162 gameplay and 13 launcher checks passed** in that copy. The isolated import avoids running a competing editor import against the open working project. The gate used the existing local ripgrep PATH workaround documented in `VALIDATION.md`; import and GDScript compilation succeeded. `regina_test.gd` editor diagnostics report no errors/warnings.

Locomotion revalidation on 2026-10-17: **68 locomotion + 93 static Regina checks**, and the full **162 gameplay + 13 launcher gate**, all passed against a fresh source-only import in `.artifacts/regina-locomotion/clean-project/`. The standard gate remains unchanged; the two Regina suites run explicitly. The source-only copy avoids a competing importer on the open working project. No GPU performance claim is made.

Optional staged capture (requires a display and an absolute output path):

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --path . -s res://arca/tests/capture_regina_locomotion.gd -- /absolute/output/directory
```

Remaining user checks:

1. **F6:** run the locomotion checklist above. The static parent still supports editor rest-pose/bone inspection; no source or imported pose needs saving.
2. **F5:** verify the existing robot still moves, aims/fires and pauses/restarts normally. Automated controller/mission coverage passed, but a fresh human F5 check has not been reported for this task.
3. The supplied FBX's animation absence is resolved by the read-only check above; a full FBX material/skin parity investigation was not needed for locomotion and is not claimed.
