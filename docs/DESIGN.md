# ARCA design boundaries

## Direction

ARCA is a fan follow-up concept to Dino Crisis 2. The broader setting is a continuity station in a remote future, research facilities reclaimed by nature, a rescue involving Regina, Dylan and Paula, and dangerous expeditions to restore station systems. The current implementation is a technical blockout, not those finished characters or story scenes.

Use Godot 4 with GDScript, readable simplified 3D art, a cold industrial palette, and short loops that combine environmental tasks with predator pressure. Preserve the tested third-person controls until a deliberate camera experiment is requested.

## Current playable slice

One maintenance room with a partitioned service corridor and screened fuse alcove, one playable placeholder robot, one animated Quaternius raptor, one fuse, one power panel and one sliding exit door. The fuse is a mission-local boolean inventory item. Power consumes it, opens the door and starts a short containment-failure warning. The dormant predator then activates near `AmbushSpawn` and navigates toward the player. Leaving alive is enough; a kill is optional.

Pause freezes the warning countdown and combat. Death cancels pending activation and stops attacks. Restart reloads the scene and resets the inventory, power, door, predator and trigger. Completion pauses the mission and cancels any pending activation. No persistent saves are implemented.

The predator currently appears at a marked location after a warning; there is no animated vent breach or service hatch. Art, humanoid character, weapon balance and sound design remain temporary. Unlimited ammunition allows control and combat testing; it does not represent the final survival resource economy.

## Keep future work small

Current experiment: the service entrance is framed from spawn with yellow signage and lighting; the fuse is hidden from the main room behind a full-height partition and alcove screen. The player explores the corridor, then backtracks to the existing power panel. Target roughly 10–20 seconds of ordinary walking from fuse to panel, subject to manual F5 timing and camera review. The camera controller and movement remain unchanged; only the mission's initial camera heading is adjusted. Navigation is rebaked for the corridor, and the base robot/raptor rooms remain unchanged.

Next candidates after this route-and-camera experiment is accepted: a readable service hatch for the ambush, then one limited ammunition/health economy experiment. Implement and playtest one feature at a time. Avoid adding squad AI, two protagonists, a large bestiary, crafting, a general inventory framework or a new engine before the short loop is convincing.

Use licensed independent assets with preserved attribution. Keep dependency/engine versions in technical documentation, but identify project development through Git commits rather than release-numbered folders.
