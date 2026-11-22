extends SceneTree
## Offline retarget and bake of TPS and Quaternius poses to Regina's unchanged skin.
## Import the source GLBs before running. See ATTRIBUTIONS.md for derivative licenses.

const TARGET := "res://arca/assets/characters/regina/regina.glb"
const DONOR := "res://player/model/player.glb"
const PISTOL_DONOR := "res://arca/assets/characters/regina/source/ual_pistol_grip.glb"
const UAL_MAP: Array[Array] = preload("res://arca/assets/characters/regina/bake_locomotion.gd").MAP
const OUTPUT := "res://arca/assets/characters/regina/gameplay.tres"
const SKIN_PATH := "Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"
const FPS: float = 60.0
const FOOT_OFFSET: float = 0.0112332
const DONOR_SCALE: float = 0.803991
# Target, donor, target tail, donor tail. Map complete anatomical chains through
# endpoint frames; never transfer the robot's mechanical limb translations/scales.
const MAP: Array[Array] = [
	["root hips_02", "hips", "", ""],
	["spine lower_03", "spine1", "", ""],
	["spine middle_04", "spine2", "", ""],
	["spine upper_05", "chest", "", ""],
	["head neck lower_06", "neck", "", ""],
	["head neck upper_07", "neck.001", "", ""],
	["arm left shoulder 1_037", "shoulder.L", "", ""],
	["arm left shoulder 2_038", "upper_arm.L", "arm left elbow_039", "forearm.L"],
	["arm left elbow_039", "forearm.L", "arm left wrist_040", "forearm.L.003"],
	["arm left wrist_040", "hand.L", "arm left finger 3a_047", "f_middle.01.L"],
	["arm right shoulder 1_018", "shoulder.R", "", ""],
	["arm right shoulder 2_019", "upper_arm.R", "arm right elbow_020", "forearm.R"],
	["arm right elbow_020", "forearm.R", "arm right wrist_021", "forearm.R.003"],
	["arm right wrist_021", "hand.R", "arm right finger 3a_028", "f_middle.01.R"],
	["leg left thigh_063", "thigh.L", "leg left knee_064", "shin.L"],
	["leg left knee_064", "shin.L", "leg left ankle_065", "foot.L"],
	["leg left ankle_065", "foot.L", "", ""],
	["leg left toes_066", "toe.L", "", ""],
	["leg right thigh_059", "thigh.R", "leg right knee_060", "shin.R"],
	["leg right knee_060", "shin.R", "leg right ankle_061", "foot.R"],
	["leg right ankle_061", "foot.R", "", ""],
	["leg right toes_062", "toe.R", "", ""],
]
const CLIPS: Array[Array] = [
	["Idlecombat", "Idlecombat"], ["running_gun", "running_gun"],
	["strafe_left", "strafe_left"], ["strafe_right", "strafe_right"],
	["strafe_back", "strafe_back"], ["strafe_front", "strafe_front"],
	["jump_2_upwards", "jump_2_upwards"], ["jump_4_falling", "jump_4_falling"],
	["jump_5_hardlanding", "jump_5_hardlanding"],
]
const PISTOL_AIM: Dictionary[StringName, StringName] = {
	&"AIM-Up": &"Pistol_Aim_Up",
	&"AIM-Down": &"Pistol_Aim_Down",
}
# Neutral-relative sagittal barrel spans measured in the full human retarget
# trial. Normalize both additive poses to the inherited 70-degree camera limit.
const PISTOL_PITCH_SPAN: Dictionary[StringName, float] = {
	&"AIM-Up": deg_to_rad(85.3515),
	&"AIM-Down": deg_to_rad(88.7064),
}


func _initialize() -> void:
	call_deferred("run")


func bone_transform(skeleton: Skeleton3D, bone: String, rest: bool = false) -> Transform3D:
	var index: int = skeleton.find_bone(bone)
	return skeleton.global_transform * (skeleton.get_bone_global_rest(index) \
		if rest else skeleton.get_bone_global_pose(index))


