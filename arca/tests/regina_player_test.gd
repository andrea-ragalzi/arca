extends SceneTree
## Integration checks for Regina in the inherited ARCA player scenes.

var checks: int = 0
var failures: int = 0
var actor: Variant
var arena: Node3D


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
	for frame in count:
		await physics_frame
	await process_frame


func check_regina_room(scene_path: String, expected_enemy: String) -> void:
	var packed := load(scene_path) as PackedScene
	check(packed != null, "%s loads" % scene_path)
	if packed == null:
		return
	var room := packed.instantiate()
	root.add_child(room)
	current_scene = room
	await frames(3)
	var player: Variant = room.get_node_or_null("Player")
	check(player != null, "%s has the inherited player controller" % scene_path)
	if player == null:
		room.queue_free()
		await process_frame
		return
	var model: Node3D = player.get_node("PlayerModel/ReginaModel")
	var regina: Node3D = model.get_node("Regina")
	var skeleton: Skeleton3D = regina.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var robot: Node3D = player.get_node("PlayerModel/Robot_Skeleton")
	check(model != null and regina.visible, "%s shows one Regina model" % scene_path)
	check(not robot.visible, "%s suppresses inherited robot geometry and shadows" % scene_path)
	check(player.find_children("*", "Skeleton3D", true, false).size() == 2,
		"Only the hidden inherited robot and one Regina skeleton remain")
	check(room.get_node_or_null(expected_enemy) != null, "%s preserves its room enemy" % scene_path)
	check(player.animation_tree.active and player.animation_tree.root_motion_track == NodePath("RootMotion"),
		"Regina uses the active tree and dedicated root-motion proxy")
	var animation_player: AnimationPlayer = model.get_node("AnimationPlayer")
	var library: AnimationLibrary = animation_player.get_animation_library("")
	check(library != null and library.get_animation_list().size() == 15,
		"Regina gameplay library provides all 15 baked animation clips")
	var tracks_valid: bool = library != null
	if library != null:
		for clip: StringName in library.get_animation_list():
			var animation: Animation = library.get_animation(clip)
			for track in animation.get_track_count():
				var path: NodePath = animation.track_get_path(track)
				tracks_valid = tracks_valid and model.get_node_or_null(
					NodePath(path.get_concatenated_names())) != null
				if path.get_subname_count() > 0:
					tracks_valid = tracks_valid and skeleton.find_bone(path.get_subname(0)) >= 0
	check(tracks_valid, "Every gameplay animation track resolves to Regina or the root-motion proxy")
	var wrist := skeleton.find_bone(&"arm right wrist_021")
	var attachment: BoneAttachment3D = skeleton.get_node_or_null("WeaponAttachment") as BoneAttachment3D
	check(wrist >= 0 and attachment != null and attachment.bone_name == &"arm right wrist_021",
		"Prototype handgun attaches to Regina's named right wrist")
	var muzzle: Marker3D = attachment.get_node_or_null("WeaponSocket/ReginaHandgun/ShootFrom") as Marker3D if attachment else null
	check(muzzle != null and player.shoot_from == muzzle and player.shoot_particle != null \
		and player.muzzle_particle != null, "Projectile origin and both inherited muzzle effects bind to the handgun")
	check(player.get_node_or_null("CameraBase/CameraRot/SpringArm3D") != null \
		and player.get_node_or_null("CapsuleShape3D") != null,
		"Existing camera and player collision remain in the inherited controller")
	room.queue_free()
	await process_frame


func check_original_robot() -> void:
	var packed := load("res://player/player.tscn") as PackedScene
	var player: Variant = packed.instantiate()
	root.add_child(player)
	await frames(2)
	var muzzle: Marker3D = player.get_node("PlayerModel/Robot_Skeleton/Skeleton3D/GunBone/ShootFrom")
	check(not player.directional_locomotion and is_equal_approx(player.jump_speed, 5.0),
		"Original robot keeps turn-to-travel and its 5 m/s jump default")
	check(player.get_node("PlayerModel/Robot_Skeleton").visible,
		"Original robot scene remains visible with its default model")
	check(player.shoot_from == muzzle and player.shoot_particle == muzzle.get_node("ShootParticle") \
		and player.muzzle_particle == muzzle.get_node("MuzzleFlash"),
		"Original robot scene keeps its default muzzle and particle bindings")
	player.queue_free()
	await process_frame


