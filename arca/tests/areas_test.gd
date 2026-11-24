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
## Probes just under each area's lowest soffit.
const WALL_PROBES := {
	"security_corridor": Vector3(-2.25, 2.4, 5),
	"control_office": Vector3(-6.25, 2.55, 5),
	"exit_lift": Vector3(-7.25, 2.55, 5),
}
const STATION := "res://arca/assets/environment/station/"
const ROOM_CEILING := 2.65
const CORRIDOR_CEILING := 2.50
const RAISED_CEILING := 3.10
const DOOR_HEAD := 2.40
## Lowest permitted point of fittings above the main path.
const OVERHEAD_CLEARANCE := 2.30

## Floor points and their expected clear height, from the local floor.
const CEILING_PROBES := {
	"security_corridor": [[Vector3(0, 0, 5), CORRIDOR_CEILING], [Vector3(-4, 0, 11), CORRIDOR_CEILING],
		[Vector3(0, 0, 29.6), CORRIDOR_CEILING], [Vector3(-1.0, 0, 19.5), RAISED_CEILING]],
	"control_office": [[Vector3(0, 0, 0.8), ROOM_CEILING], [Vector3(4, 0, 7), ROOM_CEILING]],
	"exit_lift": [[Vector3(0, 0, 6), ROOM_CEILING], [Vector3(-10, 0, 12), ROOM_CEILING],
		[Vector3(0, 0, 16), ROOM_CEILING]],
	"maintenance_dressing": [[Vector3(0, 0, 0), ROOM_CEILING], [Vector3(8.3, 0, 2), ROOM_CEILING],
		[Vector3(0, 0, 12.4), ROOM_CEILING], [Vector3(-3.5, 0, -11.8), RAISED_CEILING]],
}
## Main-path lanes (XZ rectangles) that must stay free of low fittings.
const MAIN_PATH := {
	"security_corridor": [Rect2(-0.8, 0, 1.6, 30.5), Rect2(-5.0, 10.2, 5.0, 1.6)],
	"control_office": [Rect2(-0.8, 0, 1.6, 3.0)],
	"exit_lift": [Rect2(-0.8, 0, 1.6, 17.0)],
	"maintenance_dressing": [Rect2(-0.8, -9, 1.6, 23.2), Rect2(8.7, -5.4, 1.6, 14.4)],
}
const BAND_LIMITS := {"Skirting": Vector2(0.0, 0.10), "Band": Vector2(0.10, 1.10), "Upper": Vector2(1.10, 2.65)}

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
	# Fits beneath the 2.40 m route door head with clearance.
	capsule.height = 2.3
	check_wall_family()
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
	await check_maintenance_shell()
	for area: Node3D in areas.values():
		area.free()
	await process_frame
	OS.delay_msec(200)
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
	check(not space.intersect_ray(wall_ray).is_empty(), area_name + " wall reaches the soffit")
	for roof: StaticBody3D in area.find_children("*Ceiling", "StaticBody3D"):
		var mesh := roof.get_node_or_null("Visual") as MeshInstance3D
		check(mesh != null and mesh.get_aabb().size.x > 2.0 and mesh.get_aabb().size.z > 2.0,
			str(roof.name) + " retains its rendered footprint after the headless bake")
		check(mesh != null and mesh.mesh.surface_get_material(0).resource_path == STATION + "ceiling_panel.tres",
			str(roof.name) + " uses the shared ceiling panel")
	check_ceilings(space, area_name)
	check_finishes(area, area_name)
	check_overhead(area, area_name)
	for opening: Vector3 in DOORWAYS[area_name]:
		var along := Vector3.RIGHT if opening.x != 0.0 else Vector3.BACK
		check_passage(space, opening - along * 1.2, opening + along * 1.2, "%s doorway at %s" % [area_name, opening])
	stop_looping_audio(area)
	root.remove_child(area)


func check_ceilings(space: PhysicsDirectSpaceState3D, area_name: String) -> void:
	for probe: Array in CEILING_PROBES[area_name]:
		var point: Vector3 = probe[0]
		var ceiling_ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5, point + Vector3.UP * 3.6, 1)
		var ceiling := space.intersect_ray(ceiling_ray)
		check(not ceiling.is_empty() and is_equal_approx(ceiling.position.y, probe[1]),
			"%s blocks an upward camera ray at the %.2f m soffit over %s (hit %s)" % [
				area_name, probe[1], point, ceiling.get("position", "nothing")])


