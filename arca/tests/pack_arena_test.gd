extends "res://arca/tests/first_playable_test.gd"

const ARENA := "res://arca/pack_arena.tscn"

func run() -> void:
	check(ResourceLoader.exists(ARENA), "The three-raptor arena is available from the game")
	if ResourceLoader.exists(ARENA):
		var assets := 0
		for bank: Array in ArcaRaptor.REPERTOIRE.values():
			for stream: AudioStreamWAV in bank:
				if stream.mix_rate == 48000 and not stream.stereo and stream.get_length() > 0:
					assets += 1
		check(assets == 16, "All sixteen repertoire WAVs import as 48 kHz mono")
		utility_checks()
		await arena_checks()
	print("PACK ARENA RESULT: %d checks, %d failures" % [checks, failures])
	if is_instance_valid(room):
		room.stop_audio()
		current_scene = null
		room.queue_free()
		await process_frame
	OS.delay_msec(200)
	quit(1 if failures else 0)

func arena_checks() -> void:
	var title: Node = load("res://arca/ui/title_screen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	var training := title.find_child("PackTraining") as Button
	check(training != null, "Pack Training is a dedicated title action")
	if training == null:
		title.free()
		return
	training.pressed.emit()
	await frames(5)
	room = current_scene
	var predators: Array[ArcaRaptor] = room.get_predators()
	check(predators.size() == 3 and predators.all(func(actor: ArcaRaptor): return actor.behavior != null),
		"All three opponents use the sensory combat profile")
	for actor: ArcaRaptor in predators:
		actor.rotation.y = 0.0
		actor.call_cooldown = 0.0
		actor.reply_remaining = 0.0
		actor.last_known_position = Vector3.INF
		actor.perception_remaining = 0.0
		actor.perceived = false
		actor._change_state(ArcaRaptor.State.WAIT)
	var cover := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 2.5, 0.2)
	shape.shape = box
	cover.add_child(shape)
	room.add_child(cover)
	cover.position = Vector3(-1.1, 1.25, -7.45)
	predators[2].stop_combat()
	var caller := predators[0]
	var responder := predators[1]
	caller.global_position = Vector3(0, 0.05, -5.7)
	responder.global_position = Vector3(-2.2, 0.05, -5.7)
	responder.rotation.y = PI
	await frames(5)
	check(caller.voice.stream != null and caller.voice.stream.resource_path.contains("call_"),
		"A real sighting selects the custom pack call")
	await frames(101)
	check(responder.voice.stream != null and responder.voice.stream.resource_path.contains("reply_")
		and responder.voice.playing and not responder.last_known_position.is_finite()
		and responder.reply_origin.distance_to(caller.global_position) < 1.2
		and caller.voice_variant != responder.voice_variant,
		"A nearby raptor replies to the caller before tracking Regina")
	room.restart_room()
	await frames(18)
	room = current_scene
	check(room.get_predators().size() == 3 and room.player.health_component.current == 100,
		"Restart restores the arena roster and player")
	var figure: Node3D = room.player.player_model.get_node("ReginaModel")
	check(figure.find_child("SORTPatch", true, false) != null and figure.find_child("FieldPack", true, false) != null,
		"The gameplay model wears the reference patch and backpack")

	await combat_checks()
	await jump_surface_checks()
	await regina_surface_checks()
	await separation_checks()
	await airborne_reaction_check()
	await down_volume_check()
	await engagement_range_checks()
	await autonomous_descent_checks()
	await occupied_deck_checks()
	room.set_paused(true)
	var title_button := room.hud.find_child("ReturnToTitle") as Button
	check(paused and title_button.is_visible_in_tree(), "Pause offers a return to the title")
	title_button.pressed.emit()
	await frames(3)
	check(not paused and current_scene.find_child("PackTraining") != null, "Leaving the arena restores an unpaused title")