func limb_frame(direction: Vector3, hint: Vector3) -> Basis:
	var y: Vector3 = direction.normalized()
	var z: Vector3 = (hint - y * hint.dot(y)).normalized()
	return Basis(y.cross(z).normalized(), y, z)


func add_track(animation: Animation, type: Animation.TrackType, path: String) -> int:
	var track: int = animation.add_track(type)
	animation.track_set_path(track, NodePath(path))
	return track


func apply_pose(animation: Animation, skeleton: Skeleton3D, time: float) -> void:
	for track in range(1, animation.get_track_count()):
		var bone: int = skeleton.find_bone(animation.track_get_path(track).get_subname(0))
		if animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, animation.position_track_interpolate(track, time))
		else:
			skeleton.set_bone_pose_rotation(bone, animation.rotation_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


func sole_vertices(model: Node3D, skeleton: Skeleton3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = int(float(bones.size()) / vertices.size())
			for vertex in vertices.size():
				var sample: Dictionary = {"vertex": vertices[vertex], "bones": [], "weights": [], "binds": []}
				var point := Vector3.ZERO
				for influence in influences:
					var offset: int = vertex * influences + influence
					if weights[offset] == 0.0:
						continue
					var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bones[offset]))
					var bind: Transform3D = mesh.skin.get_bind_pose(bones[offset])
					point += (skeleton.global_transform * skeleton.get_bone_global_rest(bone) \
						* bind * vertices[vertex]) * weights[offset]
					sample["bones"].append(bone)
					sample["weights"].append(weights[offset])
					sample["binds"].append(bind)
				if point.y < 0.035:
					sample["side"] = 0 if point.x > 0 else 1
					result.append(sample)
	return result


func lowest_sole(samples: Array[Dictionary], skeleton: Skeleton3D) -> float:
	var lowest: float = INF
	for sample: Dictionary in samples:
		var point := Vector3.ZERO
		for influence in sample["bones"].size():
			point += (skeleton.global_transform * skeleton.get_bone_global_pose(sample["bones"][influence]) \
				* sample["binds"][influence] * sample["vertex"]) * sample["weights"][influence]
		lowest = minf(lowest, point.y)
	return lowest


func sole_contact(samples: Array[Dictionary], skeleton: Skeleton3D, side: int) -> Vector3:
	var points: Array[Vector3] = []
	var lowest: float = INF
	for sample: Dictionary in samples:
		if sample["side"] != side:
			continue
		var point := Vector3.ZERO
		for influence in sample["bones"].size():
			point += (skeleton.global_transform * skeleton.get_bone_global_pose(sample["bones"][influence]) \
				* sample["binds"][influence] * sample["vertex"]) * sample["weights"][influence]
		lowest = minf(lowest, point.y)
		points.append(point)
	var contact := Vector3.ZERO
	var count: int = 0
	for point: Vector3 in points:
		if point.y < lowest + 0.002:
			contact += point
			count += 1
	contact /= count
	contact.y = lowest
	return contact


