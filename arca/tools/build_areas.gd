extends SceneTree
## Deterministically generate the mission areas and maintenance dressing.
## Run: godot --headless --path . -s res://arca/tools/build_areas.gd
##
## Each area's local origin is at floor level on the entry plane, with the area
## extending toward +Z. Attach_Office and Attach_Lift mark the outer faces of
## the corridor's walls so the adjoining floors and doorways line up.
##
## All four spaces share one wall family from arca/assets/environment/station/:
## steel skirting 0.00-0.10 m, washable band 0.10-1.10 m and clinical white
## above, measured from the local finished floor. Rooms have a 2.65 m clear
## height and the security corridor 2.50 m. Two raised 3.10 m bays keep the
## authored raptor leaps clear of the soffit. Route openings stay 3.0 m wide for
## the predators' navigation and the existing door leaves, with a 2.40 m head.

const OUT_DIR: String = "res://arca/areas/"
const KIT: String = "res://arca/assets/environment/kit/"
const STATION: String = "res://arca/assets/environment/station/"
const ROOM_CEILING: float = 2.65
const CORRIDOR_CEILING: float = 2.50
const RAISED_CEILING: float = 3.10
## Wall collision reaches the highest soffit; the finish above a lower ceiling
## stays hidden in the plenum.
const WALL_HEIGHT: float = 3.10
const WALL: float = 0.5
const BAY: float = 2.0
const MODULE_DEPTH: float = 0.18
const DOOR_WIDTH: float = 3.0
const DOOR_HEIGHT: float = 2.40
## The maintenance airlock leaves the mission's 3.2 m sliding leaf in place.
const AIRLOCK_WIDTH: float = 3.2
const SHELL_THICKNESS: float = 0.4