func release_actions() -> void:
	for action in ["aim", "shoot", "jump", "move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)


func stop_actor() -> void:
	if not is_instance_valid(actor):
		return
	actor.animation_tree.active = false
	for animation: AnimationPlayer in actor.find_children("*", "AnimationPlayer", true, false):
		animation.stop()
	for audio: AudioStreamPlayer in actor.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	actor.queue_free()


func spawn_actor(yaw: float = 0.0, aiming: bool = false) -> void:
	release_actions()
	if is_instance_valid(actor):
		stop_actor()
		await process_frame
	actor = load("res://arca/player/arca_player.tscn").instantiate()
	arena.add_child(actor)
	actor.position = Vector3(0, 0.05, 0)
	actor.player_input.camera_base.rotation.y = yaw
	await frames(60)
	actor.player_input.aiming = false
	actor.player_input.toggled_aim = aiming
	actor.player_input.aiming_timer = 0.0
	await frames(30)


func make_box(size: Vector3, center: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	arena.add_child(body)
	return body


func press_direction(direction: Vector2) -> void:
	if direction.x != 0:
		Input.action_press("move_right" if direction.x > 0 else "move_left")
	if direction.y != 0:
		Input.action_press("move_forward" if direction.y > 0 else "move_back")


func test_directions() -> void:
	var directions: Array[Vector2] = [Vector2(0, 1), Vector2(0, -1), Vector2(-1, 0), Vector2(1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for yaw: float in [0.0, PI * 0.5, PI]:
		for aiming: bool in [false, true]:
			for direction: Vector2 in directions:
				await spawn_actor(yaw, aiming)
				press_direction(direction)
				await frames(60)
				var start: Vector3 = actor.position
				var minimum_speed: float = INF
				var maximum_speed: float = 0.0
				var proxy_zero: bool = true
				for frame in 260:
					await frames(1)
					var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
					minimum_speed = minf(minimum_speed, speed)
					maximum_speed = maxf(maximum_speed, speed)
					var proxy: Node3D = actor.get_node("PlayerModel/ReginaModel/RootMotion")
					proxy_zero = proxy_zero and proxy.position.length() < 0.0001
				var camera: Camera3D = actor.player_input.camera_camera
				var forward: Vector3 = -camera.global_basis.z
				forward.y = 0.0
				forward = forward.normalized()
				var right: Vector3 = camera.global_basis.x
				right.y = 0.0
				right = right.normalized()
				var travel: Vector3 = actor.position - start
				var signs_correct: bool = true
				if direction.x != 0:
					signs_correct = signs_correct and travel.dot(right) * direction.x > 0.1
				if direction.y != 0:
					signs_correct = signs_correct and travel.dot(forward) * direction.y > 0.1
				var label: String = "yaw=%d aim=%s direction=%s" % [roundi(rad_to_deg(yaw)), aiming, direction]
				check(signs_correct and minimum_speed > 0.1, label + " travels correctly without a clip-end stall")
				var regina: Node3D = actor.get_node("PlayerModel/ReginaModel/Regina")
				check((regina.global_basis * Vector3.BACK).dot(forward) > 0.99,
					label + " keeps anatomical +Z facing camera-forward")
				var parameter: String = "parameters/strafe/blend_position" if aiming else "parameters/walk/blend_position"
				var blend: Vector2 = actor.animation_tree[parameter]
				check(blend.distance_to(direction.normalized()) < 0.001 and proxy_zero,
					label + " selects signed normalized blend and extracts travel only once")
				check(maximum_speed <= (2.17 if aiming else 4.11), label + " has no diagonal/wrap speed boost")
				release_actions()
				actor.player_input.toggled_aim = aiming
				await frames(90)
				check(Vector2(actor.velocity.x, actor.velocity.z).length() < 0.01, label + " settles to idle")
	await spawn_actor()
	var graph := actor.animation_tree.tree_root as AnimationNodeBlendTree
	var walk := graph.get_node("walk") as AnimationNodeBlendSpace2D
	var expected: Array[StringName] = [&"Idle", &"running_nogun", &"strafe_back", &"strafe_right", &"strafe_left"]
	var selected: Array[StringName] = []
	for point in walk.get_blend_point_count():
		selected.append((walk.get_blend_point_node(point) as AnimationNodeAnimation).animation)
	check(selected == expected, "Non-aim directional graph uses distinct forward, backward and lateral source clips")
	check(not actor.player_input.aiming and actor.animation_tree["parameters/state/current_state"] == "walk",
		"Directional non-aim movement does not fake aim/fire state")


func test_jumps() -> void:
	var library: AnimationLibrary = load("res://arca/assets/characters/regina/gameplay.tres")
	check(library.get_animation("jump_2_upwards").loop_mode == Animation.LOOP_NONE \
		and library.get_animation("jump_5_hardlanding").loop_mode == Animation.LOOP_NONE,
		"Takeoff and landing poses do not loop")
	for moving: bool in [false, true]:
		await spawn_actor()
		if moving:
			Input.action_press("move_forward")
			await frames(45)
		var start_y: float = actor.position.y
		var peak: float = 0.0
		var takeoffs: int = 0
		var landings: int = 0
		var airborne_frames: int = 0
		var was_airborne: bool = false
		var landing_pose: bool = false
		Input.action_press("jump")
		for frame in 120:
			await frames(1)
			var airborne: bool = not actor.is_on_floor()
			peak = maxf(peak, actor.position.y - start_y)
			if airborne:
				airborne_frames += 1
			if airborne and not was_airborne:
				takeoffs += 1
			if not airborne and was_airborne:
				landings += 1
			was_airborne = airborne
			landing_pose = landing_pose or actor.animation_tree["parameters/land/active"]
		check(peak >= 0.40 and peak <= 0.50, "Hop apex is 0.40–0.50 m (moving=%s, actual %.6f m)" % [moving, peak])
		check(airborne_frames >= 32 and airborne_frames <= 42,
			"Hop flight is 0.53–0.70 s (actual %.3f s)" % (airborne_frames / 60.0))
		check(takeoffs == 1 and landings == 1, "Holding jump gives one takeoff/landing without rebound")
		check(landing_pose and actor.is_on_floor(), "Actual floor contact triggers the landing pose and grounded recovery")
		Input.action_release("jump")
		await frames(4)
		Input.action_press("jump")
		await frames(5)
		check(not actor.is_on_floor() and actor.velocity.y > 0, "Release/repress permits one new hop")
		Input.action_release("jump")
	await spawn_actor()
	var ceiling: StaticBody3D = make_box(Vector3(4, 0.2, 4), Vector3(0, 2.2, 0))
	var baseline: float = actor.position.y
	Input.action_press("jump")
	var ceiling_peak: float = 0.0
	for frame in 90:
		await frames(1)
		ceiling_peak = maxf(ceiling_peak, actor.position.y - baseline)
	check(ceiling_peak < 0.20 and actor.is_on_floor(), "Low ceiling blocks the capsule and still permits a clean landing")
	ceiling.queue_free()
	release_actions()
	await spawn_actor()
	Input.action_press("jump")
	await frames(6)
	var frozen_position: Vector3 = actor.position
	paused = true
	await frames(30)
	check(actor.position.is_equal_approx(frozen_position), "Pause freezes an in-flight hop")
	paused = false
	actor.take_damage(100)
	await frames(20)
	check(not actor.animation_tree.active and not actor.is_physics_processing(),
		"Death in flight disables movement and the same animation driver")
	await spawn_actor()
	check(actor.is_on_floor() and actor.health_component.current == 100 and not actor.landing_armed,
		"A fresh instance clears in-flight state and startup does not arm landing")


func sole_probes(skeleton: Skeleton3D, model: Node3D) -> Array[Dictionary]:
	var probes: Array[Dictionary] = []
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = int(float(bones.size()) / vertices.size())
			for vertex in vertices.size():
				var probe: Dictionary = {"vertex": vertices[vertex], "bones": [], "weights": [], "binds": []}
				var reference := Vector3.ZERO
				for influence in influences:
					var offset: int = vertex * influences + influence
					if weights[offset] == 0.0:
						continue
					var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bones[offset]))
					var bind: Transform3D = mesh.skin.get_bind_pose(bones[offset])
					reference += (skeleton.global_transform * skeleton.get_bone_global_rest(bone) * bind * vertices[vertex]) * weights[offset]
					probe["bones"].append(bone)
					probe["weights"].append(weights[offset])
					probe["binds"].append(bind)
				if reference.y < 0.025:
					probe["side"] = 0 if reference.x < 0 else 1
					probes.append(probe)
	return probes


func test_necessary_sole_contact() -> void:
	await spawn_actor()
	actor.set_physics_process(false)
	actor.player_input.set_process(false)
	actor.animation_tree.active = false
	actor.position = Vector3.ZERO
	var model: Node3D = actor.get_node("PlayerModel/ReginaModel")
	var skeleton: Skeleton3D = model.get_node("Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D")
	var probes: Array[Dictionary] = sole_probes(skeleton, model.get_node("Regina"))
	check(probes.size() > 50, "Contact checks use actual skinned reference sole vertices")
	var animation_player: AnimationPlayer = model.get_node("AnimationPlayer")
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: StringName in [&"strafe_left", &"strafe_right"]:
		var animation: Animation = animation_player.get_animation(clip)
		animation_player.play(clip)
		var minima := Vector2(INF, INF)
		for sample in 121:
			animation_player.seek(animation.length * sample / 120.0, true)
			skeleton.force_update_all_bone_transforms()
			for probe: Dictionary in probes:
				var point := Vector3.ZERO
				for influence in probe["bones"].size():
					point += (skeleton.global_transform * skeleton.get_bone_global_pose(probe["bones"][influence]) \
						* probe["binds"][influence] * probe["vertex"]) * probe["weights"][influence]
				var side: int = probe["side"]
				minima[side] = minf(minima[side], point.y)
		check(minima.x <= 0.02 and minima.y <= 0.02,
			"%s both soles must reach support height somewhere in the cycle (minima %s m)" % [clip, minima])
		check(minf(minima.x, minima.y) >= -0.002, "%s has no sole penetration below 2 mm" % clip)


func hand_triangles(skeleton: Skeleton3D, regina: Node3D, side: String = "right") -> Array[Array]:
	var triangles: Array[Array] = []
	var wrist: StringName = &"arm right wrist_021" if side == "right" else &"arm left wrist_040"
	var finger_prefix: String = "arm %s finger " % side
	for mesh: MeshInstance3D in regina.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var influences: int = int(float(bones.size()) / vertices.size())
			var probes: Array[Dictionary] = []
			for vertex in vertices.size():
				var probe: Dictionary = {"vertex": vertices[vertex], "bones": [], "weights": [], "binds": [], "hand": false}
				var hand_weight: float = 0.0
				for influence in influences:
					var offset: int = vertex * influences + influence
					if weights[offset] == 0.0:
						continue
					var name: StringName = mesh.skin.get_bind_name(bones[offset])
					probe["bones"].append(skeleton.find_bone(name))
					probe["weights"].append(weights[offset])
					probe["binds"].append(mesh.skin.get_bind_pose(bones[offset]))
					if name == wrist or String(name).begins_with(finger_prefix):
						hand_weight += weights[offset]
				probe["hand"] = hand_weight >= 0.5
				probes.append(probe)
			for index in range(0, indices.size(), 3):
				var a: Dictionary = probes[indices[index]]
				var b: Dictionary = probes[indices[index + 1]]
				var c: Dictionary = probes[indices[index + 2]]
				if a["hand"] or b["hand"] or c["hand"]:
					triangles.append([a, b, c])
	return triangles


func triangle_intersects_box(points: Array[Vector3], bounds: AABB) -> bool:
	var a: Vector3 = points[0] - bounds.get_center()
	var b: Vector3 = points[1] - bounds.get_center()
	var c: Vector3 = points[2] - bounds.get_center()
	var extent: Vector3 = bounds.size * 0.5
	# Triangle/box SAT includes face normals and all edge cross-product axes.
	# Vertex-only probes miss a slide slicing through the middle of a skin face.
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK, (b - a).cross(c - a)]
	for edge: Vector3 in [b - a, c - b, a - c]:
		for box_axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
			axes.append(edge.cross(box_axis))
	for axis: Vector3 in axes:
		var radius: float = extent.dot(axis.abs())
		if minf(a.dot(axis), minf(b.dot(axis), c.dot(axis))) > radius \
				or maxf(a.dot(axis), maxf(b.dot(axis), c.dot(axis))) < -radius:
			return false
	return true


func metal_intersections(skeleton: Skeleton3D, triangles: Array[Array], gun: Node3D) -> int:
	var count: int = 0
	for triangle: Array in triangles:
		var world: Array[Vector3] = []
		for probe: Dictionary in triangle:
			var point := Vector3.ZERO
			for influence in probe["bones"].size():
				point += (skeleton.global_transform * skeleton.get_bone_global_pose(probe["bones"][influence]) \
					* probe["binds"][influence] * probe["vertex"]) * probe["weights"][influence]
			world.append(point)
		for part: String in ["Slide", "Barrel"]:
			var metal: MeshInstance3D = gun.get_node(part)
			var local: Array[Vector3] = []
			for point: Vector3 in world:
				local.append(metal.global_transform.affine_inverse() * point)
			if triangle_intersects_box(local, metal.mesh.get_aabb().grow(-0.001)):
				count += 1
	return count


func test_weapon_grip() -> void:
	await spawn_actor()
	actor.set_physics_process(false)
	actor.player_input.set_process(false)
	var model: Node3D = actor.get_node("PlayerModel/ReginaModel")
	var skeleton: Skeleton3D = model.get_node(actor.REGINA_SKIN_PATH)
	var attachment: BoneAttachment3D = skeleton.get_node("WeaponAttachment")
	var socket: Marker3D = attachment.get_node("WeaponSocket")
	var gun: Node3D = socket.get_node("ReginaHandgun")
	var grip: Marker3D = gun.get_node("GripPose")
	var library: AnimationLibrary = load("res://arca/assets/characters/regina/grip.tres")
	var pose: Animation = library.get_animation("RightHandGrip")
	check(pose.get_track_count() == 15 and library.get_animation("RightWristGrip").get_track_count() == 1,
			"Grip derivative separates all 15 right-finger rotations from the additive wrist correction")
	var paths_valid: bool = true
	for track in pose.get_track_count():
		var name: String = pose.track_get_path(track).get_subname(0)
		paths_valid = paths_valid and pose.track_get_type(track) == Animation.TYPE_ROTATION_3D \
			and skeleton.find_bone(name) >= 0 and name.begins_with("arm right finger ")
	check(paths_valid, "Grip contains only named right-finger rotation tracks, not root/limb/scale channels")
	var triangles: Array[Array] = hand_triangles(skeleton, model.get_node("Regina"))
	check(triangles.size() > 100, "Weapon clearance checks skin triangles, not just wrist points")
	actor.animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for state: String in ["walk", "strafe", "jump_up", "jump_down"]:
		for phase in 4:
			actor.animation_tree["parameters/state/transition_request"] = state
			actor.animation_tree["parameters/walk/blend_position"] = Vector2(0.5, 0.5)
			actor.animation_tree["parameters/strafe/blend_position"] = Vector2(-0.5, 0.5)
			actor.animation_tree["parameters/aim/add_amount"] = [-1.0, 0.0, 1.0, 0.0][phase] if state == "strafe" else 0.0
			actor.animation_tree.advance(0.1)
			actor.animation_tree.advance(0.25)
			# Resolve the transition request before comparing alternate weights at
			# the same playback time; advance(0) must not compare two clip resets.
			actor.animation_tree.advance(0.0)
			skeleton.force_update_all_bone_transforms()
			await process_frame
			var expected: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(attachment.bone_name))
			check(attachment.global_transform.is_equal_approx(expected) and grip.global_transform.is_equal_approx(socket.global_transform),
				"%s phase %d: socket follows evaluated wrist and weapon grip without a frame lag" % [state, phase])
			var posed: bool = true
			for track in pose.get_track_count():
				var bone: int = skeleton.find_bone(pose.track_get_path(track).get_subname(0))
				posed = posed and skeleton.get_bone_pose_rotation(bone).angle_to(pose.rotation_track_interpolate(track, 0.0)) < 0.001
			var corrected_barrel: Vector3 = -gun.global_basis.z
			actor.animation_tree["parameters/wrist_grip/add_amount"] = 0.0
			actor.animation_tree.advance(0.0)
			skeleton.force_update_all_bone_transforms()
			var baseline_wrist: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(attachment.bone_name))
			check(corrected_barrel.dot(-baseline_wrist.basis.y) > 0.9999,
				"%s phase %d: palm correction preserves the evaluated original barrel direction" % [state, phase])
			actor.animation_tree["parameters/wrist_grip/add_amount"] = 1.0
			actor.animation_tree.advance(0.0)
			skeleton.force_update_all_bone_transforms()
			await process_frame
			check(posed and gun.global_basis.get_scale().is_equal_approx(Vector3.ONE),
				"%s phase %d: filtered grip persists with unit weapon scale" % [state, phase])
			var intersections: int = metal_intersections(skeleton, triangles, gun)
			check(intersections == 0, "%s phase %d: no hand triangles penetrate slide/barrel by over 1 mm (%d)" % [state, phase, intersections])
	# Prove the geometry test catches the original defect, rather than simply
	# asserting that two markers agree or that all hand vertices lie outside metal.
	actor.animation_tree["parameters/hand_grip/blend_amount"] = 0.0
	actor.animation_tree["parameters/wrist_grip/add_amount"] = 0.0
	actor.animation_tree["parameters/state/transition_request"] = "strafe"
	actor.animation_tree["parameters/strafe/blend_position"] = Vector2.ZERO
	actor.animation_tree["parameters/aim/add_amount"] = 0.0
	actor.animation_tree.advance(1.0)
	skeleton.reset_bone_poses()
	var player: AnimationPlayer = model.get_node("AnimationPlayer")
	actor.animation_tree.active = false
	player.play("Idlecombat")
	player.seek(0.0, true)
	skeleton.force_update_all_bone_transforms()
	await process_frame
	gun.reparent(attachment, false)
	gun.position = Vector3(0, 0.02, 0)
	gun.rotation = Vector3(-PI * 0.5, 0, 0)
	check(metal_intersections(skeleton, triangles, gun) > 0, "Clearance probe reproduces the original wrist-mounted metal/hand intersection")


