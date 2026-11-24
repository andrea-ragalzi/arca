extends SceneTree

const AREAS := "res://arca/areas/"
const REQUIRED_MARKERS := {
	"security_corridor": ["Spawn_SleepingRaptor", "Pickup_Ammo", "Door_ToLift", "Door_ToOffice", "Note_1",
		"Attach_Office", "Attach_Lift"],
	"control_office": ["Pickup_Keycard", "Pickup_Medkit", "Checkpoint", "Spawn_Ambush"],
	"exit_lift": ["Spawn_FinalRaptor", "Exit_Zone", "Pickup_Ammo"],
}
const DOORWAYS := {
	"security_corridor": [Vector3.ZERO, Vector3(-5.25, 0, 11), Vector3(0, 0, 30.25)],
	"control_office": [Vector3.ZERO],
	"exit_lift": [Vector3.ZERO, Vector3(0, 0, 14.25), Vector3(-7.25, 0, 11.5)],
}
const WALL_PROBES := {
	"security_corridor": Vector3(-2.25, 4.65, 5),
	"control_office": Vector3(-6.25, 4.65, 5),
	"exit_lift": Vector3(-7.25, 4.65, 5),
}

var checks: int = 0
var failures: int = 0
var capsule := CapsuleShape3D.new()


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)


func run() -> void:
	capsule.radius = 0.9
	capsule.height = 2.6
	var areas: Dictionary[String, Node3D] = {}
	for area_name: String in REQUIRED_MARKERS:
		var scene := load(AREAS + area_name + ".tscn") as PackedScene
		check(scene != null, area_name + " loads")
		if scene == null:
			continue
		var instance := scene.instantiate()
		var area := instance as Node3D
		check(area != null, area_name + " has a Node3D root")
		if area == null:
			instance.free()
			continue
		areas[area_name] = area
		await check_area(area_name, area)
	if areas.size() == REQUIRED_MARKERS.size():
		await check_connections(areas)
	for area: Node3D in areas.values():
		area.free()
	print("AREAS RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)


func check_area(area_name: String, area: Node3D) -> void:
	check(area.transform.is_equal_approx(Transform3D.IDENTITY), area_name + " has a floor-level entry origin")
	for marker_name: String in REQUIRED_MARKERS[area_name]:
		check(area.find_child(marker_name, true, false) is Marker3D, area_name + " has marker " + marker_name)
	var bodies := area.find_children("*", "CollisionObject3D", true, false)
	check(not bodies.is_empty(), area_name + " has collision")
	for body: CollisionObject3D in bodies:
		check(body is StaticBody3D and body.collision_layer == 1, str(body.name) + " is static world collision")
	var lights := area.find_children("*", "Light3D", true, false)
	var shadow_count: int = 0
	check(lights.size() <= 4, area_name + " has at most four lights")
	for light: Light3D in lights:
		check(light is OmniLight3D, area_name + " uses omni lights")
		if light.shadow_enabled:
			shadow_count += 1
	check(shadow_count <= 1, area_name + " has at most one shadowed light")
	var has_script := area.get_script() != null
	for node: Node in area.find_children("*", "", true, false):
		has_script = has_script or node.get_script() != null
	check(not has_script and area.find_children("*", "NavigationRegion3D", true, false).is_empty(),
		area_name + " is standalone geometry and markers")

	root.add_child(area)
	await physics_frame
	await physics_frame
	var space := root.world_3d.direct_space_state
	var probe: Vector3 = WALL_PROBES[area_name]
	var wall_ray := PhysicsRayQueryParameters3D.create(probe + Vector3.LEFT, probe + Vector3.RIGHT, 1)
	check(not space.intersect_ray(wall_ray).is_empty(), area_name + " wall reaches above 4.65 m")
	for opening: Vector3 in DOORWAYS[area_name]:
		var along := Vector3.RIGHT if opening.x != 0.0 else Vector3.BACK
		check_passage(space, opening - along * 1.2, opening + along * 1.2, "%s doorway at %s" % [area_name, opening])
	root.remove_child(area)


func check_connections(areas: Dictionary[String, Node3D]) -> void:
	var corridor: Node3D = areas["security_corridor"]
	root.add_child(corridor)
	for link: String in ["Attach_Office", "Attach_Lift"]:
		var anchor := corridor.find_child(link, true, false) as Marker3D
		if anchor == null:
			continue
		var adjoining: Node3D = areas["control_office" if link == "Attach_Office" else "exit_lift"]
		adjoining.transform = anchor.global_transform
		root.add_child(adjoining)
		await physics_frame
		await physics_frame
		var space := root.world_3d.direct_space_state
		var entry := anchor.global_position
		var inward := anchor.global_basis.z
		var approach := entry - inward * 1.25
		if link == "Attach_Office":
			check(entry.x < -2.5 and entry.z > 8.0 and entry.z < 14.0,
				"office entry connects through the corridor alcove")
			approach = Vector3(0, 0, entry.z)
		check_passage(space, approach, entry + inward * 1.25, link + " joined doorway")
		for offset: float in [-0.65, -0.05, 0.05, 0.65]:
			var point := entry + inward * offset
			var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.1, point + Vector3.DOWN * 0.1, 1)
			var hit := space.intersect_ray(ray)
			check(not hit.is_empty() and is_zero_approx(hit.position.y), link + " floor at " + str(point))
		root.remove_child(adjoining)
		adjoining.transform = Transform3D.IDENTITY
	root.remove_child(corridor)


func check_passage(space: PhysicsDirectSpaceState3D, start: Vector3, finish: Vector3, label: String) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var lift := Vector3.UP * (capsule.height * 0.5 + 0.01)
	query.transform.origin = start + lift
	var start_clear := space.intersect_shape(query, 1).is_empty()
	query.motion = finish - start
	var motion := space.cast_motion(query)
	query.motion = Vector3.ZERO
	query.transform.origin = finish + lift
	var finish_clear := space.intersect_shape(query, 1).is_empty()
	check(start_clear and motion.size() == 2 and motion[0] >= 1.0 and finish_clear,
		label + " fits a 0.9 m radius capsule")
