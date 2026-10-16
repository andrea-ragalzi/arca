# Validation

Validated on 2026-10-17 with **Godot 4.5.1 Standard** on Linux using the Compatibility renderer. Run `bash scripts/check.sh` to reproduce the import and headless suites.

| Suite | Checks passed | Coverage |
| --- | ---: | --- |
| `first_playable_test.gd` | 42 | Real TPS input, movement, aiming, projectiles, cover, laser damage, death, pause and restart |
| `raptor_test.gd` | 24 | Imported animation clips, detection, navigation around cover, bite windup/dodge/occlusion, death and actual weapon hits |
| `mission_test.gd` | 52 | Mission interactions/lifecycle, corridor visibility/occlusion, actual walking and return timing, camera clearance, predator traversal both ways |
| `ambush_test.gd` | 44 | Dormancy, real hatch collision/motion, continuous physical emergence, phase-specific pause/death/restart/completion, threshold obstruction, emergence death, single activation and navigation |
| **Total** | **162** | Logic and physics checks against actual scenes |

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

The scripted ordinary-walking return measured **19.6 simulated seconds**, including brief settling at six waypoints. On **2026-10-17**, the user reported: "The service corridor works in my F5 playtest." The corridor is accepted by the user. No human timing measurement or separate camera/performance observations were supplied; do not treat the automated timing or staged captures as those measurements.

Software-OpenGL staged captures were generated using `capture_mission.gd` and inspected for the initial view, entrance, alcove screen and fuse. The helper now captures those corridor views as well as the original start/ambush views. Captures are local ignored artifacts under `.artifacts/corridor-captures/`; they do not establish human route timing, GPU performance or final visual acceptance. The rendered run reports existing X11 input-method/V-Sync warnings on this software display, not gameplay script errors. The navigation bake reports its existing agent-height voxel-rounding warning.

## Physical service-hatch entrance

Implemented on 2026-10-17 with mission-only primitive bay/hatch geometry, existing warning lights/signage and the existing raptor Walk clip. The bay reuses the corridor partition as its back wall. Power starts a 1.4-second warning, one second of physical hatch opening, then about 2.3 seconds of collision-aware emergence before the existing alert/combat flow. The exit opens independently and needs no kill.

`bash scripts/check.sh` passed using the existing local ripgrep PATH workaround: **162 gameplay checks and 13 launcher checks, zero failures**, with no script/runtime errors. The unchanged first-playable (42), raptor (24) and mission (52) suites passed, including real projectile kills and corridor traversal. The extended ambush suite passed **44 checks** covering:

- Closed/moving/cleared hatch collision; sign sightline above cover from the panel approach; hidden, non-solid and immune dormancy.
- The same raptor revealed inside the bay, continuous physics movement through the opening, Walk animation/telemetry, no wall contact or early bite damage, and real subsequent navigation progress.
- Separate pause freezes during warning, opening and emergence; death, restart and kill-optional completion cancellation during each phase; no duplicate activation or predator.
- A player obstructing the threshold blocks emergence without clipping or bites; moving away allows handoff. Weapon hits can kill the emerging raptor without a later revival/movement callback.

Mission navigation was rebaked against static bay geometry with the movable leaf clear/excluded. To reproduce in the editor, temporarily raise `ServiceHatch/Leaf` from Y `1.5` to `4.8`, bake/save the mission navigation resource, then restore the leaf to Y `1.5` before saving the scene. Keep the bay walls and closed powered-exit barrier in the bake. The bake reports agent-height voxel rounding and, in the temporary headless bake helper, navigation-map cell-size/height mismatch warnings; the normal gameplay gate reports no script/runtime errors. No navigation settings or warning suppression was changed.

`capture_mission.gd` now stages the panel sightline, closed hatch, partially open hatch, raptor inside the open bay and raptor outside, as well as the accepted corridor views. Rendered using X11/Compatibility and Mesa llvmpipe software OpenGL; captures are ignored under `.artifacts/hatch-captures/`. X11 input-method and unsupported V-Sync warnings remain on this software display. These captures are visual inspection aids, not a human F5 playtest or GPU performance measurement.

Editor diagnostics for the changed mission, raptor and ambush GDScript files report no errors or warnings. The aggregate editor report is not clean: it also attempts to parse Markdown as GDScript (for example, README prose produces "Unexpected identifier ... in class body") and reports Markdown line-length warnings. These are separate from the passing Godot import/gameplay gate; no editor/language-server configuration was changed.

Revalidated the unchanged implementation on 2026-10-17 during the hatch-acceptance task: **162 gameplay checks and 13 launcher checks passed, zero failures**, including all 44 ambush checks. Import and the full gameplay gate reported no script/runtime errors. The plain `bash scripts/check.sh` invocation first stopped because `rg` was absent from PATH; rerunning with the existing `.artifacts/baseline-tools/ripgrep/usr/bin/` directory prepended passed. No gameplay, test, engine or dependency changes were needed.

Manual acceptance completed on 2026-10-17: the user answered "yes" when asked whether the service hatch also passed the three-step F5 checklist in `README.md`. Record the hatch as accepted, including its readability/reaction comfort. The task is closed through documentation only, with no gameplay fixes needed. This is user-reported F5 acceptance, separate from the automated revalidation and staged captures; no human timing or GPU performance measurements were supplied.

## Known limits

- The hatch is a primitive sliding panel and shallow bay, not bespoke dinosaur breach animation, final environment art or new sound design.
- Art, character, sound design and level geometry remain temporary; the enemy is not a scientific species reconstruction.
- Ammunition is unlimited; inventory and progress reset on restart. No save/load system exists.
- Zed settings/tasks were syntax checked, not exercised in the user's installed Zed/ACP version. Explicit file-reading prompts provide a fallback if agent or skill auto-discovery differs.
- Hatch F5 acceptance does not establish broader aiming comfort, final polish or frame rate on the user's PC.