func combat_checks() -> void:
	var actors: Array[ArcaRaptor] = room.get_predators()
	var starting_positions: Array[Vector3] = [
		Vector3(0, 0.05, -5.85), Vector3(-2.55, 0.05, -6.05), Vector3(2.6, 0.05, -5.9)]
	for index in actors.size():
		var actor := actors[index]
		actor.global_position = starting_positions[index]
		var towards: Vector3 = room.player.global_position - actor.global_position
		actor.rotation.y = atan2(-towards.x, -towards.z)
		actor.reset_physics_interpolation()
	var attacking := [ArcaRaptor.State.ATTACK, ArcaRaptor.State.POUNCE, ArcaRaptor.State.SLASH]
	var took_turn: Dictionary[ArcaRaptor, bool] = {}
	var simultaneous := false
	var flanked := false
	var closest := INF
	for tick in 405:
		await frames(1)
		var committed := 0
		for index in actors.size():
			var actor := actors[index]
			flanked = flanked or actor.state == ArcaRaptor.State.FLANK
			if actor.state in attacking:
				committed += 1
				took_turn[actor] = true
			for other in range(index + 1, actors.size()):
				closest = minf(closest, actor.global_position.distance_to(actors[other].global_position))
		simultaneous = simultaneous or committed > 1
	check(took_turn.size() >= 2 and flanked, "Pack members take turns and attempt a lateral approach")
	check(not simultaneous and closest > 0.7, "The three nearby predators keep clearance and avoid simultaneous strikes")

func jump_surface_checks() -> void:
	room.restart_room()
	await frames(18)
	room = current_scene
	var actors: Array[ArcaRaptor] = room.get_predators()
	var actor := actors[0]
	# Isolate the authored routes from the player stationed elsewhere in the bay.
	actor.detection_range = 10.0
	for index in range(1, actors.size()):
		actors[index].stop_combat()
		actors[index].global_position = Vector3(8 + index, 0, -10)
	room.player.global_position = Vector3(9, 0, 11)
	for fixture: String in ["Desk", "Workbench", "Platform"]:
		var up := room.get_node(fixture + "/Up") as ArcaRaptorJumpPoint
		var down := room.get_node(fixture + "/Down") as ArcaRaptorJumpPoint
		actor.global_position = up.global_position
		actor.velocity = Vector3.ZERO
		actor._change_state(ArcaRaptor.State.WAIT)
		actor.rotation.y = PI
		await frames(5)
		check(actor.try_environment_jump(up) and up.occupant == actor, fixture + " has a reserved takeoff")
		var saw_flight := false
		for frame in 82:
			await frames(1)
			saw_flight = saw_flight or actor.state == ArcaRaptor.State.JUMP
		check(saw_flight and actor.is_on_floor() and up.occupant == null
			and absf(actor.global_position.y - up.landing.global_position.y) < 0.14,
			fixture + " has physical flight, touchdown and release")
		var start := actor.global_position
		actor._set_maneuver(down.global_position + Vector3(0.13, 0, 0), ArcaRaptor.State.PATROL)
		await frames(35)
		check(actor.global_position.distance_to(start) > 0.35 and actor.global_position.y > 0.60,
			fixture + " supports nav walking on top")
		check(actor.try_environment_jump(down), fixture + " has a physical descent route")
		await frames(79)
		check(actor.is_on_floor() and actor.global_position.y < 0.15, fixture + " returns to the ground")

	await blocked_jumps(actor, actors[1])
	var desk := room.get_node("Desk/Up") as ArcaRaptorJumpPoint
	actor.global_position = desk.global_position + Vector3(0, 0, -0.60)
	actor.rotation.y = PI
	actor._change_state(ArcaRaptor.State.WAIT)
	actor.last_known_position = Vector3.INF
	actor.velocity = Vector3.ZERO
	room.player.global_position = desk.landing.global_position + Vector3(1.20, 0.06, 0)
	await frames(230)
	check(actor.global_position.y > 0.60, "A real sighting on the desk triggers an autonomous ascent")
	check(actor.navigation_link_arrivals > 0, "The autonomous ascent uses an actual NavigationLink event")

