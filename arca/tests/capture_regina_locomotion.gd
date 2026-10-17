extends SceneTree
## Optional staged Compatibility captures; requires a display, not a headless test.
## Usage: godot --path . -s res://arca/tests/capture_regina_locomotion.gd -- /absolute/output


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 1 or not arguments[0].is_absolute_path():
		push_error("Supply one absolute capture output directory after --")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(arguments[0]) != OK:
		push_error("Cannot create capture output directory")
		quit(1)
		return
	var scene: Node3D = load("res://arca/character_locomotion_test.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_physics_process(false)
	scene.set_process(false)
	if not scene.valid:
		quit(1)
		return
	for view in 3:
		var grid := Image.create(1440, 1440, false, Image.FORMAT_RGBA8)
		for row in 3:
			var clip: StringName = [&"idle", &"walk", &"run"][row]
			for column in 4:
				scene.select_clip(clip)
				scene.set_translating(false)
				var animation: Animation = scene.LIBRARY.get_animation(clip)
				scene.advance_locomotion(animation.length * column / 4.0)
				scene.paused = true
				scene.view_index = view + 1
				scene._process(0.0)
				for frame in 3:
					await process_frame
				await RenderingServer.frame_post_draw
				var image: Image = root.get_texture().get_image()
				var name: String = "%s_%s_%02d.png" % [clip, ["front", "side", "back"][view], column]
				if image.save_png(arguments[0].path_join(name)) != OK:
					push_error("Cannot save capture: " + name)
					quit(1)
					return
				var width: int = roundi(image.get_width() * 650.0 / image.get_height())
				image.resize(width, 650)
				image.convert(Image.FORMAT_RGBA8)
				grid.blit_rect(image, Rect2i(floori((width - 360) * 0.5), 100, 360, 480),
					Vector2i(column * 360, row * 480))
		var path: String = arguments[0].path_join(["front", "side", "back"][view] + "_grid.png")
		grid.save_png(path)
		print("CAPTURE: ", path, " | rows idle/walk/run, columns phase 0/25/50/75 percent")
	scene.queue_free()
	await process_frame
	quit()
