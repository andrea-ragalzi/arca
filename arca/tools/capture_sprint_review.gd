extends SceneTree
## Render the actual mission and a staged combat sequence under X11/Compatibility.
## Pass an existing absolute output directory after --, then optionally "pack". Use --fixed-fps 60.

var preview: SubViewport
var room: Node3D
var camera: Camera3D
var output: String
var actor: ArcaRaptor

func _initialize() -> void:
	run.call_deferred()

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func render_still(name: String, origin: Vector3, target: Vector3) -> void:
	camera.position = origin
	camera.look_at(target)
	camera.reset_physics_interpolation()
	for draw in 3:
		await RenderingServer.frame_post_draw
	var file := output.path_join(name + ".png")
	assert(preview.get_texture().get_image().save_png(file) == OK)
	print("CAPTURE: ", file)

func run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty() or arguments.size() > 2 or not DirAccess.dir_exists_absolute(arguments[0]) \
			or (arguments.size() == 2 and arguments[1] != "pack"):
		printerr("Pass an existing output directory and optionally pack.")
		quit(1)
		return
	output = arguments[0]
	preview = SubViewport.new()
	preview.size = Vector2i(1280, 720)
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(preview)
	var pack := arguments.size() == 2
	room = load("res://arca/pack_arena.tscn" if pack else "res://arca/mission_room.tscn").instantiate()
	preview.add_child(room)
	room.stop_all_predators()
	camera = Camera3D.new()
	camera.fov = 67.0
	preview.add_child(camera)
	camera.make_current()
	await ticks(15)
	if pack:
		await render_pack()
	else:
		await render_mission()
	room.stop_audio()
	room.queue_free()
	await process_frame
	preview.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit()


func render_pack() -> void:
	camera.fov = 64.0
	await render_still("pack-training", Vector3(0, 3.65, -7.0), Vector3(0, 0.85, 3.3))
	room.get_node("HUD").hide()
	camera.fov = 48.0
	await render_still("regina-front", Vector3(1.3, 1.41, -6.9), Vector3(0, 0.91, -9))
	await render_still("regina-back", Vector3(-1.2, 1.47, -11.2), Vector3(0, 0.91, -9))


func render_mission() -> void:
	room.get_node("HUD").hide()
	room.player.hide()
	await render_still("maintenance", Vector3(0.6, 2.15, -8.15), Vector3(-3.4, 1.30, -11.62))
	await render_still("office", Vector3(-7, 1.85, 25.15), Vector3(-13.5, 1.5, 26.1))
	await render_still("sleeper", Vector3(0.85, 1.75, 21.7), Vector3(-3.3, 1.46, 25.7))
	await render_still("freight", Vector3(-3.7, 1.9, 55.5), Vector3(-9, 1.9, 56.3))

	room.player.show()
	room.player.global_position = Vector3(0, 0.05, -9)
	room.player.reset_physics_interpolation()
	actor = room.get_node("ExitLift/FinalRaptor")
	actor.global_position = Vector3(0, 0.05, -6)
	actor.rotation.y = 0
	actor.reset_physics_interpolation()
	actor.combat_enabled = true
	for tick in 30:
		await ticks(1)
		if actor.is_on_floor() and room.player.is_on_floor():
			break
	assert(actor.try_pounce(room.player.global_position))
	await ticks(15)
	await render_still("pounce", Vector3(4.0, 2.35, -6.9), Vector3(0, 1.1, -7.9))
	await ticks(26)
	assert(room.player.is_downed())
	await render_still("knockdown", Vector3(3.25, 2.3, -10.3), Vector3(0, 0.55, -8.35))
	room.stop_all_predators()

	# Read back each frame so the sample includes GPU work and readback cost.
	camera.position = Vector3(-3.7, 1.9, 55.5)
	camera.look_at(Vector3(-9, 1.9, 56.3))
	for frame in 40:
		await RenderingServer.frame_post_draw
	var texture := preview.get_texture()
	var start := Time.get_ticks_usec()
	for frame in 90:
		await RenderingServer.frame_post_draw
		texture.get_image()
	var seconds := float(Time.get_ticks_usec() - start) / 1000000.0
	print("RENDER WITH READBACK: ", RenderingServer.get_video_adapter_name(), " | 1280x720 | 90 frames in ", seconds,
		" s | ", 90.0 / seconds, " frames/s")
