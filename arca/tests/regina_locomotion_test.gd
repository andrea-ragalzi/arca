extends SceneTree
## Deterministic playback/contact checks, not a substitute for rendered inspection.

const SCENE := "res://arca/character_locomotion_test.tscn"
const SKIN_PATH := "ModelPivot/Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"
const DT: float = 1.0 / 60.0
# Flat support, excluding heel-strike, toe-off and the run's intended flight.
const WALK_CONTACTS: Array[Vector2] = [Vector2(0.12, 0.30), Vector2(0.62, 0.80)]
const RUN_CONTACTS: Array[Vector2] = [Vector2(0.06, 0.12), Vector2(0.56, 0.62)]
const MAX_STANCE_DRIFT: float = 0.03
const MAX_STANCE_CLEARANCE: float = 0.02

var checks: int = 0
var failures: int = 0
var scene: Node3D
var skeleton: Skeleton3D
var soles: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func skin_vertices(mesh: MeshInstance3D, rest: bool = false) -> PackedVector3Array:
	var matrices: Array[Transform3D] = []
	for bind in mesh.skin.get_bind_count():
		var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bind))
		matrices.append(skeleton.global_transform * (skeleton.get_bone_global_rest(bone) \
			if rest else skeleton.get_bone_global_pose(bone)) * mesh.skin.get_bind_pose(bind))
	var arrays: Array = mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var influences: int = int(float(bones.size()) / vertices.size())
	var result := PackedVector3Array()
	for vertex in vertices.size():
		var point := Vector3.ZERO
		for influence in influences:
			var offset: int = vertex * influences + influence
			point += (matrices[bones[offset]] * vertices[vertex]) * weights[offset]
		result.append(point)
		if rest and point.y < 0.025:
			soles.append({"mesh": mesh, "vertex": vertex, "side": 0 if point.x < 0 else 1})
	return result


func contact_points() -> Array[Vector3]:
	var mesh_points: Dictionary = {}
	for sample: Dictionary in soles:
		var mesh: MeshInstance3D = sample["mesh"]
		if not mesh_points.has(mesh):
			mesh_points[mesh] = skin_vertices(mesh)
	var lowest: Array[float] = [INF, INF]
	for sample: Dictionary in soles:
		var point: Vector3 = mesh_points[sample["mesh"]][sample["vertex"]]
		lowest[sample["side"]] = minf(lowest[sample["side"]], point.y)
	var positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	var counts: Array[int] = [0, 0]
	for sample: Dictionary in soles:
		var side: int = sample["side"]
		var point: Vector3 = mesh_points[sample["mesh"]][sample["vertex"]]
		if point.y < lowest[side] + 0.002:
			positions[side] += point
			counts[side] += 1
	for side in 2:
		positions[side] /= counts[side]
		positions[side].y = lowest[side]
	return positions


func start_clip(clip: StringName, translate: bool = false) -> void:
	scene.select_clip(clip)
	scene.set_translating(translate)


func test_library(library: AnimationLibrary) -> void:
	var expected: Array[StringName] = [&"idle", &"run", &"walk"]
	check(library.get_animation_list() == expected,
		"Exactly the three intended playable clips, no combat/robot tracks")
	for clip: StringName in library.get_animation_list():
		var animation: Animation = library.get_animation(clip)
		check(animation.length > 0.5 and animation.loop_mode == Animation.LOOP_LINEAR,
			"%s has a positive duration and loops" % clip)
		var valid_tracks: bool = true
		var normalized: bool = true
		var closed: bool = true
		for track in animation.get_track_count():
			var path: NodePath = animation.track_get_path(track)
			valid_tracks = valid_tracks and scene.get_node_or_null(NodePath(path.get_concatenated_names())) != null
			if path.get_subname_count() > 0:
				valid_tracks = valid_tracks and skeleton.find_bone(path.get_subname(0)) >= 0
			valid_tracks = valid_tracks and animation.track_get_type(track) in [Animation.TYPE_POSITION_3D,
				Animation.TYPE_ROTATION_3D]
			for key in animation.track_get_key_count(track):
				var value: Variant = animation.track_get_key_value(track, key)
				if value is Quaternion:
					normalized = normalized and value.is_finite() and absf(value.length() - 1.0) < 0.0001
				else:
					normalized = normalized and value.is_finite()
			if path != NodePath("RootMotion"):
				var first: Variant = animation.track_get_key_value(track, 0)
				var last: Variant = animation.track_get_key_value(track, animation.track_get_key_count(track) - 1)
				closed = closed and (first.angle_to(last) < 0.001 if first is Quaternion \
					else first.distance_to(last) < 0.00001)
		check(valid_tracks, "%s tracks resolve, with no scale transfer" % clip)
		check(normalized, "%s keys are finite and rotations normalized" % clip)
		check(closed, "%s pose seam closes independently of intended root travel" % clip)


