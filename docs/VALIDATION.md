# Validation

Validated on 2026-10-16 with **Godot 4.5.1 Standard** on Linux using the Compatibility renderer. Run `bash scripts/check.sh` to reproduce the import and headless suites.

| Suite | Checks passed | Coverage |
| --- | ---: | --- |
| `first_playable_test.gd` | 42 | Real TPS input, movement, aiming, projectiles, cover, laser damage, death, pause and restart |
| `raptor_test.gd` | 24 | Imported animation clips, detection, navigation around cover, bite windup/dodge/occlusion, death and actual weapon hits |
| `mission_test.gd` | 28 | Real E input, pickup/installation, missing-fuse feedback, interaction occlusion, animated door collision, completion and mission reset |
| `ambush_test.gd` | 17 | Dormant immunity/collision, power trigger, warning, pause timing, single activation, navigation, death/restart cancellation and escape without a kill |
| **Total** | **111** | Logic and physics checks against actual scenes |

The new ambush suite restores power through the actual interaction input path. It does not require killing the predator to complete the mission. The existing raptor suite separately verifies that actual player projectiles can kill it.

Additional checks: shell syntax for all launch/check scripts; parsing of Zed JSON; repository skill frontmatter validation; scene/material UID alignment with tracked import settings; archive extraction and clean Godot import. Git caches and local outputs are excluded from the archive, while `.uid` and source-side `.import` settings are included.

Rendered captures of the actual mission before and after power restoration were inspected using a software OpenGL GPU on a virtual X11 display. These checks confirm the English HUD, room, opened door, alarm and visible predator; they are not NVIDIA performance measurements. The capture script stages mission state for inspection and is not a manual completion of the mission.

An optional visual helper is `arca/tests/capture_mission.gd`. It requires a display; run Godot with `-s res://arca/tests/capture_mission.gd -- /absolute/output/directory` after importing. `capture.gd`, `capture_raptor.gd` and `shadows_test.gd` remain optional diagnostic tools outside the standard headless command.

## Known limits

- The predator appears at `AmbushSpawn` after the warning; no animated hatch breach exists yet.
- Art, character, sound design and level geometry remain temporary; the enemy is not a scientific species reconstruction.
- Ammunition is unlimited; inventory and progress reset on restart. No save/load system exists.
- Zed settings/tasks were syntax checked, not exercised in the user's installed Zed/ACP version. Explicit file-reading prompts provide a fallback if agent or skill auto-discovery differs.
- The final game feel, aiming comfort and frame rate still require an F5 playtest on the user's PC.
