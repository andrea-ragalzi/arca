extends "res://arca/tests/mission_test.gd"

func run() -> void:
	await reset_mission()
	check(InputMap.has_action("dodge") and room.player.has_method("try_dodge"),
		"Regina exposes a tactical sidestep through the real input map")
	if room.player.has_method("try_dodge"):
		await physical_checks()
	print("PHYSICAL COMBAT RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(1 if failures else 0)

func physical_checks() -> void:
	await move_player(Vector3(0, 0.05, -9))
	var actor: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	actor.global_position = Vector3(0, 0.05, -6)
	actor.rotation.y = 0
	actor.combat_enabled = true
	for tick in 28:
		await frames(1)
		if actor.is_on_floor():
			break
	check(actor.try_pounce(room.player.global_position), "Raptor has a clear ballistic attack lane")
	await frames(7)
	check(room.player.health_component.current == 100, "The early jump cannot deal contact damage")
	var position_before: Vector3 = room.player.global_position
	room.player.player_input.camera_base.rotation.y = 0
	check(room.player.try_dodge(1.0), "Regina can start a grounded sidestep during a pounce")
	await frames(67)
	check(room.player.global_position.x - position_before.x > 1.35 and room.player.health_component.current == 100,
		"The collision-driven sidestep physically leaves the pounce lane")

	await reset_mission()
	await move_player(Vector3(0, 0.05, -9))
	actor = room.get_node("ExitLift/FinalRaptor")
	actor.global_position = Vector3(0, 0.05, -6)
	actor.rotation.y = 0
	actor.combat_enabled = true
	for tick in 28:
		await frames(1)
		if actor.is_on_floor():
			break
	check(actor.try_pounce(room.player.global_position), "A second clear attack launches")
	var clearance := INF
	for frame in 45:
		await frames(1)
		var offset: Vector3 = actor.global_position - room.player.global_position
		if absf(offset.y) < 0.92:
			clearance = minf(clearance, offset.slide(Vector3.UP).length())
	check(clearance >= 0.87, "The pouncing capsule and Regina stay physically separate on impact")
	check(room.player.health_component.current == 100 - 26 and room.player.is_downed()
		and room.player.global_position.z < -9.3,
		"One contact inside the window knocks Regina along the actual impact direction")
	check(not room.player.try_dodge(-1.0) and not room.player.can_use_weapon(),
		"Regina cannot sidestep or fire while down")
	room.stop_all_predators()
	await frames(35)
	var event := InputEventAction.new()
	event.action = "dodge"
	event.pressed = true
	Input.parse_input_event(event)
	await frames(85)
	check(not room.player.is_downed() and room.player.can_use_weapon(), "Breaking free returns weapon control")
	await mobility_checks()
	await table_checks()
	await closed_door_check()
	await reaction_lifecycle_check()

func mobility_checks() -> void:
	await reset_mission()
	var actor: ArcaRaptor = room.get_node("SecurityCorridor/SleepingRaptor")
	var point := room.get_node("SecurityCorridor/Markers/CrateJump") as Marker3D
	var landing := point.get_node("Landing") as Marker3D
	actor.global_position = point.global_position
	actor._change_state(ArcaRaptor.State.WAIT)
	actor.combat_enabled = true
	await frames(5)
	check(actor.try_environment_jump(point), "A marked crate provides a clear arc and supported landing")
	var highest: float = actor.global_position.y
	for tick in 65:
		await frames(1)
		highest = maxf(highest, actor.global_position.y)
	check(highest >= landing.global_position.y and actor.global_position.distance_to(landing.global_position) < 0.38,
		"The raptor moves continuously onto the crate")
	var barrier := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.13)
	collision.shape = box
	barrier.add_child(collision)
	barrier.position = point.global_position.lerp(landing.global_position, 0.45) + Vector3.UP
	room.add_child(barrier)
	actor.global_position = point.global_position
	actor.velocity = Vector3.ZERO
	await frames(4)
	check(not actor.try_environment_jump(point), "A solid barrier invalidates the authored jump")


func closed_door_check() -> void:
	await reset_mission()
	var actor: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	await move_player(Vector3(0, 0.05, 42.2))
	actor.global_position = Vector3(0, 0.05, 46.0)
	actor.combat_enabled = true
	await frames(8)
	check(not actor.try_pounce(room.player.global_position), "The intact lift door blocks an attempted pounce")
	hold_navigation_target(actor, room.player.global_position)
	await frames(150)
	check(actor.global_position.z > 44.15 and room.player.health_component.current == 100,
		"A known target beyond the closed gate does not allow a predator to cross or deal damage")


func table_checks() -> void:
	await reset_mission()
	var actor: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	var table := room.get_node("MaintenanceDressing/DiagnosticWorkstation")
	var up := table.get_node("TableJump") as Marker3D
	var down := table.get_node("TableDescent") as Marker3D
	actor.global_position = up.global_position + Vector3.UP * 0.05
	actor.combat_enabled = true
	for tick in 30:
		await frames(1)
		if actor.is_on_floor():
			break
	check(actor.try_environment_jump(up), "The maintenance table is a supported leap destination")
	await frames(63)
	check(actor.global_position.y > 0.8 and actor.is_on_floor(), "The raptor lands on the worktop")
	check(actor.try_environment_jump(down), "An authored exit validates a jump down from the table")
	await frames(65)
	check(actor.global_position.y < 0.1 and actor.global_position.x < -5.2,
		"The raptor descends physically to the other side of the table")

func reaction_lifecycle_check() -> void:
	await reset_mission()
	await move_player(Vector3(0, 0.05, -9))
	var actor: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	actor.global_position = Vector3(0, 0.05, -7.6)
	actor.rotation.y = 0
	actor.combat_enabled = true
	actor._change_state(ArcaRaptor.State.SLASH)
	await frames(12)
	check(room.player.health_component.current == 100, "The claw strike waits for its contact window")
	await frames(17)
	check(room.player.health_component.current == 86, "The claw strike deals one reduced contact hit")
	actor.stop_combat()
	room.player.take_pounce_damage(10)
	await frames(42)
	room.player.take_pounce_damage(10)
	check(room.player.is_downed(), "A surviving heavy impact enters the downed state")
	room.set_paused(true)
	await frames(180)
	check(room.player.is_downed(), "Pause freezes the downed timer")
	room.set_paused(false)
	await reset_mission()
	check(room.player.can_use_weapon() and room.player.health_component.current == 100,
		"Restart cancels physical reactions and restores control")
