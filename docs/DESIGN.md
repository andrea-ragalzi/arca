# ARCA design boundaries

## Direction

ARCA is a fan follow-up concept to Dino Crisis 2. The broader setting is a continuity station in a remote future, research facilities reclaimed by nature, a rescue involving Regina, Dylan and Paula, and dangerous expeditions to restore station systems. The current implementation is a technical blockout, not those finished characters or story scenes.

Use Godot 4 with GDScript, readable simplified 3D art, a cold industrial palette, and short loops that combine environmental tasks with predator pressure. Preserve the tested third-person controls until a deliberate camera experiment is requested.

## Current playable slice

One maintenance room with a partitioned service corridor and screened fuse alcove, one playable placeholder robot, one animated Quaternius raptor, one fuse, one power panel, one sliding exit door and a placeholder service-hatch bay. The fuse is a mission-local boolean inventory item. Power consumes it and opens the exit independently of the ambush. A 1.4-second containment-failure warning precedes a one-second hatch opening; the same dormant raptor then walks from `AmbushSpawn` through the real opening toward `HatchClearance` at 1.6 units/second. After about 2.3 seconds of unobstructed emergence it enters the existing alert/chase/combat flow. Leaving alive is enough; a kill is optional.

Pause freezes the warning, hatch motion, emergence and combat. Death and completion cancel unfinished entrance phases and stop attacks. Restart reloads the scene and resets the inventory, power, exit, closed hatch, dormant predator and trigger. The emerging raptor is shootable but cannot bite or chase until it clears the hatch; an obstructing player physically blocks it without triggering an early attack. No persistent saves are implemented.

The hatch uses primitive geometry, existing lighting/materials and the raptor's existing Walk animation, not a bespoke breach animation or cinematic. Its shallow bay reuses the corridor partition as its back wall without changing the accepted fuse route. Only the mission opts into emergence; the separate predator test room retains its normal activation. Art, humanoid character, weapon balance and sound design remain temporary. Unlimited ammunition allows control and combat testing; it does not represent the final survival resource economy.

## Keep future work small

The service corridor was accepted by the user in an F5 playtest on 2026-10-17; no human return-time measurement was supplied. The entrance is framed from spawn with yellow signage/lighting and the fuse remains concealed behind a full-height partition and alcove screen. The player explores, then backtracks to the existing panel. Movement, camera-controller code, shooting and base robot/raptor rooms remain unchanged. Mission navigation is rebaked for the corridor and hatch bay.

Current experiment: a readable physical hatch entrance with sufficient warning, pending user F5 acceptance. The next candidate after acceptance is one limited ammunition/health economy experiment; it is not part of the hatch change. Implement and playtest one feature at a time. Avoid adding squad AI, two protagonists, a large bestiary, crafting, a general inventory framework or a new engine before the short loop is convincing.

Use licensed independent assets with preserved attribution. Keep dependency/engine versions in technical documentation, but identify project development through Git commits rather than release-numbered folders.
