extends SceneTree

const PROP_DIR := "res://arca/assets/props/"
const ENVELOPES := {
	"keycard": Vector3(0.12, 0.015, 0.08),
	"checkpoint_terminal": Vector3(0.8, 1.6, 0.6),
	"note_clipboard": Vector3(0.29, 0.04, 0.39),
	"locked_door_frame": Vector3(4.2, 4.8, 0.6),
	"lift_doors": Vector3(3.3, 3.5, 0.45),
	"ammo_box": Vector3(0.58, 0.24, 0.38),
	"medkit_case": Vector3(0.60, 0.24, 0.45),
	"fuse": Vector3(0.62, 0.24, 0.24),
}
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func run() -> void:
	for prop: String in ENVELOPES:
		var path := PROP_DIR + prop + ".tscn"
		check(ResourceLoader.exists(path, "PackedScene"), prop + " scene exists")
		if not ResourceLoader.exists(path, "PackedScene"):
			continue
		var pack := load(path) as PackedScene
		var instance := pack.instantiate() as Node3D
		check(instance != null and instance.has_node("Meshes"), prop + " has its visual node contract")
		if instance == null:
			continue
		root.add_child(instance)
		var bounds := AABB()
		var meshes := instance.find_children("*", "MeshInstance3D", true, false)
		for mesh: MeshInstance3D in meshes:
			var part: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = part if not bounds.has_volume() else bounds.merge(part)
		var limit: Vector3 = ENVELOPES[prop] + Vector3.ONE * 0.001
		check(bounds.has_volume() and bounds.size.x <= limit.x and bounds.size.y <= limit.y
			and bounds.size.z <= limit.z, prop + " fits its placement envelope")
		var scripted := instance.get_script() != null
		for node: Node in instance.find_children("*", "", true, false):
			scripted = scripted or node.get_script() != null
		check(not scripted, prop + " is script free")
		var collisions := instance.find_children("*", "CollisionObject3D", true, false)
		if prop == "locked_door_frame":
			check(instance.get_node_or_null("StatusLight") is MeshInstance3D, prop + " exposes StatusLight")
			check(collisions.size() == 1 and collisions[0] is StaticBody3D
				and collisions[0].collision_layer == 1, prop + " has world-only frame collision")
		else:
			check(collisions.is_empty(), prop + " is nonblocking")
		if prop == "checkpoint_terminal":
			check(instance.get_node_or_null("Screen") is MeshInstance3D, prop + " exposes Screen")
		instance.free()
	print("PROP ASSET RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
