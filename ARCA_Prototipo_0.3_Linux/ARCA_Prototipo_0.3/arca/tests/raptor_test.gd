extends "res://arca/tests/first_playable_test.gd"
## Real scene/physics tests of the predator, including native player bullets.


func reset_room() -> void:
	for action in ["shoot", "aim", "move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)
	if is_instance_valid(room):
		room.restart_room()
		await process_frame
		await process_frame
		room = current_scene
	else:
		room = load("res://arca/raptor_room.tscn").instantiate()
		root.add_child(room)
		current_scene = room
	await frames(30)


func run() -> void:
	await reset_room()
	var predator: ArcaRaptor = room.enemy
	check(predator.clips.size() == 6, "Six real animation clips are loaded from the GLB")
	check(room.get_node("NavigationRegion3D").navigation_mesh.get_polygon_count() > 10,
		"Baked navigation geometry is present")
	check(not room.has_node("RedRobot") and get_nodes_in_group("arca_predator").size() == 1,
		"The robot is replaced by exactly one predator")
	check(predator.state == ArcaRaptor.State.WAIT, "Predator waits while the player stays far away")
	predator.position = Vector3(0, 0.05, -4)
	var starting_distance: float = predator.position.distance_to(room.player.position)
	await frames(80)
	check(predator.state == ArcaRaptor.State.CHASE,
		"Player detection advances through alert into chase")
	check(predator.position.distance_to(room.player.position) < starting_distance - 1.0,
		"The navigation agent moves the predator toward the player")
	for i in 240:
		if predator.state == ArcaRaptor.State.WINDUP:
			break
		await frames(1)
	check(predator.state == ArcaRaptor.State.WINDUP and predator.warning.visible,
		"Melee attack has a visible preparation phase")
	check(room.player.health_component.current == 100, "Windup does not deal early damage")
	for i in 100:
		if room.player.health_component.current < 100:
			break
		await frames(1)
	check(room.player.health_component.current == 80, "One bite subtracts exactly 20 HP")
	await frames(25)
	check(room.player.health_component.current == 80, "The bite does not damage the player every frame")

	await reset_room()
	predator = room.enemy
	predator.position = Vector3(0, 0.05, -7.4)
	predator._change_state(ArcaRaptor.State.WINDUP)
	room.player.position = Vector3(0, 0.05, -12)
	await frames(85)
	check(room.player.health_component.current == 100, "Retreating out of reach dodges the bite")

	await reset_room()
	predator = room.enemy
	predator.position = Vector3(-3.8, 0.05, -0.5)
	room.player.position = Vector3(-3.8, 0.05, -5.5)
	await frames(5)
	check(not predator._can_see_player(), "A cover block occludes the player's body")
	predator.hit()
	var widest_detour: float = 0.0
	for i in 450:
		await frames(1)
		widest_detour = maxf(widest_detour, absf(predator.position.x + 3.8))
		if predator.position.distance_to(room.player.position) < 2.0:
			break
	check(widest_detour > 1.3 and predator.position.distance_to(room.player.position) < 2.1,
		"The predator paths around solid cover instead of running into it")

	await reset_room()
	predator = room.enemy
	predator.position = Vector3(0, 0.05, -7.4)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.2)
	collision.shape = box
	wall.add_child(collision)
	room.add_child(wall)
	wall.position = Vector3(0, 1.5, -8.2)
	await frames(5)
	predator._change_state(ArcaRaptor.State.ATTACK)
	await frames(40)
	check(room.player.health_component.current == 100, "A wall blocks bite damage even within reach")

	await reset_room()
	predator = room.enemy
	predator.position = Vector3(0, 0.05, -7.3)
	predator.health_component.current = 1
	predator._change_state(ArcaRaptor.State.WINDUP)
	predator.hit()
	await frames(100)
	check(predator.dead and room.player.health_component.current == 100,
		"Death during windup cancels the queued bite")
	check(predator.animation.current_animation == predator.clips["Death"] or not predator.animation.is_playing(),
		"The death clip is played without restarting the attack")

	await reset_room()
	predator = room.enemy
	predator.combat_enabled = false
	predator.position = Vector3(0, 0.05, -3)
	Input.action_press("aim")
	await frames(45)
	var previous_health: int = predator.health
	await shoot_once_at(predator.global_position + Vector3.UP * 0.9)
	check(predator.health == previous_health - 1, "The original player weapon hits the predator's body")
	for i in 5:
		await shoot_once_at(predator.global_position + Vector3.UP * 0.9)
	check(predator.dead, "Six real projectiles can kill the predator")

	for cycle in 3:
		await reset_room()
		room.player.take_damage(1000)
		check(room.hud.modal.visible and not room.enemy.combat_enabled,
			"Player death stops predator combat, cycle %d" % (cycle + 1))
		await reset_room()
		check(room.player.health_component.current == 100 and room.enemy.health == 6
			and room.enemy.combat_enabled and get_nodes_in_group("arca_predator").size() == 1,
			"Restart restores one healthy predator, cycle %d" % (cycle + 1))

	print("RAPTOR RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	# Give the audio worker real wall time to drain after accelerated tests.
	OS.delay_msec(200)
	Engine.max_fps = 60
	for i in 15:
		await process_frame
	quit(0 if failures == 0 else 1)
