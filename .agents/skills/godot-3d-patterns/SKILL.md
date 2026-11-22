---
name: godot-3d-patterns
description: Review or implement GDScript, modular scenes, signals, Resources, CharacterBody3D physics and simple dinosaur AI in ARCA on Godot 4.5.1. Use for design/API decisions, not the task execution workflow covered by arca-godot.
---

# Godot 4.5.1 3D patterns

Use `arca-godot` for repository workflow and acceptance checks. This skill is a focused, corrected adaptation of the architecture, GDScript, physics and state-management topics in [vl4dt/godot-skills](https://github.com/vl4dt/godot-skills); consult `docs/AI_ENVIRONMENT.md` for the exact reviewed revision. The upstream MIT notice is in `../LICENSE_GODOT_SKILLS.txt`.

## Design within the existing project

- Prefer small composed Nodes/scenes and explicit dependencies for new behavior. Do not replace ARCA's established mission/raptor/test-room inheritance or the inherited TPS controller.
- Keep visual models, animation resources, controllers and gameplay state separate. Do not copy the base player to add a feature.
- Let parents configure children; let children emit typed signals for events. Connect siblings through their owning scene. Reuse existing signals before adding another event path.
- Store reusable authored statistics/configuration in typed Resources, not a new global manager. Remember loaded Resources may be shared: duplicate before instance-specific mutation.
- Keep local events local. Do not introduce an event-bus autoload, service locator, ECS or generic state framework just because a tutorial uses one.
- Follow existing typed GDScript and tab indentation. Verify uncertain APIs against the installed engine or the versioned 4.5 documentation, not the latest docs.

## Physics and coordinates

- Perform body movement in `_physics_process()`. `CharacterBody3D.velocity` is metres/second; `move_and_slide()` uses it without a delta argument. Gravity/acceleration need delta; velocity must not be multiplied by delta twice.
- Inspect the real Camera3D basis and model pivot before deciding forward/right. Node3D's usual -Z convention does not establish ARCA's final camera or TPS animation convention.
- Collision layers/masks belong to CollisionObject3D bodies/areas, not CollisionShape3D. Read ARCA's actual masks; do not impose tutorial layer numbers.
- For ray exclusions use object RIDs, for example `query.exclude = [body.get_rid()]`. Check query masks, bodies/areas and world/local coordinates independently.
- Distinguish CharacterBody3D kinematic movement, RigidBody3D forces and Area3D overlap detection. PhysicsMaterial belongs on a body's material override, not a Shape3D material property.
- Preserve pause/death/restart/completion semantics and input-edge handling. A timer signal does not by itself make delayed actions lifecycle-safe.

## Dinosaur AI

- Start from `arca/enemies/raptor.gd` and its current explicit states. Prefer an enum and one transition function unless additional complexity is demonstrated.
- Separate perception, decision/state and movement. Use existing navigation, line-of-sight and attack windup/cancellation contracts.
- State entry/exit owns transient actions. Dormancy must preserve the existing hidden/non-solid/immune policy; emergence must not turn into an early melee attack.
- Test a transition through real physics and lifecycle events, not only by assigning its state variable.

## API exclusions

Godot 4.5.1 Standard has no C# runtime here. Do not use newer APIs unavailable on 4.5.1, including `tween_await()`, `AreaLight3D`, `EditorDock`, or `EditorInterface.get_unsaved_scenes()`. Use existing tweens and completion signals when appropriate. Do not upgrade the engine to satisfy a pattern.
