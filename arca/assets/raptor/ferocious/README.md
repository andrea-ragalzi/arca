# Ferocious Industries gameplay raptor

"PBR Velociraptor (Animated)" by **Ferocious Industries**, **CC BY 4.0**.

- Exact source: <https://sketchfab.com/3d-models/pbr-velociraptor-animated-8f1744af7b0847a2aabe3df90be802f0> / <https://skfb.ly/oHoUE>.
- Author: <https://sketchfab.com/ferociousindustries.matthias>.
- License: <http://creativecommons.org/licenses/by/4.0/>; original notice in `source/license.txt`.
- User-supplied official download: `pbr_velociraptor_animated.zip`. The original FBX and glTF archives remain in the separate evaluation worktree's archive area; the game does not depend on that worktree or Downloads.
- `source/` contains the unchanged glTF, binary, eight textures and license notice. Source SHA-256 values are pinned in `provenance.json`; source-side `.import` files are separate Godot settings, not changes to the downloaded content.

The source has 15,098 triangles, 9,495 accessor vertices, two materials, 137 skeleton joints, five morph targets per mesh and 26 animation entries (25 moving clips and a static Action_Pose). Godot 4.5.1 converts `KHR_materials_pbrSpecularGlossiness` to its metallic/roughness workflow; the importer warns that this approximation may not match the original exactly. Source data, rig, materials and clips are not edited.

## Presentation adapter

`arca/enemies/ferocious_model.tscn` wraps the original model and a separate AnimationPlayer at the existing `$Skin/AnimationPlayer` path. The imported source player is inactive so two players cannot drive the same bones. `arca/enemies/raptor.gd` remains unchanged, including its suffix-based clip discovery and physics/combat/lifecycle logic.

| Gameplay binding | Actual source | Derived presentation |
| --- | --- | --- |
| Ferocious_Idle | Idle_02 | Authored duration; loop |
| Ferocious_Walk | Walk | 1.8125 s loop, matching the original RM distance of 2.9 m at existing 1.6 m/s emergence |
| Ferocious_Run | Jog | 1.01415625 s loop, matching measured 3.2453 m RM distance at existing 3.2 m/s chase |
| Ferocious_Attack | Bite_02 | Trim the initial 14/24 s preparation prefix, then retime to the existing 0.833333 s attack cycle |
| Ferocious_Death | Death_01 | Retimed to the previous 1.291667 s death presentation; holds the terminal pose |
| Ferocious_Jump | Leap_01 | Retimed to previous 1.125 s clip; retained unused binding, not a new jump mechanic |

Every alias is an explicit binding to a real source clip, not an invented animation. Hit/roar and other source clips remain in the source asset but do not introduce new AI states. Sprint is not selected because its endpoints do not match as well as Jog.

Derived tracks retain source body/morph motion, but the Root_02 position is held at its initial value. This prevents imported world travel from moving the model away from its collision body during death or unused jump playback. CharacterBody3D still owns all navigation and hatch emergence. Source animation tracks and skeleton rests are untouched.

The bite trim removes the long authored preparation before its jaw opening. Its closure now falls near the **existing 0.24 s** hit check while the whole attack still lasts **0.833333 s**. Tests check that the jaw opens before, and is nearly closed at, that hit time. Damage is not emitted by animation callbacks and neither the AI's 0.45 s windup nor recovery timing is changed.

The wrapper uses native scale 1.0 and the original gameplay skin's 180-degree yaw to convert +Z source facing to -Z gameplay facing. Collision, navigation dimensions, warning marker, six hit points, damage, ranges, movement speeds and all mission scripts stay unchanged. The visible head/tail do not acquire new collision shapes.

## Regenerate and validate

From the ARCA root, after imports finish, use the pinned executable (prefer an isolated source snapshot while the live editor is open):

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --path . -s res://arca/assets/raptor/ferocious/bake_animations.gd
```

The baker references the retained Quaternius library only to preserve the existing attack/death/jump durations; it does not retarget that rig or use its poses in the new model. `gameplay.tres` is a CC BY 4.0 derivative of the credited Ferocious Industries animation data.

`arca/tests/raptor_test.gd` verifies the six source mappings, rig/track validity, inactive source driver, scale/facing, root anchoring, gait/bite presentation timing, pause/resume and all prior combat/navigation/projectile/lifecycle behavior. `bash scripts/ai_check.sh` runs the documented full gate in an isolated snapshot. The replacement does not fix the three existing Regina-player quality failures.

## Remaining visual limits

The source audit found some mesh/ground penetration and non-closed endpoints in unselected clips. No rig repair, IK, per-clip floor offsets or source pose editing was done. Jaw timing is checked numerically; final bite contact, death pose, tail clearance and material appearance still need the user's F5 inspection. Compatibility captures verify the new model is visible in the real hatch sequence; they are not GPU benchmarks or manual mission acceptance.
