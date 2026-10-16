extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var room: Node3D = load("res://arca/raptor_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	room.player.position = Vector3(0, 0.05, -3.5)
	room.enemy.position = Vector3(-1.3, 0.05, 1.5)
	Input.action_press("aim")
	room.player.reset_physics_interpolation()
	room.enemy.reset_physics_interpolation()
	for i in 80:
		await physics_frame
	await RenderingServer.frame_post_draw
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "user://ARCA_Raptor.png"
	root.get_texture().get_image().save_png(path)
	print("CAPTURE: ", path)
	for mesh in room.enemy.skin.find_children("*", "MeshInstance3D", true, false):
		var baked: ArrayMesh = mesh.bake_mesh_from_current_skeleton_pose()
		if baked:
			print("RAPTOR WORLD BOUNDS: ", mesh.global_transform * baked.get_aabb())
	room.stop_audio()
	room.queue_free()
	Engine.max_fps = 60
	for i in 15:
		await process_frame
	quit()