func test_motion(library: AnimationLibrary) -> void:
	for clip: StringName in library.get_animation_list():
		var animation: Animation = library.get_animation(clip)
		var end: Vector3 = animation.track_get_key_value(0, animation.track_get_key_count(0) - 1)
		start_clip(clip)
		var sum := Vector3.ZERO
		var max_step: float = 0.0
		var frames: int = roundi(animation.length * 60.0 * 3.0)
		var stable_lengths: bool = true
		var continuous: bool = true
		var previous: Array[Quaternion] = []
		for bone in skeleton.get_bone_count():
			previous.append(skeleton.get_bone_pose_rotation(bone))
		for frame in frames:
			scene.advance_locomotion(DT)
			skeleton.force_update_all_bone_transforms()
			var delta: Vector3 = scene.last_root_delta
			sum += delta
			max_step = maxf(max_step, delta.length())
			for bone in skeleton.get_bone_count():
				var rotation: Quaternion = skeleton.get_bone_pose_rotation(bone)
				continuous = continuous and previous[bone].angle_to(rotation) < 0.35
				previous[bone] = rotation
				stable_lengths = stable_lengths and skeleton.get_bone_pose_scale(bone).is_equal_approx(
					skeleton.get_bone_rest(bone).basis.get_scale())
				if skeleton.get_bone_name(bone) != "root hips_02":
					stable_lengths = stable_lengths and skeleton.get_bone_pose_position(bone).is_equal_approx(
						skeleton.get_bone_rest(bone).origin)
		var expected: Vector3 = end * (frames * DT / animation.length)
		check(sum.distance_to(expected) < 0.003, "%s extraction accumulates correctly across three loops" % clip)
		check(max_step < absf(end.z) / animation.length * DT + 0.001,
			"%s has no root reset/reversal spike" % clip)
		check(stable_lengths, "%s preserves Regina lengths/scales and secondary bone reference locals" % clip)
		check(continuous, "%s has no sudden knee/shoulder/hand rotation flip at 60 Hz" % clip)
		check(scene.model_pivot.position.is_equal_approx(scene.initial_position), "%s centered mode removes travel" % clip)
		check(scene.get_node("RootMotion").position.length() < 0.00001, "%s extraction prevents double visual travel" % clip)
		print("MOTION: ", clip, " displacement=", sum, " max_step=", max_step, " m/s=", -end.z / animation.length)
		start_clip(clip, true)
		var elapsed: float = 0.0
		while elapsed < animation.length - 0.000001:
			var step: float = minf(DT, animation.length - elapsed)
			scene.advance_locomotion(step)
			elapsed += step
		check((scene.model_pivot.position - scene.initial_position).distance_to(end) < 0.003,
			"%s translated preview applies the extracted delta exactly once along -Z" % clip)


func test_contacts(library: AnimationLibrary) -> void:
	for clip: StringName in library.get_animation_list():
		start_clip(clip, true)
		var duration: float = library.get_animation(clip).length
		var first: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
		var initialized: Array[bool] = [false, false]
		var max_drift: float = 0.0
		var max_height: float = 0.0
		var min_height: float = INF
		var contact_count: int = 0
		for frame in 121:
			if frame > 0:
				scene.advance_locomotion(duration / 120.0)
			skeleton.force_update_all_bone_transforms()
			var points: Array[Vector3] = contact_points()
			for side in 2:
				min_height = minf(min_height, points[side].y)
				var phase: float = frame / 120.0
				var interval := Vector2(0, 1)
				if clip == &"walk":
					interval = WALK_CONTACTS[side]
				elif clip == &"run":
					interval = RUN_CONTACTS[side]
				if phase < interval.x or phase > interval.y:
					continue
				contact_count += 1
				max_height = maxf(max_height, points[side].y)
				if not initialized[side]:
					first[side] = points[side]
					initialized[side] = true
				var drift: Vector3 = points[side] - first[side]
				drift.y = 0
				max_drift = maxf(max_drift, drift.length())
		check(contact_count >= 12, "%s contact windows contain meaningful samples on both feet" % clip)
		check(min_height > -0.002, "%s soles do not penetrate the floor beyond 2 mm" % clip)
		check(max_height <= MAX_STANCE_CLEARANCE, "%s flat-support clearance stays within 2 cm" % clip)
		check(max_drift <= MAX_STANCE_DRIFT, "%s flat-support drift stays within 3 cm" % clip)
		print("CONTACT: ", clip, " minimum_y=", min_height, " stance_max_y=", max_height,
			" stance_drift=", max_drift, " samples=", contact_count)


func test_meshes(library: AnimationLibrary) -> void:
	var meshes: Array[Node] = scene.get_node("ModelPivot/Regina").find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 9, "All nine original mesh/material parts remain present")
	for clip: StringName in library.get_animation_list():
		start_clip(clip)
		var valid_meshes: bool = true
		for sample in 8:
			scene.advance_locomotion(library.get_animation(clip).length / 8.0)
			skeleton.force_update_all_bone_transforms()
			for node: Node in meshes:
				var mesh := node as MeshInstance3D
				valid_meshes = valid_meshes and mesh.get_node(mesh.skeleton) == skeleton \
					and mesh.get_active_material(0) != null
				for point: Vector3 in skin_vertices(mesh):
					valid_meshes = valid_meshes and point.is_finite() and absf(point.x) < 1.5 \
						and absf(point.z) < 1.5 and point.y > -0.002 and point.y < 2.1
		check(valid_meshes, "%s full-cycle CPU skin has finite human-sized attached parts" % clip)