func calibrate(animation: Animation, skeleton: Skeleton3D, soles: Array[Dictionary], name: String) -> void:
	# Fit a constant travel speed to the two flat-foot support intervals, not to
	# swing feet/toe-off. No IK, per-frame ground clamping or runtime foot locking.
	var intervals: Array[Vector2] = [Vector2(0.12, 0.30), Vector2(0.62, 0.80)]
	if name != "walk":
		intervals = [Vector2(0.06, 0.12), Vector2(0.56, 0.62)]
	var speed: float = 0.0
	if name != "idle":
		for side in 2:
			var times: Array[float] = []
			var positions: Array[float] = []
			for sample in 21:
				var time: float = lerpf(intervals[side].x, intervals[side].y, sample / 20.0) * animation.length
				apply_pose(animation, skeleton, time)
				times.append(time)
				positions.append(sole_contact(soles, skeleton, side).z)
			var mean_time: float = 0.0
			var mean_position: float = 0.0
			for i in times.size():
				mean_time += times[i] / times.size()
				mean_position += positions[i] / positions.size()
			var numerator: float = 0.0
			var denominator: float = 0.0
			for i in times.size():
				numerator += (times[i] - mean_time) * (positions[i] - mean_position)
				denominator += pow(times[i] - mean_time, 2)
			speed -= 0.5 * numerator / denominator
	var floor_y: float = INF
	for sample in 121:
		apply_pose(animation, skeleton, animation.length * sample / 120.0)
		floor_y = minf(floor_y, lowest_sole(soles, skeleton))
	var lift: float = FOOT_OFFSET - floor_y + 0.0005
	var hip: int = skeleton.find_bone("root hips_02")
	var parent_world: Basis = (skeleton.global_transform \
		* skeleton.get_bone_global_rest(skeleton.get_bone_parent(hip))).basis
	for key in animation.track_get_key_count(1):
		var position: Vector3 = animation.track_get_key_value(1, key)
		animation.track_set_key_value(1, key, position + parent_world.inverse() * Vector3.UP * lift)
	for key in animation.track_get_key_count(0):
		animation.track_set_key_value(0, key, Vector3(0, 0, -speed * animation.track_get_key_time(0, key)))
	animation.set_meta("speed_mps", speed)
	animation.set_meta("constant_height_correction_m", lift)
	print("CALIBRATED ", name, " seconds=", animation.length, " speed_mps=", speed,
		" meters_per_cycle=", speed * animation.length, " constant_height_correction_m=", lift)


func align_sole_height(animation: Animation, skeleton: Skeleton3D, soles: Array[Dictionary]) -> void:
	var minimum: float = INF
	for sample in 121:
		apply_pose(animation, skeleton, animation.length * sample / 120.0)
		minimum = minf(minimum, lowest_sole(soles, skeleton))
	var lift: float = FOOT_OFFSET + 0.0005 - minimum
	var hip: int = skeleton.find_bone("root hips_02")
	var parent_basis: Basis = (skeleton.global_transform \
		* skeleton.get_bone_global_rest(skeleton.get_bone_parent(hip))).basis
	for key in animation.track_get_key_count(1):
		var value: Vector3 = animation.track_get_key_value(1, key)
		animation.track_set_key_value(1, key, value + parent_basis.inverse() * Vector3.UP * lift)
	animation.set_meta("constant_height_correction_m", lift)