func test_aim_pose_quality() -> void:
	await spawn_actor()
	actor.set_physics_process(false)
	actor.player_input.set_process(false)
	actor.animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var model: Node3D = actor.get_node("PlayerModel/ReginaModel")
	var skeleton: Skeleton3D = model.get_node(actor.REGINA_SKIN_PATH)
	var gun: Node3D = actor.shoot_from.get_parent()
	var right_triangles: Array[Array] = hand_triangles(skeleton, model.get_node("Regina"))
	var left_triangles: Array[Array] = hand_triangles(skeleton, model.get_node("Regina"), "left")
	check(right_triangles.size() > 100 and left_triangles.size() > 100, "Aim clearance samples skinned triangles from both hands")
	var library: AnimationLibrary = load("res://arca/assets/characters/regina/gameplay.tres")
	for clip: StringName in [&"AIM-Up", &"AIM-Down"]:
		var animation: Animation = library.get_animation(clip)
		var constant: bool = true
		for track in animation.get_track_count():
			constant = constant and animation.track_get_key_count(track) == 1 \
				and animation.rotation_track_interpolate(track, 0.0).angle_to(animation.rotation_track_interpolate(track, animation.length)) < 0.001
		check(constant, "%s remains an additive pose at its endpoint, not an absolute-pose tail" % clip)
	var directions: Array[Vector3] = []
	actor.animation_tree["parameters/state/transition_request"] = "strafe"
	actor.animation_tree["parameters/strafe/blend_position"] = Vector2.ZERO
	for camera_pitch: float in [0.0, PlayerInputSynchronizer.CAMERA_X_ROT_MAX, PlayerInputSynchronizer.CAMERA_X_ROT_MIN]:
		actor.player_input.camera_rot.rotation.x = camera_pitch
		var pitch: float = actor.player_input.get_aim_rotation()
		actor.animation_tree["parameters/aim/add_amount"] = pitch
		actor.animation_tree.advance(0.1)
		actor.animation_tree.advance(0.25)
		actor.animation_tree.advance(0.0)
		skeleton.force_update_all_bone_transforms()
		await process_frame
		var barrel: Vector3 = actor.global_basis.inverse() * -gun.global_basis.z
		directions.append(barrel)
		if camera_pitch != 0.0:
			var label: String = "Full up aim" if pitch > 0.0 else "Full down aim"
			check(barrel.z > 0.0, "%s stays in the forward hemisphere (%s)" % [label, barrel])
			var right_intersections: int = metal_intersections(skeleton, right_triangles, gun)
			var left_intersections: int = metal_intersections(skeleton, left_triangles, gun)
			check(right_intersections == 0 and left_intersections == 0,
				"%s has no hand triangles penetrating slide/barrel by over 1 mm (right %d, left %d)" % [label, right_intersections, left_intersections])
	check(directions[1].y < directions[0].y - 0.1,
		"Down aim pitches the visible barrel below neutral (neutral %s, down %s)" % [directions[0], directions[1]])
	check(directions[2].y > directions[0].y + 0.1,
		"Up aim pitches the visible barrel above neutral (neutral %s, up %s)" % [directions[0], directions[2]])


