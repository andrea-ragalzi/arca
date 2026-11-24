# ARCA gameplay prop set

Each packed scene has a floor-level `Node3D` root and a `Meshes` group. Flat pickups place their bottom on the root Y plane. The terminal and frames face −Z. Props are original ARCA MIT additions that reuse modular kit materials.

| Scene | Placement envelope (m) | Special nodes |
| --- | --- | --- |
| keycard | 0.12 × 0.015 × 0.08 | — |
| checkpoint_terminal | 0.8 × 1.6 × 0.6 | `Screen` |
| note_clipboard | 0.29 × 0.04 × 0.39 | — |
| locked_door_frame | 4.2 × 4.8 × 0.6 | `StatusLight`, `Solid` |
| lift_doors | 3.3 × 3.5 × 0.45 | — |
| ammo_box | 0.58 × 0.24 × 0.38 | — |
| medkit_case | 0.60 × 0.24 × 0.45 | — |
| fuse | 0.62 × 0.24 × 0.24 | — |

All props are script-free. The door frame alone has layer-1 collision and a 3 × 3.4 m clear opening. Instance props beneath gameplay nodes to retain the existing interaction range and behavior.

Run `godot --headless --path . -s res://arca/tools/assets/check_props.gd` after importing. The contact sheet is at `.artifacts/d02-preview/props.png` in the main checkout. Each prop is individually framed.