func run() -> void:
	var donor: Node3D = load(DONOR).instantiate()
	var target: Node3D = load(TARGET).instantiate()
	root.add_child(donor)
	root.add_child(target)
	var source := donor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var dest := target.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := donor.get_node("AnimationPlayer") as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for entry: Array in MAP:
		if dest.find_bone(entry[0]) < 0 or source.find_bone(entry[1]) < 0 \
				or (entry[2] != "" and (dest.find_bone(entry[2]) < 0 or source.find_bone(entry[3]) < 0)):
			fail("Incomplete TPS/Regina bone map: " + str(entry))
			return
	for pair: Array in CLIPS:
		if not player.has_animation(pair[0]):
			fail("Missing TPS animation clip: " + str(pair[0]))
			return
	var corrections: Dictionary = {}
	var hints: Dictionary = {}
	for entry: Array in MAP:
		var target_basis: Basis = bone_transform(dest, entry[0], true).basis.orthonormalized()
		var source_basis: Basis = bone_transform(source, entry[1], true).basis.orthonormalized()
		if entry[2] == "":
			corrections[entry[0]] = source_basis.inverse() * target_basis
		else:
			var direction: Vector3 = bone_transform(dest, entry[2], true).origin \
				- bone_transform(dest, entry[0], true).origin
			corrections[entry[0]] = limb_frame(direction, Vector3.BACK).inverse() * target_basis
		hints[entry[0]] = source_basis.inverse() * Vector3.BACK
	var dest_length: float = bone_transform(dest, "leg left thigh_063", true).origin.distance_to(
		bone_transform(dest, "leg left knee_064", true).origin) \
		+ bone_transform(dest, "leg left knee_064", true).origin.distance_to(
			bone_transform(dest, "leg left ankle_065", true).origin)
	var source_length: float = bone_transform(source, "thigh.L", true).origin.distance_to(
		bone_transform(source, "shin.L", true).origin) \
		+ bone_transform(source, "shin.L", true).origin.distance_to(
			bone_transform(source, "foot.L", true).origin)
	var ratio: float = dest_length / source_length
	var source_pelvis: Vector3 = 0.5 * (bone_transform(source, "thigh.L", true).origin \
		+ bone_transform(source, "thigh.R", true).origin)
	var target_pelvis: Vector3 = 0.5 * (bone_transform(dest, "leg left thigh_063", true).origin \
		+ bone_transform(dest, "leg right thigh_059", true).origin)
	var library := AnimationLibrary.new()
	var soles: Array[Dictionary] = sole_vertices(target, dest)
	for pair: Array in CLIPS:
		var source_clip: Animation = player.get_animation(pair[0]).duplicate(true)
		var loop_mode: Animation.LoopMode = source_clip.loop_mode
		source_clip.loop_mode = Animation.LOOP_NONE
		var local_library := AnimationLibrary.new()
		local_library.add_animation("source", source_clip)
		if player.has_animation_library("bake"):
			player.remove_animation_library("bake")
		player.add_animation_library("bake", local_library)
		player.play("bake/source")
		var animation := _bake_clip(player, source, dest, pair[0], pair[1], ratio,
			corrections, hints, source_pelvis, target_pelvis)
		animation.loop_mode = Animation.LOOP_NONE if pair[0] == "jump_2_upwards" else loop_mode
		align_sole_height(animation, dest, soles)
		library.add_animation(pair[1], animation)
	if not player.has_animation(&"AIM-Center"):
		fail("Missing TPS aiming pose: AIM-Center")
		return
	var center := player.get_animation(&"AIM-Center").duplicate(true) as Animation
	center.loop_mode = Animation.LOOP_NONE
	var center_library := AnimationLibrary.new()
	center_library.add_animation(&"source", center)
	player.remove_animation_library(&"bake")
	player.add_animation_library(&"bake", center_library)
	player.play(&"bake/source")
	library.add_animation(&"AIM-Center", _bake_clip(player, source, dest, &"AIM-Center", &"AIM-Center",
		ratio, corrections, hints, source_pelvis, target_pelvis))
	if not _bake_pistol_aim(dest, library):
		return
	var locomotion: AnimationLibrary = load("res://arca/assets/characters/regina/locomotion.tres")
	for pair: Array in [["idle", "Idle"], ["run", "running_nogun"]]:
		var animation: Animation = locomotion.get_animation(pair[0]).duplicate(true)
		for track in animation.get_track_count():
			var path: String = str(animation.track_get_path(track))
			path = path.replace("ModelPivot/Regina/", "Regina/")
			animation.track_set_path(track, NodePath(path))
			if pair[0] == "run" and path == "RootMotion":
				for key in animation.track_get_key_count(track):
					var delta: Vector3 = animation.track_get_key_value(track, key)
					delta.z = -delta.z
					animation.track_set_key_value(track, key, delta)
		animation.set_meta("source_library", "locomotion.tres")
		library.add_animation(pair[1], animation)
	var eyes := Animation.new()
	eyes.length = 0.001
	library.add_animation("eyes", eyes)
	var result: Error = ResourceSaver.save(library, OUTPUT)
	if result != OK:
		fail("Could not save Regina gameplay library: " + error_string(result))
		return
	print("BAKED Regina gameplay library with ", library.get_animation_list().size(), " clips")
	quit(0)


