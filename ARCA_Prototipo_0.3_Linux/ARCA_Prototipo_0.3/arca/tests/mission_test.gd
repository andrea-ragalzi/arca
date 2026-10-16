extends "res://arca/tests/first_playable_test.gd"

var collection_count: int = 0

func reset_mission() -> void:
	for action in ["interact", "shoot", "aim", "move_forward"]:
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
	check(InputMap.has_action("interact") and InputMap.action_get_events("interact").size() > 0,
		"E is configured in the real project Input Map")
	check(not room.has_fuse and not room.power_restored and not room.mission_complete,
		"Mission starts with an empty inventory and no power")
	check(room.hud.status_label.text.begins_with("01") and room.hud.get_node("Frame/Inventory").text.contains("MANCANTE"),
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
	check(room.hud.get_node("Frame/Notice").text.contains("Manca il fusibile"),
		"Missing fuse feedback is visible on screen")
	await move_player(Vector3(2, 0.05, -7.2))
	check(room.hud.get_node("Frame/Interaction").visible, "Proximity displays the E prompt")
	# Insert an actual physics wall between player and item.
	var wall := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.15)
	shape_node.shape = shape
	wall.add_child(shape_node)
	room.add_child(wall)
	wall.position = Vector3(2, 1.5, -6.6)
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
	check(room.hud.status_label.text.begins_with("02") and room.hud.get_node("Frame/Inventory").text.contains("IN INVENTARIO"),
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
	check(room.hud.status_label.text.begins_with("03") and room.hud.get_node("Frame/Inventory").text.contains("INSTALLATO"),
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
	await move_player(Vector3(2, 0.05, -7.2))
	room.player.take_damage(1000)
	await press_e()
	check(not room.has_fuse and room.hud.modal.visible, "A dead player cannot collect items")
	await reset_mission()
	await move_player(Vector3(0, 0.05, 12.4))
	check(not room.mission_complete, "Entering an unpowered exit cannot complete the mission")
	await reset_mission()
	room.enemy.combat_enabled = true
	room.enemy.position = Vector3(-2.5, 0.05, 7)
	await move_player(Vector3(2, 0.05, -7.2))
	room.enemy.hit()
	var start_distance: float = room.enemy.position.distance_to(room.player.position)
	await frames(220)
	check(room.enemy.position.distance_to(room.player.position) < start_distance - 4.0,
		"Raptor navigates the mission toward the fuse without getting stuck")
	print("MISSION RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)
