extends "res://arca/tests/mission_test.gd"
## Exercise the live mission trigger, cancellation and predator activation.

var ambush_count: int = 0

func restore_power() -> void:
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()

func run() -> void:
	await reset_mission()
	check(room.enemy.state == ArcaRaptor.State.DORMANT and not room.enemy.visible,
		"The mission starts without a visible predator")
	check(room.enemy.collision_layer == 0 and room.enemy.collision_mask == 0,
		"The hidden predator cannot block movement or projectiles")
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
	var time_before_pause: float = room.ambush_remaining
	room.set_paused(true)
	await frames(100)
	check(is_equal_approx(room.ambush_remaining, time_before_pause) and not room.ambush_triggered,
		"Pause freezes the warning countdown")
	room.ambush_started.connect(func(): ambush_count += 1)
	room.set_paused(false)
	await frames(90)
	check(room.ambush_triggered and room.enemy.visible and room.enemy.combat_enabled,
		"Resuming activates the real animated predator after the warning")
	check(room.enemy.collision_layer == 1 and room.enemy.collision_mask == 3,
		"Activation restores the predator's original physics layers")
	check(ambush_count == 1 and not room.enemy.activate_ambush(),
		"An active predator cannot be activated twice")
	var start_distance: float = room.enemy.position.distance_to(room.player.position)
	await frames(150)
	check(room.enemy.position.distance_to(room.player.position) < start_distance - 2.0,
		"The ambush spawn has a usable navigation route around cover")
	await press_e()
	check(ambush_count == 1 and get_nodes_in_group("arca_predator").size() == 1,
		"Repeated panel input cannot create another predator")
	room.player.take_damage(1000)
	check(not room.enemy.combat_enabled, "Player death stops an active ambush")

	await reset_mission()
	await restore_power()
	room.player.take_damage(1000)
	await frames(120)
	check(not room.ambush_triggered and not room.enemy.visible,
		"Death during the warning cancels the pending ambush")

	await reset_mission()
	await restore_power()
	await reset_mission()
	await frames(120)
	check(not room.ambush_triggered and not room.power_restored and room.enemy.state == ArcaRaptor.State.DORMANT,
		"Restart during the warning discards the old trigger and resets the mission")

	await restore_power()
	# A fast player can escape before activation; completion must remain final.
	await frames(62)
	await move_player(Vector3(0, 0.05, 12.4))
	check(room.mission_complete and not room.ambush_triggered,
		"A fast exit completes the mission without requiring a kill")
	await frames(120)
	check(not room.enemy.visible and not room.enemy.combat_enabled,
		"No pending ambush can activate after mission completion")

	print("AMBUSH RESULT: %d checks, %d failures" % [checks, failures])
	paused = false
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)
