extends SceneTree
## Resource/skin inspection, not a playable-character or visual-quality test.

const ASSET := "res://arca/assets/characters/regina/regina.glb"
const TEXTURE_DIR := "res://arca/assets/characters/regina/"
const TEXTURE_SIZES: Array[Vector2i] = [
	Vector2i(1024, 1024), Vector2i(1024, 1024),
	Vector2i(256, 512), Vector2i(256, 512),
	Vector2i(256, 256), Vector2i(256, 256),
	Vector2i(1024, 1024), Vector2i(1024, 1024),
	Vector2i(1024, 1024), Vector2i(1024, 1024),
	Vector2i(512, 512), Vector2i(2, 2),
	Vector2i(512, 512), Vector2i(512, 512),
	Vector2i(512, 1024), Vector2i(512, 1024), Vector2i(256, 128),
]

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func source_document() -> Dictionary:
	var file := FileAccess.open(ASSET, FileAccess.READ)
	if file == null:
		return {}
	if file.get_32() != 0x46546c67 or file.get_32() != 2:
		return {}
	if file.get_32() != file.get_length():
		return {}
	var json_length: int = file.get_32()
	if file.get_32() != 0x4e4f534a:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_buffer(json_length).get_string_from_utf8())
	return parsed if parsed is Dictionary else {}


func texture_matches(texture: Texture2D, index: int) -> bool:
	return texture != null and texture.resource_path == TEXTURE_DIR + "regina_%d.png" % index \
		and Vector2i(texture.get_size()) == TEXTURE_SIZES[index]


func valid_vertices(mesh: MeshInstance3D) -> bool:
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if vertices.is_empty() or bones.size() != weights.size():
			return false
		var influences: int = int(float(bones.size()) / vertices.size())
		if influences not in [4, 8] or bones.size() != vertices.size() * influences:
			return false
		for vertex in vertices.size():
			if not vertices[vertex].is_finite():
				return false
			var total: float = 0.0
			for influence in influences:
				var offset: int = vertex * influences + influence
				if bones[offset] < 0 or bones[offset] >= mesh.skin.get_bind_count() \
					or not is_finite(weights[offset]) or weights[offset] < 0.0:
					return false
				total += weights[offset]
			if absf(total - 1.0) > 0.0001:
				return false
	return true


func posed_bounds(mesh: MeshInstance3D, skeleton: Skeleton3D) -> AABB:
	# Dummy/headless rendering cannot bake a GPU skin. Apply the same named bind
	# matrices on the CPU; raw mesh AABBs ignore the imported skeleton/rest axes.
	var transforms: Array[Transform3D] = []
	for bind in mesh.skin.get_bind_count():
		var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bind))
		transforms.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) \
			* mesh.skin.get_bind_pose(bind))
	var bounds := AABB()
	var started: bool = false
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences: int = int(float(bones.size()) / vertices.size())
		for vertex in vertices.size():
			var point := Vector3.ZERO
			for influence in influences:
				var offset: int = vertex * influences + influence
				point += (transforms[bones[offset]] * vertices[vertex]) * weights[offset]
			bounds = bounds.expand(point) if started else AABB(point, Vector3.ZERO)
			started = true
	return bounds


