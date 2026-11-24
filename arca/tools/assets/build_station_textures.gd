extends SceneTree
## Deterministically paint the neutral 0.60 m suspended-ceiling panel tile.
## Run: godot --headless --path . -s res://arca/tools/assets/build_station_textures.gd
## The tile multiplies the ceiling_panel.tres albedo, so the panel field stays
## close to white. World triplanar mapping repeats it every 0.60 m.

const OUTPUT := "res://arca/assets/environment/station/ceiling_panel_grid.png"
const SIZE := 512
## Exposed T-bar face and the shadow gap on each side of a joint, in pixels.
const BAR := 9
const GAP := 3


func _initialize() -> void:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var grain := FastNoiseLite.new()
	grain.seed = 603
	grain.frequency = 0.045
	grain.fractal_octaves = 3
	for y: int in SIZE:
		for x: int in SIZE:
			# Distance to the nearest tile edge; the joint straddles the seam.
			var edge: int = mini(mini(x, SIZE - 1 - x), mini(y, SIZE - 1 - y))
			var value: float
			if edge < BAR:
				value = 0.86
			elif edge < BAR + GAP:
				value = 0.42
			else:
				# Mineral-fibre field: faint, neutral speckle around full white.
				value = 0.97 + 0.03 * grain.get_noise_2d(x, y)
			image.set_pixel(x, y, Color(value, value, value))
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("STATION TEXTURES: ", error_string(result))
	quit(0 if result == OK else 1)