func _bake_pistol_aim(dest: Skeleton3D, library: AnimationLibrary) -> bool:
	var donor: Node3D = load(PISTOL_DONOR).instantiate()
	root.add_child(donor)
	var source := donor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := donor.get_node("AnimationPlayer") as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var poses: Dictionary[StringName, Dictionary] = {}
	for clip: StringName in [&"Pistol_Aim_Neutral", PISTOL_AIM[&"AIM-Up"], PISTOL_AIM[&"AIM-Down"]]:
		if not player.has_animation(clip):
			fail("Missing Quaternius pistol pose: " + String(clip))
			return false
		source.reset_bone_poses()
		player.play(clip)
		player.seek(0.0, true)
		source.force_update_all_bone_transforms()
		dest.reset_bone_poses()
		var rotations: Dictionary[String, Quaternion] = {}
		for entry: Array in UAL_MAP:
			var target_bone: String = entry[0]
			# Evaluate the parents before extracting the local arm and neck rotations.
			if target_bone.begins_with("arm left ") or target_bone.begins_with("leg "):
				continue
			var index: int = dest.find_bone(target_bone)
			if index < 0 or source.find_bone(entry[1]) < 0 \
					or (entry[2] != "" and (dest.find_bone(entry[2]) < 0 or source.find_bone(entry[3]) < 0)):
				fail("Incomplete Quaternius pistol mapping: " + str(entry))
				return false
			var target_rest: Basis = bone_transform(dest, target_bone, true).basis.orthonormalized()
			var source_rest: Basis = bone_transform(source, entry[1], true).basis.orthonormalized()
			var source_pose: Basis = bone_transform(source, entry[1]).basis.orthonormalized()
			var desired: Basis = source_pose * source_rest.inverse() * target_rest
			if entry[2] != "":
				var rest_direction: Vector3 = bone_transform(dest, entry[2], true).origin \
					- bone_transform(dest, target_bone, true).origin
				var pose_direction: Vector3 = bone_transform(source, entry[3]).origin \
					- bone_transform(source, entry[1]).origin
				desired = limb_frame(pose_direction, source_pose * source_rest.inverse() * Vector3.BACK) \
					* limb_frame(rest_direction, Vector3.BACK).inverse() * target_rest
			dest.force_update_all_bone_transforms()
			var parent: int = dest.get_bone_parent(index)
			var parent_basis: Basis = (dest.global_transform * dest.get_bone_global_pose(parent)).basis.orthonormalized()
			var rotation: Quaternion = (parent_basis.inverse() * desired).get_rotation_quaternion().normalized()
			dest.set_bone_pose_rotation(index, rotation)
			if target_bone.begins_with("head ") or target_bone.begins_with("arm right "):
				rotations[target_bone] = rotation
		poses[clip] = rotations
	var neutral: Dictionary = poses[&"Pistol_Aim_Neutral"]
	for name: StringName in PISTOL_AIM:
		var clip: StringName = PISTOL_AIM[name]
		var animation := Animation.new()
		animation.length = 0.001
		var weight: float = PlayerInputSynchronizer.CAMERA_X_ROT_MAX / PISTOL_PITCH_SPAN[name]
		for bone: String in neutral:
			var neutral_rotation: Quaternion = neutral[bone]
			var pose_rotation: Quaternion = poses[clip][bone]
			var rest: Quaternion = dest.get_bone_rest(dest.find_bone(bone)).basis.get_rotation_quaternion()
			var delta: Quaternion = (neutral_rotation.inverse() * pose_rotation).normalized()
			var track: int = add_track(animation, Animation.TYPE_ROTATION_3D, SKIN_PATH + ":" + bone)
			# Godot strips the target rest before applying the additive rotation.
			animation.rotation_track_insert_key(track, 0.0, (rest * Quaternion.IDENTITY.slerp(delta, weight)).normalized())
		animation.set_meta("source_clip", String(clip))
		animation.set_meta("neutral_clip", "Pistol_Aim_Neutral")
		animation.set_meta("additive_scale", weight)
		library.add_animation(name, animation)
	donor.queue_free()
	return true