func blocked_jumps(actor: ArcaRaptor, ally: ArcaRaptor) -> void:
	var up := room.get_node("Desk/Up") as ArcaRaptorJumpPoint
	var alternate := room.get_node("Desk/UpFar") as ArcaRaptorJumpPoint
	actor.global_position = up.global_position
	actor.velocity = Vector3.ZERO
	actor._change_state(ArcaRaptor.State.WAIT)
	await frames(5)
	room.player.global_position = up.landing.global_position
	await frames(3)
	check(not actor.try_environment_jump(up), "A player on the destination blocks the jump")
	room.player.global_position = Vector3(9, 0, 11)
	var wall := StaticBody3D.new()
	var node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3, 0.15)
	node.shape = shape
	wall.add_child(node)
	room.add_child(wall)
	wall.position = up.global_position.lerp(up.landing.global_position, 0.45) + Vector3.UP
	await frames(4)
	check(not actor.try_environment_jump(up), "A wall intersecting the capsule arc blocks takeoff")
	check(actor._seek_environment_jump(up.landing.global_position) and actor.planned_jump == alternate,
		"Pathfinding selects the opposite marked approach when the near arc is blocked")
	wall.queue_free()
	actor.global_position = up.global_position
	actor.velocity = Vector3.ZERO
	actor.last_known_position = Vector3.INF
	actor._change_state(ArcaRaptor.State.WAIT)
	await frames(6)
	check(actor.try_environment_jump(up), "A cleared route can be reserved")
	ally.combat_enabled = true
	ally._change_state(ArcaRaptor.State.WAIT)
	ally.global_position = alternate.global_position
	ally.velocity = Vector3.ZERO
	await frames(3)
	check(not ally.try_environment_jump(alternate), "A second raptor cannot reserve an overlapping landing")
	actor._change_state(ArcaRaptor.State.WAIT)
	check(up.occupant == null and ally.try_environment_jump(alternate),
		"Cancellation releases the reservation and another raptor can take the alternate approach")
	ally.stop_combat()
	ally.global_position = Vector3(9, 0, -10)

func regina_surface_checks() -> void:
	room.restart_room()
	await frames(18)
	room = current_scene
	var player = room.player
	var actors: Array[ArcaRaptor] = room.get_predators()
	room.stop_all_predators()
	var events: Array[StringName] = []
	player.physical_audio.connect(func(event: StringName): events.append(event))
	for fixture: String in ["Desk", "Workbench", "Platform"]:
		var point := room.get_node(fixture + "/Up") as ArcaRaptorJumpPoint
		await place_regina(point.global_position + Vector3.UP * 0.035, 0.0)
		events.clear()
		await player_jump_input()
		var height: float = point.landing.global_position.y - 0.13
		check(player.is_on_floor() and player.global_position.y >= height,
			"Regina jumps onto the %s through TPS input (actual %s)" % [fixture, player.global_position])
		check(events.count(&"effort") == 1 and events.count(&"landing") == 1,
			"One takeoff and landing audio event on the " + fixture)
		var start: Vector3 = player.global_position
		Input.action_press("move_right")
		await frames(11)
		Input.action_release("move_right")
		await frames(8)
		check(player.is_on_floor() and player.global_position.y >= height and player.global_position.distance_to(start) > 0.10,
			"Regina walks on the " + fixture)
		Input.action_press("move_forward")
		await frames(62)
		Input.action_release("move_forward")
		await frames(15)
		check(player.is_on_floor() and player.global_position.y < 0.14 and events.count(&"landing") == 2,
			"Regina leaves the edge, lands and plays one floor cue")

	var desk := room.get_node("Desk/Up") as ArcaRaptorJumpPoint
	var destination: Vector3 = desk.landing.global_position
	destination.x = desk.global_position.x
	actors[0].global_position = destination
	await place_regina(desk.global_position + Vector3.UP * 0.035, 0.0)
	await player_jump_input()
	check(player.global_position.y < 0.18 and player.global_position.z < destination.z - 0.70,
		"An occupied desk falls back to the low jump and cannot be crossed")
	actors[0].global_position = Vector3(9, 0, 10)
	await place_regina(desk.global_position + Vector3(0, 0.035, 0.99), 0.0)
	await player_jump_input()
	check(player.global_position.y > 0.65, "The reproduced close approach loads vertically before crossing the desk edge")
	await place_regina(desk.global_position + Vector3(0, 0.035, 1.39), 0.0)
	await player_jump_input()
	check(player.global_position.y < 0.18 and player.global_position.z < destination.z - 0.70,
		"A jump pressed against the desk face stays outside the cover")
	var ceiling := test_box(desk.global_position + Vector3.UP * 2.24, Vector3(2.1, 0.12, 2.8))
	await place_regina(desk.global_position + Vector3.UP * 0.035, 0.0)
	await player_jump_input()
	check(player.global_position.y < 0.18, "Low ceiling vetoes the traversal arc")
	ceiling.queue_free()
	await place_regina(desk.global_position + Vector3.UP * 0.035, 0.0)
	Input.action_press("move_forward")
	await frames(3)
	Input.action_press("jump")
	await frames(5)
	Input.action_release("jump")
	Input.action_release("move_forward")
	check(player.reserved_top.is_finite(), "The in-flight assisted jump initially owns a clear landing")
	actors[0].global_position = destination
	await frames(64)
	check(not player.reserved_top.is_finite() and player.is_on_floor() and player.global_position.y < 0.18,
		"A newly occupied landing interrupts assistance without forcing the body through the occupant")
	actors[0].global_position = Vector3(9, 0, 10)