var materials: Dictionary[String, StandardMaterial3D] = {}
var kit_meshes: Dictionary[String, ArrayMesh] = {}
var track_mesh: ArrayMesh


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	# Shared station finishes. Builder-local names map onto the palette.
	for pair: Array in [["floor_plate", "floor_resin"], ["wall_panel", "clinical_wall"],
			["frame", "industrial_blue"], ["service_blue", "industrial_blue"], ["pipe", "steel_painted"],
			["bare_steel", "steel_bare"],
			["gasket", "steel_painted"], ["steel", "steel_painted"], ["hazard_trim", "safety"],
			["oxidized_steel", "oxidation"], ["emergency_red", "emergency_alarm"],
			["mineral_liner", "clinical_wall"], ["wash_band", "wash_band"], ["ceramic", "ceramic"],
			["third_energy", "third_energy"], ["ceiling_panel", "ceiling_panel"],
			["light_emissive", "lamp_diffuser"]]:
		materials[pair[0]] = load(STATION + pair[1] + ".tres")
	for name: String in ["dark_glass", "indicator"]:
		materials[name] = load(KIT + name + ".tres")
	var module: Node3D = load(KIT + "console.tscn").instantiate()
	kit_meshes["console"] = (module.get_node("Visual") as MeshInstance3D).mesh
	module.free()
	materials["dried_blood"] = shell_material(Color(0.113, 0.039, 0.031), 0.0, 0.95)
	materials["track"] = shell_material(Color(0.097, 0.077, 0.057), 0.0, 0.97)
	materials["water"] = shell_material(Color(0.077, 0.125, 0.124), 0.12, 0.21)
	materials["damp"] = shell_material(Color(0.36, 0.36, 0.31, 0.55), 0.0, 0.32)
	materials["damp"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials["inspection_glass"] = shell_material(Color(0.31, 0.41, 0.41, 0.38), 0.1, 0.38)
	materials["inspection_glass"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials["paper"] = shell_material(Color(0.68, 0.61, 0.44), 0.0, 0.92)
	track_mesh = floor_mark(PackedVector2Array([
		Vector2(-0.027, -0.17), Vector2(0.026, -0.15), Vector2(0.041, -0.066),
		Vector2(0.127, -0.09), Vector2(0.092, -0.015), Vector2(0.048, 0.016),
		Vector2(0.024, 0.13), Vector2(-0.007, 0.159), Vector2(-0.025, 0.028),
		Vector2(-0.082, 0.04), Vector2(-0.13, 0.008), Vector2(-0.062, -0.042),
	]), materials["track"])
	var ok: bool = save(build_maintenance_dressing(), "maintenance_dressing")
	ok = save(build_security_corridor(), "security_corridor") and ok
	ok = save(build_control_office(), "control_office") and ok
	ok = save(build_exit_lift(), "exit_lift") and ok
	print("AREAS BUILD: ", "ok" if ok else "FAILED")
	quit(0 if ok else 1)


func shell_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func save(root: Node3D, file: String) -> bool:
	_own(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Cannot pack " + file)
		root.free()
		return false
	var result := ResourceSaver.save(packed, OUT_DIR + file + ".tscn")
	root.free()
	if result != OK:
		push_error("Cannot save %s: %s" % [file, error_string(result)])
	return result == OK


func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		# Instanced kit scenes keep their own internals.
		if child.scene_file_path.is_empty():
			_own(child, owner_node)


# --- primitives ---------------------------------------------------------------

func solid(parent: Node3D, node_name: String, size: Vector3, center: Vector3, material: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	if node_name.begins_with("Desk"):
		dress_desk(body, size)
	elif not material.is_empty():
		visual(body, "Mesh", size, Vector3.ZERO, material)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func dress_desk(body: StaticBody3D, size: Vector3) -> void:
	var scale := Vector3(size.x / 1.5, size.y / 1.5, size.z / 0.5)
	var part := MeshInstance3D.new()
	part.name = "Mesh"
	part.mesh = kit_meshes["console"]
	part.transform = Transform3D(Basis.from_scale(scale), Vector3.DOWN * size.y * 0.5)
	body.add_child(part)


func visual(parent: Node3D, node_name: String, size: Vector3, center: Vector3, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = center
	var box := BoxMesh.new()
	box.size = size
	box.material = materials[material]
	mesh.mesh = box
	parent.add_child(mesh)
	return mesh


## Instance the shared wall bay along a run. Standard bays are 2.00 m; the two
## end bays share the remainder so the run fits the existing footprint. Bays
## scale only in length and depth. World triplanar finishes keep their density.
func wall_finish(parent: Node3D, node_name: String, base: Vector3, length: float,
		thickness: float, along_z: bool) -> Node3D:
	var run_node := group(parent, node_name)
	run_node.position = base
	var widths: Array[float] = []
	var full := floori(length / BAY + 0.001)
	var remainder := length - full * BAY
	if full == 0:
		widths.append(length)
	elif remainder < 0.01:
		for index: int in full:
			widths.append(BAY)
	else:
		var end_bay := (remainder + BAY) * 0.5
		widths.append(end_bay)
		for index: int in full - 1:
			widths.append(BAY)
		widths.append(end_bay)
	var cursor := -length * 0.5
	for index: int in widths.size():
		var bay := kit(run_node, "wall_bay", "Bay%d" % index, Vector3.ZERO, 0.0, STATION)
		var center := cursor + widths[index] * 0.5
		bay.position = Vector3(0, 0, center) if along_z else Vector3(center, 0, 0)
		bay.rotation.y = PI * 0.5 if along_z else 0.0
		bay.scale = Vector3(widths[index] / BAY, 1, thickness / MODULE_DEPTH)
		cursor += widths[index]
	return run_node


## Wall along Z at x, spanning z0..z1.
func wall_z(parent: Node3D, node_name: String, x: float, z0: float, z1: float, thickness: float = WALL) -> void:
	var body := solid(parent, node_name, Vector3(thickness, WALL_HEIGHT, z1 - z0),
		Vector3(x, WALL_HEIGHT * 0.5, (z0 + z1) * 0.5), "")
	wall_finish(body, "Finish", Vector3.DOWN * WALL_HEIGHT * 0.5, z1 - z0, thickness, true)


## Wall along X at z, spanning x0..x1.
func wall_x(parent: Node3D, node_name: String, z: float, x0: float, x1: float, thickness: float = WALL) -> void:
	var body := solid(parent, node_name, Vector3(x1 - x0, WALL_HEIGHT, thickness),
		Vector3((x0 + x1) * 0.5, WALL_HEIGHT * 0.5, z), "")
	wall_finish(body, "Finish", Vector3.DOWN * WALL_HEIGHT * 0.5, x1 - x0, thickness, false)


## Wall along X at z with a centred doorway at x = door_x.
func doorway_x(parent: Node3D, node_name: String, z: float, x0: float, x1: float, door_x: float,
		width: float = DOOR_WIDTH, thickness: float = WALL) -> void:
	var left: float = door_x - width * 0.5
	var right: float = door_x + width * 0.5
	if left > x0:
		wall_x(parent, node_name + "L", z, x0, left, thickness)
	if x1 > right:
		wall_x(parent, node_name + "R", z, right, x1, thickness)
	_lintel(parent, node_name, Vector3(width, WALL_HEIGHT - DOOR_HEIGHT, thickness), Vector3(door_x, 0, z))
	opening_frame(parent, node_name + "Frame", Vector3(door_x, 0, z), 0.0, width, thickness)


## Wall along Z at x with a centred doorway at z = door_z.
func doorway_z(parent: Node3D, node_name: String, x: float, z0: float, z1: float, door_z: float) -> void:
	var near: float = door_z - DOOR_WIDTH * 0.5
	var far: float = door_z + DOOR_WIDTH * 0.5
	if near > z0:
		wall_z(parent, node_name + "Near", x, z0, near)
	if z1 > far:
		wall_z(parent, node_name + "Far", x, far, z1)
	_lintel(parent, node_name, Vector3(WALL, WALL_HEIGHT - DOOR_HEIGHT, DOOR_WIDTH), Vector3(x, 0, door_z))
	opening_frame(parent, node_name + "Frame", Vector3(x, 0, door_z), 90.0, DOOR_WIDTH, WALL)


func opening_frame(parent: Node3D, node_name: String, base: Vector3, yaw: float, width: float,
		thickness: float) -> Node3D:
	var frame := kit(parent, "wall_opening", node_name, base, yaw, STATION)
	frame.scale = Vector3(width / DOOR_WIDTH, 1, thickness / MODULE_DEPTH)
	return frame


## Collision-only header. The opening frame supplies the visible infill.
func _lintel(parent: Node3D, node_name: String, size: Vector3, base: Vector3) -> void:
	solid(parent, node_name + "Lintel", size, Vector3(base.x, DOOR_HEIGHT + size.y * 0.5, base.z), "")


## Continuous technical resin floor; one opaque slab per footprint.
func floor_slab(parent: Node3D, node_name: String, x0: float, x1: float, z0: float, z1: float) -> void:
	solid(parent, node_name, Vector3(x1 - x0, 0.6, z1 - z0), Vector3((x0 + x1) * 0.5, -0.3, (z0 + z1) * 0.5),
		"floor_plate")


## External corner guard and internal corner cove of the wall family.
func corner(parent: Node3D, node_name: String, point: Vector3, external: bool = true) -> void:
	kit(parent, "wall_corner" if external else "wall_corner_joint", node_name, point, 0.0, STATION)


func kit(parent: Node3D, piece: String, node_name: String, position: Vector3, yaw_degrees: float = 0.0,
		folder: String = KIT) -> Node3D:
	var instance: Node3D = load(folder + piece + ".tscn").instantiate()
	instance.name = node_name
	instance.position = position
	instance.rotation.y = deg_to_rad(yaw_degrees)
	parent.add_child(instance)
	return instance


func lamp(parent: Node3D, node_name: String, position: Vector3, color: Color, energy: float, light_range: float, shadow: bool = false) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = shadow
	parent.add_child(light)


func sign_label(parent: Node3D, node_name: String, text: String, position: Vector3, yaw_degrees: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = position
	label.rotation.y = deg_to_rad(yaw_degrees)
	label.font_size = 44
	label.pixel_size = 0.007
	label.modulate = color
	label.double_sided = false
	label.outline_size = 3
	label.outline_modulate = Color(0.02, 0.03, 0.04)
	parent.add_child(label)
	return label


func marker(parent: Node3D, node_name: String, position: Vector3, yaw_degrees: float = 0.0) -> Marker3D:
	var point := Marker3D.new()
	point.name = node_name
	point.position = position
	point.rotation.y = deg_to_rad(yaw_degrees)
	parent.add_child(point)
	return point


func group(parent: Node3D, node_name: String) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	parent.add_child(node)
	return node


# --- areas -------------------------------------------------------------------

## Normal lamps are neutral white. Red is reserved for active alarms.
const NEUTRAL := Color(1.0, 0.97, 0.92)
const COOL := Color(0.62, 0.8, 1.0)
const ALARM := Color(1.0, 0.25, 0.2)
const SIGN_TEXT := Color(0.88, 0.86, 0.72)
## The raised bay keeps the marked crate leap and the raptor standing on the
## crate clear of the 2.50 m corridor soffit.
const CRATE_BAY := Vector2(16.5, 22.5)


## 4 m wide, 30 m long corridor with a left recess leading to the office
## and a far doorway leading to the lift hall.
func build_security_corridor() -> Node3D:
	var root := Node3D.new()
	root.name = "SecurityCorridor"
	var shell := group(root, "Shell")
	floor_slab(shell, "Floor", -2.5, 2.5, 0.0, 30.5)
	floor_slab(shell, "RecessFloor", -5.5, -2.5, 8.0, 14.0)
	wall_z(shell, "WallLeftNear", -2.25, 0.0, 8.0)
	wall_z(shell, "WallLeftFar", -2.25, 14.0, 30.5)
	doorway_z(shell, "RecessBack", -5.25, 7.5, 14.5, 11.0)
	wall_x(shell, "RecessNear", 8.0 - WALL * 0.5, -5.5, -2.0)
	wall_x(shell, "RecessFar", 14.0 + WALL * 0.5, -5.5, -2.0)
	wall_z(shell, "WallRight", 2.25, 0.0, 30.5)
	ceiling(shell, "MainCeiling", Rect2(-2.5, 0, 5, CRATE_BAY.x), CORRIDOR_CEILING)
	ceiling(shell, "CrateBayCeiling", Rect2(-2.5, CRATE_BAY.x, 5, CRATE_BAY.y - CRATE_BAY.x), RAISED_CEILING)
	ceiling(shell, "FarCeiling", Rect2(-2.5, CRATE_BAY.y, 5, 30.5 - CRATE_BAY.y), CORRIDOR_CEILING)
	ceiling(shell, "RecessCeiling", Rect2(-5.5, 8, 3, 6), CORRIDOR_CEILING)
	for z: float in [CRATE_BAY.x, CRATE_BAY.y]:
		soffit_step(shell, "SoffitStep%d" % roundi(z * 10), Vector3(0, 0, z), 4.0, false,
			CORRIDOR_CEILING, RAISED_CEILING)
	for x: float in [-2.0, 2.0]:
		upstand(shell, "BayUpstand%d" % roundi(x * 10), Vector3(x - signf(x) * 0.005, 0, 19.5),
			CRATE_BAY.y - CRATE_BAY.x, true, CORRIDOR_CEILING, RAISED_CEILING)
	doorway_x(shell, "WallEntry", 0.25, -2.5, 2.5, 0.0)
	doorway_x(shell, "WallEnd", 30.25, -2.5, 2.5, 0.0)
	for point: Vector3 in [Vector3(-2.0, 0, 8.0), Vector3(-2.0, 0, 14.0)]:
		corner(shell, "RecessCorner%d" % roundi(point.z * 10), point)
	for point: Vector3 in [Vector3(-5.0, 0, 8.0), Vector3(-5.0, 0, 14.0)]:
		corner(shell, "RecessCove%d" % roundi(point.z * 10), point, false)
	var dressing := group(root, "Dressing")
	corridor_services(dressing)
	for z: float in [3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 24.0, 27.0]:
		var height := RAISED_CEILING if z > CRATE_BAY.x and z < CRATE_BAY.y else CORRIDOR_CEILING
		luminaire(dressing, Vector3(0, height, z), 90.0)
	luminaire(dressing, Vector3(-3.9, CORRIDOR_CEILING, 11.0), 90.0)
	kit(dressing, "crate", "CrateEntry", Vector3(1.2, 0.0, 5.0), 90.0)
	kit(dressing, "crate", "CrateMid", Vector3(-1.4, 0.0, 20.5), 90.0)
	kit(dressing, "crate", "CrateEnd", Vector3(1.4, 0.0, 25.0), 90.0)
	kit(dressing, "vent_grille", "RecessVent", Vector3(-4.95, 0.62, 13.35), 90.0)
	var lights := group(root, "Lights")
	lamp(lights, "LightEntry", Vector3(0, 2.28, 4.5), NEUTRAL, 1.05, 7.0)
	lamp(lights, "LightRecess", Vector3(-3.9, 2.25, 11.0), NEUTRAL, 0.85, 5.5)
	lamp(lights, "LightMiddle", Vector3(0, 2.80, 19.5), NEUTRAL, 1.0, 7.5, true)
	var breaker_light := group(dressing, "LiftAlarmFixture")
	breaker_light.position = Vector3(-1.78, 2.18, 29.93)
	breaker_light.rotation.y = PI
	fault_beacon(breaker_light)
	lamp(lights, "LightLift", Vector3(-0.6, 2.2, 29.4), ALARM, 1.1, 6.5)
	animate_loop(root, "LiftAlarmCycle", NodePath("Lights/LightLift:light_energy"),
		[0.0, 2.8, 2.89, 3.02, 3.12, 4.6], [1.1, 1.1, 0.42, 1.1, 0.78, 1.1])
	var signs := group(root, "Signs")
	station_sign(signs, "SignEntry", "B-02   /   SECURITY", Vector3(1.957, 1.75, 2.0), -90, 2.5)
	station_sign(signs, "SignOffice", "B-03   /   CONTROL OFFICE", Vector3(-1.957, 1.75, 6.4), 90, 3.3)
	station_sign(signs, "SignLift", "B-04   /   EXIT LIFT", Vector3(1.957, 1.75, 28.2), -90, 2.55)
	dress_security(dressing)
	var markers := group(root, "Markers")
	marker(markers, "Spawn_SleepingRaptor", Vector3(-3.75, 0.05, 9.35), 157.5)
	marker(markers, "Spawn_CorridorAmbush", Vector3(0.0, 0.05, 27.5), 180.0)
	marker(markers, "Pickup_Ammo", Vector3(1.55, 0.1, 21.5))
	marker(markers, "Note_1", Vector3(1.2, 1.05, 5.0))
	marker(markers, "Door_ToOffice", Vector3(-5.25, 0.0, 11.0), -90.0)
	marker(markers, "Door_ToLift", Vector3(0.0, 0.0, 29.75))
	marker(markers, "Attach_Office", Vector3(-5.5, 0.0, 11.0), -90.0)
	marker(markers, "Attach_Lift", Vector3(0.0, 0.0, 30.5))
	var jump := marker(markers, "CrateJump", Vector3(-1.35, 0, 18.0))
	jump.add_to_group("arca_raptor_jump", true)
	marker(jump, "Landing", Vector3(0, 1.04, 2.5))
	return root


## 12 x 10 m office entered from the corridor recess.
func build_control_office() -> Node3D:
	var root := Node3D.new()
	root.name = "ControlOffice"
	var shell := group(root, "Shell")
	floor_slab(shell, "Floor", -6.5, 6.5, 0.0, 10.5)
	wall_z(shell, "WallLeft", -6.25, 0.0, 10.5)
	wall_z(shell, "WallRight", 6.25, 0.0, 10.5)
	wall_x(shell, "WallBack", 10.25, -6.5, 6.5)
	doorway_x(shell, "WallFront", 0.25, -6.5, 6.5, 0.0)
	ceiling(shell, "OfficeCeiling", Rect2(-6.5, 0, 13, 10.5), ROOM_CEILING)
	for point: Vector3 in [Vector3(-6.0, 0, 0.5), Vector3(6.0, 0, 0.5), Vector3(-6.0, 0, 10.0), Vector3(6.0, 0, 10.0)]:
		corner(shell, "Cove_%d_%d" % [roundi(point.x), roundi(point.z)], point, false)
	solid(shell, "DeskLeft", Vector3(2.2, 0.8, 1.0), Vector3(-3.4, 0.4, 4.0), "frame")
	solid(shell, "DeskRight", Vector3(2.2, 0.8, 1.0), Vector3(2.6, 0.4, 4.0), "frame")
	solid(shell, "DeskCorner", Vector3(1.6, 0.8, 0.9), Vector3(4.7, 0.4, 8.6), "frame")
	var screen := solid(shell, "GlassScreen", Vector3(0.1, 2.2, 3.2),
		Vector3(3.2, 1.1, 7.9), "inspection_glass")
	screen.get_node("Mesh").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual(screen, "KickPlate", Vector3(0.13, 0.10, 3.22), Vector3(0, -1.05, 0), "steel")
	for edge: float in [-1.58, 0, 1.58]:
		visual(screen, "Mullion%d" % roundi(edge * 100), Vector3(0.13, 2.20, 0.062),
			Vector3(0, 0, edge), "frame")
	visual(screen, "CapRail", Vector3(0.15, 0.065, 3.26), Vector3(0, 1.09, 0), "frame")
	solid(shell, "Cabinet", Vector3(0.6, 2.0, 2.4), Vector3(-5.85, 1.0, 6.5), "wash_band")
	var dressing := group(root, "Dressing")
	kit(dressing, "console", "ConsoleBackLeft", Vector3(-3.0, 0.0, 9.75), 180.0)
	kit(dressing, "console", "ConsoleBackMid", Vector3(-1.0, 0.0, 9.75), 180.0)
	kit(dressing, "vent_grille", "AirReturn", Vector3(5.95, 1.2, 5.5), -90.0)
	for location: Vector3 in [Vector3(0, 0, 2), Vector3(-2.5, 0, 5.5), Vector3(3.5, 0, 8.5),
			Vector3(-2.5, 0, 2), Vector3(3.5, 0, 5.5), Vector3(-2.5, 0, 8.5)]:
		luminaire(dressing, location + Vector3.UP * ROOM_CEILING)
	office_instruments(dressing)
	var lights := group(root, "Lights")
	lamp(lights, "LightEntry", Vector3(0, 2.38, 2.0), NEUTRAL, 0.95, 7.0)
	lamp(lights, "LightDesks", Vector3(-2.5, 2.38, 5.5), NEUTRAL, 1.0, 7.0, true)
	lamp(lights, "LightConsoles", Vector3(3.5, 2.38, 8.5), NEUTRAL, 0.9, 6.5)
	var signs := group(root, "Signs")
	station_sign(signs, "SignOffice", "B-03   /   HABITAT OPERATIONS", Vector3(-1.25, 2.47, 9.954), 180, 3.4, 0.24)
	dress_office(dressing)
	var markers := group(root, "Markers")
	marker(markers, "Pickup_Keycard", Vector3(4.7, 0.85, 8.6))
	marker(markers, "Pickup_Medkit", Vector3(-5.2, 0.1, 1.4))
	marker(markers, "Checkpoint", Vector3(-5.2, 0.0, 9.3), 180.0)
	marker(markers, "Note_2", Vector3(-3.4, 0.85, 4.0))
	marker(markers, "Spawn_Ambush", Vector3(5.0, 0.05, 5.5), -90.0)
	return root


## 14 x 14 m hall beyond the corridor's far doorway, with a lift alcove.
func build_exit_lift() -> Node3D:
	var root := Node3D.new()
	root.name = "ExitLift"
	var shell := group(root, "Shell")
	floor_slab(shell, "Floor", -7.5, 7.5, 0.0, 14.5)
	floor_slab(shell, "LiftFloor", -2.5, 2.5, 14.5, 18.0)
	doorway_x(shell, "WallFront", 0.25, -7.5, 7.5, 0.0)
	doorway_z(shell, "WallLeft", -7.25, 0.0, 14.5, 11.5)
	floor_slab(shell, "FreightGalleryFloor", -13.0, -7.5, 9.5, 14.5)
	wall_x(shell, "FreightGallerySouth", 9.75, -13.0, -7.5)
	wall_x(shell, "FreightGalleryNorth", 14.25, -13.0, -7.5)
	wall_z(shell, "FreightBulkhead", -12.75, 9.5, 14.5)
	wall_z(shell, "WallRight", 7.25, 0.0, 14.5)
	doorway_x(shell, "WallBack", 14.25, -7.5, 7.5, 0.0)
	wall_z(shell, "LiftLeft", -2.25, 14.5, 18.0)
	wall_z(shell, "LiftRight", 2.25, 14.5, 18.0)
	wall_x(shell, "LiftBack", 17.75, -2.5, 2.5)
	ceiling(shell, "HallCeiling", Rect2(-7.5, 0, 15, 14.5), ROOM_CEILING)
	ceiling(shell, "CabinCeiling", Rect2(-2.5, 14.5, 5, 3.5), ROOM_CEILING)
	ceiling(shell, "FreightCeiling", Rect2(-13, 9.5, 5.5, 5), ROOM_CEILING)
	for point: Vector3 in [Vector3(-7.0, 0, 0.5), Vector3(7.0, 0, 0.5), Vector3(-7.0, 0, 14.0),
			Vector3(7.0, 0, 14.0), Vector3(-2.0, 0, 17.5), Vector3(2.0, 0, 17.5),
			Vector3(-12.5, 0, 10.0), Vector3(-12.5, 0, 14.0)]:
		corner(shell, "Cove_%d_%d" % [roundi(point.x * 10), roundi(point.z * 10)], point, false)
	var dressing := group(root, "Dressing")
	for spot in [Vector3(-4, 0, 5), Vector3(4, 0, 5), Vector3(-4, 0, 10), Vector3(4, 0, 10)]:
		kit(dressing, "pillar", "Pillar_%d_%d" % [int(spot.x), int(spot.z)], spot)
	kit(dressing, "crate", "CoverLeft", Vector3(-2.2, 0.0, 7.5))
	kit(dressing, "crate", "CoverRight", Vector3(2.6, 0.0, 3.2), 90.0)
	kit(dressing, "console", "LiftConsole", Vector3(3.6, 0.0, 13.75), 180.0)
	for location: Vector3 in [Vector3(0, 0, 3), Vector3(0, 0, 6.6), Vector3(0, 0, 10.2),
			Vector3(-5.4, 0, 7.2), Vector3(5.4, 0, 7.2), Vector3(0, 0, 16.2), Vector3(-10.2, 0, 12.0)]:
		luminaire(dressing, location + Vector3.UP * ROOM_CEILING, 90.0)
	lift_systems(dressing)
	extractor(dressing)
	var lights := group(root, "Lights")
	lamp(lights, "LightHall", Vector3(0, 2.38, 6.6), NEUTRAL, 1.15, 9.5, true)
	lamp(lights, "LightLift", Vector3(0, 2.38, 16.2), NEUTRAL, 1.0, 5.5)
	lamp(lights, "LightAlarm", Vector3(-6.55, 2.15, 13.4), ALARM, 0.95, 6.0)
	lamp(lights, "FreightInspectionLight", Vector3(-10.2, 2.38, 12.0), NEUTRAL, 1.0, 5.0)
	var signs := group(root, "Signs")
	station_sign(signs, "SignLift", "B-04   /   EVACUATION LIFT", Vector3(-3.7, 1.75, 13.957), 180, 3.6)
	dress_freight(dressing)
	var markers := group(root, "Markers")
	marker(markers, "Lift_Panel", Vector3(3.6, 0.0, 13.2), 180.0)
	marker(markers, "Door_Lift", Vector3(0.0, 0.0, 13.75))
	marker(markers, "Exit_Zone", Vector3(0.0, 0.0, 16.3))
	marker(markers, "Spawn_FinalRaptor", Vector3(-9.35, 0.05, 11.5), -90.0)
	marker(markers, "Pickup_Ammo", Vector3(5.9, 0.1, 1.6))
	return root


# --- evidence and room-specific fixtures --------------------------------------

func floor_mark(outline: PackedVector2Array, material: Material) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	var triangles := Geometry2D.triangulate_polygon(outline)
	for index: int in triangles:
		var point := outline[index]
		surface.set_normal(Vector3.UP)
		surface.add_vertex(Vector3(point.x, 0, point.y))
	return surface.commit()


func stain(parent: Node3D, node_name: String, point: Vector3, radius: Vector2, material: String) -> MeshInstance3D:
	var outline := PackedVector2Array()
	for index: int in 13:
		var angle := TAU * float(index) / 13.0
		var edge := 0.79 + 0.16 * cos(angle * 4.0) + 0.09 * sin(angle * 7.0)
		outline.append(Vector2(cos(angle), sin(angle)) * radius * edge)
	var mark := MeshInstance3D.new()
	mark.name = node_name
	mark.mesh = floor_mark(outline, materials[material])
	mark.position = point
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mark)
	return mark


## A stain on a wall face. The mark lies in the local XY plane facing +Z.
func wall_stain(parent: Node3D, node_name: String, point: Vector3, yaw_degrees: float, radius: Vector2,
		material: String) -> void:
	var mark := stain(parent, node_name, point, radius, material)
	mark.rotation = Vector3(PI * 0.5, deg_to_rad(yaw_degrees), 0)


func tracks(parent: Node3D, start: Vector3, end: Vector3, count: int) -> void:
	var group_node := group(parent, "Trackway")
	var forward := (end - start).normalized()
	var side := Vector3.UP.cross(forward)
	var yaw := atan2(forward.x, forward.z)
	var variation: Array[float] = [0.89, 0.96, 0.83, 1.04]
	for index: int in count:
		var print_mesh := MeshInstance3D.new()
		print_mesh.name = "Print%d" % index
		print_mesh.mesh = track_mesh
		var lateral: float = (0.14 if index % 2 == 0 else -0.14)
		print_mesh.position = start.lerp(end, float(index) / (count - 1)) + side * lateral
		print_mesh.rotation.y = yaw + lateral
		print_mesh.scale = Vector3.ONE * variation[index % variation.size()]
		group_node.add_child(print_mesh)


func tubing(parent: Node3D, node_name: String, start: Vector3, end: Vector3, radius: float, material: String) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 12
	mesh.rings = 0
	mesh.material = materials[material]
	var segment := MeshInstance3D.new()
	segment.name = node_name
	segment.mesh = mesh
	var away := (end - start).normalized()
	segment.transform = Transform3D(Basis(Quaternion(Vector3.UP, away)), (start + end) * 0.5)
	parent.add_child(segment)
	return segment


## Short collar on a pipe run along the given axis.
func flange(parent: Node3D, node_name: String, center: Vector3, axis: Vector3, radius: float,
		material: String = "steel") -> void:
	tubing(parent, node_name, center - axis * 0.025, center + axis * 0.025, radius, material)


## Shell walls of the inherited maintenance room. The test-room walls keep
## their own collision and receive the station finish here. The mission-owned
## airlock, service corridor and hatch bay are generated with collision.
func maintenance_shell(root: Node3D) -> void:
	var shell := group(root, "Shell")
	var inherited := group(shell, "InheritedWallFinish")
	wall_finish(inherited, "WallBack", Vector3(0, 0, -14), 22.0, SHELL_THICKNESS, false)
	wall_finish(inherited, "WallLeft", Vector3(-11, 0, 0), 28.0, SHELL_THICKNESS, true)
	wall_finish(inherited, "WallRight", Vector3(11, 0, 0), 28.0, SHELL_THICKNESS, true)
	for z: float in [10.8, 14.0]:
		var label := "Airlock" if z < 12.0 else "Front"
		doorway_x(shell, label, z, -11.0, 11.0, 0.0, AIRLOCK_WIDTH, SHELL_THICKNESS)
	wall_z(shell, "ServicePartition", 5.8, -5.4, 10.8, SHELL_THICKNESS)
	wall_z(shell, "ServiceLining", 10.8, -5.4, 10.8, SHELL_THICKNESS)
	wall_x(shell, "AlcoveScreen", 6.0, 5.6, 8.4, SHELL_THICKNESS)
	# The service entrance is open between its yellow posts.
	var entrance := opening_frame(shell, "ServiceEntranceFrame", Vector3(8.3, 0, -5.4), 0.0, 4.6, SHELL_THICKNESS)
	for jamb: String in ["WestJamb", "EastJamb"]:
		entrance.get_node(jamb).free()
	# Live-cargo hatch bay. Its roof meets the room soffit and needs no finish.
	wall_x(shell, "HatchSideNear", 6.6, 2.2, 5.6, 0.3)
	wall_x(shell, "HatchSideFar", 10.5, 2.2, 5.6, 0.3)
	solid(shell, "HatchRoof", Vector3(3.0, 0.3, 4.2), Vector3(3.9, ROOM_CEILING + 0.15, 8.55), "")
	var header := solid(shell, "HatchHeader", Vector3(0.2, 0.4, 4.2), Vector3(1.95, 2.45, 8.55), "frame")
	visual(header, "HazardEdge", Vector3(0.21, 0.06, 4.2), Vector3(0, -0.17, 0), "hazard_trim")
	ceiling(shell, "MaintenanceCeiling", Rect2(-11, -9.6, 22, 23.8), ROOM_CEILING)
	ceiling(shell, "MaintenanceCeilingWest", Rect2(-11, -14, 4.4, 4.4), ROOM_CEILING)
	ceiling(shell, "MaintenanceCeilingEast", Rect2(-0.4, -14, 11.4, 4.4), ROOM_CEILING)
	# Raised over the diagnostic table so the authored table leap stays clear.
	ceiling(shell, "WorkstationBayCeiling", Rect2(-6.6, -14, 6.2, 4.4), RAISED_CEILING)
	soffit_step(shell, "BayStepNorth", Vector3(-3.5, 0, -9.6), 6.2, false, ROOM_CEILING, RAISED_CEILING)
	soffit_step(shell, "BayStepWest", Vector3(-6.6, 0, -11.8), 4.4, true, ROOM_CEILING, RAISED_CEILING)
	soffit_step(shell, "BayStepEast", Vector3(-0.4, 0, -11.8), 4.4, true, ROOM_CEILING, RAISED_CEILING)
	upstand(shell, "BayUpstandBack", Vector3(-3.5, 0, -13.795), 6.2, false, ROOM_CEILING, RAISED_CEILING)
	for point: Vector3 in [Vector3(-10.8, 0, -13.8), Vector3(10.8, 0, -13.8), Vector3(5.6, 0, -5.4),
			Vector3(6.0, 0, -5.4), Vector3(8.4, 0, 5.8), Vector3(8.4, 0, 6.2)]:
		var external := is_equal_approx(point.z, -5.4) or is_equal_approx(point.x, 8.4)
		corner(shell, ("Guard_%d_%d" if external else "Cove_%d_%d") % [roundi(point.x * 10), roundi(point.z * 10)],
			point, external)


func build_maintenance_dressing() -> Node3D:
	var root := Node3D.new()
	root.name = "MaintenanceDressing"
	maintenance_shell(root)
	var station := group(root, "TransferEquipment")
	for index: int in 3:
		var z: float = -7.2 + 2.3 * index
		var cabinet := solid(station, "Pump%d" % index, Vector3(0.58, 1.86, 1.52),
			Vector3(-10.51, 0.93, z), "frame")
		visual(cabinet, "Door", Vector3(0.08, 1.37, 1.27), Vector3(0.31, -0.1, 0), "wash_band")
		visual(cabinet, "Control", Vector3(0.055, 0.25, 0.60), Vector3(0.36, 0.52, 0), "gasket")
		visual(cabinet, "Pilot", Vector3(0.06, 0.035, 0.12), Vector3(0.39, 0.52, -0.16), "indicator")
		visual(cabinet, "Handle", Vector3(0.04, 0.22, 0.035), Vector3(0.365, -0.1, 0.5), "hazard_trim")
		tubing(station, "SupplyDrop%d" % index, Vector3(-10.1, 1.86, z),
			Vector3(-10.1, 2.30, z), 0.065, "pipe")
		flange(station, "DropFlange%d" % index, Vector3(-10.1, 2.02, z), Vector3.UP, 0.095)
	tubing(station, "SupplyManifold", Vector3(-10.1, 2.30, -8.2), Vector3(-10.1, 2.30, 5.6), 0.11, "pipe")
	tubing(station, "ReturnManifold", Vector3(-10.5, 2.50, -8.2), Vector3(-10.5, 2.50, 5.6), 0.08, "pipe")
	for index: int in 6:
		var z: float = -8.0 + 2.3 * index
		flange(station, "ManifoldFlange%d" % index, Vector3(-10.1, 2.30, z), Vector3.BACK, 0.15)
		visual(station, "ManifoldBracket%d" % index, Vector3(0.62, 0.05, 0.06), Vector3(-10.48, 2.16, z), "steel")
	# The weeping flange over the second pump leaves rust and a damp run.
	flange(station, "WeepingFlange", Vector3(-10.1, 2.30, -4.9), Vector3.BACK, 0.16, "oxidized_steel")
	wall_stain(station, "RustRun", Vector3(-10.785, 1.95, -4.9), 90, Vector2(0.09, 0.32), "oxidized_steel")
	stain(station, "PumpLeak", Vector3(-10.0, 0.012, -4.6), Vector2(0.62, 0.38), "water")
	var pump_label := sign_label(station, "PumpBankIdentification", "TRANSFER PUMPS",
		Vector3(-10.075, 1.51, -7.2), 90, Color(0.74, 0.84, 0.82))
	pump_label.pixel_size = 0.0032
	for location: Vector3 in [Vector3(-7, 0, -7), Vector3(7, 0, 5), Vector3(-6, 0, 8), Vector3(5, 0, -9),
			Vector3(-7, 0, 1), Vector3(0, 0, -5), Vector3(0, 0, 2), Vector3(8.3, 0, 1)]:
		luminaire(station, location + Vector3.UP * ROOM_CEILING, 90.0)
	luminaire(station, Vector3(-3.5, RAISED_CEILING, -11.8), 90.0)
	maintenance_services(station)
	# Existing cover remains the collision envelope for this work surface.
	visual(station, "Worktop", Vector3(2.5, 0.07, 1.42), Vector3(-3.8, 1.78, -3.0), "steel")
	visual(station, "OpenToolTray", Vector3(0.54, 0.09, 0.35), Vector3(-4.36, 1.865, -3.18), "gasket")
	visual(station, "WorkOrder", Vector3(0.27, 0.006, 0.19), Vector3(-3.14, 1.824, -2.86), "paper").rotation.y = 0.24
	for index: int in 4:
		visual(station, "Tool%d" % index, Vector3(0.021, 0.021, 0.19 - 0.018 * index),
			Vector3(-4.52 + 0.092 * index, 1.923, -3.18), "bare_steel").rotation.y = 0.17 * index - 0.23
	station_sign(station, "BenchTag", "TRANSFER DIAGNOSTICS", Vector3(-3.65, 1.75, -13.757), 0, 2.77)
	visual(station, "TestBenchTop", Vector3(2.29, 0.064, 1.48), Vector3(4, 1.782, 1.0), "steel")
	visual(station, "InsulatedCase", Vector3(0.53, 0.19, 0.32), Vector3(4.59, 1.906, 1.22), "gasket")
	visual(station, "CaseLatch", Vector3(0.075, 0.055, 0.03), Vector3(4.59, 1.903, 1.048), "pipe")
	add_maintenance_workstation(root)
	var evidence := group(root, "TransferLockEvidence")
	for index: int in 4:
		var point := Vector3(1.842, 2.58 - index * 0.085, 7.1 + index * 0.115)
		visual(evidence, "FrameGouge%d" % index, Vector3(0.008, 0.019, 0.48 - 0.056 * index),
			point, "pipe").rotation.x = -0.46
	visual(evidence, "WaterTrough", Vector3(0.57, 0.22, 0.94),
		Vector3(4.91, 0.11, 9.86), "oxidized_steel")
	visual(evidence, "TroughWater", Vector3(0.44, 0.02, 0.8),
		Vector3(4.91, 0.225, 9.86), "water")
	visual(evidence, "TornGuide", Vector3(0.09, 0.09, 2.2),
		Vector3(1.75, 0.073, 9.9), "oxidized_steel").rotation.y = -0.20
	stain(evidence, "WipedSmear", Vector3(1.85, 0.014, 8.18), Vector2(0.84, 0.27), "dried_blood")
	stain(evidence, "DrySpot", Vector3(0.69, 0.015, 8.31), Vector2(0.23, 0.14), "dried_blood")
	return root


func add_maintenance_workstation(root: Node3D) -> void:
	var work := group(root, "DiagnosticWorkstation")
	var desk := solid(work, "ServiceTable", Vector3(2.05, 0.86, 0.94),
		Vector3(-3.55, 0.43, -11.8), "frame")
	desk.get_node("Mesh").free()
	visual(desk, "BenchSurface", Vector3(2.05, 0.095, 0.94), Vector3(0, 0.3825, 0), "frame")
	for side: float in [-0.86, 0.86]:
		visual(desk, "Leg%d" % roundi(side * 100), Vector3(0.12, 0.77, 0.81),
			Vector3(side, -0.045, 0), "steel")
	var display := kit(work, "instrument_display", "DiagnosticCRT", Vector3(-4.12, 1.086, -12.04))
	display.scale = Vector3(0.57, 0.55, 2.8)
	visual(work, "PowerLamp", Vector3(0.028, 0.026, 0.02), Vector3(-3.95, 0.92, -11.833), "indicator")
	visual(work, "ServiceMap", Vector3(0.46, 0.007, 0.31), Vector3(-3.52, 0.866, -11.93), "paper").rotation.y = 0.21
	for index in 4:
		visual(work, "MapRoute%d" % index, Vector3(0.23 - index * 0.025, 0.003, 0.015),
			Vector3(-3.54, 0.872, -12.005 + index * 0.041), "track").rotation.y = 0.21
	var chair := group(work, "KnockedChair")
	chair.position = Vector3(-4.23, 0.32, -10.92)
	chair.rotation = Vector3(0.39, -0.36, -1.21)
	visual(chair, "Seat", Vector3(0.40, 0.073, 0.37), Vector3(0, 0.11, 0), "gasket")
	visual(chair, "Back", Vector3(0.39, 0.33, 0.072), Vector3(0, 0.34, -0.18), "frame")
	var feet: Array[Vector2] = [Vector2(-0.15, -0.14), Vector2(0.15, -0.14), Vector2(-0.15, 0.14), Vector2(0.15, 0.14)]
	for index: int in feet.size():
		var leg := feet[index]
		visual(chair, "Leg%d" % index, Vector3(0.046, 0.36, 0.052), Vector3(leg.x, -0.09, leg.y), "pipe")
	var shelf := group(work, "SpareParts")
	shelf.position = Vector3(-10.55, 0, 0.6)
	for tier in 3:
		var y: float = 0.46 + tier * 0.53
		visual(shelf, "Tray%d" % tier, Vector3(0.65, 0.065, 1.75), Vector3(0, y, 0), "wash_band")
		visual(shelf, "PartsBin%d" % tier, Vector3(0.43, 0.24, 0.52), Vector3(-0.04, y + 0.15, 0.39 - tier * 0.36),
			"hazard_trim" if tier == 0 else "gasket")
	for end: float in [-0.83, 0.83]:
		visual(shelf, "Upright%d" % roundi(end * 100), Vector3(0.55, 1.83, 0.076), Vector3(0, 0.915, end), "steel")
	var takeoff := marker(work, "TableJump", Vector3(-1.08, 0, -11.8))
	takeoff.add_to_group("arca_raptor_jump", true)
	marker(takeoff, "Landing", Vector3(-2.47, 0.905, 0))
	var descent := marker(work, "TableDescent", Vector3(-3.55, 0.87, -11.8))
	descent.add_to_group("arca_raptor_jump", true)
	marker(descent, "Landing", Vector3(-2.21, -0.825, 0))


## The lowered corridor carries services beside the passage: wall trunking on
## the right and one supported pipe on the left. Nothing on the route hangs
## below 2.30 m.
func corridor_services(parent: Node3D) -> void:
	var services := group(parent, "WallServices")
	visual(services, "CableTrunking", Vector3(0.07, 0.11, 29.5), Vector3(1.965, 2.22, 15.25), "steel")
	visual(services, "TrunkingDrop", Vector3(0.07, 1.0, 0.11), Vector3(1.965, 1.67, 15.25 + 0.75), "steel")
	tubing(services, "ServicePipe", Vector3(-1.87, 2.37, 0.5), Vector3(-1.87, 2.37, 30.0), 0.055, "pipe")
	for z: float in [0.5, 30.0]:
		flange(services, "WallCollar%d" % roundi(z * 10), Vector3(-1.87, 2.37, z + (0.03 if z < 1 else -0.03)),
			Vector3.BACK, 0.1)
	for index: int in 15:
		var z: float = 1.5 + 2.0 * index
		if z > 8.0 and z < 14.0:
			continue # The pipe spans the recess mouth without a wall bracket.
		visual(services, "PipeBracket%d" % index, Vector3(0.16, 0.03, 0.05), Vector3(-1.93, 2.30, z), "steel")
	for z: float in [6.0, 14.5, 23.0]:
		flange(services, "PipeFlange%d" % roundi(z * 10), Vector3(-1.87, 2.37, z), Vector3.BACK, 0.085)


func dress_security(parent: Node3D) -> void:
	var evidence := group(parent, "CondensateAndTracks")
	visual(evidence, "CondensateHousing", Vector3(0.20, 0.85, 0.78), Vector3(-4.90, 0.49, 8.61), "frame")
	tubing(evidence, "CondensateFeed", Vector3(-4.87, CORRIDOR_CEILING, 8.55), Vector3(-4.87, 0.89, 8.55), 0.065, "pipe")
	flange(evidence, "FeedFlange", Vector3(-4.87, 1.62, 8.55), Vector3.UP, 0.09, "oxidized_steel")
	tubing(evidence, "DrainSpout", Vector3(-4.86, 0.70, 8.55), Vector3(-4.55, 0.58, 8.55), 0.043, "pipe")
	stain(evidence, "WaterAtDrain", Vector3(-4.53, 0.022, 8.64), Vector2(0.72, 0.44), "water")
	wall_stain(evidence, "DampWall", Vector3(-4.995, 1.05, 8.55), 90, Vector2(0.24, 0.62), "damp")
	wall_stain(evidence, "RustUnderFlange", Vector3(-4.994, 1.38, 8.8), 90, Vector2(0.06, 0.22), "oxidized_steel")
	condensate_evidence(parent, evidence)
	visual(evidence, "FeedTray", Vector3(0.47, 0.085, 0.32), Vector3(-4.67, 0.06, 9.31), "oxidized_steel").rotation.y = -0.49
	for index: int in 3:
		visual(evidence, "FeedWrapper%d" % index, Vector3(0.17, 0.014, 0.14),
			Vector3(-4.53 + index * 0.13, 0.022, 9.43 + index * 0.105), "paper").rotation.y = index * 0.68
	tracks(evidence, Vector3(0.36, 0.026, 28.25), Vector3(-0.33, 0.026, 24.5), 6)
	var alcove := group(evidence, "AlcoveTracks")
	tracks(alcove, Vector3(-0.4, 0.026, 12.8), Vector3(-3.75, 0.026, 9.45), 7)
	# Emergency storage is recessed into the side of the circulation path.
	var locker := solid(parent, "RescueLocker", Vector3(0.44, 1.36, 1.18),
		Vector3(1.77, 0.68, 15.25), "wash_band")
	visual(locker, "DoorPanel", Vector3(0.034, 1.12, 0.99), Vector3(-0.236, 0, 0), "frame")
	visual(locker, "Latch", Vector3(0.043, 0.15, 0.065), Vector3(-0.264, 0.12, 0.39), "hazard_trim")
	sign_label(parent, "RescueLockerLabel", "EMERGENCY\nRESPONSE", Vector3(1.503, 1.08, 15.25), -90, COOL)


func dress_office(parent: Node3D) -> void:
	var desk := group(parent, "EvacuationRecords")
	for index: int in 3:
		var x: float = -4.2 + index * 1.43
		visual(desk, "FileBay%d" % index, Vector3(1.26, 0.62, 0.29), Vector3(x, 1.94, 9.84), "wash_band")
		for slot: int in 3:
			visual(desk, "File%d_%d" % [index, slot], Vector3(0.33, 0.36, 0.17),
				Vector3(x - 0.38 + slot * 0.38, 1.92, 9.65), "paper" if slot == 1 else "frame")
	var board := visual(desk, "TransferBoard", Vector3(2.12, 0.86, 0.065), Vector3(0.33, 1.90, 9.95), "gasket")
	visual(board, "Line", Vector3(1.86, 0.014, 0.012), Vector3(0, 0.11, -0.037), "pipe")
	var board_text := sign_label(desk, "TransferStatus", "FREIGHT STATUS\n01   LIVE CARGO\n02   HOLD / LOCKDOWN",
		Vector3(0.33, 1.93, 9.905), 180, Color(0.69, 0.86, 0.79))
	board_text.pixel_size = 0.0036
	var display := kit(desk, "instrument_display", "HabitatMonitor", Vector3(2.79, 1.15, 4.18), 180)
	display.scale = Vector3.ONE * 0.78
	visual(desk, "Keyboard", Vector3(0.42, 0.026, 0.16), Vector3(2.79, 0.826, 3.86), "gasket")
	for index: int in 4:
		visual(desk, "LooseReport%d" % index, Vector3(0.21, 0.006, 0.30),
			Vector3(3.05 + 0.14 * index, 0.818 + 0.007 * index, 4.05 - 0.12 * index),
			"paper").rotation.y = 0.9 * index
	visual(desk, "TippedTray", Vector3(0.32, 0.052, 0.26), Vector3(4.98, 0.12, 9.37), "oxidized_steel").rotation.z = 0.63
	for page: int in 3:
		visual(desk, "DroppedManifest%d" % page, Vector3(0.22, 0.006, 0.30),
			Vector3(-5.08 + page * 0.12, 0.025 + page * 0.008, 6.0 - page * 0.32),
			"paper").rotation.y = -0.29 + 0.41 * page
	# Wear at the contact points: scuffed band under the air return and worn
	# floor in front of the consoles.
	wall_stain(desk, "ScuffedBand", Vector3(5.995, 0.55, 4.4), -90, Vector2(0.42, 0.18), "oxidized_steel")
	stain(desk, "WornResin", Vector3(-2.0, 0.011, 9.05), Vector2(1.3, 0.36), "track")


func dress_freight(parent: Node3D) -> void:
	var breach := group(parent, "DamagedFreightEntrance")
	var steel := "oxidized_steel"
	# Broken shutter pieces face the hall. All remnants stay above the 2.40 m bore.
	visual(breach, "ShutterDrum", Vector3(0.29, 0.22, 3.33), Vector3(-6.92, 2.54, 11.5), steel)
	for index: int in 4:
		var rib := visual(breach, "BentSlat%d" % index, Vector3(0.05, 0.05, 1.48 - 0.23 * index),
			Vector3(-6.86 + 0.02 * index, 2.42 + 0.035 * index, 12.17 + 0.09 * index), steel)
		rib.rotation.x = 0.06 + 0.04 * index
	visual(breach, "PulledGuide", Vector3(0.11, 2.2, 0.12), Vector3(-6.95, 1.18, 13.16), "pipe").rotation.x = -0.12
	visual(breach, "FallenSection", Vector3(0.95, 0.065, 0.53), Vector3(-6.47, 0.068, 12.88), steel).rotation.y = 0.44
	tubing(breach, "TrunkCable", Vector3(-7.02, 2.38, 9.78), Vector3(-7.02, 1.9, 9.78), 0.025, "gasket")
	tubing(breach, "TornCableTail", Vector3(-7.02, 1.9, 9.78), Vector3(-6.63, 1.6, 9.77), 0.025, "gasket")
	var designation := sign_label(breach, "FreightDesignation", "LIVE CARGO TRANSFER", Vector3(-6.99, 1.95, 8.6), 90,
		Color(0.75, 0.61, 0.24))
	designation.pixel_size = 0.0045
	visual(breach, "FreightBulkheadLeaf", Vector3(0.31, 2.55, 2.96), Vector3(-12.41, 1.275, 11.94), "frame")
	for index: int in 5:
		visual(breach, "BulkheadRib%d" % index, Vector3(0.11, 0.12, 2.81),
			Vector3(-12.22, 0.40 + 0.45 * index, 11.94), steel)
	sign_label(breach, "BulkheadNotice", "FREIGHT SHAFT  /  SEALED", Vector3(-12.245, 2.13, 11.94), 90, COOL).pixel_size = 0.0045
	for z: float in [10.84, 12.12]:
		visual(breach, "TransportGuide%d" % roundi(z * 100), Vector3(4.7, 0.027, 0.10), Vector3(-9.9, 0.022, z), "bare_steel")
	tracks(breach, Vector3(-11.69, 0.029, 11.44), Vector3(-4.72, 0.029, 11.75), 10)
	stain(breach, "DraggedBlood", Vector3(-7.01, 0.032, 12.04), Vector2(0.98, 0.19), "dried_blood")
	stain(breach, "SeepAtBulkhead", Vector3(-12.0, 0.012, 13.2), Vector2(0.55, 0.42), "water")
	wall_stain(breach, "RustAtSeal", Vector3(-12.495, 0.55, 13.75), 90, Vector2(0.12, 0.42), "oxidized_steel")
	visual(parent, "CabinKickPlate", Vector3(2.78, 0.24, 0.1), Vector3(0, 0.12, 17.452), "bare_steel")
	for sign_x: float in [-1.97, 1.97]:
		tubing(parent, "CabinHandrail%d" % roundi(sign_x * 100), Vector3(sign_x, 1.08, 15.27),
			Vector3(sign_x, 1.08, 17.33), 0.049, "bare_steel")


## A suspended ceiling at a local clear height. The collision is a one-sided
## plane so a future navigation bake cannot mistake the roof for a walking
## floor. The panel material is world triplanar, so the 0.60 m grid keeps one
## phase and orientation across every connected space.
func ceiling(parent: Node3D, node_name: String, footprint: Rect2, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_mask = 0
	body.position = Vector3(footprint.get_center().x, height, footprint.get_center().y)
	var corner_point := Vector3(footprint.size.x * 0.5, 0, footprint.size.y * 0.5)
	var a := -corner_point
	var b := Vector3(corner_point.x, 0, -corner_point.z)
	var c := corner_point
	var d := Vector3(-corner_point.x, 0, corner_point.z)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(PackedVector3Array([a, d, c, a, c, b]))
	var collider := CollisionShape3D.new()
	collider.name = "Underside"
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	var panels := visual(body, "Visual", Vector3(footprint.size.x, 0.04, footprint.size.y),
		Vector3.UP * 0.02, "ceiling_panel")
	panels.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Vertical closure between two soffit heights, with collision so the camera
## cannot look into the plenum.
func soffit_step(parent: Node3D, node_name: String, base: Vector3, length: float, along_z: bool,
		low: float, high: float) -> void:
	var size := Vector3(0.06, high - low, length) if along_z else Vector3(length, high - low, 0.06)
	var step := solid(parent, node_name, size, Vector3(base.x, (low + high) * 0.5, base.z), "wall_panel")
	step.get_node("Mesh").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge := Vector3(0.08, 0.03, length) if along_z else Vector3(length, 0.03, 0.08)
	visual(step, "Edge", edge, Vector3.DOWN * ((high - low) * 0.5 - 0.015), "steel")


## Clinical white wall face above the 2.65 m bay top inside a raised soffit.
func upstand(parent: Node3D, node_name: String, base: Vector3, length: float, along_z: bool,
		low: float, high: float) -> void:
	var size := Vector3(0.01, high - ROOM_CEILING, length) if along_z else Vector3(length, high - ROOM_CEILING, 0.01)
	visual(parent, node_name, size, Vector3(base.x, (ROOM_CEILING + high) * 0.5, base.z), "wall_panel")


func station_sign(parent: Node3D, node_name: String, text: String, center: Vector3,
		yaw: float, width: float, height: float = 0.34) -> void:
	var sign_root := group(parent, node_name)
	sign_root.position = center
	sign_root.rotation.y = deg_to_rad(yaw)
	visual(sign_root, "EnamelPlate", Vector3(width, height, 0.085), Vector3.ZERO, "service_blue")
	visual(sign_root, "CodeStripe", Vector3(0.064, height * 0.78, 0.009),
		Vector3(-width * 0.5 + 0.077, 0, 0.046), "hazard_trim")
	var label := sign_label(sign_root, "Stencil", text, Vector3(0.042, 0, 0.054), 0, SIGN_TEXT)
	label.pixel_size = 0.0041 * minf(1.0, height / 0.34)


## Surface-mounted industrial luminaire under a soffit; lowest point 0.085 m
## below the ceiling.
func luminaire(parent: Node3D, point: Vector3, yaw: float = 0.0) -> void:
	kit(parent, "ceiling_luminaire", "Luminaire_%d_%d" % [roundi(point.x * 100), roundi(point.z * 100)],
		point, yaw, STATION)


func fault_beacon(parent: Node3D) -> void:
	visual(parent, "Housing", Vector3(0.37, 0.23, 0.105), Vector3.ZERO, "frame")
	visual(parent, "RedLens", Vector3(0.27, 0.12, 0.045), Vector3(0, 0, 0.075), "emergency_red")


func animate_loop(parent: Node3D, node_name: String, target: NodePath, times: Array[float], values: Array) -> void:
	var clip := Animation.new()
	clip.length = times[-1]
	clip.loop_mode = Animation.LOOP_LINEAR
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, target)
	for index: int in times.size():
		clip.track_insert_key(track, times[index], values[index])
	var library := AnimationLibrary.new()
	library.add_animation("cycle", clip)
	var animation := AnimationPlayer.new()
	animation.name = node_name
	animation.add_animation_library("", library)
	animation.autoplay = "cycle"
	parent.add_child(animation)


func local_sound(parent: Node3D, node_name: String, file: String, point: Vector3, volume: float, distance: float) -> void:
	var audio := AudioStreamPlayer3D.new()
	audio.name = node_name
	audio.stream = load("res://arca/audio/env/" + file + ".wav")
	audio.position = point
	audio.volume_db = volume
	audio.max_distance = distance
	audio.autoplay = true
	parent.add_child(audio)


func condensate_evidence(parent: Node3D, evidence: Node3D) -> void:
	# The smaller prints stop underneath the damaged return, separate from the
	# large raptor trail to the drinking station.
	var trace := group(evidence, "SmallClawTrail")
	trace.position = Vector3(-4.62, 0.025, 12.55)
	trace.scale = Vector3(0.39, 1, 0.39)
	tracks(trace, Vector3(-0.38, 0, -2.0), Vector3(-0.46, 0, 2.25), 6)
	for index: int in 3:
		var scar := visual(evidence, "GrilleClaw%d" % index, Vector3(0.013, 0.018, 0.25 - index * 0.034),
			Vector3(-4.68, 0.92 + index * 0.092, 13.22 - index * 0.058), "oxidized_steel")
		scar.rotation.x = 0.52
	visual(evidence, "PriedLouver", Vector3(0.075, 0.048, 0.38), Vector3(-4.61, 0.86, 13.17), "pipe").rotation.y = -0.41
	var droplet := visual(evidence, "FallingCondensate", Vector3(0.016, 0.043, 0.016),
		Vector3(-4.54, 0.55, 8.55), "water")
	droplet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	animate_loop(evidence, "DripFall", NodePath("FallingCondensate:position:y"),
		[0.0, 1.60, 1.96, 2.10], [0.57, 0.57, 0.024, 0.024])
	local_sound(evidence, "LeakingDrain", "condensate", Vector3(-4.54, 0.18, 8.55), -15, 6.0)
	station_sign(parent, "InspectionNotice", "RETURN AIR  /  B-02", Vector3(-4.957, 1.95, 13.3), 90, 1.25, 0.26)


func office_instruments(parent: Node3D) -> void:
	var wall := group(parent, "HabitatTelemetry")
	wall.position = Vector3(2.69, 1.6, 9.74)
	wall.rotation.y = PI
	visual(wall, "Rack", Vector3(3.18, 1.42, 0.30), Vector3.ZERO, "service_blue")
	visual(wall, "InstrumentRail", Vector3(3.03, 0.10, 0.06), Vector3(0, 0.48, 0.163), "pipe")
	var panel_labels := ["PADDOCK A", "PADDOCK B", "THIRD ENERGY"]
	for index: int in panel_labels.size():
		var x := (index - 1) * 1.02
		var monitor := kit(wall, "instrument_display", "Monitor%d" % index, Vector3(x, 0.068, 0.208))
		var screen: MeshInstance3D = monitor.get_node("Phosphor")
		var material: ShaderMaterial = screen.mesh.material.duplicate()
		material.set_shader_parameter("channel", 0.29 * index)
		material.set_shader_parameter("phosphor", Color(0.298, 0.659, 0.718) if index == 2 else Color(0.48, 0.70, 0.41))
		screen.material_override = material
		var caption := sign_label(wall, "MonitorCaption%d" % index, panel_labels[index],
			Vector3(x, -0.44, 0.162), 0, COOL)
		caption.pixel_size = 0.0024
		for button: int in 4:
			visual(wall, "Switch%d_%d" % [index, button], Vector3(0.09, 0.058, 0.035),
				Vector3(x - 0.21 + 0.14 * button, -0.56, 0.167),
				"indicator" if button == 0 else "gasket")
	# Third Energy reaches the rack through one insulated, lit conductor.
	tubing(parent, "RackMains", Vector3(3.91, 2.31, 9.75), Vector3(3.91, ROOM_CEILING, 9.75), 0.049, "gasket")
	tubing(parent, "ThirdEnergyFeed", Vector3(3.71, 2.31, 9.75), Vector3(3.71, ROOM_CEILING, 9.75), 0.03, "third_energy")
	for y: float in [2.38, 2.56]:
		flange(parent, "FeedInsulator%d" % roundi(y * 100), Vector3(3.71, y, 9.75), Vector3.UP, 0.05, "ceramic")
	local_sound(parent, "RackHum", "equipment_hum", Vector3(2.7, 1.6, 9.6), -20, 7.5)

	# The protruding drawer is in the cabinet recess, outside the playable lane.
	var cabinet := group(parent, "RecordsCabinetFront")
	cabinet.position = Vector3(-5.51, 1.0, 6.5)
	cabinet.rotation.y = PI * 0.5
	for index: int in 4:
		var height: float = -0.65 + index * 0.42
		var extension: float = 0.19 if index == 2 else 0.01
		visual(cabinet, "Drawer%d" % index, Vector3(2.23, 0.36, 0.09),
			Vector3(0, height, extension), "service_blue")
		visual(cabinet, "Pull%d" % index, Vector3(0.26, 0.045, 0.05),
			Vector3(0, height + 0.055, extension + 0.063), "hazard_trim")
	visual(cabinet, "FilingTray", Vector3(2.16, 0.043, 0.32), Vector3(0, 0.041, 0.02), "gasket")
	for index: int in 3:
		visual(cabinet, "File%d" % index, Vector3(0.23, 0.019, 0.25),
			Vector3(-0.62 + 0.52 * index, 0.068, 0.08), "paper").rotation.y = 0.08 * index


func lift_systems(parent: Node3D) -> void:
	var cabin := group(parent, "EvacuationCarriage")
	visual(cabin, "BackLiner", Vector3(4.02, 2.45, 0.10), Vector3(0, 1.325, 17.43), "service_blue")
	for x: float in [-1.81, 1.81]:
		visual(cabin, "VerticalRib%d" % roundi(x * 100), Vector3(0.125, 2.5, 0.12),
			Vector3(x, 1.35, 17.34), "pipe")
	station_sign(cabin, "CarNumber", "B-04   /   SURFACE TRANSFER", Vector3(0, 2.12, 17.36), 180, 3.42)
	var call_panel := group(cabin, "CallPanel")
	call_panel.position = Vector3(1.23, 1.4, 17.30)
	call_panel.rotation.y = PI
	visual(call_panel, "Plate", Vector3(0.43, 0.62, 0.066), Vector3.ZERO, "frame")
	visual(call_panel, "ReadyLamp", Vector3(0.10, 0.048, 0.026), Vector3(0.10, 0.18, 0.044), "indicator")
	visual(call_panel, "EmergencyStop", Vector3(0.089, 0.089, 0.034), Vector3(0.10, -0.17, 0.044), "emergency_red")
	var beacon := group(parent, "FreightFaultBeacon")
	beacon.position = Vector3(-6.94, 2.15, 13.6)
	beacon.rotation.y = PI * 0.5
	fault_beacon(beacon)
	for z: float in [10.84, 12.12]:
		visual(parent, "HallCargoGuide%d" % roundi(z * 100), Vector3(4.12, 0.016, 0.10),
			Vector3(-5.15, 0.011, z), "bare_steel")
	for x: float in [-1.27, 1.27]:
		visual(cabin, "ThresholdStripe%d" % roundi(x * 100), Vector3(0.13, 0.008, 1.75),
			Vector3(x, 0.012, 14.15), "hazard_trim")
	local_sound(parent, "CableDrive", "equipment_hum", Vector3(1.7, 2.3, 16.1), -25, 8.0)


func maintenance_services(parent: Node3D) -> void:
	station_sign(parent, "SectorMark", "B-01   /   TRANSFER MAINTENANCE",
		Vector3(-10.757, 1.75, 3.4), 90, 3.1)
	var manifold := group(parent, "IsolationManifold")
	manifold.position = Vector3(-10.10, 2.30, -8.2)
	visual(manifold, "FeedBox", Vector3(0.66, 0.62, 0.6), Vector3(-0.37, -0.12, 0), "frame")
	visual(manifold, "FeedCover", Vector3(0.10, 0.42, 0.39), Vector3(-0.013, -0.12, 0), "service_blue")
	tubing(parent, "MainRiser", Vector3(-10.35, 2.42, -8.2), Vector3(-10.35, ROOM_CEILING, -8.2), 0.10, "pipe")
	tubing(parent, "ReturnRiser", Vector3(-10.50, 2.50, 5.6), Vector3(-10.50, ROOM_CEILING, 5.6), 0.08, "pipe")
	tubing(parent, "SupplyTurnDown", Vector3(-10.1, 2.30, 5.6), Vector3(-10.1, 1.95, 5.6), 0.11, "pipe")
	visual(parent, "IsolationBox", Vector3(0.64, 0.56, 0.58), Vector3(-10.39, 1.81, 5.6), "frame")
	visual(parent, "IsolationHandle", Vector3(0.11, 0.11, 0.40), Vector3(-10.02, 1.86, 5.6), "hazard_trim")
	var grille := kit(parent, "vent_grille", "InspectionGrille", Vector3(-10.75, 0.18, -10.4), 90.0)
	grille.scale = Vector3(0.6, 0.55, 0.4)
	local_sound(parent, "PumpHum", "equipment_hum", Vector3(-10, 1.1, -2.9), -16, 11.0)


func extractor(parent: Node3D) -> void:
	var fan := group(parent, "ShaftExtractor")
	fan.position = Vector3(6.9, 1.75, 9.6)
	fan.rotation.y = -PI * 0.5
	visual(fan, "Housing", Vector3(1.28, 1.28, 0.23), Vector3.ZERO, "frame")
	var recess := group(fan, "Recess")
	recess.rotation.x = PI * 0.5
	tubing(recess, "Duct", Vector3(0, 0.12, 0), Vector3(0, 0.18, 0), 0.55, "gasket")
	var rotor := group(fan, "Rotor")
	rotor.position.z = 0.20
	for blade: int in 5:
		var arm := group(rotor, "Arm%d" % blade)
		arm.rotation.z = blade * TAU / 5.0
		visual(arm, "Blade", Vector3(0.21, 0.40, 0.038), Vector3(0.03, 0.26, 0),
			"oxidized_steel").rotation.z = -0.29
	tubing(recess, "Hub", Vector3(0, 0.19, 0), Vector3(0, 0.23, 0), 0.095, "pipe")
	for index: int in 5:
		var height := (index - 2) * 0.18
		visual(fan, "Guard%d" % index, Vector3(0.94 - absf(height) * 0.6, 0.025, 0.033),
			Vector3(0, height, 0.24), "pipe")
	animate_loop(fan, "FanMotor", NodePath("Rotor:rotation:z"), [0.0, 1.15], [0.0, TAU])
	local_sound(fan, "FanRumble", "equipment_hum", Vector3(0, 0, 0.25), -26, 6.0)
