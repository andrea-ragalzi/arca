# ARCA design boundaries

## Direction

ARCA is a fan follow-up concept to Dino Crisis 2. The broader setting is a continuity station in a remote future, research facilities reclaimed by nature, a rescue involving Regina, Dylan and Paula, and dangerous expeditions to restore station systems. The current implementation is a technical blockout, not those finished characters or story scenes.

Use Godot 4 with GDScript, readable simplified 3D art, a cold industrial palette, and short loops that combine environmental tasks with predator pressure. Preserve the tested third-person controls until a deliberate camera experiment is requested.

## Current playable slice

The demo starts in the maintenance room with a partitioned service corridor and a screened fuse alcove. Power consumes the fuse and opens the door to the security corridor independently of the ambush. A 1.4-second warning precedes a one-second hatch opening. The dormant predator then walks toward `HatchClearance` at 1.6 units per second before entering alert and chase. Beyond the powered door, the security corridor leads through a raptor alcove to the control office. The office keycard opens the far lift gate. A final predator waits in the lift hall. Reaching the cabin completes the mission without requiring a kill.

Pause freezes the warning, hatch motion, emergence and combat. Death and completion cancel unfinished entrance phases and stop attacks. Restart reloads the scene and resets the inventory, power, exit, closed hatch, dormant predator and trigger. The emerging raptor is shootable but cannot bite or chase until it clears the hatch; an obstructing player physically blocks it without triggering an early attack. The mission records active play time, actual shots and cumulative damage, and shows them with the predator outcome on victory or defeat. Restart clears the run statistics. The office terminal records a checkpoint in memory for the current run. Restarting the entire mission clears it.

The hatch uses primitive geometry, existing lighting/materials and the raptor's Walk presentation, not a bespoke breach animation or cinematic. The Ferocious Industries visual replacement uses a separate source-backed animation wrapper while retaining the same AI, collision, damage timing and physical emergence. World/root travel remains owned by the existing CharacterBody3D, not by the imported clips. Its shallow bay reuses the corridor partition as its back wall without changing the accepted fuse route. Only the mission opts into emergence; the separate predator test room retains its normal activation. Regina and her primitive prototype handgun, weapon balance and sound design remain temporary. Regina starts with a 12-round magazine and 12 rounds in reserve. Reloading takes 1.5 seconds. The corridor ammo box adds 12 rounds, and the room medkit restores up to 40 HP. Pickups use the same line-of-sight and reach checks as the fuse, and restart restores the initial supplies.

Regina's current locomotion correction opts into camera-facing directional ground movement and a small free hop (2.6 m/s initial impulse; measured approximately 0.324 m rise / 0.50 s flight), while retaining the TPS physics pipeline and robot defaults. The mission does not require jumping; contextual traversal was evaluated but not added. The Quaternius UAL2 lateral walks drive Regina’s spine and lower body while the established blend speeds and weapon pose tracks are retained. Do not expand into IK/rig repair or a new traversal mechanic without a separate decision.

Regina's handgun uses a calibrated wrist socket and a separate gameplay-only hand pose, without source rig/clip or gun-geometry edits. The vertical aim overlay uses Quaternius up/down poses relative to the neutral pistol pose, scaled against the 70-degree camera limit and filtered to the neck/head and right arm. The support arm stays on the base animation. The user accepted vertical aim in F5 on 2026-11-22. The lateral footwork passes the headless sole-contact gate and was accepted in the combined F5 playtest on 2026-11-24.

The raptor roars during its alert phase and has a short hit reaction: an accepted hit while alert, chasing, winding up or recovering staggers it for 0.5 s, at most once every 1.5 s. A stagger during the windup cancels that bite, rewarding accurate fire without adding damage. Committed bites, emergence and dormancy are not interruptible. These reactions use authentic Ferocious source clips and don't change damage, speed or the bite timing.

## Interaction contract (S1-01)

Every interactable extends `ArcaInteractionPoint` (`arca/interactables/interaction_point.gd`), joins the `arca_interactable` group in `_ready()` and overrides two methods: `get_prompt(room) -> String` for the text after `[ E ]`, and `interact(room) -> bool` for the action. The mission discovers candidates from the group, restricted to its own descendants, and keeps the nearest one that passes the existing reach and line-of-sight check. A new interactable is a new script plus an instance in the scene; `mission_room.gd` does not change. Ammo and medkit boxes share `supply_pickup.gd` with exported `kind` and `amount`. One E press performs at most one action: key-repeat echoes are ignored, and a second press in the same frame is dropped. The room still owns shared feedback (`_notify`, `_collect_supply`) and mission state such as the fuse flag.

## Keep future work small

The service corridor was accepted by the user in an F5 playtest on 2026-10-17; no human return-time measurement was supplied. The entrance is framed from spawn with yellow signage/lighting and the fuse remains concealed behind a full-height partition and alcove screen. The player explores, then backtracks to the existing panel. Movement, camera-controller code and shooting remain on the tested TPS controller; the robot remains available in its standalone reference scene. Mission navigation is rebaked for the corridor and hatch bay.

The readable physical hatch entrance and its warning were accepted by the user through the F5 checklist on 2026-10-17; the task is closed without further gameplay changes. The limited ammunition and health economy is the next implemented slice, with the mission route and escape option preserved. Implement and playtest one feature at a time. Avoid adding squad AI, two protagonists, a large bestiary, crafting, a general inventory framework or a new engine before the short loop is convincing.

Use licensed independent assets with preserved attribution. Keep dependency/engine versions in technical documentation, but identify project development through Git commits rather than release-numbered folders.

## Sprint route and key items

The mission extends from the maintenance blockout to the security corridor, office and lift hall. The fuse and security keycard are unique mission-local IDs. The power panel spends the fuse, and the lift gate consumes the card. Both access points reuse the sliding door. A nearby corridor sleeper can wake on proximity, gunfire or damage. The final hall has a separate predator. Opening a note suspends the mission and the clock until the player closes it.
