extends "res://arca/tests/mission_test.gd"


func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func tap(code: Key) -> void:
	key(code, true)
	key(code, false)
	await frames(2)


func finish() -> void:
	if is_instance_valid(room):
		room.stop_audio()
		room.queue_free()
		await process_frame
		await process_frame
	OS.delay_msec(100)
	print("ECONOMY RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)


func run() -> void:
	await reset_mission()
	var ammo: Node = room.player.get_node_or_null("AmmoComponent")
	check(ammo != null and room.has_node("AmmoPickup") and room.has_node("MedkitPickup"),
		"Mission loads a player magazine and both world pickups")
	if ammo == null or not room.has_node("AmmoPickup") or not room.has_node("MedkitPickup"):
		await finish()
		return
	var health: ArcaHealth = room.player.health_component
	check(ammo.magazine == 12 and ammo.reserve == 12, "Mission starts with 12 rounds loaded and 12 in reserve")

	room.player.player_input.toggled_aim = true
	await frames(30)
	Input.action_press("shoot")
	await frames(3)
	Input.action_release("shoot")
	check(ammo.magazine == 11 and ammo.reserve == 12, "A real firing input consumes one loaded round")
	await tap(KEY_R)
	check(room == current_scene and ammo.reloading, "R starts a manual reload in the current mission")
	check(room.hud.get_node("Frame/AmmoPanel/Margin/VBox/Reload").visible, "HUD shows reload feedback")
	room.set_paused(true)
	var remaining: float = ammo.reload_remaining
	await frames(120)
	check(ammo.reload_remaining == remaining and ammo.magazine == 11, "Pause freezes reload progress and ammo")
	room.set_paused(false)
	await frames(95)
	check(ammo.magazine == 12 and ammo.reserve == 11 and not ammo.reloading,
		"Manual reload transfers only the missing round")
	check(not room.hud.get_node("Frame/AmmoPanel/Margin/VBox/Reload").visible, "HUD clears completed reload feedback")

	ammo.magazine = 0
	var spawned: Array[Node] = []
	room.child_entered_tree.connect(func(node: Node):
		if node.scene_file_path == "res://player/bullet/bullet.tscn":
			spawned.append(node))
	Input.action_press("shoot")
	await frames(3)
	Input.action_release("shoot")
	check(spawned.is_empty() and ammo.magazine == 0, "An empty magazine spawns no projectile")
	check(ammo.reloading, "Dry firing with reserve starts an automatic reload")
	await frames(95)
	check(ammo.magazine == 11 and ammo.reserve == 0 and not ammo.start_reload(),
		"Automatic reload uses the remaining reserve and reload is refused once reserve is empty")

	var box: ArcaInteractionPoint = room.get_node("AmmoPickup")
	await tap(KEY_E)
	check(is_instance_valid(box) and ammo.reserve == 0, "Ammo cannot be collected from spawn")
	await move_player(Vector3(8.7, 0.05, box.position.z))
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(0.1, 2.5, 1.0)
	shape.shape = box_shape
	wall.add_child(shape)
	room.add_child(wall)
	wall.position = (room.player.position + box.position) * 0.5 + Vector3.UP
	await frames(3)
	await tap(KEY_E)
	check(is_instance_valid(box) and ammo.reserve == 0, "A wall blocks pickup with the player inside the interaction area")
	wall.queue_free()
	await frames(3)
	key(KEY_E, true)
	key(KEY_E, true, true)
	key(KEY_E, false)
	await frames(3)
	check(not is_instance_valid(box) and ammo.reserve == 12, "One E press collects exactly 12 rounds and removes the ammo box")

	var medkit: ArcaInteractionPoint = room.get_node("MedkitPickup")
	await move_player(medkit.position + Vector3(1.0, -medkit.position.y + 0.05, 0.0))
	await tap(KEY_E)
	check(is_instance_valid(medkit) and health.current == 100, "A full-health player keeps the medkit available")
	health.take_damage(25)
	await tap(KEY_E)
	check(not is_instance_valid(medkit) and health.current == 100, "The medkit heals once and caps health at its maximum")

	ammo.magazine = 1
	await tap(KEY_R)
	check(ammo.reloading, "Reload is active before the player dies")
	health.cooldown_remaining = 0.0
	health.take_damage(100)
	await frames(95)
	check(not ammo.reloading and ammo.magazine == 1 and ammo.reserve == 12 and not health.heal(40),
		"Death cancels reload and healing cannot revive the player")
	var previous_id: int = room.get_instance_id()
	await tap(KEY_BACKSPACE)
	room = current_scene
	await frames(10)
	check(room.get_instance_id() != previous_id and room.player.ammo_component.magazine == 12
		and room.player.ammo_component.reserve == 12 and room.player.health_component.current == 100
		and room.has_node("AmmoPickup") and room.has_node("MedkitPickup"),
		"Backspace reloads the mission and restores health, ammunition and both pickups")

	health = room.player.health_component
	medkit = room.get_node("MedkitPickup")
	health.take_damage(55)
	await tap(KEY_E)
	check(is_instance_valid(medkit) and health.current == 45, "Medkit cannot be used from spawn")
	await move_player(medkit.position + Vector3(1.0, -medkit.position.y + 0.05, 0.0))
	await tap(KEY_E)
	check(not is_instance_valid(medkit) and health.current == 85, "Medkit restores 40 HP when at least 40 is missing")
	await test_ammo_budget()
	await weapon_and_impact_checks()
	await test_interaction_contract()
	await finish()


func test_ammo_budget() -> void:
	await reset_mission()
	var ammo: ArcaAmmo = room.player.ammo_component
	await move_player(Vector3(8.7, 0.05, room.get_node("AmmoPickup").position.z))
	await tap(KEY_E)
	check(ammo.magazine == 12 and ammo.reserve == 24, "Collecting the box before firing makes 36 rounds available")
	room.player.player_input.toggled_aim = true
	Input.action_press("shoot")
	for frame in 1200:
		await frames(1)
		if room.get_mission_summary()["shots"] >= 35:
			break
	Input.action_release("shoot")
	await frames(30)
	check(room.get_mission_summary()["shots"] == 35 and ammo.magazine == 1 and ammo.reserve == 0,
		"After 35 shots exactly one round remains in the magazine")
	Input.action_press("shoot")
	await frames(90)
	Input.action_release("shoot")
	check(room.get_mission_summary()["shots"] == 36 and ammo.magazine == 0 and ammo.reserve == 0
		and not ammo.reloading, "Last round counts once and dry firing adds no shots or ammo")
	ammo.add_reserve(1)
	await tap(KEY_R)
	await frames(95)
	check(ammo.magazine == 1 and ammo.reserve == 0 and room.get_mission_summary()["shots"] == 36,
		"Reload transfers the final reserve round without incrementing shots")


func spawn_ammo(amount: int, position: Vector3, parent: Node = null) -> ArcaInteractionPoint:
	var pickup: ArcaInteractionPoint = load("res://arca/interactables/ammo_pickup.tscn").instantiate()
	pickup.amount = amount
	(parent if parent != null else room).add_child(pickup)
	pickup.position = position
	return pickup


func interaction_text() -> String:
	var label: Label = room.hud.get_node("Frame/Interaction")
	return label.text if label.visible else ""


func test_interaction_contract() -> void:
	# S1-01: rooms discover interactables from the group, with no hard-coded list.
	await reset_mission()
	var ammo: ArcaAmmo = room.player.ammo_component
	var spot := Vector3(-2.0, 0.05, -4.0)
	await move_player(spot)
	var extra := spawn_ammo(5, spot + Vector3(-1.0, 0.09, 0.0))
	await frames(4)
	check(extra.is_in_group(ArcaInteractionPoint.GROUP), "A runtime-instanced pickup joins the interactable group")
	check(interaction_text() == "[ E ]  Collect 5 rounds",
		"A runtime ammo pickup with amount 5 is prompted with its own amount (got '%s')" % interaction_text())
	var reserve: int = ammo.reserve
	await tap(KEY_E)
	check(ammo.reserve == reserve + 5 and not is_instance_valid(extra),
		"One E press grants exactly +5 reserve from the runtime pickup and removes it")
	check(interaction_text().is_empty(), "The prompt clears once the runtime pickup is gone")

	# Two presses delivered in the same frame perform one action, even with two targets in range.
	var first := spawn_ammo(5, spot + Vector3(-1.0, 0.09, 0.0))
	var second := spawn_ammo(7, spot + Vector3(1.0, 0.09, 0.0))
	await frames(4)
	reserve = ammo.reserve
	var frame: int = Engine.get_process_frames()
	key(KEY_E, true)
	key(KEY_E, false)
	key(KEY_E, true)
	key(KEY_E, false)
	var same_frame: bool = Engine.get_process_frames() == frame
	await frames(3)
	var remaining: int = int(is_instance_valid(first)) + int(is_instance_valid(second))
	check(same_frame and remaining == 1 and (ammo.reserve == reserve + 5 or ammo.reserve == reserve + 7),
		"Two E presses in one frame collect exactly one of two pickups in range")

	# Holding E (key repeat echoes over many frames) performs a single action.
	var survivor: ArcaInteractionPoint = first if is_instance_valid(first) else second
	var spare := spawn_ammo(3, spot + Vector3(0.0, 0.09, 1.0))
	await frames(4)
	reserve = ammo.reserve
	key(KEY_E, true)
	for i in 20:
		await frames(1)
		key(KEY_E, true, true)
	key(KEY_E, false)
	await frames(3)
	remaining = int(is_instance_valid(survivor)) + int(is_instance_valid(spare))
	check(remaining == 1 and ammo.reserve > reserve and ammo.reserve <= reserve + 7,
		"Holding E with repeat echoes collects only one pickup")
	for pickup in [survivor, spare]:
		if is_instance_valid(pickup):
			pickup.queue_free()
	await frames(3)

	# Interactables outside the room's subtree are never offered.
	var outsider := spawn_ammo(9, spot + Vector3(-1.0, 0.09, 0.0), root)
	outsider.global_position = room.player.global_position + Vector3(-1.0, 0.09, 0.0)
	await frames(4)
	reserve = ammo.reserve
	await tap(KEY_E)
	check(is_instance_valid(outsider) and ammo.reserve == reserve and interaction_text().is_empty(),
		"A pickup outside the room subtree is neither prompted nor collected")
	outsider.queue_free()
	await frames(3)

	# A pickup behind the real corridor partition is in range but occluded.
	await move_player(Vector3(5.0, 0.05, 3.0))
	var hidden := spawn_ammo(5, Vector3(6.4, 0.14, 3.0))
	await frames(4)
	reserve = ammo.reserve
	check(hidden.overlaps_body(room.player), "The occlusion test player is inside the hidden pickup's range")
	check(room._find_interaction_target() != hidden and interaction_text().is_empty(),
		"A pickup behind the corridor partition is not offered")
	await tap(KEY_E)
	check(is_instance_valid(hidden) and ammo.reserve == reserve, "E cannot collect through the corridor partition")

func weapon_and_impact_checks() -> void:
	await reset_mission()
	await move_player(Vector3(0, 0.05, -9))
	var player = room.player
	var ammo: ArcaAmmo = player.ammo_component
	var hud_ammo: Label = room.hud.get_node("Frame/AmmoPanel/Margin/VBox/Ammo")
	var impacts: Array[StringName] = []
	player.shot_resolved.connect(func(material: StringName, _point: Vector3): impacts.append(material))
	Input.action_press("aim")
	await frames(45)
	var metal := impact_fixture(Vector3(0, 1.35, -5.5), Vector3(1.7, 2.4, 0.20))
	metal.add_to_group("arca_metal")
	await shoot_once_at(metal.global_position)
	check(impacts.back() == &"metal" and ammo.magazine == 11 and hud_ammo.text.contains("11 / 12"),
		"One shot into metal resolves at impact and updates the magazine HUD")
	metal.queue_free()
	await frames(3)
	var wall := impact_fixture(Vector3(0, 1.40, -5.5), Vector3(1.7, 2.4, 0.20))
	await shoot_once_at(wall.global_position)
	check(impacts.back() == &"wall" and ammo.magazine == 10, "A wall impact spends one round and uses the wall effect")
	wall.queue_free()
	await frames(3)
	var raptor: ArcaRaptor = room.get_node("ExitLift/FinalRaptor")
	raptor.global_position = Vector3(0, 0, -5.5)
	var before := raptor.health
	await shoot_once_at(raptor.global_position + Vector3.UP)
	check(impacts.back() == &"raptor" and raptor.health == before - 1 and ammo.magazine == 9,
		"The pistol trace deals one packet through the existing predator hit contract")
	var muzzle: Vector3 = player.shoot_from.global_position
	var obstruction := impact_fixture((player.global_position + Vector3.UP * 1.4 + muzzle) * 0.5, Vector3(0.30, 1.1, 0.035))
	await shoot_once_at(raptor.global_position + Vector3.UP)
	check(impacts.back() == &"wall" and raptor.health == before - 1 and ammo.magazine == 8,
		"An obstructed muzzle uses the near-surface impact and spends a round")
	obstruction.queue_free()
	await frames(3)
	# A shot aimed into the room ceiling is a real impact. Use an
	# isolated fixture floor to keep exercising the no-hit shot contract.
	impact_fixture(Vector3(0, -0.15, -24), Vector3(8, 0.3, 8))
	await move_player(Vector3(0, 0.05, -24))
	var clear_aim := Vector3(0, 95, -22)
	await shoot_once_at(clear_aim)
	check(impacts.back() == &"miss" and ammo.magazine == 7, "A shot with no collision still consumes one round")
	await tap(KEY_R)
	check(ammo.reloading, "Primary can begin a partial reload before a weapon switch")
	var fired_before := impacts.size()
	Input.action_press("shoot")
	await frames(11)
	Input.action_release("shoot")
	check(impacts.size() == fired_before and ammo.magazine == 7, "A firing input refused during reload consumes zero rounds")
	var saved := player.capture_ammo_state() as Dictionary
	await tap(KEY_2)
	check(player.ammo_component == player.backup_ammo and not ammo.reloading and ammo.magazine == 7
		and ammo.reserve == 12 and hud_ammo.text.contains("06 / 00"), "Switching cancels reload without transferring rounds and rebinds HUD")
	await shoot_once_at(clear_aim)
	check(player.backup_ammo.magazine == 5 and ammo.magazine == 7 and hud_ammo.text.contains("05 / 00"),
		"Backup weapon has independent ammunition")
	await tap(KEY_1)
	check(player.ammo_component == ammo and hud_ammo.text.contains("07 / 12"), "Returning to the primary restores its exact HUD state")
	player.restore_ammo_state(saved)
	check(player.backup_ammo.magazine == 6 and ammo.magazine == 7, "Snapshot restores both weapons without duplicating primary rounds")
	Input.action_release("aim")


func impact_fixture(origin: Vector3, size: Vector3) -> StaticBody3D:
	var fixture := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	fixture.add_child(collision)
	room.add_child(fixture)
	fixture.global_position = origin
	return fixture