func _bake_clip(player: AnimationPlayer, source: Skeleton3D, dest: Skeleton3D,
		source_name: StringName, output_name: StringName, ratio: float,
		corrections: Dictionary, hints: Dictionary, source_pelvis: Vector3,
		target_pelvis: Vector3) -> Animation:
	var source_clip: Animation = player.get_animation("bake/source")
	var animation := Animation.new()
	animation.length = maxf(source_clip.length, 0.001)
	if source_name == &"jump_2_upwards":
		animation.length = 0.25
	elif source_name == &"jump_5_hardlanding":
		animation.length = 0.2
	var root_track: int = add_track(animation, Animation.TYPE_POSITION_3D, "RootMotion")
	var hip_track: int = add_track(animation, Animation.TYPE_POSITION_3D, SKIN_PATH + ":root hips_02")
	for entry: Array in MAP:
		add_track(animation, Animation.TYPE_ROTATION_3D, SKIN_PATH + ":" + entry[0])
	var samples: int = maxi(roundi(source_clip.length * FPS), 1)
	var root_index: int = source.find_bone("root")
	player.seek(0.0, true)
	source.force_update_all_bone_transforms()
	var root_origin: Vector3 = source.get_bone_pose_position(root_index)
	var root_rest_world: Vector3 = (source.global_transform * source.get_bone_global_rest(root_index)).origin
	var hip: int = dest.find_bone("root hips_02")
	var parent_world: Transform3D = dest.global_transform * dest.get_bone_global_rest(dest.get_bone_parent(hip))
	for sample in samples + 1:
		var time: float = animation.length * sample / samples
		player.seek(source_clip.length * sample / samples, true)
		source.force_update_all_bone_transforms()
		dest.reset_bone_poses()
		var root_delta: Vector3 = (source.get_bone_pose_position(root_index) - root_origin) * DONOR_SCALE
		root_delta.y = 0.0
		if String(source_name).begins_with("jump_"):
			root_delta = Vector3.ZERO
		animation.position_track_insert_key(root_track, time, root_delta)
		var root_world_delta: Vector3 = (source.global_transform \
			* source.get_bone_global_pose(root_index)).origin - root_rest_world
		var hip_position: Vector3 = dest.get_bone_rest(hip).origin
		for i in MAP.size():
			var entry: Array = MAP[i]
			var source_basis: Basis = bone_transform(source, entry[1]).basis.orthonormalized()
			var desired: Basis = source_basis * corrections[entry[0]]
			if entry[2] != "":
				var direction: Vector3 = bone_transform(source, entry[3]).origin \
					- bone_transform(source, entry[1]).origin
				desired = limb_frame(direction, source_basis * hints[entry[0]]) * corrections[entry[0]]
			var index: int = dest.find_bone(entry[0])
			dest.force_update_all_bone_transforms()
			var parent_index: int = dest.get_bone_parent(index)
			var parent_basis: Basis = (dest.global_transform * dest.get_bone_global_pose(parent_index)).basis.orthonormalized()
			var rotation: Quaternion = (parent_basis.inverse() * desired).get_rotation_quaternion().normalized()
			dest.set_bone_pose_rotation(index, rotation)
			animation.rotation_track_insert_key(i + 2, time, rotation)
		dest.force_update_all_bone_transforms()
		var source_center: Vector3 = 0.5 * (bone_transform(source, "thigh.L").origin \
			+ bone_transform(source, "thigh.R").origin)
		var target_center: Vector3 = 0.5 * (bone_transform(dest, "leg left thigh_063").origin \
			+ bone_transform(dest, "leg right thigh_059").origin)
		hip_position += parent_world.basis.inverse() * (target_pelvis \
			+ (source_center - root_world_delta - source_pelvis) * ratio - target_center)
		animation.position_track_insert_key(hip_track, time, hip_position)
	animation.loop_mode = source_clip.loop_mode
	animation.set_meta("source_clip", String(source_name))
	animation.set_meta("retarget_ratio", ratio)
	print("BAKED ", output_name, " from ", source_name, " duration=", animation.length)
	return animation


func fail(message: String) -> void:
	push_error(message)
	quit(1)
