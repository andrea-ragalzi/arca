extends "res://arca/tests/first_playable_test.gd"

var collection_count: int = 0
const FUSE_APPROACH := Vector3(8, 0.05, 8.8)

func reset_mission() -> void:
	for action in ["interact", "shoot", "aim", "move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)
	if is_instance_valid(room):
		room.restart_room()
		await frames(3)
		room = current_scene
	else:
		room = load("res://arca/mission_room.tscn").instantiate()
		root.add_child(room)
		current_scene = room
	room.enemy.stop_combat()
	await frames(15)

func move_player(position: Vector3) -> void:
	room.player.position = position
	room.player.velocity = Vector3.ZERO
	room.player.reset_physics_interpolation()
	await frames(8)

func approach_fuse() -> void:
	await move_player(FUSE_APPROACH)

func walk_to(target: Vector3, max_frames: int = 600) -> int:
	# Drive the real root-motion controller; teleporting cannot validate a route.
	var walked_frames: int = 0
	for i in max_frames:
		var offset: Vector3 = target - room.player.position
		offset.y = 0.0
		if offset.length() < 0.35:
			break
		room.player.player_input.camera_base.rotation.y = atan2(offset.x, offset.z)
		Input.action_press("move_forward")
		await frames(1)
		walked_frames += 1
	Input.action_release("move_forward")
	await frames(12)
	var remaining: Vector3 = target - room.player.position
	remaining.y = 0.0
	check(remaining.length() < 0.8, "Walking reaches route waypoint %s (actual %s)" % [target, room.player.position])
	return walked_frames + 12

func corridor_checks() -> void:
	var space: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
	var entrance_sign: Label3D = room.get_node("ServiceCorridor/EntranceSign")
	var sight := PhysicsRayQueryParameters3D.create(room.player.position + Vector3.UP * 1.6, entrance_sign.global_position, 1)
	check(space.intersect_ray(sight).is_empty(), "Entrance sign has a clear sightline from the starting area")
	var camera: Camera3D = room.player.player_input.camera_camera
	check(camera.is_position_in_frustum(entrance_sign.global_position), "The initial camera frames the service entrance sign")
	for origin in [Vector3(0, 1.6, -9), Vector3(0, 1.6, 2), Vector3(5, 1.6, 8.8), Vector3(10, 1.6, -8)]:
		sight.from = origin
		sight.to = room.fuse.global_position
		check(not space.intersect_ray(sight).is_empty(), "Main-room sightline %s cannot reveal the fuse" % origin)
	await move_player(Vector3(5, 0.05, 8.8))
	check(room.fuse.overlaps_body(room.player), "Opposite-wall test is inside the fuse interaction range")
	await press_e()
	check(not room.has_fuse and not room.hud.get_node("Frame/Interaction").visible,
		"The actual corridor wall blocks pickup and its prompt at close range")
	await move_player(Vector3(4.3, 0.05, 8.8))
	room.player.player_input.camera_base.rotation.y = PI / 2.0
	Input.action_press("move_forward")
	await frames(80)
	Input.action_release("move_forward")
	check(room.player.position.x > 4.8 and room.player.position.x < 5.6,
		"Real player movement approaches but cannot cross the corridor partition")
	await move_player(Vector3(0, 0.05, -9))
	await walk_to(Vector3(9.4, 0.05, -9.5))
	await walk_to(Vector3(9.4, 0.05, 4.5))
	await walk_to(Vector3(9.4, 0.05, 8.8))
	await walk_to(FUSE_APPROACH)
	room.player.player_input.camera_base.rotation.y = -PI / 2.0
	await frames(15)
	check(camera.global_position.x < 10.6,
		"The corridor lining keeps the camera in front of inherited wall decorations")
	await press_e()
	check(room.has_fuse, "Walking through the entrance and around the screen reaches the real fuse")
	var return_frames: int = 0
	for target in [Vector3(9.4, 0.05, 8.8), Vector3(9.4, 0.05, 4.5), Vector3(9.4, 0.05, -9.5),
			Vector3(1, 0.05, -9.5), Vector3(-8.8, 0.05, -6), Vector3(-8.8, 0.05, 5.1)]:
		return_frames += await walk_to(target)
	var return_seconds: float = return_frames / 60.0
	print("CORRIDOR RETURN: %.2f simulated seconds of ordinary walking (manual F5 timing still required)" % return_seconds)
	check(return_seconds >= 10.0 and return_seconds <= 20.0, "The ordinary walking return route targets 10–20 seconds")
	await press_e()
	check(room.power_restored, "The walked return route reaches the working power panel")
	await reset_mission()

func press_e() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func gate_hit() -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(0, 1.4, 9.5), Vector3(0, 1.4, 12), 1)
	return room.get_world_3d().direct_space_state.intersect_ray(query)