func test_lifecycle() -> void:
	start_clip(&"run", true)
	for frame in 10:
		scene.advance_locomotion(DT)
	var before: Vector3 = scene.model_pivot.position
	var rotation: Quaternion = skeleton.get_bone_pose_rotation(skeleton.find_bone("leg left knee_064"))
	scene.paused = true
	for frame in 10:
		scene.advance_locomotion(DT)
	check(scene.model_pivot.position == before and rotation.is_equal_approx(
		skeleton.get_bone_pose_rotation(skeleton.find_bone("leg left knee_064"))), "Pause freezes both pose and travel")
	scene.paused = false
	scene.advance_locomotion(DT)
	check(scene.model_pivot.position.z < before.z, "Resume continues travel without a delayed jump")
	scene.reset_preview()
	check(scene.selected_clip == &"idle" and not scene.paused and not scene.translating \
		and scene.model_pivot.position.is_equal_approx(scene.initial_position), "Reset restores idle, centered origin and pause state")
	scene.advance_locomotion(DT)
	check(scene.last_root_delta.length() < 0.0001, "Reset clears the previous root-motion extraction history")
	var clean_transitions: bool = true
	var previous: Array[Quaternion] = []
	for bone in skeleton.get_bone_count():
		previous.append(skeleton.get_bone_pose_rotation(bone))
	for clip: StringName in [&"walk", &"run", &"idle"]:
		scene.select_clip(clip)
		for frame in 20:
			scene.advance_locomotion(DT)
			clean_transitions = clean_transitions and scene.last_root_delta.length() < 0.11 \
				and scene.last_root_delta.z <= 0.0001
			for bone in skeleton.get_bone_count():
				var rotation_now: Quaternion = skeleton.get_bone_pose_rotation(bone)
				clean_transitions = clean_transitions and previous[bone].angle_to(rotation_now) < 0.35
				previous[bone] = rotation_now
		clean_transitions = clean_transitions and scene.playback.get_current_node() == clip
	check(clean_transitions, "Crossfades reach idle/walk/run without pose flips, root reversal or travel spikes")
	start_clip(&"run", true)
	for frame in 180:
		scene.advance_locomotion(DT)
	check(scene.lane_finished and scene.paused and scene.model_pivot.position.z < -12.0,
		"Finite travel lane pauses explicitly at its end instead of teleporting")
	scene.reset_preview()
	check(not scene.lane_finished, "Reset clears lane-end state")


func press_key(key: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame


func test_inputs() -> void:
	# Earlier checks advance the manual animation synchronously; let the root
	# viewport finish its first frame before dispatching real input events.
	await process_frame
	scene.reset_preview()
	await press_key(KEY_2)
	check(scene.selected_clip == &"walk", "Physical 2 selects walk through the real input path")
	await press_key(KEY_3, true)
	check(scene.selected_clip == &"walk", "Held-key echo does not retrigger clip selection")
	await press_key(KEY_3)
	await press_key(KEY_M)
	check(scene.selected_clip == &"run" and scene.translating, "Physical 3/M select run and enable travel")
	await press_key(KEY_SPACE)
	check(scene.paused, "Physical Space pauses the preview")
	var view: int = scene.view_index
	await press_key(KEY_V)
	check(scene.view_index == (view + 1) % 4, "Physical V changes inspection view while paused")
	await press_key(KEY_R)
	check(scene.selected_clip == &"idle" and not scene.paused and not scene.translating,
		"Physical R restores centered idle while paused")


func run() -> void:
	check(FileAccess.get_sha256("res://arca/assets/characters/regina/regina.glb") ==
		"54e1da324e570ac7eb16712377e819f2fd823fb15a4791f17f56e929da0db75e", "Original Regina GLB is byte-unchanged")
	check(FileAccess.get_sha256("res://player/model/player.glb") ==
		"d1b497efaee3eec602b9e7f7aec8ab4b2f50394838c36605beccf97d41f4fd68", "Original TPS donor GLB is byte-unchanged")
	scene = load(SCENE).instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_physics_process(false)
	check(scene.valid, "Inherited isolated preview initializes with valid animation paths")
	if not scene.valid:
		quit(1)
		return
	skeleton = scene.get_node(SKIN_PATH)
	for mesh: MeshInstance3D in scene.get_node("ModelPivot/Regina").find_children("*", "MeshInstance3D", true, false):
		skin_vertices(mesh, true)
	check(soles.size() > 50, "Contact probes come from actual reference-pose sole vertices")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://arca/mission_room.tscn", "F5 remains the original mission")
	var library: AnimationLibrary = load("res://arca/assets/characters/regina/locomotion.tres")
	test_library(library)
	test_motion(library)
	test_contacts(library)
	test_meshes(library)
	test_lifecycle()
	await test_inputs()
	scene.queue_free()
	await process_frame
	print("RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
