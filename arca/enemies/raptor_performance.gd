extends SkeletonModifier3D
## Additive acting on the Ferocious rig after the locomotion clip is sampled.

var actor: ArcaRaptor
var yaw := 0.0
var pitch := 0.0
var tail := 0.0
var previous_heading := 0.0
var bones: Dictionary[StringName, int] = {}


func _process_modification() -> void:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not is_inside_tree() or not actor.combat_enabled:
		return
	var rig := get_skeleton()
	if bones.is_empty():
		for id in rig.get_bone_count():
			bones[rig.get_bone_name(id)] = id
	var heading := actor.global_rotation.y
	var turn := angle_difference(previous_heading, heading)
	previous_heading = heading
	var target := actor.performance_focus()
	var relative := actor.global_basis.inverse() * (target - actor.global_position) if target.is_finite() else Vector3.ZERO
	var active := actor.cue_age < actor.cue_length
	var beat := sin(PI * clampf(actor.cue_age / maxf(actor.cue_length, 0.01), 0.0, 1.0))
	var look := clampf(atan2(-relative.x, -relative.z), -0.65, 0.65) if relative.length_squared() > 0.2 else 0.0
	var elevation := clampf(relative.y * 0.20, -0.28, 0.28)
	var weight := 0.0
	match actor.state:
		ArcaRaptor.State.FLANK: weight = 0.10
		ArcaRaptor.State.JUMP_LOAD: weight = minf(actor.elapsed / 0.23, 1.0) * 0.20
		ArcaRaptor.State.JUMP_LAND: weight = sin(PI * clampf(actor.elapsed / 0.26, 0.0, 1.0)) * 0.18
	if active and actor.cue_kind == "call":
		elevation += 0.32 * beat
	if active and actor.cue_kind == "threat":
		elevation -= 0.19 * beat
	yaw = lerpf(yaw, look, 0.26)
	pitch = lerpf(pitch, elevation, 0.23)
	tail = lerpf(tail, clampf(-turn * 5.0, -0.37, 0.37), 0.25)
	_rotate(rig, &"Neck_1_06", Vector3.UP, yaw * 0.37)
	_rotate(rig, &"Neck_2_07", Vector3.RIGHT, pitch * 0.55)
	_rotate(rig, &"Head_09", Vector3.UP, yaw * 0.50)
	_rotate(rig, &"Head_09", Vector3.RIGHT, pitch * 0.45)
	_rotate(rig, &"Eye.L_012", Vector3.UP, yaw * 0.16)
	_rotate(rig, &"Eye.R_010", Vector3.UP, yaw * 0.16)
	_rotate(rig, &"Tail_1_074", Vector3.UP, tail)
	_rotate(rig, &"Tail_3_076", Vector3.UP, tail * 0.6)
	_rotate(rig, &"Spine_1_03", Vector3.RIGHT, -weight)
	if weight > 0.0:
		_rotate(rig, &"UpperLeg.L_089", Vector3.RIGHT, weight * 0.66)
		_rotate(rig, &"UpperLeg.R_060", Vector3.RIGHT, weight * 0.66)
		_rotate(rig, &"LowerLeg.L_090", Vector3.RIGHT, -weight * 1.16)
		_rotate(rig, &"LowerLeg.R_061", Vector3.RIGHT, -weight * 1.16)
	_rotate(rig, &"Jaw_1_014", Vector3.RIGHT, beat * 0.12 if active else 0.0)
	var root: int = bones.get(&"Root_02", -1)
	if root >= 0 and weight > 0.0:
		var local_down := rig.get_bone_global_pose(root).basis.inverse() * (rig.global_basis.inverse() * Vector3.DOWN)
		rig.set_bone_pose_position(root, rig.get_bone_pose_position(root) + local_down * weight * 0.48)


func _rotate(rig: Skeleton3D, name: StringName, axis: Vector3, angle: float) -> void:
	var id: int = bones.get(name, -1)
	if id < 0:
		return
	var bone_axis := (rig.get_bone_global_pose(id).basis.inverse() * rig.global_basis.inverse() * actor.global_basis * axis).normalized()
	rig.set_bone_pose_rotation(id, rig.get_bone_pose_rotation(id) * Quaternion(bone_axis, angle))
