# Validation

Validated on 2026-10-16 with **Godot 4.5.1 Standard** on Linux using the Compatibility renderer. Run `bash scripts/check.sh` to reproduce the import and headless suites.

| Suite | Checks passed | Coverage |
| --- | ---: | --- |
| `first_playable_test.gd` | 42 | Real TPS input, movement, aiming, projectiles, cover, laser damage, death, pause and restart |
| `raptor_test.gd` | 24 | Imported animation clips, detection, navigation around cover, bite windup/dodge/occlusion, death and actual weapon hits |
| `mission_test.gd` | 52 | Mission interactions/lifecycle, corridor visibility/occlusion, actual walking and return timing, camera clearance, predator traversal both ways |
| `ambush_test.gd` | 17 | Dormant immunity/collision, power trigger, warning, pause timing, single activation, navigation, death/restart cancellation and escape without a kill |
| **Total** | **135** | Logic and physics checks against actual scenes |

The new ambush suite restores power through the actual interaction input path. It does not require killing the predator to complete the mission. The existing raptor suite separately verifies that actual player projectiles can kill it.

Additional checks: shell syntax for all launch/check scripts; parsing of Zed JSON; repository skill frontmatter validation; scene/material UID alignment with tracked import settings; archive extraction and clean Godot import. Git caches and local outputs are excluded from the archive, while `.uid` and source-side `.import` settings are included.

Rendered captures of the actual mission before and after power restoration were inspected using a software OpenGL GPU on a virtual X11 display. These checks confirm the English HUD, room, opened door, alarm and visible predator; they are not NVIDIA performance measurements. The capture script stages mission state for inspection and is not a manual completion of the mission.

An optional visual helper is `arca/tests/capture_mission.gd`. It requires a display; run Godot with `-s res://arca/tests/capture_mission.gd -- /absolute/output/directory` after importing. `capture.gd`, `capture_raptor.gd` and `shadows_test.gd` remain optional diagnostic tools outside the standard headless command.

## Local baseline checkpoint

Rechecked on 2026-10-16 with `/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64`, reporting `4.5.1.stable.official.f62fdbde1`. All four suites above passed again: **111 checks, zero failures**. No gameplay scripts or test assertions were changed.

Reviewed and retained the editor/import changes:

- `project.godot`: expanded E/R input-event serialization preserves physical E/R bindings and default device/modifier values. Omitted window-mode and 3D-scaling settings still resolve to `0` (windowed and bilinear). Compatibility rendering is unchanged. A headless settings probe confirmed the effective values and bindings.
- The 15 texture `.import` files reflect Godot's 3D detection: lossless storage changes to lossy VRAM/S3TC compression, mipmaps are enabled, and the one-time 3D-detection callback is disabled. The format/path metadata describes the resulting imported resources; it is not just a cosmetic rename. Compression can introduce block artifacts, while mipmaps reduce distant shimmer and add mip-level storage. Source dimensions, size limits, texture UIDs and quality-slider values are unchanged.
- Three normal maps now explicitly enable normal-map compression. The robot/player normal textures disable their own roughness processing; their ORM textures reference the associated normal maps for roughness mip generation. Corrected the two ORM `roughness/mode` values from out-of-range `8` to `3` (Green), matching the materials' green roughness channel. Godot 4.5.1's texture importer defines modes `0–6`; see the [pinned importer source](https://github.com/godotengine/godot/blob/4.5.1-stable/editor/import/resource_importer_texture.cpp).

The first check attempt stopped because ripgrep was missing. Without changing system packages, Ubuntu's `ripgrep` 14.1.0 package was downloaded and extracted under ignored `.artifacts/baseline-tools/`. The successful command was:

```bash
PATH="$PWD/.artifacts/baseline-tools/ripgrep/usr/bin:$PATH" bash scripts/check.sh
```

The extracted tool, settings probe and test logs are local artifacts, not checkpoint content. For the normal check command without a PATH override, install ripgrep as described in the README. Headless checks do not establish rendered texture quality, visual polish or GPU performance; manual F5 verification remains required.

## Service corridor: route and camera experiment

Implementation adds a mission-only partition, screened fuse alcove, yellow entrance/return signage and floor guide. The initial camera heading frames the entrance. One inherited crate is moved only in the mission, and a thin colliding wall lining keeps the existing spring arm ahead of inherited decorative wall panels. Movement, camera-controller code, shooting and ambush timing are unchanged.

Focused regression coverage now includes initial entrance framing/sightline, fuse concealment from sampled main-room positions, blocked interaction through the actual partition while within pickup range, player movement against the partition, actual root-motion walking from spawn through the corridor and around the screen, the walked return and panel activation, camera clearance at the alcove, and raptor travel into and out of the corridor. These are logic/physics checks, not proof of universal visibility or camera comfort.

Rechecked with Godot 4.5.1 after the corridor changes: **135 gameplay checks and 13 launcher checks passed with zero failures**, using the documented local ripgrep PATH workaround. `git diff --check` passed in both the ARCA root and the nested `arca` Git worktree. No commits were made in either worktree.

The scripted ordinary-walking return measured **19.6 simulated seconds**, including brief settling at six waypoints. Manual F5 acceptance is pending: verify entrance recognition from spawn, actual exploration to find the fuse, and roughly 10–20 seconds from fuse pickup to the panel prompt while walking normally without inspection stops. Test camera rotation at both turns, returning from the alcove and near the outer wall; try jumping against the partitions, then complete the original ambush/escape loop and restart.

Software-OpenGL staged captures were generated using `capture_mission.gd` and inspected for the initial view, entrance, alcove screen and fuse. The helper now captures those corridor views as well as the original start/ambush views. Captures are local ignored artifacts under `.artifacts/corridor-captures/`; they do not establish human route timing, GPU performance or final visual acceptance. The rendered run reports existing X11 input-method/V-Sync warnings on this software display, not gameplay script errors. The navigation bake reports its existing agent-height voxel-rounding warning.

## Known limits

- The predator appears at `AmbushSpawn` after the warning; no animated hatch breach exists yet.
- Art, character, sound design and level geometry remain temporary; the enemy is not a scientific species reconstruction.
- Ammunition is unlimited; inventory and progress reset on restart. No save/load system exists.
- Zed settings/tasks were syntax checked, not exercised in the user's installed Zed/ACP version. Explicit file-reading prompts provide a fallback if agent or skill auto-discovery differs.
- The final game feel, aiming comfort and frame rate still require an F5 playtest on the user's PC.
