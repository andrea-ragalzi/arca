extends SceneTree
## Optional visual capture with an active display; not a performance benchmark.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var scene: Node3D = load("res://arca/test_room.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 100:
		await physics_frame
	await RenderingServer.frame_post_draw
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var destination: String = args[0] if not args.is_empty() else "user://ARCA_Prototipo.png"
	root.get_texture().get_image().save_png(destination)
	print("Saved gameplay capture: ", destination)
	scene.stop_audio()
	scene.queue_free()
	await process_frame
	Engine.max_fps = 60
	for i in 15:
		await process_frame
	quit()
