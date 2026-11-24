# ARCA area dressing and atmosphere

The area builder dresses all four spaces, including the inherited maintenance room, with the shared station wall family, resin floor, 0.60 m panel ceiling and surface luminaires. Rooms are 2.65 m high and the security corridor 2.50 m, with raised 3.10 m bays over the two authored raptor leaps. Existing floor-level collision, opening widths, navigation resource and gameplay marker transforms are preserved; route door heads are 2.40 m.

The connected mission uses the shared `station_interior.tres` Environment. Neutral white ceiling luminaires lead along the corridor toward the red locked lift gate. The office adds habitat displays and a lit Third Energy conductor at the telemetry rack. The lift hall uses a neutral freight inspection pool and a red local fault beacon. Transfer-pump and lift equipment hums and the condensate drip use short-range 3D emitters. The area-specific Environment files remain available for standalone viewing.

Rebuild with `godot --headless --path . -s res://arca/tools/build_areas.gd`. See the [style guide](../../ENVIRONMENT_STYLE_GUIDE.md) for station conventions and the [review record](../tasks/S2-10.md) for the operational roles. [S2-11](../tasks/S2-11.md) records the current captures, heights and timings.
