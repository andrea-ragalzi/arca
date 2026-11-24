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


func presentation_checks(predator: ArcaRaptor) -> void:
	check(predator.skin.scene_file_path == "res://arca/enemies/ferocious_model.tscn",
		"Gameplay uses the Ferocious Industries model wrapper")
	check(predator.skin.scale.is_equal_approx(Vector3.ONE)
		and predator.skin.basis.z.is_equal_approx(Vector3.FORWARD),
		"Native model scale and -Z gameplay facing are preserved")
	var capsule: CapsuleShape3D = predator.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius, 0.45) and is_equal_approx(capsule.height, 1.45)
		and is_equal_approx(predator.move_speed, 3.2) and predator.attack_damage == 20,
		"The visual replacement does not change collision, chase speed or damage")
	var model: Node3D = load("res://arca/enemies/ferocious_model.tscn").instantiate()
	root.add_child(model)
	await process_frame
	var animation: AnimationPlayer = model.get_node("AnimationPlayer")
	var imported: AnimationPlayer = model.get_node("Model/AnimationPlayer")
	check(not imported.active and imported.get_animation_list().size() == 26,
		"All source clips remain available, but only the gameplay player drives the rig")
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var root_bone: int = skeleton.find_bone("Root_02")
	var jaw: int = skeleton.find_bone("Jaw_1_014")
	check(skeleton.get_bone_count() == 137 and root_bone >= 0 and jaw >= 0,
		"The original complete rig, root and jaw are bound")
	var sources: Dictionary = {"Idle": "Idle_02", "Walk": "Walk", "Run": "Jog",
		"Attack": "Bite_02", "Death": "Death_01", "Jump": "Leap_01",
		"Hurt": "Hurt_01", "Roar": "Roar_03"}
	for action: String in sources:
		var name: StringName = predator.clips[action]
		var clip: Animation = animation.get_animation(name)
		check(clip != null and clip.get_meta("source_clip") == sources[action],
			"%s explicitly binds the intended real source clip" % action)
		check(clip.loop_mode == (Animation.LOOP_LINEAR if action in ["Idle", "Walk", "Run"] else Animation.LOOP_NONE),
			"%s has the intended loop/one-shot behavior" % action)
		var valid: bool = true
		for track: int in clip.get_track_count():
			var path: NodePath = clip.track_get_path(track)
			var target: Node = model.get_node_or_null(NodePath(path.get_concatenated_names()))
			valid = valid and target != null and clip.track_get_type(track) not in [Animation.TYPE_METHOD, Animation.TYPE_AUDIO]
			if target is Skeleton3D and path.get_subname_count() > 0:
				valid = valid and skeleton.find_bone(path.get_subname(0)) >= 0
		check(valid, "%s resolves every track and cannot trigger gameplay events" % action)
		skeleton.reset_bone_poses()
		animation.play(name)
		var anchored: bool = true
		var finite: bool = true
		for phase: int in 5:
			animation.seek(clip.length * phase / 4.0, true)
			skeleton.force_update_all_bone_transforms()
			anchored = anchored and skeleton.get_bone_pose_position(root_bone).length() < 0.0001
			for bone: int in skeleton.get_bone_count():
				finite = finite and skeleton.get_bone_global_pose(bone).is_finite()
		check(anchored and finite, "%s retains finite poses without moving its physics-owned root" % action)
	check(is_equal_approx(animation.get_animation(predator.clips["Walk"]).length, 2.9 / 1.6)
		and is_equal_approx(animation.get_animation(predator.clips["Run"]).length, 3.2453 / 3.2),
		"Walk and jog presentation match the unchanged gameplay movement speeds")
	var attack: Animation = animation.get_animation(predator.clips["Attack"])
	check(absf(attack.length - 5.0 / 6.0) < 0.00001,
		"New attack presentation preserves the previous 0.833333 s combat cycle")
	animation.play(predator.clips["Attack"])
	animation.seek(0.0, true)
	var closed: Quaternion = skeleton.get_bone_pose_rotation(jaw)
	animation.seek(0.12, true)
	check(closed.angle_to(skeleton.get_bone_pose_rotation(jaw)) > deg_to_rad(20.0),
		"The bite visibly opens before the unchanged hit time")
	animation.seek(0.24, true)
	check(closed.angle_to(skeleton.get_bone_pose_rotation(jaw)) < deg_to_rad(5.0),
		"The bite jaw closes near the existing 0.24 s damage check")
	var hurt: Animation = animation.get_animation(predator.clips["Hurt"])
	var roar: Animation = animation.get_animation(predator.clips["Roar"])
	check(is_equal_approx(hurt.length, predator.stagger_duration)
		and is_equal_approx(roar.length, ArcaRaptor.ALERT_DURATION),
		"Hurt and roar presentations fit the stagger and unchanged alert windows")
	animation.play(predator.clips["Roar"])
	animation.seek(0.0, true)
	var roar_closed: Quaternion = skeleton.get_bone_pose_rotation(jaw)
	animation.seek(0.23, true)
	var roar_open: float = roar_closed.angle_to(skeleton.get_bone_pose_rotation(jaw))
	animation.seek(roar.length, true)
	var roar_end: float = roar_closed.angle_to(skeleton.get_bone_pose_rotation(jaw))
	check(roar_open > deg_to_rad(45.0) and roar_end < deg_to_rad(10.0),
		"The roar opens the jaw wide early in the alert and closes before the chase")
	model.queue_free()
	var before: float = predator.animation.current_animation_position
	room.set_paused(true)
	await frames(30)
	check(is_equal_approx(predator.animation.current_animation_position, before),
		"Pause freezes the replacement animation player")
	room.set_paused(false)
	await frames(2)
	check(predator.animation.current_animation_position > before,
		"Resume advances the same replacement clip")


