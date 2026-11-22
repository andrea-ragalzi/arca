---
name: godot-animation-audit
description: Inspect ARCA 3D skeletons, skinning, materials, AnimationPlayer, AnimationTree and root motion on Godot 4.5.1. Use for Regina or predator animation diagnosis without silently replacing assets, retargeting rigs or changing TPS motion.
---

# Audit a 3D character before changing it

Use `arca-godot` for the implementation workflow. This is a corrected adaptation of animation topics from [vl4dt/godot-skills](https://github.com/vl4dt/godot-skills); the reviewed revision and differences are recorded in `docs/AI_ENVIRONMENT.md`. Preserve `../LICENSE_GODOT_SKILLS.txt`.

1. Read `docs/REGINA.md`, `TASK.md` and the actual controller/model scenes. Distinguish imported source, visual wrapper, generated AnimationLibrary and runtime-installed nodes.
2. Inventory Skeleton3D bone names/parents/rests, Skin bind names/indices, mesh surfaces/material overrides and AnimationPlayer libraries/tracks. Record actual clip count: a rigged model is not proof of authored animation.
3. Inspect scale, anatomical facing, model pivot, final camera axes and root-motion proxy separately. Do not swap input signs to conceal a visual-axis defect.
4. Compare physical body displacement, extracted root motion, hip pose and skinned feet as independent measurements. A passing movement test does not prove planted-foot quality.

## Correct API boundaries

- AnimationPlayer owns clips/libraries; AnimationTree evaluates the configured graph. Do not drive the same tracks from both independently.
- For an actual root AnimationNodeStateMachine, obtain its AnimationNodeStateMachinePlayback from `parameters/playback`; nested graphs have their own real parameter paths. Inspect the graph instead of assuming `get("state_machine")` or a playback `has_state()` method.
- BlendSpace1D uses `parameters/<node>/blend_position` with a float; BlendSpace2D uses a Vector2. There is no `AnimationNodeBlendDBone2D` class. ARCA's graph paths are contractual; discover them before writing parameters.
- Use AnimationTree root-motion extraction with the existing physics pipeline. Do not apply donor root travel to both body and hips, double-integrate it or overwrite body transforms to bypass collision.
- Validate cyclic seams across repeated loops, finite values, retiming and reset/pause/lifecycle transitions. Completion signals are not emitted every loop of a looping animation.
- Built-in node properties require `godot_inspection_get_node_property`; `get_node_properties` returns script variables, not a complete Inspector dump.
- The MCP inspection/property tools and `godot_read_resource` provide generic inspection, not a dedicated rig-retargeting or material-quality certification. Use existing Godot inspection/regression scripts for bone poses and CPU-skinned measurements.

## Materials and visual evidence

Inspect surface count, StandardMaterial3D properties, textures, alpha/culling, skeleton bindings and import metadata without resaving the source asset. Headless can check resource values and numeric poses; lighting, skin deformation and contact quality need rendered views. Report renderer/GPU and staged versus human-playtest evidence honestly.

## Regina stop condition

The source has no authored clips. The existing gameplay suite has two documented lateral sole-contact failures. Keep those failures visible; do not loosen tolerances, lower the whole model, add IK, regenerate animation assets, download clips or rewrite a rig as part of a tooling/inspection task. Generated resources must be reproduced through their baker only when that work is explicitly authorized.
