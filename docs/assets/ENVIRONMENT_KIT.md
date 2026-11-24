# ARCA environment kit

The kit uses cold painted metal, recessed gaskets, amber safety details and cyan fixtures for an industrial research facility. Each module is a directly instantiable scene under `arca/assets/environment/kit/`. Its visual mesh batches geometry by shared material. Solid modules carry simple layer-1 box collision.

| Scene | Width × height × depth (m) | Use |
| --- | --- | --- |
| `wall_4m.tscn` | 4 × 4.5 × 0.5 | Two-bay partition with finished faces on both sides |
| `wall_2m.tscn` | 2 × 4.5 × 0.5 | Half-length partition using the same face pattern |
| `doorway_frame.tscn` | 4 × 4.5 × 0.5 | Wall replacement with a 1.8 m wide × 2.6 m tall opening and three collision boxes |
| `floor_tile.tscn` | 4 × 0.5 × 4 | Structural deck with access-plate seams and continuous collision |
| `pillar.tscn` | 0.5 × 4.5 × 0.5 | Full-height column for corners and transitions |
| `pipe_run.tscn` | 4 × 0.5 × 0.5 | Straight coolant pipe with collars |
| `cable_tray.tscn` | 4 × 0.5 × 0.5 | Overhead open ladder tray with bundled cables |
| `light_strip.tscn` | 2 × 0.5 × 0.5 | Wall-mounted cyan emissive fixture |
| `vent_grille.tscn` | 1.5 × 1 × 0.5 | Wall-mounted louvred return grille |
| `crate.tscn` | 1.5 × 1 × 1 | Solid equipment crate |
| `console.tscn` | 1.5 × 1.5 × 0.5 | Solid terminal block with a dark display and status indicators |

## Place the kit

- Use 0.5 m translation snapping and 90° Y rotation increments for structural modules. Instance floor tiles on 4 m centres. The floor pivot sits on the walking plane at local Y = 0, with the slab underneath. Other pivots are centred on the bottom of the module envelope. Rotate a floor tile 180° around X or Z and raise its pivot to 4.5 m for a matching ceiling.
- Walls, doorways and service runs extend along local X. The detailed face of the doorway, pillar, vent, light and console points toward local +Z. Put adjacent wall centres half the sum of their widths apart. Swap a 4 m wall instance for a doorway at the same transform.
- The doorway has no threshold. Keep its jamb and header boxes independent when fitting a door leaf or routing navigation. The kit supplies the aperture and collision. A placed door interaction or navigation bake belongs to the receiving level.
- Pipe, tray, fixture and vent instances are nonblocking dressing. Mount them on or above structural collision and keep the visible geometry out of traversable clearances.
- The shared materials are `wall_panel`, `floor_plate`, `hazard_trim`, `pipe`, `light_emissive`, `dark_glass`, `frame`, `gasket` and `indicator`. Emission marks a light source visually. Add a local light in the receiving scene when it needs to illuminate surroundings.

## Rebuild and inspect

From the ARCA root, use Godot 4.5.1 Standard.

```bash
GODOT_BIN="${GODOT_BIN:-$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64}"
"$GODOT_BIN" --headless --path . -s res://arca/tools/assets/build_environment_kit.gd
"$GODOT_BIN" --headless --audio-driver Dummy --fixed-fps 60 --path . -s res://arca/tests/environment_kit_test.gd
bash scripts/check.sh
```

Edit the generator when changing the source geometry or palette. Regeneration replaces the generated scenes and materials. The suite checks module envelopes and origins, collision setup, visible and physical doorway clearance, triangle caps and preview coverage.

To review locally, open `kit_preview.tscn` in an editor checkout containing the kit and press **F6** to run that scene. The ARCA project's **F5** entry point runs the mission. In the 3D editor, preview `ServiceCamera` for the second angle. Check the panel seams under grazing light, the jamb markings, and how the floor and ceiling tile at the wall edge. The local X11/Compatibility captures are `.artifacts/d01-preview/corridor.png` and `.artifacts/d01-preview/service.png`.
