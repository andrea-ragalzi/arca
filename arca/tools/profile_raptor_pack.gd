extends SceneTree
## Launch through X11 without fixed FPS. Pass 1, 2 or 3 after --.

func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var count := int(arguments[0]) if arguments.size() == 1 else 0
	if count < 1 or count > 3:
		printerr("Pass a pack size from 1 to 3.")
		quit(1)
		return
	var room: Node3D = load("res://arca/pack_arena.tscn").instantiate()
	root.add_child(room)
	var actors: Array[ArcaRaptor] = room.get_predators()
	for index in range(count, actors.size()):
		actors[index].queue_free()
	actors.resize(count)
	await create_timer(1.0).timeout
	var starts := [Vector3(0, 0.05, -5.7), Vector3(-2.1, 0.05, -5.55), Vector3(2.2, 0.05, -5.5)]
	var initial := _counters(actors)
	var initial_queries := _queries(actors)
	var utility_times: Array[float] = []
	var ai_times: Array[float] = []
	var godot_process: Array[float] = []
	var collect_tick := func():
		var utility_usec := 0
		var full_usec := 0
		for actor: ArcaRaptor in actors:
			utility_usec += actor.decision_cost_usec
			full_usec += actor.ai_update_cost_usec
		if utility_usec > 0:
			utility_times.append(utility_usec / 1000.0)
		ai_times.append(full_usec / 1000.0)
	physics_frame.connect(collect_tick)
	room.player.health_component.cooldown_remaining = 12.0
	for index in count:
		var actor := actors[index]
		actor.global_position = starts[index]
		var direction: Vector3 = room.player.global_position - actor.global_position
		actor.rotation.y = atan2(-direction.x, -direction.z)
		actor._change_state(ArcaRaptor.State.WAIT)
		actor.reset_physics_interpolation()
	var frame_times: Array[float] = []
	var started := Time.get_ticks_usec()
	var last := started
	while last - started < 6000000:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		frame_times.append((now - last) / 1000.0)
		godot_process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		last = now
	physics_frame.disconnect(collect_tick)
	frame_times.sort()
	utility_times.sort()
	ai_times.sort()
	godot_process.sort()
	var totals := _counters(actors) - initial
	var average := (last - started) / (1000.0 * frame_times.size())
	print("PACK PROFILE | %d raptors | %d frames | mean %.2f ms | P95 %.2f ms | P99 %.2f ms | %d paths | %d perception samples | %d sight rays"
		% [count, frame_times.size(), average, frame_times[int((frame_times.size() - 1) * 0.95)],
		frame_times[int((frame_times.size() - 1) * 0.99)], totals.x, totals.y, totals.z])
	print("PACK AI | %d raptors | %d explicit physics queries | utility active P95 %.3f ms (%d ticks) | controller P95 %.3f ms | Godot process P95 %.3f ms"
		% [count, _queries(actors) - initial_queries, utility_times[int((utility_times.size() - 1) * 0.95)] if not utility_times.is_empty() else 0.0,
			utility_times.size(),
			ai_times[int((ai_times.size() - 1) * 0.95)], godot_process[int((godot_process.size() - 1) * 0.95)]])
	room.stop_audio()
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit()


func _counters(actors: Array[ArcaRaptor]) -> Vector3i:
	var values := Vector3i.ZERO
	for actor in actors:
		values += Vector3i(actor.path_requests, actor.perception_samples, actor.visibility_checks)
	return values


func _queries(actors: Array[ArcaRaptor]) -> int:
	var total := 0
	for actor: ArcaRaptor in actors:
		total += actor.physical_queries
	return total
