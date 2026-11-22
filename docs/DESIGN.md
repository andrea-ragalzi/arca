# ARCA design boundaries

## Direction

ARCA is a fan follow-up concept to Dino Crisis 2. The broader setting is a continuity station in a remote future, research facilities reclaimed by nature, a rescue involving Regina, Dylan and Paula, and dangerous expeditions to restore station systems. The current implementation is a technical blockout, not those finished characters or story scenes.

Use Godot 4 with GDScript, readable simplified 3D art, a cold industrial palette, and short loops that combine environmental tasks with predator pressure. Preserve the tested third-person controls until a deliberate camera experiment is requested.

## Current playable slice

One maintenance room with a partitioned service corridor and screened fuse alcove, one playable Regina prototype using the inherited TPS controller, one animated Ferocious Industries raptor, one fuse, one power panel, one sliding exit door and a placeholder service-hatch bay. The fuse is a mission-local boolean inventory item. Power consumes it and opens the exit independently of the ambush. A 1.4-second containment-failure warning precedes a one-second hatch opening; the same dormant raptor then walks from `AmbushSpawn` through the real opening toward `HatchClearance` at 1.6 units/second. After about 2.3 seconds of unobstructed emergence it enters the existing alert/chase/combat flow. Leaving alive is enough; a kill is optional.

Pause freezes the warning, hatch motion, emergence and combat. Death and completion cancel unfinished entrance phases and stop attacks. Restart reloads the scene and resets the inventory, power, exit, closed hatch, dormant predator and trigger. The emerging raptor is shootable but cannot bite or chase until it clears the hatch; an obstructing player physically blocks it without triggering an early attack. No persistent saves are implemented.

The hatch uses primitive geometry, existing lighting/materials and the raptor's Walk presentation, not a bespoke breach animation or cinematic. The Ferocious Industries visual replacement uses a separate source-backed animation wrapper while retaining the same AI, collision, damage timing and physical emergence. World/root travel remains owned by the existing CharacterBody3D, not by the imported clips. Its shallow bay reuses the corridor partition as its back wall without changing the accepted fuse route. Only the mission opts into emergence; the separate predator test room retains its normal activation. Regina and her primitive prototype handgun, weapon balance and sound design remain temporary. Unlimited ammunition allows control and combat testing; it does not represent the final survival resource economy.

Regina's current locomotion correction opts into camera-facing directional ground movement and a small free hop (2.6 m/s initial impulse; measured approximately 0.324 m rise / 0.50 s flight), while retaining the TPS physics pipeline and robot defaults. The mission does not require jumping; contextual traversal was evaluated but not added. Natural gait acceptance is blocked by the TPS-derived lateral poses failing sole-contact clearance. Do not expand into IK/rig repair or a new traversal mechanic without a separate decision.

Regina's handgun uses a calibrated wrist socket and a separate gameplay-only hand pose, without source rig/clip or gun-geometry edits. The vertical aim overlay uses Quaternius up/down poses relative to the neutral pistol pose, scaled against the 70-degree camera limit and filtered to the neck/head and right arm. The support arm stays on the base animation. The user accepted vertical aim in F5 on 2026-11-22. Lateral footwork remains a quality blocker.

## Keep future work small

The service corridor was accepted by the user in an F5 playtest on 2026-10-17; no human return-time measurement was supplied. The entrance is framed from spawn with yellow signage/lighting and the fuse remains concealed behind a full-height partition and alcove screen. The player explores, then backtracks to the existing panel. Movement, camera-controller code and shooting remain on the tested TPS controller; the robot remains available in its standalone reference scene. Mission navigation is rebaked for the corridor and hatch bay.

The readable physical hatch entrance and its warning were accepted by the user through the F5 checklist on 2026-10-17; the task is closed without further gameplay changes. The next candidate is one limited ammunition/health economy experiment, to be scoped separately; it is not part of the hatch change. Implement and playtest one feature at a time. Avoid adding squad AI, two protagonists, a large bestiary, crafting, a general inventory framework or a new engine before the short loop is convincing.

Use licensed independent assets with preserved attribution. Keep dependency/engine versions in technical documentation, but identify project development through Git commits rather than release-numbered folders.
