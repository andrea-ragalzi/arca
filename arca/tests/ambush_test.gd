extends "res://arca/tests/mission_test.gd"
## Exercise the real hatch sequence, collision, cancellation and predator handoff.

var ambush_count: int = 0

func restore_power() -> void:
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()

func wait_for_phase(phase: int, max_frames: int = 240) -> void:
	for i in max_frames:
		if room.ambush_phase == phase:
			return
		await frames(1)
	check(false, "Entrance reaches phase %s within its time bound" % room.AmbushPhase.keys()[phase])

func wait_for_alert() -> void:
	for i in 240:
		if room.enemy.state == ArcaRaptor.State.ALERT:
			return
		await frames(1)
	check(false, "Physical emergence reaches the normal alert state within four seconds")

func hatch_hit() -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(1.5, 1.4, 8.55), Vector3(4.8, 1.4, 8.55), 1, [room.enemy.get_rid()])
	return room.get_world_3d().direct_space_state.intersect_ray(query)

func pause_entrance(label: String) -> void:
	var remaining: float = room.ambush_remaining
	var hatch_position: Vector3 = room.hatch.position
	var enemy_position: Vector3 = room.enemy.position
	var phase: int = room.ambush_phase
	room.set_paused(true)
	await frames(100)
	check(is_equal_approx(room.ambush_remaining, remaining) and room.ambush_phase == phase
		and room.hatch.position == hatch_position and room.enemy.position == enemy_position,
		"Pause freezes countdown, hatch and predator during " + label)
	room.set_paused(false)

func prepare_phase(phase: int) -> void:
	await reset_mission()
	await restore_power()
	await wait_for_phase(phase)
	if phase != room.AmbushPhase.WARNING:
		await frames(12)

func lifecycle_checks() -> void:
	for phase in [room.AmbushPhase.WARNING, room.AmbushPhase.OPENING, room.AmbushPhase.EMERGING]:
		var label: String = room.AmbushPhase.keys()[phase]
		await prepare_phase(phase)
		room.player.take_damage(1000)
		var hatch_position: Vector3 = room.hatch.position
		var enemy_position: Vector3 = room.enemy.position
		var triggered: bool = room.ambush_triggered
		await frames(300)
		room._start_ambush()
		check(room.ambush_phase == room.AmbushPhase.CANCELLED and room.ambush_triggered == triggered
			and not room.enemy.combat_enabled and room.hatch.position == hatch_position
			and room.enemy.position == enemy_position,
			"Death during %s cancels all delayed entrance movement and combat" % label)
		if not triggered:
			check(not room.enemy.visible, "Death during %s cannot reveal the dormant predator" % label)

		await prepare_phase(phase)
		var previous_room: WeakRef = weakref(room)
		await reset_mission()
		await frames(300)
		check(previous_room.get_ref() == null and not room.ambush_triggered and not room.power_restored
			and room.ambush_phase == room.AmbushPhase.IDLE and is_equal_approx(room.hatch.position.y, 1.5)
			and room.enemy.state == ArcaRaptor.State.DORMANT and not room.enemy.visible
			and not hatch_hit().is_empty() and get_nodes_in_group("arca_predator").size() == 1,
			"Restart during %s restores the closed hatch and one dormant predator" % label)

		await prepare_phase(phase)
		# The exit opens independently, including before the warning has expired.
		for i in 90:
			if room.door.is_open:
				break
			await frames(1)
		check(room.door.is_open and room.ambush_phase == phase,
			"The powered exit is usable during " + label)
		await move_player(Vector3(0, 0.05, 12.4))
		hatch_position = room.hatch.position
		enemy_position = room.enemy.position
		triggered = room.ambush_triggered
		await frames(300)
		room._start_ambush()
		check(room.mission_complete and paused and not room.enemy.dead and not room.enemy.combat_enabled
			and room.ambush_phase == room.AmbushPhase.CANCELLED and room.ambush_triggered == triggered
			and room.hatch.position == hatch_position and room.enemy.position == enemy_position,
			"Escape during %s needs no kill and cannot restart the entrance after completion" % label)
		if not triggered:
			check(not room.enemy.visible, "Completion during %s leaves the predator hidden" % label)

func obstruction_and_death_checks() -> void:
	await prepare_phase(room.AmbushPhase.OPENING)
	await move_player(Vector3(1.5, 0.05, 8.55))
	await wait_for_phase(room.AmbushPhase.EMERGING)
	await frames(240)
	check(room.enemy.state == ArcaRaptor.State.EMERGE and room.enemy.position.x > room.player.position.x + 0.7
		and room.player.health_component.current == 100,
		"A player camping the threshold blocks emergence without clipping or premature bites")
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await wait_for_alert()
	check(room.enemy.position.distance_to(room.get_node("HatchClearance").position) < 0.15,
		"The predator finishes walking out after the player clears the threshold")

	await prepare_phase(room.AmbushPhase.EMERGING)
	var health_before: int = room.enemy.health
	room.enemy.hit()
	check(room.enemy.health == health_before - 1 and room.enemy.state == ArcaRaptor.State.EMERGE,
		"The exposed emerging predator accepts the existing weapon hit contract")
	for i in 5:
		await frames(10)
		room.enemy.hit()
	check(room.enemy.dead, "The predator can be killed before emergence completes")
	var death_position: Vector3 = room.enemy.position
	await frames(300)
	check(room.enemy.dead and room.enemy.position == death_position
		and room.hud.get_node("Frame/Notice").text != "PREDATOR EMERGING - fight or reach the green exit!",
		"Death during emergence cannot move or revive the predator at the handoff")