func reaction_checks() -> void:
	await reset_room()
	var predator: ArcaRaptor = room.enemy
	var staggers: Array[int] = [0]
	predator.staggered.connect(func(): staggers[0] += 1)
	predator.hit()
	check(predator.state == ArcaRaptor.State.ALERT and staggers[0] == 0,
		"A hit on a waiting predator still alerts it instead of staggering it")
	check(predator.animation.current_animation == predator.clips["Roar"] and predator.warning.visible,
		"The alert phase plays the roar with the existing warning marker")

	await reset_room()
	predator = room.enemy
	staggers = [0]
	predator.staggered.connect(func(): staggers[0] += 1)
	predator.position = Vector3(0, 0.05, -7.4)
	predator._change_state(ArcaRaptor.State.WINDUP)
	await frames(5)
	predator.hit()
	check(predator.state == ArcaRaptor.State.HURT and staggers[0] == 1
		and predator.animation.current_animation == predator.clips["Hurt"] and not predator.warning.visible,
		"A hit during the windup staggers the predator and plays the hurt reaction")
	check(predator.get_status_text().ends_with("STAGGERED"), "Telemetry reports the stagger")
	await frames(20)
	check(predator.state == ArcaRaptor.State.HURT, "The stagger holds the predator in place briefly")
	await frames(25)
	check(room.player.health_component.current == 100,
		"The staggered windup never delivers its bite")
	check(predator.state in [ArcaRaptor.State.CHASE, ArcaRaptor.State.WINDUP],
		"The predator resumes the hunt after the stagger")

	await reset_room()
	predator = room.enemy
	staggers = [0]
	predator.staggered.connect(func(): staggers[0] += 1)
	predator.health_component.max_health = 20
	predator.health_component.current = 20
	predator.position = Vector3(0, 0.05, 2)
	predator._change_state(ArcaRaptor.State.CHASE)
	for shot in 5:
		predator.hit()
		await frames(12)
	check(staggers[0] == 1 and predator.health == 15,
		"Five hits within the cooldown deal full damage but cause only one stagger")
	await frames(45)
	predator.hit()
	check(staggers[0] == 2 and predator.state == ArcaRaptor.State.HURT,
		"The predator can be staggered again once the cooldown has elapsed")

	await reset_room()
	predator = room.enemy
	predator.position = Vector3(0, 0.05, 2)
	predator._change_state(ArcaRaptor.State.CHASE)
	predator.hit()
	await frames(6)
	var hurt_elapsed: float = predator.elapsed
	var cooldown_left: float = predator.stagger_cooldown_remaining
	room.set_paused(true)
	await frames(40)
	check(predator.state == ArcaRaptor.State.HURT and is_equal_approx(predator.elapsed, hurt_elapsed)
		and is_equal_approx(predator.stagger_cooldown_remaining, cooldown_left),
		"Pause freezes the stagger and its cooldown")
	room.set_paused(false)
	var deaths: Array[int] = [0]
	predator.exploded.connect(func(): deaths[0] += 1)
	predator.health_component.current = 1
	await frames(10)
	predator.hit()
	await frames(5)
	check(predator.dead and deaths[0] == 1, "A lethal hit during the stagger kills the predator once")

	await reset_room()
	predator = room.enemy
	staggers = [0]
	predator.staggered.connect(func(): staggers[0] += 1)
	predator.position = Vector3(0, 0.05, -7.4)
	predator._change_state(ArcaRaptor.State.ATTACK)
	predator.hit()
	check(predator.state == ArcaRaptor.State.ATTACK and staggers[0] == 0,
		"A committed bite is not interrupted by a hit")

	await reset_room()
	predator = room.enemy
	staggers = [0]
	predator.staggered.connect(func(): staggers[0] += 1)
	var health_before: int = predator.health
	predator.prepare_ambush()
	predator.hit()
	check(predator.health == health_before and predator.state == ArcaRaptor.State.DORMANT,
		"A dormant predator stays immune")
	predator.emerge_from_hatch(predator.global_position + Vector3(3, 0, 0))
	predator.hit()
	check(predator.state == ArcaRaptor.State.EMERGE and predator.health == health_before - 1 and staggers[0] == 0,
		"An emerging predator takes damage without staggering")


