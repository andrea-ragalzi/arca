# ARCA interior style guide

Continuity Station is a scientific and industrial facility. Give each asset a job in habitat care, Third Energy monitoring, transfer operations, staff shelter or evacuation. Build original station equipment and markings around those functions.

## Architecture

Maintenance, security, the control office and the lift hall read as adjoining departments of one research station. They share one wall family, floor, ceiling and luminaire; furnishings, light and local wear give each room its character. Measure every height from the local finished floor.

| Element | Convention |
| --- | --- |
| Scale | One Godot unit is one metre. Model access panels, drawers and work surfaces for a standing operator. |
| Walls | Steel skirting 0.00-0.10 m, washable grey-green band 0.10-1.10 m and clinical white above, in 2.00 m bays with a 0.18 m nominal module. Fit the two end bays to the existing footprint. The module scales to the shell thickness; world triplanar finishes keep their texture density. |
| Clear height | Rooms 2.65 m. Security corridor 2.50 m, with services beside the passage. Keep the lowest point of fittings over the main path at 2.30 m or higher. |
| Raised bays | 3.10 m over the corridor crate leap and the maintenance diagnostic table. Close each change of height with a white soffit step and a steel edge. |
| Openings | Route openings stay 3.0 m wide for the predators' navigation (0.6 m agent radius) and the existing 3.2 m door leaves. The head is 2.40 m so the default TPS arm does not contract on each threshold. Frames use industrial blue. The live-cargo hatch head is 2.25 m to carry its sign. |
| Floor | One continuous opaque dark-steel resin per footprint, with mottled wear. Align finish elevation at thresholds. |
| Ceiling | Clinical white 0.60 m square panels with readable joints. World triplanar mapping keeps one grid phase and orientation across connected spaces. Collision is a downward-facing plane at the soffit. |
| Services | Support exposed spans from the wall. End conduits at a cabinet, manifold, junction or penetration with a visible collar or flange. Put rust and damp under joints that can leak. |

## Material and signal palette

The shared StandardMaterial3D resources live in `arca/assets/environment/station/`. Colours are sRGB albedo under neutral light; textures are neutral so they do not shift the palette.

| Resource | HEX | Use | Roughness / metallic |
| --- | --- | --- | --- |
| `steel_painted` / `steel_bare` / `floor_resin` | #363E40 | Skirting, brackets, pipes, grilles; handled bare metal; floor tint | 0.65 / 0; 0.48 / 0.75; 0.78 / 0 |
| `wash_band` | #777D70 | Washable band, service cabinets | 0.58 / 0 |
| `clinical_wall` / `ceiling_panel` / `ceramic` | #C5C5B5 | Upper wall, ceiling, insulators | 0.78 / 0.85 / 0.40, all 0 |
| `industrial_blue` | #304653 | Door frames, panels and technical furniture | 0.62 / 0 |
| `safety` | #BE9C3C | Dangerous thresholds, handles, operating marks | 0.70 / 0 |
| `emergency` / `emergency_alarm` | #A43832 | Alarm hardware; the lit lens only while its alarm is active | 0.70 / 0 |
| `third_energy` | #4CA8B7 | Localised emission on the conductor or instrument that carries Third Energy | 0.45 / 0 |
| `oxidation` | #635345 | Bolts, exposed scratches, rust runs under fittings | 0.90 / 0 |

- Use muted blue for numbered enamel signs. Set labels in uppercase English using the built-in Godot font. The sign module uses pale lettering on a dark plate and a narrow yellow identification stripe. Keep a strong silhouette at TPS distance.
- Keep two or three wear zones per room, tied to a cause: under a leaking flange, at a sealed bulkhead, at the base of a panel or in front of consoles. In Compatibility use small offset meshes for stains and damp. Existing interactable colours still communicate their gameplay roles.

## Lighting and sound

Place emitters in a readable housing. The connected areas share one low neutral ambient fill. Normal lamps are neutral white surface luminaires on the ceiling grid; red is limited to the failed lift gate, the freight fault and the unpowered maintenance airlock. Keep thresholds, the floor and interactions readable, with darker areas between light pools. Use at most one shadowed light per area.

Put looped audio at equipment or leaks with a short audible radius. Distinguish the transfer pump and lift extractor from the condensate drip by source, range and timbre. Keep local cues beneath mission warnings and predator calls.

## Reuse

| Use | Source |
| --- | --- |
| Walls | `station/wall_bay.tscn` for a full bay, `wall_opening.tscn` for the frame and header infill of an opening, `wall_corner.tscn` for an external corner guard and `wall_corner_joint.tscn` for the internal corner cove |
| Floor and ceiling | `station/floor_resin.tres`, `station/ceiling_panel.tres` (`ceiling_panel_grid.png` from `arca/tools/assets/build_station_textures.gd`) |
| Lighting | `station/ceiling_luminaire.tscn` |
| Utilities and fittings | `kit/vent_grille.tscn`, `kit/pillar.tscn`; pipes, flanges and trunking from `build_areas.gd` |
| Controls | `kit/console.tscn` for a standing station, `kit/instrument_display.tscn` for mountable telemetry |
| Identification | `station_sign()` in `arca/tools/build_areas.gd` for the enamel plate, stencil and stripe |

The kit catalogue still describes the D-01 modules. The route no longer uses `wall_2m`, `wall_4m`, `floor_tile`, `ceiling_bay`, `bulkhead_trim`, `strip_luminaire`, `pipe_run` or `cable_tray`; they remain for the kit preview and other rooms. The area builder assembles scenes offline while keeping art and collision explicit: walls and lintels carry simple box collision, ceilings a one-sided plane. Do not override materials on instanced station modules. Keep wear meshes small and offset them slightly from the base surface. Use simple shapes for objects that need collision and keep the authored routes and approach space clear. [Environment kit catalogue](docs/assets/ENVIRONMENT_KIT.md)

## Environment review

Run the area builder with Godot 4.5.1 Standard. Inspect the finished mission using X11 and the Compatibility renderer. Run the area and route checks after editing room shells; they assert soffit heights, shared finishes and 2.30 m overhead clearance over the main path. Inspect door openings, corners and soffits with the TPS spring arm in motion at both pitch limits and while aiming. Record the hardware, render resolution and sampling method with the frame timings. The screen and light loops use small local effects and require no GI or screen-space reflections.

The [interior task record](docs/tasks/S2-10.md) maps the mission areas to their operational roles. The [station finish record](docs/tasks/S2-11.md) holds the measured heights, captures and timings of the shared finish.
