extends "res://arca/tests/mission_test.gd"

func run() -> void:
	await reset_mission()
	var actor: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	check(actor.get("behavior") != null, "The mission configures the sensory predator behavior")
	if actor.get("behavior") != null:
		await perception_checks(actor)
		await pack_checks()
	print("PREDATOR PERCEPTION RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(1 if failures else 0)

func place(actor: ArcaRaptor, position: Vector3, yaw: float) -> void:
	actor.global_position = position
	actor.rotation.y = yaw
	actor.velocity = Vector3.ZERO
	actor.reset_physics_interpolation()

func perception_checks(actor: ArcaRaptor) -> void:
	place(actor, Vector3(0, 0.05, -8), PI)
	await move_player(Vector3(0, 0.05, -11.5))
	actor.combat_enabled = true
	await frames(30)
	check(actor.state == ArcaRaptor.State.WAIT, "An idle raptor cannot see Regina behind its field of view")
	await move_player(Vector3(0, 0.05, -4.5))
	await frames(55)
	check(actor.get_status_text().contains("STALKING"), "Visible Regina is observed before pursuit")
	var sighting: Vector3 = actor.get("last_known_position")
	var barrier := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6, 3, 0.2)
	shape_node.shape = shape
	barrier.add_child(shape_node)
	barrier.position = Vector3(0, 1.5, -6.15)
	room.add_child(barrier)
	await move_player(Vector3(1.8, 0.05, -3.75))
	await frames(135)
	var remembered: Vector3 = actor.get("last_known_position")
	check(remembered.distance_to(sighting) < 0.3, "Occlusion preserves the prior sighting instead of tracking through a wall")
	check(actor.get_status_text().contains("SEARCHING"), "Lost contact leads to a bounded search")
	actor._change_state(ArcaRaptor.State.WAIT)
	room.player.shot_fired.emit()
	await frames(5)
	check(actor.get_status_text().contains("INVESTIGATING"), "A nearby shot can be investigated through cover")


func pack_checks() -> void:
	await reset_mission()
	var caller: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	var listener: ArcaRaptor = room.get_node("SecurityCorridor/SleepingRaptor")
	place(caller, Vector3(0, 0.05, -8), PI)
	place(listener, Vector3(-2.1, 0.05, -8.6), 0)
	listener._change_state(ArcaRaptor.State.WAIT)
	await move_player(Vector3(0, 0.05, -4.5))
	listener.combat_enabled = true
	caller.combat_enabled = true
	await frames(7)
	check(caller.state == ArcaRaptor.State.ALERT and caller.voice.playing,
		"The first raptor sounds an alert after sighting Regina")
	check(listener.state == ArcaRaptor.State.INVESTIGATE and listener.voice.playing
		and listener.last_heard_position.distance_to(caller.global_position) < 0.3
		and not listener.last_known_position.is_finite(),
		"The second hears and investigates the caller's location without sharing Regina's position")
	var committed := [ArcaRaptor.State.ATTACK, ArcaRaptor.State.POUNCE, ArcaRaptor.State.SLASH]
	var simultaneous := false
	var engaged := false
	var closest := INF
	for tick in 270:
		await frames(1)
		var caller_attacks := caller.state in committed
		var listener_attacks := listener.state in committed
		engaged = engaged or caller_attacks or listener_attacks
		simultaneous = simultaneous or (caller_attacks and listener_attacks)
		closest = minf(closest, caller.global_position.distance_to(listener.global_position))
	check(engaged and not simultaneous and closest > 0.7,
		"Nearby raptors enter combat without overlapping or committing together")
