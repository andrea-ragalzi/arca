extends SceneTree
## Integration checks against actual Godot scenes, physics and upstream input.
## Run after importing: godot --headless --fixed-fps 60 --path . -s res://arca/tests/first_playable_test.gd

var failures: int = 0
var checks: int = 0
var room: Node3D


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame


func reset_room() -> void:
	for action in ["shoot", "aim", "move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)
	if is_instance_valid(room):
		room.restart_room()
		await process_frame
		await process_frame
		room = current_scene
	else:
		room = load("res://arca/test_room.tscn").instantiate()
		root.add_child(room)
		current_scene = room
	await frames(30)


func shoot_once_at(target: Vector3) -> void:
	var player = room.player
	var camera: Camera3D = player.player_input.camera_camera
	camera.look_at(target)
	camera.start_rotation = camera.rotation
	# Camera projection uses an interpolated transform: settle before firing.
	await frames(4)
	Input.action_press("shoot")
	await frames(3)
	Input.action_release("shoot")
	await frames(55)


func run() -> void:
	await reset_room()
	check(room.player.is_on_floor(), "Original player lands on the ARCA floor")
	check(room.player.health_component.current == 100, "Player starts with 100 HP")
	check(room.enemy.health == 5, "One upstream enemy starts with five hit points")
	check(room.enemy.ray_mesh.global_basis.z.normalized().dot(room.enemy.ray_from.global_basis.y.normalized()) < -0.99,
		"Visible laser and damage ray share the cannon's forward axis")
	room.enemy.set_physics_process(false)
	var start: Vector3 = room.player.position
	Input.action_press("move_forward")
	await frames(75)
	Input.action_release("move_forward")
	await frames(20)
	check(room.player.position.distance_to(start) > 2.0, "WASD drives the original animated root-motion controller")
	var yaw: float = room.player.player_input.camera_base.rotation.y
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(100, 0)
	Input.parse_input_event(event)
	await frames(2)
	check(absf(room.player.player_input.camera_base.rotation.y - yaw) > 0.05, "Mouse input rotates the original camera")

	room.set_paused(true)
	var paused_at: Vector3 = room.player.position
	Input.action_press("move_forward")
	await frames(45)
	check(room.player.position.is_equal_approx(paused_at), "Pause freezes gameplay physics")
	var escape := InputEventAction.new()
	escape.action = "quit"
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	check(not paused, "Escape unpauses through the live HUD")
	Input.action_release("move_forward")

	await reset_room()
	room.enemy.set_physics_process(false)
	# A short range removes dispersion from the native camera shake.
	room.enemy.position = Vector3(0, 0.05, -3)
	await frames(10)
	Input.action_press("aim")
	await frames(45)
	var hp: int = room.enemy.health
	await shoot_once_at(room.enemy.global_position + Vector3.UP * 1.1)
	check(room.enemy.health == hp - 1, "One native projectile subtracts exactly one enemy hit point")
	for i in 4:
		await shoot_once_at(room.enemy.global_position + Vector3.UP * 1.1)
	check(room.enemy.dead, "Native weapon can kill the upstream enemy")
	var before: int = room.player.health_component.current
	room.enemy.shoot()
	room.enemy.shoot_check()
	room.enemy.play_shoot()
	await frames(180)
	check(room.player.health_component.current == before, "A dead enemy cannot deliver a queued shot")

	await reset_room()
	room.enemy.set_physics_process(false)
	room.enemy.position = Vector3(0, 0.05, -3)
	var cover := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 4, 0.3)
	shape.shape = box
	cover.add_child(shape)
	room.add_child(cover)
	cover.position = Vector3(0, 2, -6)
	await frames(5)
	Input.action_press("aim")
	await frames(45)
	await shoot_once_at(room.enemy.global_position + Vector3.UP)
	check(room.enemy.health == 5, "A solid wall blocks the actual projectile")
	# Put a thin wall between the chest and the muzzle, then inspect origin.
	var chest: Vector3 = room.player.global_position + Vector3.UP * 1.4
	var muzzle: Vector3 = room.player.shoot_from.global_position
	cover.position = (chest + muzzle) * 0.5
	box.size = Vector3(4, 4, 0.03)
	await frames(3)
	var safe_origin: Vector3 = room.player.get_shoot_origin()
	check(safe_origin.distance_to(chest) < muzzle.distance_to(chest), "The muzzle cannot spawn a projectile across nearby cover")

	await reset_room()
	# Exercise the real enemy animation event and line-of-sight query.
	for i in 950:
		await frames(1)
		if room.player.health_component.current < 100:
			break
	check(room.player.health_component.current == 75, "A real robot laser hit inflicts the configured 25 HP")
	var hp_after_laser: int = room.player.health_component.current
	await frames(30)
	check(room.player.health_component.current == hp_after_laser, "Laser damage is not applied every physics frame")
	room.enemy.set_physics_process(false)
	room.player.take_damage(25)
	check(room.player.health_component.current == hp_after_laser, "Damage cooldown rejects immediate repeat packets")

	for cycle in 5:
		if cycle > 0:
			await reset_room()
		room.enemy.set_physics_process(false)
		await frames(60)
		room.player.take_damage(1000)
		check(room.player.health_component.current == 0 and room.hud.modal.visible,
			"Death opens the restart panel, cycle %d" % (cycle + 1))
		Input.action_press("aim")
		Input.action_press("shoot")
		await frames(60)
		check(not room.player.is_physics_processing() and not room.player.player_input.shooting,
			"Dead player cannot move or fire, cycle %d" % (cycle + 1))
		room.player.take_damage(1000)
		check(room.player.health_component.current == 0, "Further damage after death is ignored")
		await reset_room()
		check(get_nodes_in_group("arca_player").size() == 1 and get_nodes_in_group("arca_room").size() == 1,
			"Restart does not duplicate actors, cycle %d" % (cycle + 1))
		check(room.player.health_component.current == 100 and room.enemy.health == 5
			and room.get_children().filter(func(n): return n is CanvasLayer).size() == 1,
			"Restart restores player/enemy/HUD, cycle %d" % (cycle + 1))

	# Run into a perimeter wall; the player capsule must remain in the room.
	room.enemy.set_physics_process(false)
	room.player.position = Vector3(0, 0.05, 12)
	Input.action_press("move_forward")
	await frames(180)
	Input.action_release("move_forward")
	check(room.player.position.z < 13.5 and room.player.position.y > -0.1,
		"Perimeter walls retain the moving player")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	await process_frame
	# Let the audio worker release voices before the test process exits.
	# --fixed-fps can execute faster than wall time, bypassing the FPS cap.
	OS.delay_msec(200)
	Engine.max_fps = 60
	for i in 15:
		await process_frame
	quit(0 if failures == 0 else 1)