func run() -> void:
	await reset_mission()
	await corridor_checks()
	check(InputMap.has_action("interact") and InputMap.action_get_events("interact").size() > 0,
		"E is configured in the real project Input Map")
	check(not room.has_fuse and not room.power_restored and not room.mission_complete,
		"Mission starts with an empty inventory and no power")
	check(room.hud.status_label.text.begins_with("01") and room.hud.get_node("Frame/Inventory").text.contains("MISSING"),
		"HUD gives the first objective and inventory state")
	check(not gate_hit().is_empty(), "The closed door physically blocks the exit")
	check(room.get_node("NavigationRegion3D").navigation_mesh.resource_path.ends_with("mission_navigation.tres"),
		"Mission uses navigation baked for the new obstacles")
	await press_e()
	check(not room.has_fuse, "E cannot collect a distant fuse")
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	check(not room.power_restored and not room.door.is_opening,
		"A panel without a fuse cannot open the door")
	check(room.hud.get_node("Frame/Notice").text.contains("Fuse missing"),
		"Missing fuse feedback is visible on screen")
	await approach_fuse()
	check(room.hud.get_node("Frame/Interaction").visible, "Proximity displays the E prompt")
	# Insert an actual physics wall between player and item.
	var wall := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.15, 3, 3)
	shape_node.shape = shape
	wall.add_child(shape_node)
	room.add_child(wall)
	wall.position = Vector3(7.35, 1.5, 8.8)
	await frames(5)
	await press_e()
	check(not room.has_fuse, "A wall blocks collection through geometry")
	wall.queue_free()
	await frames(5)
	room.set_paused(true)
	await press_e()
	check(not room.has_fuse, "Pause blocks interaction input")
	room.set_paused(false)
	room.fuse.collected.connect(func(): collection_count += 1)
	await press_e()
	check(room.has_fuse and not is_instance_valid(room.fuse), "E collects the fuse and removes its world instance")
	check(collection_count == 1, "Collection emits exactly one signal")
	check(room.hud.status_label.text.begins_with("02") and room.hud.get_node("Frame/Inventory").text.contains("CARRIED"),
		"Collection updates both objective and inventory on screen")
	await press_e()
	check(collection_count == 1, "Repeated E cannot duplicate the item")
	# Enemy death must not overwrite the mission objective.
	room._on_enemy_destroyed()
	check(room.hud.status_label.text.begins_with("02"), "Defeating the raptor preserves the puzzle objective")
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	check(room.power_restored and not room.has_fuse and room.panel.is_powered,
		"The panel consumes one fuse and restores power")
	check(room.door.is_opening, "Restoring power starts the animated door")
	await press_e()
	await frames(80)
	check(room.door.is_open and gate_hit().is_empty(), "Door animation clears the real exit collision")
	check(room.hud.status_label.text.begins_with("03") and room.hud.get_node("Frame/Inventory").text.contains("INSTALLED"),
		"Powered sector shows exit objective and installed fuse")
	await move_player(Vector3(0, 0.05, 12.4))
	check(room.mission_complete and paused and room.hud.modal.visible,
		"Entering the powered exit pauses gameplay and shows completion")
	room.set_paused(false)
	check(paused, "Escape cannot resume a finished mission")
	var restart := InputEventAction.new()
	restart.action = "arca_restart"
	restart.pressed = true
	Input.parse_input_event(restart)
	await frames(4)
	room = current_scene
	room.enemy.stop_combat()
	await frames(10)
	check(not paused and not room.mission_complete and not room.has_fuse and not room.power_restored,
		"R from completion resets all mission flags")
	check(is_instance_valid(room.fuse) and room.fuse.enabled and not room.panel.is_powered and not room.door.is_open,
		"Restart restores the fuse, unpowered panel and closed door")
	check(room.panel.get_node("Indicator").material_override.albedo_color.r > 0.8,
		"Restart restores red panel material without shared resource leakage")
	await approach_fuse()
	room.player.take_damage(1000)
	await press_e()
	check(not room.has_fuse and room.hud.modal.visible, "A dead player cannot collect items")
	await reset_mission()
	await move_player(Vector3(0, 0.05, 12.4))
	check(not room.mission_complete, "Entering an unpowered exit cannot complete the mission")
	await reset_mission()
	room.enemy.activate_ambush()
	room.enemy.position = Vector3(-2.5, 0.05, 7)
	await approach_fuse()
	room.enemy.hit()
	var passed_entrance: bool = false
	var passed_screen: bool = false
	for i in 1500:
		await frames(1)
		if room.enemy.position.x > 6.0 and room.enemy.position.z < -5.4:
			passed_entrance = true
		if room.enemy.position.x > 8.4 and room.enemy.position.z > 6.2:
			passed_screen = true
		if room.enemy.position.distance_to(room.player.position) < 2.0:
			break
	check(passed_entrance and passed_screen and room.enemy.position.distance_to(room.player.position) < 2.0,
		"Raptor reaches the fuse via the corridor entrance and screened alcove without getting stuck")
	await move_player(Vector3(1, 0.05, -9.5))
	for i in 1200:
		await frames(1)
		if room.enemy.position.distance_to(room.player.position) < 2.0:
			break
	check(room.enemy.position.distance_to(room.player.position) < 2.0,
		"Raptor can return from the alcove through the corridor to the main room")
	print("MISSION RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)
