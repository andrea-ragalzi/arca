extends "res://arca/tests/mission_test.gd"


func run() -> void:
	await reset_mission()
	var terminal := room.get_node_or_null("ControlOffice/CheckpointTerminal") as Node3D
	check(terminal != null, "The office contains a working checkpoint terminal")
	if terminal != null:
		await retry_checks(terminal)
	print("CHECKPOINT RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)


func retry_checks(terminal: Node3D) -> void:
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	await frames(90)
	await open_lift_for_exit_fixture()
	room.enemy.health_component.current = 1
	room.enemy.hit()
	room.player.take_damage(40)
	room.player.ammo_component.magazine = 7
	room.player.ammo_component.reserve = 9
	room.add_key_item(&"override_card")
	var checkpoint_position := terminal.global_position
	await move_player(checkpoint_position + Vector3(1, 0.05, 0))
	await press_e()
	check(room.hud.get_node("Frame/Notice").text.contains("CHECKPOINT SAVED"), "E records the checkpoint")
	var saved_clock: float = room.mission_seconds
	room.player.ammo_component.magazine = 2
	room.player.ammo_component.reserve = 1
	room.consume_key_item(&"override_card")
	await frames(60)
	room.player.take_damage(1000)
	var retry := room.hud.get_node("Frame/Modal/Center/Panel/Margin/VBox/Retry") as Button
	check(retry.visible, "The death modal offers a checkpoint retry")
	retry.pressed.emit()
	await frames(12)
	room = current_scene
	check(room.player.global_position.distance_to(checkpoint_position) < 0.3,
		"Retry places Regina at the checkpoint")
	check(room.player.health_component.current == 60 and room.player.ammo_component.magazine == 7
		and room.player.ammo_component.reserve == 9, "Retry restores health and ammunition")
	check(room.has_key_item(&"override_card") and not room.has_fuse and room.power_restored and room.panel.is_powered,
		"Retry restores the captured inventory and panel state")
	var gate_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1, 42.6), Vector3(0, 1, 45), 1)
	var space: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
	check(room.door.is_open and room.lift_gate.slider.is_open and room.ambush_phase == room.AmbushPhase.CANCELLED
		and gate_hit().is_empty() and space.intersect_ray(gate_ray).is_empty(),
		"Retry restores both open doors, their collision and the completed hatch")
	check(not is_instance_valid(room.fuse) and not is_instance_valid(room.enemy) and room.get_mission_summary()["kills"] == 1,
		"Consumed pickups and killed predators are absent after retry")
	check(room.mission_seconds >= saved_clock - 0.1 and room.mission_seconds < saved_clock + 0.5,
		"Retry continues the mission clock from the saved time")
	await frames(60)
	room.player.take_damage(1000)
	check(room.hud.get_node("Frame/Modal/Center/Panel/Margin/VBox/Retry").visible
		and room.hud.modal_title.text == "SIGNAL LOST",
		"The same checkpoint remains available on a later death, even after the primary predator is gone")
	await reset_mission()
	check(not room.power_restored and not room.door.is_open and not room.lift_gate.slider.is_open
		and is_instance_valid(room.fuse) and is_instance_valid(room.enemy) and room.key_items.is_empty(),
		"Full restart reloads a pristine mission")
	room.player.take_damage(1000)
	check(not room.hud.get_node("Frame/Modal/Center/Panel/Margin/VBox/Retry").visible,
		"Full restart discards the previous checkpoint")
