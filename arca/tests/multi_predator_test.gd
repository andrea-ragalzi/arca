extends "res://arca/tests/mission_test.gd"
## Several predators in one room: shared lifecycle, kill accounting and telemetry.

const RAPTOR_SCENE: PackedScene = preload("res://arca/enemies/raptor.tscn")


func load_raptor_room() -> void:
	for action in ["interact", "shoot", "aim", "move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)
	if is_instance_valid(room) and room.scene_file_path == "res://arca/raptor_room.tscn":
		room.restart_room()
		await frames(3)
		room = current_scene
	else:
		await drop_room()
		room = load("res://arca/raptor_room.tscn").instantiate()
		root.add_child(room)
		current_scene = room
	await frames(30)


func drop_room() -> void:
	if not is_instance_valid(room):
		return
	room.stop_audio()
	current_scene = null
	room.queue_free()
	room = null
	await frames(2)


func add_predator(position: Vector3) -> ArcaRaptor:
	var predator: ArcaRaptor = RAPTOR_SCENE.instantiate()
	room.add_child(predator)
	predator.position = position
	predator.reset_physics_interpolation()
	room.register_predator(predator)
	await frames(2)
	return predator


func telemetry() -> String:
	return room.hud.enemy_label.text


func raptor_room_checks() -> void:
	await load_raptor_room()
	var primary: ArcaRaptor = room.enemy
	var second: ArcaRaptor = await add_predator(Vector3(3, 0.05, 6))
	check(room.get_predators().size() == 2 and room.get_predators().has(primary) and room.get_predators().has(second),
		"The room tracks the primary and an added predator")
	primary.position = Vector3(0, 0.05, -4)
	second.health_component.current = 4
	await frames(3)
	check(telemetry() == primary.get_status_text(), "Telemetry follows the nearest predator")
	second.position = Vector3(1, 0.05, -7)
	second.reset_physics_interpolation()
	await frames(3)
	check(telemetry() == second.get_status_text() and telemetry().contains("4/6"),
		"Telemetry switches when another predator is nearer")

	await load_raptor_room()
	primary = room.enemy
	check(room.get_predators().size() == 1, "Restart restores exactly the scene's original predator count")
	primary.position = Vector3(-1.5, 0.05, -4)
	second = await add_predator(Vector3(1.5, 0.05, -4))
	var primary_start: float = primary.position.distance_to(room.player.position)
	var second_start: float = second.position.distance_to(room.player.position)
	await frames(80)
	var hunting: Array[ArcaRaptor.State] = [ArcaRaptor.State.CHASE, ArcaRaptor.State.WINDUP,
		ArcaRaptor.State.ATTACK, ArcaRaptor.State.RECOVER]
	check(primary.state in hunting and second.state in hunting
		and primary.position.distance_to(room.player.position) < primary_start - 0.5
		and second.position.distance_to(room.player.position) < second_start - 0.5,
		"Both predators detect and chase the player")
	var primary_position: Vector3 = primary.position
	var second_position: Vector3 = second.position
	var second_elapsed: float = second.elapsed
	room.set_paused(true)
	await frames(30)
	check(primary.position == primary_position and second.position == second_position
		and is_equal_approx(second.elapsed, second_elapsed),
		"Pause freezes every predator")
	room.set_paused(false)
	await frames(2)
	var bites_after_death: Array[int] = [0]
	room.player.take_damage(1000)
	primary.attack_landed.connect(func(): bites_after_death[0] += 1)
	second.attack_landed.connect(func(): bites_after_death[0] += 1)
	check(not primary.combat_enabled and not second.combat_enabled,
		"Player death stops every predator's combat")
	await frames(90)
	check(bites_after_death[0] == 0, "No predator lands a bite after the player dies")

	await load_raptor_room()
	check(room.get_predators().size() == 1 and room.enemy.combat_enabled and room.enemy.health == 6,
		"Restart after death removes added predators and restores a healthy primary")


func mission_checks() -> void:
	await drop_room()
	await reset_mission()
	var second: ArcaRaptor = await add_predator(Vector3(-5, 0.05, -2))
	second.stop_combat()
	room.register_predator(second)
	await frames(3)
	check(room.enemy.state == ArcaRaptor.State.DORMANT and telemetry() == second.get_status_text(),
		"Telemetry ignores the dormant ambush predator and reports an active one")
	check(room.get_mission_summary()["kills"] == 0 and room.get_mission_summary()["predators_total"] == 2,
		"The summary counts every predator in the mission")
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	check(room.power_restored and room.ambush_phase == room.AmbushPhase.WARNING,
		"Power starts the hatch warning with a second predator present")
	second.health_component.current = 1
	second.hit()
	await frames(2)
	var summary: Dictionary = room.get_mission_summary()
	check(second.dead and summary["kills"] == 1 and summary["predators_total"] == 2
		and summary["predator"] == "STILL ALIVE",
		"Killing a secondary predator counts one kill without changing the primary outcome")
	check(room.ambush_phase == room.AmbushPhase.WARNING and room.hud.get_node("Frame/Notice").text == "PREDATOR DOWN",
		"A secondary kill announces itself without cancelling the hatch ambush")
	for i in 200:
		if room.ambush_triggered:
			break
		await frames(1)
	check(room.ambush_triggered and room.enemy.state != ArcaRaptor.State.DORMANT,
		"The primary predator still emerges after a secondary kill")

	await reset_mission()
	second = await add_predator(Vector3(-5, 0.05, -2))
	check(room.get_mission_summary()["kills"] == 0 and room.get_mission_summary()["predators_total"] == 2,
		"Restart clears the kill count")
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	await frames(90)
	await move_player(Vector3(0, 0.05, 12.4))
	check(room.mission_complete and not second.combat_enabled and not room.enemy.combat_enabled,
		"Mission completion stops every predator")

	await reset_mission()
	second = await add_predator(Vector3(-5, 0.05, -2))
	room.player.take_damage(1000)
	check(not second.combat_enabled, "Player death in the mission stops a secondary predator")
	await reset_mission()
	check(room.get_predators().size() == 1, "Mission restart restores one predator")


func run() -> void:
	await raptor_room_checks()
	await mission_checks()
	print("MULTI PREDATOR RESULT: %d checks, %d failures" % [checks, failures])
	await drop_room()
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)
