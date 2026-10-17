extends SceneTree
## Offline, asset-specific UAL -> Regina bake. Run after importing the source GLBs.
## Animation derivatives retain the source CC0 notice; Regina geometry is not saved.

const TARGET := "res://arca/assets/characters/regina/regina.glb"
const DONOR := "res://arca/assets/characters/regina/source/ual_locomotion.glb"
const OUTPUT := "res://arca/assets/characters/regina/locomotion.tres"
const SKIN_PATH := "ModelPivot/Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"
const FPS: float = 60.0
const FOOT_OFFSET: float = 0.0112332
# Target, donor, target tail, donor tail. Empty tails preserve the target's
# reference orientation; limb frames instead align anatomical segment directions.
const MAP: Array[Array] = [
	["root hips_02", "DEF-hips", "", ""],
	["spine lower_03", "DEF-spine.001", "", ""],
	["spine middle_04", "DEF-spine.002", "", ""],
	["spine upper_05", "DEF-spine.003", "", ""],
	["head neck lower_06", "DEF-neck", "", ""],
	["head neck upper_07", "DEF-head", "", ""],
	["arm left shoulder 1_037", "DEF-shoulder.L", "", ""],
	["arm left shoulder 2_038", "DEF-upper_arm.L", "arm left elbow_039", "DEF-forearm.L"],
	["arm left elbow_039", "DEF-forearm.L", "arm left wrist_040", "DEF-hand.L"],
	["arm left wrist_040", "DEF-hand.L", "arm left finger 3a_047", "DEF-f_middle.01.L"],
	["arm right shoulder 1_018", "DEF-shoulder.R", "", ""],
	["arm right shoulder 2_019", "DEF-upper_arm.R", "arm right elbow_020", "DEF-forearm.R"],
	["arm right elbow_020", "DEF-forearm.R", "arm right wrist_021", "DEF-hand.R"],
	["arm right wrist_021", "DEF-hand.R", "arm right finger 3a_028", "DEF-f_middle.01.R"],
	["leg left thigh_063", "DEF-thigh.L", "leg left knee_064", "DEF-shin.L"],
	["leg left knee_064", "DEF-shin.L", "leg left ankle_065", "DEF-foot.L"],
	["leg left ankle_065", "DEF-foot.L", "", ""],
	["leg left toes_066", "DEF-toe.L", "", ""],
	["leg right thigh_059", "DEF-thigh.R", "leg right knee_060", "DEF-shin.R"],
	["leg right knee_060", "DEF-shin.R", "leg right ankle_061", "DEF-foot.R"],
	["leg right ankle_061", "DEF-foot.R", "", ""],
	["leg right toes_062", "DEF-toe.R", "", ""],
]


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