func run() -> void:
	var source: Dictionary = source_document()
	check(not source.is_empty(), "Source is a readable GLB 2 document")
	var packed := load("res://arca/character_test.tscn") as PackedScene
	check(packed != null, "Separate character test scene loads")
	if source.is_empty() or packed == null:
		finish()
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var model: Node3D = scene.get_node("ModelPivot/Regina")
	var camera: Camera3D = scene.get_node("Camera3D")
	check(camera.is_current(), "Inspection scene has a current camera")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://arca/mission_room.tscn",
		"F5 main scene remains the mission")
	var skeletons: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	check(skeletons.size() == 1, "Exactly one imported Skeleton3D")
	if skeletons.size() != 1:
		scene.queue_free()
		await process_frame
		finish()
		return
	var skeleton := skeletons[0] as Skeleton3D
	print("SKELETON: ", model.get_path_to(skeleton))
	print("SKELETON WORLD TRANSFORM: ", skeleton.global_transform)
	var nodes: Array = source["nodes"]
	var joints: Array = source["skins"][0]["joints"]
	check(joints.size() == 69 and skeleton.get_bone_count() == joints.size(),
		"All 69 source joints are preserved without added bones")
	var hierarchy_valid: bool = true
	for joint: int in joints:
		var name: String = nodes[joint]["name"]
		var bone: int = skeleton.find_bone(name)
		if bone < 0:
			hierarchy_valid = false
			continue
		var expected_parent: String = ""
		for candidate: int in joints:
			for child: int in nodes[candidate].get("children", []):
				if child == joint:
					expected_parent = nodes[candidate]["name"]
		var parent: int = skeleton.get_bone_parent(bone)
		var parent_name: String = skeleton.get_bone_name(parent) if parent >= 0 else ""
		hierarchy_valid = hierarchy_valid and parent_name == expected_parent \
			and skeleton.get_bone_rest(bone).is_finite()
		print("BONE: ", bone, " | ", name, " | parent=", parent, " | rest=", skeleton.get_bone_rest(bone))
	check(hierarchy_valid, "Source bone names/parents and finite rest transforms survive import")
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	var authored_clips: int = 0
	for player: AnimationPlayer in players:
		for name: StringName in player.get_animation_list():
			var animation: Animation = player.get_animation(name)
			print("ANIMATION: ", name, " length=", animation.length, " loop=", animation.loop_mode,
				" tracks=", animation.get_track_count())
			if name != &"RESET":
				authored_clips += 1
	print("ANIMATION PLAYERS: ", players.size(), " | authored clips=", authored_clips)
	check(source.get("animations", []).is_empty() and authored_clips == 0,
		"Zero authored clips is source data, not an import failure")
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 9 and source["materials"].size() == 9, "All nine source mesh/material parts exist")
	var combined := AABB()
	var started: bool = false
	var body: MeshInstance3D
	for node: Node in meshes:
		var mesh := node as MeshInstance3D
		var index: int = String(mesh.name).trim_prefix("Object_").to_int() - 75
		check(index >= 0 and index < 9, "%s has its expected source part ID" % mesh.name)
		if index < 0 or index >= 9:
			continue
		var bindings_valid: bool = mesh.skin != null and mesh.get_node_or_null(mesh.skeleton) == skeleton
		if bindings_valid:
			for bind in mesh.skin.get_bind_count():
				bindings_valid = bindings_valid and skeleton.find_bone(mesh.skin.get_bind_name(bind)) >= 0 \
					and mesh.skin.get_bind_pose(bind).is_finite()
		check(bindings_valid, "%s has valid named skeleton bindings" % mesh.name)
		check(mesh.global_transform.is_finite() and mesh.mesh.get_surface_count() == 1,
			"%s has one surface and a finite transform" % mesh.name)
		if not bindings_valid:
			continue
		var vertices_valid: bool = valid_vertices(mesh)
		check(vertices_valid, "%s has finite vertices and valid normalized skin weights" % mesh.name)
		if vertices_valid:
			var bounds: AABB = posed_bounds(mesh, skeleton)
			check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.has_volume(),
				"%s has nonempty posed world bounds" % mesh.name)
			combined = combined.merge(bounds) if started else bounds
			started = true
			print("MESH: ", model.get_path_to(mesh), " | binds=", mesh.skin.get_bind_count(), " | posed=", bounds)
			if index == 4:
				body = mesh
		var material := mesh.get_active_material(0) as StandardMaterial3D
		var expected: Dictionary = source["materials"][index]
		check(material != null and material.resource_name == expected["name"],
			"%s retains its source material" % mesh.name)
		if material == null:
			continue
		var albedo_index: int = expected["pbrMetallicRoughness"]["baseColorTexture"]["index"]
		check(texture_matches(material.albedo_texture, albedo_index),
			"%s albedo mapping and dimensions match" % mesh.name)
		if expected.has("normalTexture"):
			var normal_index: int = expected["normalTexture"]["index"]
			check(material.normal_enabled and texture_matches(material.normal_texture, normal_index),
				"%s normal mapping and dimensions match" % mesh.name)
		else:
			check(material.normal_texture == null, "%s correctly has no normal texture" % mesh.name)
		var alpha_valid: bool = material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
		if expected.get("alphaMode", "OPAQUE") == "MASK":
			alpha_valid = material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR \
				and is_equal_approx(material.alpha_scissor_threshold, expected["alphaCutoff"])
		check(alpha_valid and material.cull_mode == BaseMaterial3D.CULL_DISABLED,
			"%s preserves source alpha mode/cutoff and double-sided rendering" % mesh.name)
		print("MATERIAL: ", material.resource_name, " | albedo=", material.albedo_texture.resource_path,
			" | normal=", material.normal_texture.resource_path if material.normal_texture else "none",
			" | roughness=", material.roughness, " | specular=", material.metallic_specular,
			" | alpha=", material.transparency, " | cutoff=", material.alpha_scissor_threshold)
	print("COMBINED POSED WORLD BOUNDS: ", combined)
	check(started and combined.size.y > 1.7 and combined.size.y < 1.9 and absf(combined.position.y) < 0.001,
		"Measured rest-pose height is human scale and wrapper aligns feet with ground")
	if body != null:
		var before: AABB = posed_bounds(body, skeleton)
		var wrist: int = skeleton.find_bone("arm right wrist_021")
		var original: Quaternion = skeleton.get_bone_pose_rotation(wrist)
		skeleton.set_bone_pose_rotation(wrist, original * Quaternion(Vector3.FORWARD, 0.15))
		await process_frame
		var moved: AABB = posed_bounds(body, skeleton)
		check(not before.is_equal_approx(moved), "Temporary wrist rotation deforms the bound body mesh")
		skeleton.set_bone_pose_rotation(wrist, original)
		await process_frame
		check(before.is_equal_approx(posed_bounds(body, skeleton)), "Restoring wrist pose restores mesh bounds")
	scene.queue_free()
	await process_frame
	finish()


func finish() -> void:
	print("RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