func run() -> void:
	await reset_room()
	var predator: ArcaRaptor = room.enemy
	check(predator.clips.size() == 10, "Ten real source-backed gameplay animation bindings are loaded")
	await presentation_checks(predator)
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

	await reaction_checks()
	await sleep_checks()

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


func spawn_sleeper() -> ArcaRaptor:
	var sleeper: ArcaRaptor = load("res://arca/enemies/raptor.tscn").instantiate()
	sleeper.set("start_mode", 1)
	sleeper.position = Vector3(0, 0.05, -4)
	room.add_child(sleeper)
	return sleeper


func sleep_checks() -> void:
	await reset_room()
	check(room.enemy.get("start_mode") != null, "Raptor exposes a configurable sleeping start")
	if room.enemy.get("start_mode") == null:
		return
	room.enemy.prepare_ambush()
	var sleeper := spawn_sleeper()
	var hp: int = room.player.health_component.current
	var facing := sleeper.rotation.y
	room.player.position = Vector3(4, 0.05, -4)
	await frames(75)
	check(sleeper.get_status_text().contains("SLEEPING") and sleeper.collision_layer != 0
		and is_equal_approx(sleeper.rotation.y, facing) and room.player.health_component.current == hp,
		"A solid sleeper stays asleep, facing the same way with the player four metres away")
	check(sleeper.animation.current_animation == &"Ferocious_Sleep"
		and sleeper.animation.get_animation(&"Ferocious_Sleep").loop_mode == Animation.LOOP_LINEAR,
		"The sleeping pose uses the authentic looping source clip")

	room.player.position = Vector3(0, 0.05, 11)
	room.player.shot_fired.emit()
	check(sleeper.get_status_text().contains("SLEEPING"), "Shooting 15 m away does not wake a sleeper")
	room.player.position = Vector3(0, 0.05, 6)
	room.player.shot_fired.emit()
	check(sleeper.animation.current_animation == &"Ferocious_Wake", "Shooting 10 m away starts the wake clip")
	await frames(112)
	check(sleeper.state == ArcaRaptor.State.ALERT and sleeper.animation.current_animation == &"Ferocious_Roar",
		"Completing the wake animation enters the normal alert roar")

	await reset_room()
	room.enemy.prepare_ambush()
	sleeper = spawn_sleeper()
	room.player.position = Vector3(0, 0.05, -6)
	await frames(32)
	room.set_paused(true)
	await frames(75)
	check(sleeper.get_status_text().contains("SLEEPING"), "Pause freezes the sleeper proximity timer")
	room.set_paused(false)
	await frames(32)
	check(sleeper.animation.current_animation == &"Ferocious_Wake", "One second within 2.5 m starts waking")

	await reset_room()
	check(not is_instance_valid(sleeper), "Restart destroys the previous sleeping encounter")
	room.enemy.prepare_ambush()
	sleeper = spawn_sleeper()
	check(sleeper.get_status_text().contains("SLEEPING"), "A fresh sleeping encounter restarts in sleep")
	sleeper.hit()
	check(sleeper.animation.current_animation == &"Ferocious_Wake", "A nonlethal hit wakes a sleeper immediately")
	var lethal_sleeper := spawn_sleeper()
	lethal_sleeper.health_component.current = 1
	var deaths: Array[int] = []
	lethal_sleeper.exploded.connect(func(): deaths.append(1))
	lethal_sleeper.hit()
	lethal_sleeper.hit()
	check(lethal_sleeper.dead and deaths.size() == 1, "A lethal hit during sleep kills and signals exactly once")
