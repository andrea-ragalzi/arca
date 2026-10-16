# Regina asset inspection

Inspected on 2026-10-17 with **Godot 4.5.1 Standard**, Linux and the **Compatibility** renderer. This is an isolated visual/rig test, not a playable character replacement. The mission still uses the original TPS robot.

## Open the test scene

Open `arca/character_test.tscn` and press **F6**. It has a fixed three-quarter camera, neutral background/lighting, plain ground, a 2 m ruler with 0.5 m ticks, a separate 1 m ground reference, labeled world axes and a -Z forward marker. There is no runtime movement, animation or mouse capture. Stop F6 and use the editor's 3D viewport to orbit/zoom for front, side, back and face inspection. **F5** still starts `arca/mission_room.tscn`.

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

Missing locomotion is a real integration blocker, but not evidence that conversion discarded animations. The original source is required to determine whether any clips ever existed.

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

## Rendered observations and remaining source check

Rendered overview, front, side, back, face close-up and temporary right-elbow bend views were inspected using X11, Compatibility and Mesa llvmpipe software OpenGL. The model is upright and textured, with red cutout hair, visible eyes/eyelashes, dark costume and hip/holster accessories. No obvious detached mesh, missing texture or exploded rest skin was observed in those views. Hair highlights are bright and the costume has source roughness 0; skin/shoulder shading and hair cutout edges remain visible quality considerations, not proof of a conversion defect. A small temporary elbow rotation moves the bound limb without an obvious detached part in the staged view; the automated wrist test also deforms/restores the body bounds. These are limited pose checks, not animation-ready deformation certification.

Captures/logs are ignored local artifacts under `.artifacts/regina/`, not redistributed asset variants. X11 input-method and unsupported V-Sync warnings occur on the software display; no script/runtime errors occurred in the successful rendered run. This is not user F6 acceptance, a manual editor pose session or a GPU performance result.

**Original FBX comparison is blocked:** the repository contains only the unrelated `arca/assets/raptor/source/Velociraptor.fbx`. Supply the original Regina FBX/archive and matching textures to compare rig/rest transforms, animations, mesh parts and materials. Nothing was reconverted or overwritten. Absence of GLB clips and the specular translation difference justify source comparison, but neither establishes what the FBX contains. Model provenance beyond the supplied credit/metadata is also unverified.

## Connecting to the existing TPS later

The current input/physics/weapon flow is:

```text
player/player_input.gd: move/aim input + camera crosshair target
  -> player/player.gd: AnimationTree walk/strafe/jump and additive aiming
  -> animation root translation/rotation -> horizontal velocity -> move_and_slide()
  -> aiming + shooting -> muzzle-to-target projectile + existing effects/cooldown
arca/player/arca_player.gd: health/death + cover-safe chest-to-muzzle sweep
```

A direct `PlayerModel` replacement would break hard-coded resource paths and leave no root motion to drive horizontal movement. Keep the existing controller, camera, projectile, health and mission inheritance; this task does not modify them.

| Area | Existing contract | Work needed before replacement |
| --- | --- | --- |
| Locomotion | `AnimationTree` uses `Robot_Skeleton/Skeleton3D:root` root motion | Obtain compatible licensed idle/run/strafe/jump/fall/land clips; verify/retarget root motion to `root ground_01`/hips with the correct coordinate convention, and rebuild the model-specific animation paths |
| Rig | Robot names/rest orientations and animation track paths | Explicit humanoid map and rest-pose alignment; compare both shoulder joints, spine, neck/head and finger chains, rather than renaming bones. There is no explicitly named head joint; inspect upper-neck/head geometry before mapping |
| Aim | `AIM-Up`/`AIM-Down`; filters target `neck.001` and `upper_arm.R` | Retarget/author aim poses and rebuild filters for Regina; keep camera pitch, strafe facing and crosshair target behavior |
| Shooting | `GunBone` on `hand.R`, `ShootFrom` marker and two particle paths | Attach an appropriate weapon/muzzle to right wrist (bone 21), establish grip/forward axis and adapt the few model-specific paths. Hip accessories are visible but there is no separate named gun/muzzle node or firing clip; identify/separate usable geometry or supply a suitable licensed weapon, not an assumed working gun |
| Scale/cover | 1.6 m camera pivot and 1.4 m chest sweep in the existing player | Evaluate the measured 1.799 m character against the unchanged capsule/camera/chest references in a later playable test. Keep the visual axis correction below the pivot whose world basis the controller overwrites |
| Lifecycle | Existing death disables animation/input/fire; pause/restart freeze/reset gameplay | Preserve these contracts and repeat existing cover/shoot/lifecycle integration tests after any eventual replacement |

Current blend resources require `Idle`, `Idlecombat`, `running_nogun`, `running_gun`, `strafe_left`, `strafe_right`, `strafe_back`, `strafe_front`, `jump_2_upwards`, `jump_4_falling`, `jump_5_hardlanding`, `AIM-Up`, `AIM-Down` and `eyes`. Regina supplies none. Eye/hair/finger extra bones do not substitute for those animations. Bone names alone are not a retarget: local axes, rest orientation and root displacement must agree.

**Recommended next bounded action:** obtain the original Regina FBX/archive and textures, then determine whether it supplies the missing animation data before choosing a retargeting task. Do not rewrite movement or add IK to compensate for an unverified source asset.

## Reproduce checks

After importing, from the ARCA project root (set `GODOT_BIN` in launch/check workflows if the engine is not discovered):

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/regina_test.gd
bash scripts/check.sh
```

The focused script emits the actual skeleton/rest hierarchy, mesh bounds, material mappings and animation inventory, and exits nonzero on failed assertions. It checks real source/import correspondence, bindings, texture sizes, alpha settings, skin weights, camera, feet/scale and reversible wrist deformation. It is separate from the unchanged gameplay gate.

Results: **93 Regina checks passed** in both the live project and an isolated clean-import source copy; **162 gameplay and 13 launcher checks passed** in that copy. The isolated import avoids running a competing editor import against the open working project. The gate used the existing local ripgrep PATH workaround documented in `VALIDATION.md`; import and GDScript compilation succeeded. `regina_test.gd` editor diagnostics report no errors/warnings.

Remaining user checks:

1. **F6:** inspect the scene and reference scale; orbit/zoom in the editor to judge face, hair, shoulders, accessories and feet. Inspect bones with temporary unsaved rotations, then reset them. Report any visible defect; no source or imported pose needs saving.
2. **F5:** verify the existing robot still moves, aims/fires and pauses/restarts normally. Automated controller/mission coverage passed, but a fresh human F5 check has not been reported for this task.
3. Supply the original Regina FBX/archive plus textures for the unresolved source comparison.