func run() -> void:
	var donor: Node3D = load(DONOR).instantiate()
	var target: Node3D = load(TARGET).instantiate()
	root.add_child(donor)
	root.add_child(target)
	var source := donor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var dest := target.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for entry: Array in MAP:
		if dest.find_bone(entry[0]) < 0 or source.find_bone(entry[1]) < 0 \
				or (entry[2] != "" and (dest.find_bone(entry[2]) < 0 or source.find_bone(entry[3]) < 0)):
			push_error("Incomplete Regina/UAL bone map: " + str(entry))
			quit(1)
			return
	var player := donor.get_node("AnimationPlayer") as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var corrections: Dictionary = {}
	var hints: Dictionary = {}
	for entry: Array in MAP:
		var a: Basis = bone_transform(dest, entry[0], true).basis.orthonormalized()
		var s: Basis = bone_transform(source, entry[1], true).basis.orthonormalized()
		if entry[2] == "":
			corrections[entry[0]] = s.inverse() * a
		else:
			var direction: Vector3 = bone_transform(dest, entry[2], true).origin \
				- bone_transform(dest, entry[0], true).origin
			corrections[entry[0]] = limb_frame(direction, Vector3.BACK).inverse() * a
		hints[entry[0]] = s.inverse() * Vector3.BACK
	var dest_length: float = bone_transform(dest, "leg left thigh_063", true).origin.distance_to(
		bone_transform(dest, "leg left knee_064", true).origin) \
		+ bone_transform(dest, "leg left knee_064", true).origin.distance_to(
			bone_transform(dest, "leg left ankle_065", true).origin)
	var source_length: float = bone_transform(source, "DEF-thigh.L", true).origin.distance_to(
		bone_transform(source, "DEF-shin.L", true).origin) \
		+ bone_transform(source, "DEF-shin.L", true).origin.distance_to(
			bone_transform(source, "DEF-foot.L", true).origin)
	var ratio: float = dest_length / source_length
	var soles: Array[Dictionary] = sole_vertices(target, dest)
	var source_pelvis: Vector3 = 0.5 * (bone_transform(source, "DEF-thigh.L", true).origin \
		+ bone_transform(source, "DEF-thigh.R", true).origin)
	var target_pelvis: Vector3 = 0.5 * (bone_transform(dest, "leg left thigh_063", true).origin \
		+ bone_transform(dest, "leg right thigh_059", true).origin)
	var library := AnimationLibrary.new()
	for pair: Array in [["Idle", "idle"], ["Walk", "walk"], ["Jog_Fwd", "run"]]:
		source.reset_bone_poses()
		var source_clip: Animation = player.get_animation(pair[0]).duplicate(true)
		source_clip.loop_mode = Animation.LOOP_NONE
		var local_library := AnimationLibrary.new()
		local_library.add_animation("source", source_clip)
		if player.has_animation_library("bake"):
			player.remove_animation_library("bake")
		player.add_animation_library("bake", local_library)
		player.play("bake/source")
		var animation := Animation.new()
		animation.length = source_clip.length
		add_track(animation, Animation.TYPE_POSITION_3D, "RootMotion")
		add_track(animation, Animation.TYPE_POSITION_3D, SKIN_PATH + ":root hips_02")
		for entry: Array in MAP:
			add_track(animation, Animation.TYPE_ROTATION_3D, SKIN_PATH + ":" + entry[0])
		var samples: int = roundi(animation.length * FPS)
		for sample in samples + 1:
			var time: float = animation.length * sample / samples
			player.seek(time, true)
			source.force_update_all_bone_transforms()
			dest.reset_bone_poses()
			animation.position_track_insert_key(0, time, Vector3.ZERO)
			var hip: int = dest.find_bone("root hips_02")
			var parent_world: Transform3D = dest.global_transform \
				* dest.get_bone_global_rest(dest.get_bone_parent(hip))
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
				var parent_basis: Basis = (dest.global_transform \
					* dest.get_bone_global_pose(dest.get_bone_parent(index))).basis.orthonormalized()
				var rotation: Quaternion = (parent_basis.inverse() * desired).get_rotation_quaternion().normalized()
				dest.set_bone_pose_rotation(index, rotation)
				animation.rotation_track_insert_key(i + 2, time, rotation)
			# Regina's hips joint lies below the thigh origins; the donor's does
			# not. Transfer the anatomical pelvis center, not that pivot offset.
			dest.force_update_all_bone_transforms()
			var source_center: Vector3 = 0.5 * (bone_transform(source, "DEF-thigh.L").origin \
				+ bone_transform(source, "DEF-thigh.R").origin)
			var target_center: Vector3 = 0.5 * (bone_transform(dest, "leg left thigh_063").origin \
				+ bone_transform(dest, "leg right thigh_059").origin)
			hip_position += parent_world.basis.inverse() \
				* (target_pelvis + (source_center - source_pelvis) * ratio - target_center)
			animation.position_track_insert_key(1, time, hip_position)
		# The exported jog has a small endpoint mismatch (about 3 degrees/2.6 cm).
		# Remove that residual drift across one cycle, preserving periodic playback.
		for track in range(1, animation.get_track_count()):
			var first: Variant = animation.track_get_key_value(track, 0)
			var last: Variant = animation.track_get_key_value(track, samples)
			for key in samples + 1:
				var phase: float = float(key) / samples
				var value: Variant = animation.track_get_key_value(track, key)
				if first is Quaternion:
					value = (Quaternion.IDENTITY.slerp(first * last.inverse(), phase) * value).normalized()
				else:
					value -= (last - first) * phase
				animation.track_set_key_value(track, key, value)
		calibrate(animation, dest, soles, pair[1])
		var playback_scale: float = 0.7 if pair[1] == "run" else 1.0
		if playback_scale != 1.0:
			# Keep the donor's full stride, but temper its abrupt knee flexion.
			# Edit backwards so increasing key times cannot reorder later keys.
			for track in animation.get_track_count():
				for key in range(animation.track_get_key_count(track) - 1, -1, -1):
					animation.track_set_key_time(track, key, animation.track_get_key_time(track, key) / playback_scale)
			animation.length /= playback_scale
			animation.set_meta("speed_mps", float(animation.get_meta("speed_mps")) * playback_scale)
		animation.set_meta("source_playback_scale", playback_scale)
		animation.loop_mode = Animation.LOOP_LINEAR
		animation.set_meta("source_clip", pair[0])
		animation.set_meta("hip_translation_scale", ratio)
		print("BAKED ", pair[1], " seconds=", animation.length,
			" final_speed_mps=", animation.get_meta("speed_mps"), " source_playback_scale=", playback_scale)
		library.add_animation(pair[1], animation)
	var result: Error = ResourceSaver.save(library, OUTPUT)
	donor.free()
	target.free()
	if result != OK:
		push_error("Could not save Regina locomotion: " + error_string(result))
	quit(0 if result == OK else 1)
