extends "res://arca/tests/mission_test.gd"
## Follow the actual TPS walking and interaction path into the final lift.

const CORRIDOR_Z: float = 14.2
const EXIT_APPROACH := Vector3(0, 0.05, 60.6)


func walk_leg(points: Array[Vector3]) -> int:
	var walked: int = 0
	for point: Vector3 in points:
		walked += await walk_to(point) - 12
	return walked


func run() -> void:
	await reset_mission()
	var corridor := room.get_node_or_null("SecurityCorridor") as Node3D
	var office := room.get_node_or_null("ControlOffice") as Node3D
	var lift := room.get_node_or_null("ExitLift") as Node3D
	check(corridor != null and office != null and lift != null, "The mission contains the three connected route areas")
	if corridor != null and office != null and lift != null:
		var final_raptor := lift.get_node("FinalRaptor") as ArcaRaptor
		check(final_raptor.position.x < -7.5 and final_raptor.visible
			and final_raptor.state == ArcaRaptor.State.WAIT,
			"The final raptor starts physically in the freight gallery beyond the breach")
		await navigation_checks()
		await walk_route(office)
		await chase_checks()
		await freight_discovery_check()
	print("ROUTE RESULT: %d checks, %d failures" % [checks, failures])
	paused = false
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)


func walk_route(office: Node3D) -> void:
	room.stop_all_predators()
	room.ambush_delay = 9999.0
	var walked: int = await walk_leg([
		Vector3(9.4, 0.05, -9.5), Vector3(9.4, 0.05, 4.5),
		Vector3(9.4, 0.05, 8.8), FUSE_APPROACH,
	])
	await press_e()
	check(room.has_fuse, "Walking from spawn reaches the fuse")
	walked += await walk_leg([
		Vector3(9.4, 0.05, 8.8), Vector3(9.4, 0.05, 4.5),
		Vector3(9.4, 0.05, -9.5), Vector3(1, 0.05, -9.5),
		Vector3(-8.8, 0.05, -6), Vector3(-8.8, 0.05, 5.1),
	])
	await press_e()
	check(room.power_restored, "Walking back reaches the power panel")
	await frames(75)
	walked += await walk_leg([
		Vector3(-8.8, 0.05, 7.6), Vector3(-1.0, 0.05, 7.6), Vector3(0, 0.05, 9.9),
		Vector3(0, 0.05, CORRIDOR_Z + 3), Vector3(0, 0.05, CORRIDOR_Z + 28.4),
	])
	check(room.hud.status_label.text.begins_with("04") and not room.mission_complete,
		"The original exit leads to the keycard objective")
	await press_e()
	check(room.hud.get_node("Frame/Notice").text.contains("requires Keycard"),
		"The far corridor door denies entry without the card")

	var entry := Vector3(0, 0.05, CORRIDOR_Z + 11)
	walked += await walk_leg([
		entry, office.to_global(Vector3(0, 0.05, 1.6)),
		office.to_global(Vector3(5.2, 0.05, 1.6)), office.to_global(Vector3(5.2, 0.05, 7.35)),
	])
	await press_e()
	check(room.has_key_item(&"keycard") and room.hud.status_label.text.begins_with("05"),
		"The player reaches and collects the office keycard")
	walked += await walk_leg([
		office.to_global(Vector3(5.2, 0.05, 1.6)), office.to_global(Vector3(0, 0.05, 1.6)), entry,
		Vector3(0, 0.05, CORRIDOR_Z + 28.4),
	])
	await press_e()
	await frames(75)
	check(room.hud.status_label.text.begins_with("06"), "The keycard opens the way to the lift")
	walked += await walk_leg([Vector3(0, 0.05, 46.5), EXIT_APPROACH])
	check(room.mission_complete and paused and room.hud.modal.visible,
		"Walking all the way to the lift completes the mission")
	print("ROUTE WALKING TIME: %.2f simulated seconds with movement input held" % (walked / 60.0))


func navigation_checks() -> void:
	await frames(5)
	var map := room.get_world_3d().navigation_map
	var destinations: Array[Vector3] = [
		Vector3(0, 0, 6), Vector3(0, 0, 23), Vector3(-12, 0, 26), Vector3(0, 0, 58),
	]
	for predator: ArcaRaptor in room.get_predators():
		var origin := predator.global_position
		if predator == room.enemy:
			origin = room.get_node("HatchClearance").global_position
		for destination: Vector3 in destinations:
			var path := NavigationServer3D.map_get_path(map, origin, destination, true)
			check(not path.is_empty() and path[-1].distance_to(destination) < 0.8,
				"%s has a baked route to %s" % [predator.name, destination])


func chase_checks() -> void:
	await reset_mission()
	await open_lift_for_exit_fixture()
	room.door.open()
	await frames(70)
	var actors: Array[ArcaRaptor] = [
		room.enemy, room.get_node("SecurityCorridor/SleepingRaptor"), room.get_node("ExitLift/FinalRaptor"),
	]
	var starts: Array[Vector3] = [
		Vector3(0.4, 0.05, 8.55), actors[1].position + Vector3(0, 0, CORRIDOR_Z),
		actors[2].global_position,
	]
	var targets: Array[Vector3] = [
		Vector3(-12, 0.05, 26), Vector3(0, 0.05, 58), Vector3(0, 0.05, 6),
	]
	for actor: ArcaRaptor in actors:
		actor.collision_layer = 0
		actor.collision_mask = 0
	for index: int in actors.size():
		await move_player(targets[index])
		var actor := actors[index]
		actor.global_position = starts[index]
		actor.collision_mask = 3
		actor.combat_enabled = true
		actor.attack_range = 0.1
		actor.set_physics_process(true)
		hold_navigation_target(actor, room.player.position)
		for frame: int in range(1500):
			await frames(1)
			if actor.global_position.distance_to(room.player.global_position) < 1.5 and actor.agent.is_navigation_finished():
				break
		check(actor.global_position.distance_to(room.player.global_position) < 1.5 and actor.agent.is_navigation_finished(),
			"%s follows its path into pursuit range (actual %s)" % [actor.name, actor.global_position])
		actor.stop_combat()
		actor.collision_mask = 0


func freight_discovery_check() -> void:
	await reset_mission()
	var raptor := room.get_node("ExitLift/FinalRaptor") as ArcaRaptor
	raptor.combat_enabled = true
	await move_player(Vector3(-4.75, 0.05, 56.2))
	for tick: int in range(200):
		await frames(1)
		if raptor.position.x > -6.8:
			break
	check(raptor.position.x > -6.8 and raptor.state != ArcaRaptor.State.WAIT,
		"Normal detection brings the freight raptor through the wrecked shutter (actual %s, %s)"
			% [raptor.global_position, raptor.get_status_text()])