func run() -> void:
	await reset_mission()
	var predator_id: int = room.enemy.get_instance_id()
	check(room.enemy.state == ArcaRaptor.State.DORMANT and not room.enemy.visible,
		"The mission starts without a visible predator")
	check(room.enemy.collision_layer == 0 and room.enemy.collision_mask == 0,
		"The hidden predator cannot block movement or projectiles")
	var closed_hit: Dictionary = hatch_hit()
	check(not closed_hit.is_empty() and closed_hit.collider == room.hatch,
		"The closed hatch physically blocks the real bay opening")
	var dormant_position: Vector3 = room.enemy.position
	room.enemy.hit()
	await frames(100)
	check(room.enemy.health == 6 and room.enemy.position == dormant_position,
		"Dormant predators ignore stray hits and do not move")
	check(room.enemy.get_status_text() == "NO CONTACT",
		"Debug telemetry does not reveal a dormant predator's health")
	await restore_power()
	check(room.power_restored and room.ambush_remaining > 0.0 and not room.ambush_triggered,
		"Real E interactions schedule the ambush only after installing the fuse")
	check(room.get_node("AlarmLight").visible and room.get_node("BreachWarning").visible,
		"Containment failure has visible warning lights and signage")
	var sight := PhysicsRayQueryParameters3D.create(
		room.player.position + Vector3.UP * 1.6, room.get_node("ServiceHatch/Sign").global_position, 1)
	check(room.get_world_3d().direct_space_state.intersect_ray(sight).is_empty(),
		"The hatch sign is readable above cover from the power-panel approach")
	await pause_entrance("the warning")
	room.ambush_started.connect(func(): ambush_count += 1)
	await wait_for_phase(room.AmbushPhase.OPENING)
	check(not room.enemy.visible and room.enemy.position == dormant_position and not room.ambush_triggered
		and room.player.health_component.current == 100,
		"The full warning elapses before the hatch opens, without early reveal or damage")
	await frames(24)
	check(room.hatch.position.y > 1.5 and room.hatch.position.y < 4.8 and not hatch_hit().is_empty(),
		"The hatch visibly moves over time and its moving collider still blocks the partial opening")
	await pause_entrance("hatch opening")
	await wait_for_phase(room.AmbushPhase.EMERGING)
	check(is_equal_approx(room.hatch.position.y, 4.8) and hatch_hit().is_empty(),
		"The hatch mesh and collision are clear before emergence starts")
	check(room.ambush_triggered and room.enemy.visible and room.enemy.combat_enabled
		and room.enemy.state == ArcaRaptor.State.EMERGE and room.enemy.get_instance_id() == predator_id
		and room.enemy.position.distance_to(dormant_position) < 0.15,
		"The same animated predator is revealed inside the bay, not teleported into the room")
	check(room.enemy.collision_layer == 1 and room.enemy.collision_mask == 3,
		"Activation restores the predator's original physics layers")
	check(ambush_count == 1 and not room.enemy.activate_ambush(),
		"An emerging predator cannot be activated twice")
	check(room.enemy.get_status_text().contains("EMERGING")
		and room.enemy.animation.current_animation == room.enemy.clips["Walk"],
		"Emergence uses the existing walk animation and a valid telemetry label")
	await frames(12)
	await pause_entrance("physical emergence")
	var previous_position: Vector3 = room.enemy.position
	var samples: int = 0
	var crossed_opening: bool = false
	var continuous: bool = true
	var wall_contact: bool = false
	for i in 240:
		if room.enemy.state != ArcaRaptor.State.EMERGE:
			break
		await frames(1)
		var position: Vector3 = room.enemy.position
		continuous = continuous and position.distance_to(previous_position) <= 0.04
		continuous = continuous and absf(position.z - dormant_position.z) < 0.05
		for j in room.enemy.get_slide_collision_count():
			if room.enemy.get_slide_collision(j).get_collider() != room.get_node("Floor"):
				wall_contact = true
		previous_position = position
		crossed_opening = crossed_opening or position.x < room.hatch.position.x - 0.6
		samples += 1
	check(samples > 60 and continuous and crossed_opening and not wall_contact,
		"The raptor physically walks through the opening over many frames without teleporting or wall contact")
	check(room.enemy.state == ArcaRaptor.State.ALERT
		and room.enemy.position.distance_to(room.get_node("HatchClearance").position) < 0.15
		and room.player.health_component.current == 100,
		"Normal combat starts only after the raptor clears the hatch, with no early damage")
	var start_distance: float = room.enemy.position.distance_to(room.player.position)
	await frames(150)
	check(room.enemy.position.distance_to(room.player.position) < start_distance - 2.0,
		"The emerged predator has a usable navigation route around cover")
	await press_e()
	check(ambush_count == 1 and get_nodes_in_group("arca_predator").size() == 1,
		"Repeated panel input cannot create another predator or replay the entrance")
	room.player.take_damage(1000)
	check(not room.enemy.combat_enabled, "Player death stops an active ambush")

	await lifecycle_checks()
	await obstruction_and_death_checks()
	print("AMBUSH RESULT: %d checks, %d failures" % [checks, failures])
	paused = false
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)
