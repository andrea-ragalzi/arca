extends SceneTree
## Render the corridor and physical hatch entrance; requires a display.

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Could not save capture: " + path)
	print("Mission capture: ", path)

func run() -> void:
	var room: Node3D = load("res://arca/mission_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var directory: String = args[0] if not args.is_empty() else "user://"
	for i in 60:
		await physics_frame
	await capture(directory.path_join("mission_start.png"))
	for view in [
			["corridor_entrance.png", Vector3(9.4, 0.05, -7), 0.0],
			["corridor_screen.png", Vector3(9.4, 0.05, 4), 0.0],
			["corridor_fuse.png", Vector3(8.5, 0.05, 8.8), -PI / 2.0]]:
		room.player.position = view[1]
		room.player.player_input.camera_base.rotation.y = view[2]
		room.player.reset_physics_interpolation()
		for i in 20:
			await physics_frame
		await capture(directory.path_join(view[0]))
	room.fuse.collect()
	room.player.position = Vector3(-8.8, 0.05, 5.1)
	room.player.player_input.camera_base.rotation.y = 1.27
	room.player.reset_physics_interpolation()
	for i in 20:
		await physics_frame
	await capture(directory.path_join("hatch_panel_view.png"))
	# Stage a closer view; captures do not establish human reaction time.
	room.player.position = Vector3(-2, 0.05, 5.5)
	room.player.player_input.camera_base.rotation.y = 0.94
	room.player.reset_physics_interpolation()
	for i in 20:
		await physics_frame
	await capture(directory.path_join("hatch_closed.png"))
	room.panel.activate(room.has_fuse)
	for i in 120:
		if room.ambush_phase == room.AmbushPhase.OPENING:
			break
		await physics_frame
	for i in 24:
		await physics_frame
	await capture(directory.path_join("hatch_opening.png"))
	for i in 120:
		if room.ambush_phase == room.AmbushPhase.EMERGING:
			break
		await physics_frame
	for i in 20:
		await physics_frame
	await capture(directory.path_join("hatch_emerging.png"))
	for i in 240:
		if room.enemy.state == ArcaRaptor.State.ALERT:
			break
		await physics_frame
	room.enemy.stop_combat()
	await capture(directory.path_join("mission_ambush.png"))
	room.stop_audio()
	room.queue_free()
	await process_frame
	quit()
