extends SceneTree

const KIT := "res://arca/assets/environment/kit/"
const SIZES := {
	"wall_4m": Vector3(4, 4.5, 0.5),
	"wall_2m": Vector3(2, 4.5, 0.5),
	"doorway_frame": Vector3(4, 4.5, 0.5),
	"floor_tile": Vector3(4, 0.5, 4),
	"pillar": Vector3(0.5, 4.5, 0.5),
	"pipe_run": Vector3(4, 0.5, 0.5),
	"cable_tray": Vector3(4, 0.5, 0.5),
	"light_strip": Vector3(2, 0.5, 0.5),
	"vent_grille": Vector3(1.5, 1, 0.5),
	"crate": Vector3(1.5, 1, 1),
	"console": Vector3(1.5, 1.5, 0.5),
}
const SOLIDS := ["wall_4m", "wall_2m", "doorway_frame", "floor_tile", "pillar", "crate", "console"]
var checks := 0
var failures := 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)


func run() -> void:
	for piece: String in SIZES:
		var path := KIT + piece + ".tscn"
		check(ResourceLoader.exists(path, "PackedScene"), piece + " exists")
		if not ResourceLoader.exists(path, "PackedScene"):
			continue
		var module: Node3D = load(path).instantiate()
		var visual: MeshInstance3D = module.get_node_or_null("Visual")
		check(visual != null and visual.mesh != null, piece + " has renderable geometry")
		if visual == null or visual.mesh == null:
			module.free()
			continue
		var bounds: AABB = visual.transform * visual.get_aabb()
		var size: Vector3 = SIZES[piece]
		var bottom := -size.y if piece == "floor_tile" else 0.0
		check(bounds.size.is_equal_approx(size), piece + " matches the grid envelope: " + str(bounds))
		check(bounds.position.is_equal_approx(Vector3(-size.x / 2, bottom, -size.z / 2)),
			piece + " has a centred placement origin")
		var triangles := visual.mesh.get_faces().size() / 3.0
		check(triangles > 0 and triangles <= 2000, piece + " triangle budget: " + str(triangles))
		var solid: StaticBody3D = module.get_node_or_null("Solid")
		if piece in SOLIDS:
			check(solid != null and solid.collision_layer == 1, piece + " has world collision")
			if solid != null:
				check(solid.get_child_count() == (3 if piece == "doorway_frame" else 1),
					piece + " uses minimal collision shapes")
				for shape: CollisionShape3D in solid.get_children():
					check(shape.shape is BoxShape3D and not shape.disabled, piece + " uses active box collision")
		else:
			check(module.find_children("*", "CollisionObject3D").is_empty(), piece + " is nonblocking dressing")
		if piece == "doorway_frame" and solid != null:
			await check_opening(module, visual)
		module.free()

	var preview_path := KIT + "kit_preview.tscn"
	check(ResourceLoader.exists(preview_path, "PackedScene"), "preview is loadable")
	if ResourceLoader.exists(preview_path, "PackedScene"):
		var preview: Node3D = load(preview_path).instantiate()
		for piece: String in SIZES:
			var source := KIT + piece + ".tscn"
			check(preview.get_children().any(func(node: Node) -> bool: return node.scene_file_path == source),
				"preview includes " + piece)
		preview.free()
	print("ENVIRONMENT KIT RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)


func check_opening(module: Node3D, visual: MeshInstance3D) -> void:
	root.add_child(module)
	await physics_frame
	await physics_frame
	var space := root.world_3d.direct_space_state
	var mesh_faces := visual.mesh.get_faces()
	for x: float in [-0.899, 0.0, 0.899]:
		for y: float in [0.001, 1.3, 2.599]:
			var start := Vector3(x, y, -1)
			var end := Vector3(x, y, 1)
			var ray := PhysicsRayQueryParameters3D.create(start, end, 1)
			check(space.intersect_ray(ray).is_empty(), "doorway clearance at " + str(start))
			var clear := true
			for i in range(0, mesh_faces.size(), 3):
				if Geometry3D.segment_intersects_triangle(start, end,
					mesh_faces[i], mesh_faces[i + 1], mesh_faces[i + 2]) != null:
					clear = false
					break
			check(clear, "doorway visual clearance at " + str(start))
	for point: Vector2 in [Vector2(-1, 1), Vector2(1, 1), Vector2(0, 2.7)]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(point.x, point.y, -1),
			Vector3(point.x, point.y, 1), 1)
		check(not space.intersect_ray(ray).is_empty(), "jamb or header blocks at " + str(point))
	root.remove_child(module)
