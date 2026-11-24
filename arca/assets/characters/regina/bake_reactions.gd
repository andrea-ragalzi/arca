extends "res://arca/assets/characters/regina/bake_locomotion.gd"
## Reuse the Standard UAL retarget calibration for non-looping reactions.

const REACTION_DONOR := "res://arca/assets/characters/regina/source/ual_reactions.glb"
const REACTION_OUTPUT := "res://arca/assets/characters/regina/reactions.tres"
const GAMEPLAY_SKIN_PATH := "Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"
const HIT_DURATION: float = 0.3


func run() -> void:
	var donor: Node3D = load(REACTION_DONOR).instantiate()
	var target: Node3D = load(TARGET).instantiate()
	root.add_child(donor)
	root.add_child(target)
	var source := donor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var dest := target.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := donor.get_node("AnimationPlayer") as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var corrections: Array[Basis] = []
	var hints: Array[Vector3] = []
	for entry: Array in MAP:
		if dest.find_bone(entry[0]) < 0 or source.find_bone(entry[1]) < 0 \
				or (entry[2] != "" and (dest.find_bone(entry[2]) < 0 or source.find_bone(entry[3]) < 0)):
			push_error("Incomplete Regina/UAL bone map: " + str(entry))
			quit(1)
			return
		var target_rest: Basis = bone_transform(dest, entry[0], true).basis.orthonormalized()
		var source_rest: Basis = bone_transform(source, entry[1], true).basis.orthonormalized()
		var reference: Basis = source_rest
		if entry[2] != "":
			var direction: Vector3 = bone_transform(dest, entry[2], true).origin \
				- bone_transform(dest, entry[0], true).origin
			reference = limb_frame(direction, Vector3.BACK)
		corrections.append(reference.inverse() * target_rest)
		hints.append(source_rest.inverse() * Vector3.BACK)

	var library := AnimationLibrary.new()
	for clip: StringName in [&"Death01", &"Hit_Chest"]:
		if not player.has_animation(clip):
			push_error("Missing Quaternius reaction: " + String(clip))
			quit(1)
			return
		var animation: Animation = bake_reaction(player, source, dest, clip, corrections, hints)
		library.add_animation(clip, animation)
		print("BAKED ", clip, " seconds=", animation.length)
	var result: Error = ResourceSaver.save(library, REACTION_OUTPUT)
	if result != OK:
		push_error("Could not save Regina reactions: " + error_string(result))
	quit(0 if result == OK else 1)


func pelvis(skeleton: Skeleton3D, left: String, right: String, rest: bool) -> Vector3:
	return (bone_transform(skeleton, left, rest).origin + bone_transform(skeleton, right, rest).origin) * 0.5


func leg_length(skeleton: Skeleton3D, thigh: String, knee: String, ankle: String) -> float:
	var joint: Vector3 = bone_transform(skeleton, knee, true).origin
	return joint.distance_to(bone_transform(skeleton, thigh, true).origin) \
		+ joint.distance_to(bone_transform(skeleton, ankle, true).origin)


func bake_reaction(player: AnimationPlayer, source: Skeleton3D, dest: Skeleton3D,
		clip: StringName, corrections: Array[Basis], hints: Array[Vector3]) -> Animation:
	var is_hit: bool = clip == &"Hit_Chest"
	var source_duration: float = player.get_animation(clip).length
	var animation := Animation.new()
	animation.length = HIT_DURATION if is_hit else source_duration
	animation.set_meta("source_clip", String(clip))
	var hip: int = dest.find_bone("root hips_02")
	var hip_track: int = -1
	if not is_hit:
		hip_track = add_track(animation, Animation.TYPE_POSITION_3D, GAMEPLAY_SKIN_PATH + ":root hips_02")
	var ratio: float = leg_length(dest, "leg left thigh_063", "leg left knee_064", "leg left ankle_065") \
		/ leg_length(source, "DEF-thigh.L", "DEF-shin.L", "DEF-foot.L")
	var source_rest: Vector3 = pelvis(source, "DEF-thigh.L", "DEF-thigh.R", true)
	var target_rest: Vector3 = pelvis(dest, "leg left thigh_063", "leg right thigh_059", true)
	var hip_parent: Basis = (dest.global_transform * dest.get_bone_global_rest(dest.get_bone_parent(hip))).basis
	var track_ids: Array[int] = []
	var initial_rotations: Dictionary[int, Quaternion] = {}
	for entry: Array in MAP:
		var bone: String = entry[0]
		var upper_body: bool = bone.begins_with("spine ") or bone.begins_with("head ")
		track_ids.append(add_track(animation, Animation.TYPE_ROTATION_3D, GAMEPLAY_SKIN_PATH + ":" + bone)
			if not is_hit or upper_body else -1)

	source.reset_bone_poses()
	player.play(clip)
	var samples: int = maxi(roundi(animation.length * FPS), 1)
	for sample in samples + 1:
		var phase: float = float(sample) / samples
		player.seek(source_duration * phase, true)
		source.force_update_all_bone_transforms()
		dest.reset_bone_poses()
		for i in MAP.size():
			var entry: Array = MAP[i]
			var source_pose: Basis = bone_transform(source, entry[1]).basis.orthonormalized()
			var desired: Basis = source_pose * corrections[i]
			if entry[2] != "":
				var direction: Vector3 = bone_transform(source, entry[3]).origin \
					- bone_transform(source, entry[1]).origin
				desired = limb_frame(direction, source_pose * hints[i]) * corrections[i]
			var index: int = dest.find_bone(entry[0])
			dest.force_update_all_bone_transforms()
			var parent_pose: Basis = (dest.global_transform \
				* dest.get_bone_global_pose(dest.get_bone_parent(index))).basis.orthonormalized()
			var rotation: Quaternion = (parent_pose.inverse() * desired).get_rotation_quaternion().normalized()
			dest.set_bone_pose_rotation(index, rotation)
			if track_ids[i] < 0:
				continue
			if is_hit:
				if sample == 0:
					initial_rotations[i] = rotation
				var rest: Quaternion = dest.get_bone_rest(index).basis.get_rotation_quaternion()
				# Godot removes the target rest when applying additive tracks.
				rotation = (rest * initial_rotations[i].inverse() * rotation).normalized()
			animation.rotation_track_insert_key(track_ids[i], animation.length * phase, rotation)
		if hip_track >= 0:
			dest.force_update_all_bone_transforms()
			var source_center: Vector3 = pelvis(source, "DEF-thigh.L", "DEF-thigh.R", false)
			var target_center: Vector3 = pelvis(dest, "leg left thigh_063", "leg right thigh_059", false)
			var position: Vector3 = dest.get_bone_rest(hip).origin \
				+ hip_parent.inverse() * (target_rest + (source_center - source_rest) * ratio - target_center)
			animation.position_track_insert_key(hip_track, animation.length * phase, position)
	return animation