func place_regina(position: Vector3, yaw: float) -> void:
	room.player.global_position = position
	room.player.velocity = Vector3.ZERO
	room.player.player_input.camera_base.rotation.y = yaw
	room.player.reset_physics_interpolation()
	await frames(12)


func player_jump_input() -> void:
	Input.action_press("move_forward")
	await frames(3)
	Input.action_press("jump")
	await frames(3)
	Input.action_release("jump")
	Input.action_release("move_forward")
	await frames(62)


func test_box(position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	node.shape = shape
	body.add_child(node)
	room.add_child(body)
	body.global_position = position
	return body


func separation_checks() -> void:
	var actors: Array[ArcaRaptor] = room.get_predators()
	var player = room.player
	var events: Array[StringName] = []
	player.physical_audio.connect(func(event: StringName): events.append(event))
	# A short lane with one capsule-width opening. The first raptor is braced at the end.
	var west := test_box(Vector3(-0.75, 1, -8), Vector3(0.15, 2, 4))
	var east := test_box(Vector3(0.75, 1, -8), Vector3(0.15, 2, 4))
	actors[0].global_position = Vector3(0, 0, -7)
	actors[1].global_position = Vector3(0, 0, -8.05)
	await place_regina(Vector3(0, 0.05, -9.4), 0.0)
	Input.action_press("move_forward")
	await frames(50)
	Input.action_release("move_forward")
	check(player.global_position.z <= actors[1].global_position.z - 0.91,
		"TPS running cannot pass through a raptor in a narrow lane")
	actors[1].combat_enabled = true
	actors[1].last_known_position = Vector3(0, 0, -5)
	actors[1]._change_state(ArcaRaptor.State.CHASE)
	var closest := INF
	for tick in 45:
		await frames(1)
		closest = minf(closest, actors[0].global_position.distance_to(actors[1].global_position))
	check(closest > 0.86, "Raptor navigation respects the other capsule in a narrow lane")
	actors[1].stop_combat()
	actors[0].global_position = Vector3(9, 0, 10)
	actors[1].global_position = Vector3(8, 0, 10)
	await frames(52)
	events.clear()
	player.take_pounce_damage(12, Vector3.RIGHT)
	await frames(145)
	check(player.is_downed() and player.global_position.x < 0.26
		and events.count(&"hit") == 1 and events.count(&"fall") == 1,
		"Knockdown stops at the wall and plays a single fall cue")
	player.take_pounce_damage(12, Vector3.RIGHT)
	await frames(20)
	check(player.is_downed() and events.count(&"hit") == 2, "A second hit during rise interrupts the recovery")
	await frames(190)
	check(player.can_use_weapon() and is_zero_approx(player.regina_visual.rotation.z), "A clean rise restores the pose and weapon")
	west.queue_free()
	east.queue_free()

func airborne_reaction_check() -> void:
	await frames(8)
	var player = room.player
	var desk := room.get_node("Desk/Up") as ArcaRaptorJumpPoint
	var events: Array[StringName] = []
	player.physical_audio.connect(func(event: StringName): events.append(event))
	await place_regina(Vector3(desk.global_position.x, desk.landing.global_position.y + 0.04,
		desk.landing.global_position.z + 0.53), 0.0)
	Input.action_press("move_forward")
	for tick in 55:
		await frames(1)
		if not player.is_on_floor():
			break
	Input.action_release("move_forward")
	check(not player.is_on_floor(), "Regina runs off the edge of the desk before the impact")
	player.take_pounce_damage(12, Vector3(0, 0, 1))
	await frames(45)
	check(player.is_on_floor() and player.is_downed() and events.count(&"landing") == 1 and events.count(&"fall") == 1,
		"An airborne hit waits for floor contact and emits one landing and fall voice")
	await frames(175)
	var before: Vector3 = player.global_position
	Input.action_press("move_forward")
	await frames(25)
	Input.action_release("move_forward")
	check(player.can_use_weapon() and player.global_position.distance_to(before) > 0.30,
		"Floor recovery restores the original movement input")

func utility_checks() -> void:
	var weights := ArcaRaptorBehavior.new()
	var first := ArcaRaptorUtility.new(981)
	var repeated := ArcaRaptorUtility.new(981)
	var snapshot := {"candidates": ["observe", "attack", "flank"], "seen": true, "memory": 0.9,
		"lateral": false, "injury": 0.0}
	var outcome := first.choose(snapshot, weights, 0)
	check(outcome == repeated.choose(snapshot, weights, 0) and outcome.decision == "attack",
		"Identical snapshot and seed yield identical utility scores and choice")
	weights.flank_weight = 2.0
	check(first.choose(snapshot, weights, 4).decision == "attack", "A feasible action holds its minimum commitment")
	check(first.choose(snapshot, weights, 5, true).decision == "flank", "An interruption can replace a committed action")
	snapshot.candidates = ["observe", "investigate"]
	check(first.choose(snapshot, weights, 6).decision != "flank", "Unavailable actions cannot win with any weight")

func down_volume_check() -> void:
	var player = room.player
	var actor: ArcaRaptor = room.get_predators()[0]
	await place_regina(Vector3(0, 0.05, -10.2), 0.0)
	player.take_pounce_damage(8)
	await frames(35)
	var tilt: float = player.regina_visual.rotation.z
	var side: Vector3 = -player.player_model.global_basis.x * signf(tilt)
	actor.global_position = player.global_position + side * 2.25
	actor.velocity = Vector3.ZERO
	await frames(4)
	var contacts := KinematicCollision3D.new()
	check(not player.down_volume.disabled and actor.test_move(actor.global_transform, -side * 0.78, contacts)
		and contacts.get_collider() == player, "A raptor's swept body hits the downed protection before reaching Regina's torso")
	check(absf(player.regina_visual.rotation.z - tilt) < 0.18,
		"Arrival at the downed body does not snap the floor pose upright")
	await frames(155)
	check(player.down_volume.disabled and player.can_use_weapon(), "Rising releases the downed volume and restores weapon control")

func engagement_range_checks() -> void:
	room.restart_room()
	await frames(15)
	room = current_scene
	var center: ArcaRaptor = room.enemy
	check(center.last_known_position.is_finite() and center.global_position.distance_to(room.player.global_position) > 10.0,
		"The center raptor sees Regina from the real starting positions across the bay")

	var wall := test_box(Vector3(0, 1.6, -3.4), Vector3(14, 3.2, 0.20))
	center.position = Vector3(0, 0.05, 2.7)
	center.rotation.y = PI
	center.last_known_position = Vector3.INF
	center.perceived = false
	center._change_state(ArcaRaptor.State.WAIT)
	var start := center.global_position
	await frames(19)
	check(not center.last_known_position.is_finite(), "A full wall still blocks long-range sight")
	room.player.shot_fired.emit()
	await frames(50)
	check(not center.last_known_position.is_finite() and center.global_position.z < start.z - 0.85,
		"A gunshot through cover prompts movement toward sound without granting sight")
	wall.queue_free()
	await frames(7)

	room.restart_room()
	await frames(29)
	room = current_scene
	center = room.enemy
	start = center.global_position
	center.rotation.y = PI
	center._change_state(ArcaRaptor.State.WAIT)
	center.perceived = false
	center.last_known_position = Vector3.INF
	Input.action_press("aim")
	await shoot_once_at(center.global_position + Vector3.UP)
	Input.action_release("aim")
	check(center.health < center.health_component.max_health and center.global_position.z < start.z - 1.0,
		"A real hit brings a raptor that was facing away toward Regina")

func autonomous_descent_checks() -> void:
	room.restart_room()
	await frames(18)
	room = current_scene
	var actor: ArcaRaptor = room.enemy
	for ally: ArcaRaptor in room.get_predators():
		if ally != actor:
			ally.stop_combat()
			ally.global_position = Vector3(8, 0, 11)
	for fixture: String in ["Desk", "Workbench", "Platform"]:
		var down := room.get_node(fixture + "/Down") as ArcaRaptorJumpPoint
		var near_down := room.get_node(fixture + "/DownNear") as ArcaRaptorJumpPoint
		var top: Vector3 = (down.global_position + near_down.global_position) * 0.5
		await place_regina(Vector3(top.x + 2.0, 0.06, top.z), 0.0)
		actor.global_position = top + Vector3.UP * 0.08
		actor.rotation.y = -PI / 2
		actor.velocity = Vector3.ZERO
		actor.last_known_position = room.player.global_position
		actor.time_out_of_sight = 0.0
		actor._change_state(ArcaRaptor.State.CHASE)
		var blocker: StaticBody3D
		if fixture != "Desk":
			blocker = test_box(down.landing.global_position + Vector3.UP * 0.6, Vector3(1, 1.2, 1))
		var second_blocker: StaticBody3D
		if fixture == "Platform":
			second_blocker = test_box(near_down.landing.global_position + Vector3.UP * 0.6, Vector3(1, 1.2, 1))
			await frames(95)
			check(actor.global_position.y > 0.55 and is_instance_valid(actor),
				"A platform with two occupied exits keeps the raptor safely on top")
			second_blocker.queue_free()
		var descended := false
		for tick in 240:
			await frames(1)
			if actor.is_on_floor() and actor.global_position.y < 0.15:
				descended = true
				break
		await frames(3)
		check(descended and down.occupant == null and near_down.occupant == null,
			"The pursuing raptor leaves the %s and releases the exit even when the direct route is poor" % fixture)
		if is_instance_valid(blocker):
			blocker.queue_free()
		await frames(8)

func occupied_deck_checks() -> void:
	room.restart_room()
	await frames(18)
	room = current_scene
	var actor: ArcaRaptor = room.enemy
	var pack: Array[ArcaRaptor] = room.get_predators()
	var first: ArcaRaptor = pack[0] if pack[0] != actor else pack[1]
	var up := room.get_node("Workbench/Up") as ArcaRaptorJumpPoint
	var top := up.landing.global_position + Vector3(0.0, 0.03, 0.0)
	for other: ArcaRaptor in pack:
		if other != actor:
			other.stop_combat()
			other.global_position = Vector3(9, 0, 11)
	await place_regina(Vector3(9, 0, 11), 0.0)
	actor.global_position = up.global_position
	actor.velocity = Vector3.ZERO
	actor.rotation.y = PI
	actor._change_state(ArcaRaptor.State.WAIT)
	first.global_position = top + Vector3.RIGHT * 0.63
	await frames(8)
	check(not actor.try_environment_jump(up), "A live raptor already on the bench holds the top for itself")
	first.health_component.take_damage(first.health)
	await frames(8)
	var accepted := actor.try_environment_jump(up)
	check(first.dead and not accepted, "A corpse on the workbench keeps a second raptor from booking the top")
	if accepted:
		actor._change_state(ArcaRaptor.State.WAIT)

	await place_regina(top + Vector3.RIGHT * 1.16, 0.0)
	actor.global_position = up.global_position + Vector3(0, 0.035, -1.0)
	actor.rotation.y = PI
	actor.velocity = Vector3.ZERO
	actor.last_known_position = room.player.global_position
	actor.time_out_of_sight = 0.0
	actor._change_state(ArcaRaptor.State.CHASE)
	var visited_top := false
	var traveled := 0.0
	for tick in 240:
		var before := actor.global_position
		await frames(1)
		if tick > 65:
			traveled += actor.global_position.distance_to(before)
		visited_top = visited_top or actor.global_position.y > 0.65
	check(not visited_top and traveled < 1.1,
		"A living raptor waits at the occupied bench without pacing back and forth")
	var guard_origin := actor.global_position
	await place_regina(guard_origin + Vector3(0, 0.04, -5.9), PI)
	room.player.shot_fired.emit()
	var resumed := false
	for tick in 72:
		await frames(1)
		if actor.state != ArcaRaptor.State.GUARD_DECK and actor.is_on_floor() and actor.global_position.z < guard_origin.z - 1.1:
			resumed = true
			break
	check(resumed, "A shot from the ground makes the raptor leave its guard and pursue the new location")