func test_hit_reaction() -> void:
	var distances: Array[float] = []
	for take_hit in [false, true]:
		await spawn_actor()
		press_direction(Vector2.UP)
		await frames(30)
		var start: Vector3 = actor.position
		if take_hit:
			actor.take_damage(10)
			await frames(3)
			check(actor.animation_tree.get("parameters/chest_hit/active") == true,
				"An accepted hit activates the chest one-shot")
			actor.take_damage(10)
			check(actor.health_component.current == 90,
				"Damage cooldown rejects a second hit during the reaction")
			await frames(18)
			check(actor.animation_tree.get("parameters/chest_hit/active") == false,
				"Chest reaction ends within the short blend window")
			await frames(39)
		else:
			await frames(60)
		distances.append(start.distance_to(actor.position))
	check(distances[0] > 1.0 and distances[1] >= distances[0] * 0.9,
		"Chest hit preserves at least 90 percent of normal walking displacement")
	release_actions()
	stop_actor()
	await process_frame


func hip_pose(player: Node3D) -> Transform3D:
	var model: Node3D = player.get_node("PlayerModel/ReginaModel")
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("root hips_02"))


func test_death_reaction() -> void:
	change_scene_to_file("res://arca/mission_room.tscn")
	await scene_changed
	await frames(60)
	var room: Node = current_scene
	var player: Variant = room.get_node("Player")
	var animations: AnimationPlayer = player.get_node("PlayerModel/ReginaModel/AnimationPlayer")
	var death: Animation = animations.get_animation("reactions/Death01") \
		if animations.has_animation("reactions/Death01") else null
	check(death != null, "Death01 is installed as a separate reaction clip")
	var standing: Transform3D = hip_pose(player)
	var position: Vector3 = player.global_position
	player.take_damage(100)
	press_direction(Vector2.UP)
	Input.action_press("jump")
	Input.action_press("shoot")
	await frames(12)
	paused = true
	var paused_pose: Transform3D = hip_pose(player)
	await frames(30)
	check(hip_pose(player).is_equal_approx(paused_pose), "Pause freezes the death pose")
	paused = false
	await frames(ceili(death.length * 60.0) - 12 if death else 60)
	check(standing.origin.y - hip_pose(player).origin.y >= 0.5, "Death lowers the hips by at least 0.5 m")
	# Allow the playback start frame and sample the exact endpoint.
	await frames(2)
	var fallen: Transform3D = hip_pose(player)
	await frames(120)
	check(hip_pose(player).is_equal_approx(fallen), "Death holds the final hip pose for two more seconds")
	check(player.global_position.is_equal_approx(position), "Held input cannot displace the dead body")
	release_actions()
	room.restart_room()
	await scene_changed
	await frames(60)
	check(absf(hip_pose(current_scene.get_node("Player")).origin.y - standing.origin.y) < 0.05,
		"Mission restart restores Regina's standing idle pose")
	current_scene.stop_audio()
	current_scene.queue_free()
	await process_frame


func run() -> void:
	await check_regina_room("res://arca/test_room.tscn", "RedRobot")
	await check_regina_room("res://arca/raptor_room.tscn", "Raptor")
	await check_regina_room("res://arca/mission_room.tscn", "Raptor")
	await check_original_robot()
	arena = Node3D.new()
	root.add_child(arena)
	make_box(Vector3(100, 0.4, 100), Vector3(0, -0.2, 0))
	if "--reactions-only" in OS.get_cmdline_user_args():
		await test_hit_reaction()
		await test_death_reaction()
	elif "--weapon-grip-only" in OS.get_cmdline_user_args():
		await test_weapon_grip()
	else:
		await test_directions()
		await test_jumps()
		await test_weapon_grip()
		await test_aim_pose_quality()
		await test_necessary_sole_contact()
		await test_hit_reaction()
		await test_death_reaction()
	release_actions()
	stop_actor()
	arena.queue_free()
	actor = null
	await process_frame
	await process_frame
	# Unthrottled fixed-fps steps can outrun the Dummy audio mixer's cleanup.
	OS.delay_msec(100)
	print("REGINA PLAYER RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