## Every wall run instances the shared bay and keeps its finishes, band heights
## and UV density. No mesh in the family may carry a local material override.
func check_finishes(area: Node3D, area_name: String) -> void:
	var bays := 0
	var openings := 0
	for node: Node in area.find_children("*", "Node3D", true, false):
		if node.scene_file_path == STATION + "wall_bay.tscn":
			bays += 1
		elif node.scene_file_path == STATION + "wall_opening.tscn":
			openings += 1
		else:
			continue
		var bay := node as Node3D
		check(is_equal_approx(bay.scale.y, 1.0) and is_zero_approx(bay.global_position.y),
			"%s %s keeps its height and sits on the local floor" % [area_name, bay.get_path()])
		for mesh: MeshInstance3D in bay.find_children("*", "MeshInstance3D", true, false):
			check(mesh.material_override == null and mesh.get_surface_override_material(0) == null,
				"%s %s has no local finish override" % [area_name, mesh.name])
	check(bays >= 8 and openings >= 1, "%s builds walls from the shared family (%d bays, %d openings)" % [
		area_name, bays, openings])


func check_wall_family() -> void:
	var bay: Node3D = load(STATION + "wall_bay.tscn").instantiate()
	for part: String in BAND_LIMITS:
		var mesh := bay.get_node(part) as MeshInstance3D
		var bounds := mesh.transform * mesh.get_aabb()
		var limits: Vector2 = BAND_LIMITS[part]
		check(is_equal_approx(bounds.position.y, limits.x) and is_equal_approx(bounds.end.y, limits.y),
			"Wall bay %s spans %.2f-%.2f m from the floor" % [part, limits.x, limits.y])
		check(is_equal_approx(bounds.size.x, 2.0), "Wall bay %s uses the 2.00 m bay" % part)
	var expected := {"Skirting": "steel_painted", "Band": "wash_band", "Upper": "clinical_wall"}
	for part: String in expected:
		var material := (bay.get_node(part) as MeshInstance3D).mesh.surface_get_material(0)
		check(material.resource_path == STATION + expected[part] + ".tres", "Wall bay %s uses %s" % [part, expected[part]])
		check(material is StandardMaterial3D and (material as StandardMaterial3D).uv1_world_triplanar
			or expected[part] == "steel_painted", "Wall bay %s keeps world-space texture density" % part)
	bay.free()
	var opening: Node3D = load(STATION + "wall_opening.tscn").instantiate()
	var head := opening.get_node("Head") as MeshInstance3D
	check(is_equal_approx((head.transform * head.get_aabb()).position.y, DOOR_HEAD), "Opening head sits at 2.40 m")
	check(head.mesh.surface_get_material(0).resource_path == STATION + "industrial_blue.tres",
		"Openings share the industrial blue frame")
	opening.free()


## Nothing visible hangs below 2.30 m over the main path.
func check_overhead(area: Node3D, area_name: String) -> void:
	for geometry: GeometryInstance3D in area.find_children("*", "GeometryInstance3D", true, false):
		if not geometry.is_visible_in_tree() or geometry is Label3D:
			continue
		var bounds := geometry.global_transform * geometry.get_aabb()
		if bounds.end.y < OVERHEAD_CLEARANCE or bounds.position.y < 1.0:
			continue
		for lane: Rect2 in MAIN_PATH[area_name]:
			var footprint := Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)
			check(not lane.intersects(footprint) or bounds.position.y >= OVERHEAD_CLEARANCE - 0.001,
				"%s %s keeps %.2f m over the main path (lowest %.2f m)" % [
					area_name, geometry.get_path(), OVERHEAD_CLEARANCE, bounds.position.y])


## The inherited maintenance room is generated in the same family as the areas.
func check_maintenance_shell() -> void:
	var dressing: Node3D = load(AREAS + "maintenance_dressing.tscn").instantiate()
	var finish := dressing.get_node_or_null("Shell/InheritedWallFinish")
	check(finish != null and finish.get_child_count() == 3, "Maintenance finishes the three inherited walls")
	root.add_child(dressing)
	await physics_frame
	await physics_frame
	var space := root.world_3d.direct_space_state
	check_ceilings(space, "maintenance_dressing")
	check_finishes(dressing, "maintenance_dressing")
	check_overhead(dressing, "maintenance_dressing")
	var airlock := PhysicsRayQueryParameters3D.create(Vector3(0, 2.2, 10.0), Vector3(0, 2.2, 11.6), 1)
	check(space.intersect_ray(airlock).is_empty(), "Maintenance airlock keeps its door bore below the 2.40 m head")
	airlock.from = Vector3(0, 2.5, 10.0)
	airlock.to = Vector3(0, 2.5, 11.6)
	check(not space.intersect_ray(airlock).is_empty(), "Maintenance airlock header closes the wall above the door")
	stop_looping_audio(dressing)
	root.remove_child(dressing)
	dressing.free()


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
		stop_looping_audio(adjoining)
		root.remove_child(adjoining)
		adjoining.transform = Transform3D.IDENTITY
	stop_looping_audio(corridor)
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
		label + " fits a 0.9 m radius, 2.3 m tall capsule")


func stop_looping_audio(area: Node3D) -> void:
	for sound: AudioStreamPlayer3D in area.find_children("*", "AudioStreamPlayer3D", true, false):
		sound.stop()
