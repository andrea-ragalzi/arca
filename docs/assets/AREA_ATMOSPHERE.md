# ARCA area dressing and atmosphere

The area builder fits the D-01 wall panels, floor plates and console meshes over the existing collision volumes. It shares each kit mesh across repeated tiles. Wall heights, gate openings, static collision and gameplay markers keep their original dimensions and transforms.

The security corridor uses cool pools with a warmer office opening and red lift approach. The office has warmer desk lighting and cyan console light. The lift hall uses cool general light, cyan at the cabin and a local red accent. Each area's own lights are built into its scene.

The Environment files under `arca/assets/environment/atmosphere/` provide Compatibility ambient and fog presets for viewing each area on its own. The live connected mission uses one shared WorldEnvironment and the styled local lights. This keeps exposure consistent through doorways.

Rebuild with `godot --headless --path . -s res://arca/tools/build_areas.gd`. For reference, the rendered views of live world lighting are in `.artifacts/d05-preview/` in the main checkout. F5 and F3 in S1-12 provide the final mood and performance review.
