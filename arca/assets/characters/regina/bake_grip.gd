extends SceneTree
## Offline right-hand pose only; source clips, target rests and skin stay unchanged.

const TARGET := "res://arca/assets/characters/regina/regina.glb"
const DONOR := "res://arca/assets/characters/regina/source/ual_pistol_grip.glb"
const OUTPUT := "res://arca/assets/characters/regina/grip.tres"
const SKIN_PATH := "Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"
const FINGERS: Array[Array] = [
	["2", 31, "f_index"], ["3", 28, "f_middle"], ["4", 25, "f_ring"],
	["5", 22, "f_pinky"], ["1", 34, "thumb"],
]


func _initialize() -> void:
	call_deferred("run")


func rest(skeleton: Skeleton3D, name: String) -> Transform3D:
	return skeleton.global_transform * skeleton.get_bone_global_rest(skeleton.find_bone(name))


func palm_normal(skeleton: Skeleton3D, wrist: String, middle: String, index: String, pinky: String) -> Vector3:
	return (rest(skeleton, middle).origin - rest(skeleton, wrist).origin).cross(
		rest(skeleton, pinky).origin - rest(skeleton, index).origin).normalized()


func frame(transform: Transform3D, normal: Vector3) -> Basis:
	var y: Vector3 = transform.basis.y.normalized()
	var z: Vector3 = (normal - y * y.dot(normal)).normalized()
	return Basis(y.cross(z).normalized(), y, z)


func run() -> void:
	var donor: Node3D = load(DONOR).instantiate()
	var target: Node3D = load(TARGET).instantiate()
	root.add_child(donor)
	root.add_child(target)
	var source := donor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var dest := target.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := donor.get_node("AnimationPlayer") as AnimationPlayer
	if not player.has_animation("Pistol_Aim_Neutral"):
		push_error("Missing CC0 pistol-neutral source pose")
		quit(1)
		return
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.play("Pistol_Aim_Neutral")
	player.seek(0.0, true)
	source.force_update_all_bone_transforms()
	var source_normal: Vector3 = palm_normal(source, "DEF-hand.R", "DEF-f_middle.01.R", "DEF-f_index.01.R", "DEF-f_pinky.01.R")
	var dest_normal: Vector3 = palm_normal(dest, "arm right wrist_021", "arm right finger 3a_028", "arm right finger 2a_031", "arm right finger 5a_022")
	var animation := Animation.new()
	animation.length = 0.001
	var entries: Array[Array] = []
	for finger: Array in FINGERS:
		for segment in 3:
			entries.append(["arm right finger %s%s_0%d" % [finger[0], ["a", "b", "c"][segment], int(finger[1]) + segment],
				"DEF-%s.0%d.R" % [finger[2], segment + 1]])
	for entry: Array in entries:
		var target_name: String = entry[0]
		var source_name: String = entry[1]
		var source_index: int = source.find_bone(source_name)
		var target_index: int = dest.find_bone(target_name)
		if source_index < 0 or target_index < 0:
			push_error("Incomplete grip mapping: " + source_name + " -> " + target_name)
			quit(1)
			return
		var source_world: Transform3D = rest(source, source_name)
		var target_world: Transform3D = rest(dest, target_name)
		var source_axes: Basis = source_world.basis.orthonormalized().inverse() * frame(source_world, source_normal)
		var target_axes: Basis = target_world.basis.orthonormalized().inverse() * frame(target_world, dest_normal)
		var conversion: Basis = target_axes * source_axes.inverse()
		var delta: Basis = source.get_bone_rest(source_index).basis.orthonormalized().inverse() \
			* Basis(source.get_bone_pose_rotation(source_index))
		var rotation: Quaternion = (dest.get_bone_rest(target_index).basis.orthonormalized() \
			* conversion * delta * conversion.inverse()).get_rotation_quaternion().normalized()
		var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath(SKIN_PATH + ":" + target_name))
		animation.rotation_track_insert_key(track, 0.0, rotation)
	animation.set_meta("source_clip", "Quaternius CC0 Pistol_Aim_Neutral, first frame")
	animation.set_meta("mapping", "Right finger local rest deltas converted through anatomical palm frames")
	# Flip the backward-pointing palm, not its evaluated arm/aim motion. Combined
	# with the socket's +90-degree gun rotation, this preserves the old barrel basis.
	var wrist := Animation.new()
	wrist.length = 0.001
	var wrist_track: int = wrist.add_track(Animation.TYPE_ROTATION_3D)
	wrist.track_set_path(wrist_track, NodePath(SKIN_PATH + ":arm right wrist_021"))
	wrist.rotation_track_insert_key(wrist_track, 0.0,
			(dest.get_bone_rest(dest.find_bone("arm right wrist_021")).basis.get_rotation_quaternion()
			* Quaternion(Vector3.RIGHT, PI)).normalized())
	wrist.set_meta("purpose", "Additive palm half-turn; preserve evaluated wrist and barrel aim")
	var library := AnimationLibrary.new()
	library.add_animation("RightHandGrip", animation)
	library.add_animation("RightWristGrip", wrist)
	var result: Error = ResourceSaver.save(library, OUTPUT)
	if result != OK:
		push_error("Cannot save grip: " + error_string(result))
		quit(1)
		return
	print("GRIP BAKE: ", animation.get_track_count(), " right-hand rotation tracks")
	donor.queue_free()
	target.queue_free()
	await process_frame
	quit(0)
