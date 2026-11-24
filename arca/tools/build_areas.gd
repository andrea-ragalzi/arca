extends SceneTree
## Deterministically generate the mission areas and maintenance dressing.
## Run: godot --headless --path . -s res://arca/tools/build_areas.gd
##
## Each area's local origin is at floor level on the entry plane, with the area
## extending toward +Z. Attach_Office and Attach_Lift mark the outer faces of
## the corridor's walls so the adjoining floors and doorways line up.
## Doorways are 3.0 m wide and 3.4 m high, so the existing 3.2 x 3.5 m sliding
## door leaf covers them.

const OUT_DIR: String = "res://arca/areas/"
const KIT: String = "res://arca/assets/environment/kit/"
const WALL_HEIGHT: float = 4.8
const WALL: float = 0.5
const DOOR_WIDTH: float = 3.0
const DOOR_HEIGHT: float = 3.4

var materials: Dictionary[String, StandardMaterial3D] = {}
var kit_meshes: Dictionary[String, ArrayMesh] = {}
var track_mesh: ArrayMesh


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	# Match the test room shell. The environment kit supplies the trim and props.
	materials["wall_panel"] = shell_material(Color(0.18, 0.23, 0.25), 0.30, 0.75)
	materials["floor_plate"] = shell_material(Color(0.115, 0.15, 0.17), 0.25, 0.80)
	for name: String in ["hazard_trim", "frame", "dark_glass", "pipe", "gasket", "indicator", "light_emissive"]:
		materials[name] = load(KIT + name + ".tres")
	for piece: String in ["wall_2m", "wall_4m", "floor_tile", "console"]:
		var module: Node3D = load(KIT + piece + ".tscn").instantiate()
		var mesh: MeshInstance3D = module.get_node("Visual")
		kit_meshes[piece] = mesh.mesh
		module.free()
	materials["oxidized_steel"] = shell_material(Color(0.31, 0.24, 0.18), 0.44, 0.82)
	materials["dried_blood"] = shell_material(Color(0.113, 0.039, 0.031), 0.0, 0.95)
	materials["track"] = shell_material(Color(0.097, 0.077, 0.057), 0.0, 0.97)
	materials["water"] = shell_material(Color(0.068, 0.111, 0.126), 0.48, 0.25)
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
	if material == "floor_plate":
		dress_floor(body, size)
	elif material == "wall_panel" and is_equal_approx(size.y, WALL_HEIGHT):
		dress_wall(body, size)
	elif node_name.begins_with("Desk"):
		dress_desk(body, size)
	else:
		visual(body, "Mesh", size, Vector3.ZERO, material)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func dress_floor(body: StaticBody3D, size: Vector3) -> void:
	var tile_count := Vector2i(ceili(size.x / 4.0), ceili(size.z / 4.0))
	var tile_size := Vector3(size.x / tile_count.x, size.y, size.z / tile_count.y)
	var basis := Basis.from_scale(tile_size / Vector3(4.0, 0.5, 4.0))
	var transforms: Array[Transform3D] = []
	for x: int in tile_count.x:
		for z: int in tile_count.y:
			var center := Vector3((x + 0.5) * tile_size.x - size.x * 0.5, size.y * 0.5,
				(z + 0.5) * tile_size.z - size.z * 0.5)
			transforms.append(Transform3D(basis, center))
	attach_kit_mesh(body, kit_meshes["floor_tile"], transforms)


func dress_wall(body: StaticBody3D, size: Vector3) -> void:
	var along_z := is_equal_approx(size.x, WALL)
	var length: float = size.z if along_z else size.x
	var count := ceili(length / 4.0)
	var width: float = length / count
	var piece := "wall_2m" if width <= 2.5 else "wall_4m"
	var module_width: float = 2.0 if piece == "wall_2m" else 4.0
	var basis := Basis.from_scale(Vector3(width / module_width, size.y / 4.5, 1))
	if along_z:
		basis = basis.rotated(Vector3.UP, PI * 0.5)
	var transforms: Array[Transform3D] = []
	for index: int in count:
		var offset: float = (index + 0.5) * width - length * 0.5
		var center := Vector3(0, -size.y * 0.5, offset) if along_z else Vector3(offset, -size.y * 0.5, 0)
		transforms.append(Transform3D(basis, center))
	attach_kit_mesh(body, kit_meshes[piece], transforms)


func dress_desk(body: StaticBody3D, size: Vector3) -> void:
	var scale := Vector3(size.x / 1.5, size.y / 1.5, size.z / 0.5)
	var transform := Transform3D(Basis.from_scale(scale), Vector3.DOWN * size.y * 0.5)
	attach_kit_mesh(body, kit_meshes["console"], [transform])


func attach_kit_mesh(body: StaticBody3D, source: ArrayMesh, transforms: Array[Transform3D]) -> void:
	var visuals := group(body, "Mesh")
	for index: int in transforms.size():
		var part := MeshInstance3D.new()
		part.name = "Module%d" % index
		part.mesh = source
		part.transform = transforms[index]
		visuals.add_child(part)


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


## Wall along Z at x, spanning z0..z1.
func wall_z(parent: Node3D, node_name: String, x: float, z0: float, z1: float) -> void:
	solid(parent, node_name, Vector3(WALL, WALL_HEIGHT, z1 - z0), Vector3(x, WALL_HEIGHT * 0.5, (z0 + z1) * 0.5), "wall_panel")
	visual(parent, node_name + "Trim", Vector3(WALL + 0.04, 0.18, z1 - z0), Vector3(x, 0.09, (z0 + z1) * 0.5), "hazard_trim")


## Wall along X at z, spanning x0..x1.
func wall_x(parent: Node3D, node_name: String, z: float, x0: float, x1: float) -> void:
	solid(parent, node_name, Vector3(x1 - x0, WALL_HEIGHT, WALL), Vector3((x0 + x1) * 0.5, WALL_HEIGHT * 0.5, z), "wall_panel")
	visual(parent, node_name + "Trim", Vector3(x1 - x0, 0.18, WALL + 0.04), Vector3((x0 + x1) * 0.5, 0.09, z), "hazard_trim")


## Wall along X at z with a centred doorway at x = door_x.
func doorway_x(parent: Node3D, node_name: String, z: float, x0: float, x1: float, door_x: float) -> void:
	var left: float = door_x - DOOR_WIDTH * 0.5
	var right: float = door_x + DOOR_WIDTH * 0.5
	if left > x0:
		wall_x(parent, node_name + "L", z, x0, left)
	if x1 > right:
		wall_x(parent, node_name + "R", z, right, x1)
	_lintel(parent, node_name, Vector3(DOOR_WIDTH, WALL_HEIGHT - DOOR_HEIGHT, WALL), Vector3(door_x, 0, z))
	visual(parent, node_name + "Frame", Vector3(DOOR_WIDTH + 0.5, 0.2, WALL + 0.1), Vector3(door_x, DOOR_HEIGHT + 0.1, z), "hazard_trim")


## Wall along Z at x with a centred doorway at z = door_z.
func doorway_z(parent: Node3D, node_name: String, x: float, z0: float, z1: float, door_z: float) -> void:
	var near: float = door_z - DOOR_WIDTH * 0.5
	var far: float = door_z + DOOR_WIDTH * 0.5
	if near > z0:
		wall_z(parent, node_name + "Near", x, z0, near)
	if z1 > far:
		wall_z(parent, node_name + "Far", x, far, z1)
	_lintel(parent, node_name, Vector3(WALL, WALL_HEIGHT - DOOR_HEIGHT, DOOR_WIDTH), Vector3(x, 0, door_z))
	visual(parent, node_name + "Frame", Vector3(WALL + 0.1, 0.2, DOOR_WIDTH + 0.5), Vector3(x, DOOR_HEIGHT + 0.1, door_z), "hazard_trim")


func _lintel(parent: Node3D, node_name: String, size: Vector3, base: Vector3) -> void:
	solid(parent, node_name + "Lintel", size, Vector3(base.x, DOOR_HEIGHT + size.y * 0.5, base.z), "wall_panel")


func floor_slab(parent: Node3D, node_name: String, x0: float, x1: float, z0: float, z1: float) -> void:
	solid(parent, node_name, Vector3(x1 - x0, 0.6, z1 - z0), Vector3((x0 + x1) * 0.5, -0.3, (z0 + z1) * 0.5), "floor_plate")


func kit(parent: Node3D, piece: String, node_name: String, position: Vector3, yaw_degrees: float = 0.0) -> Node3D:
	var instance: Node3D = load(KIT + piece + ".tscn").instantiate()
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
	label.outline_size = 8
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

const COOL := Color(0.62, 0.8, 1.0)
const AMBER := Color(1.0, 0.62, 0.3)
const ALARM := Color(1.0, 0.25, 0.2)
const CYAN := Color(0.4, 0.95, 1.0)


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
	doorway_x(shell, "WallEntry", 0.25, -2.5, 2.5, 0.0)
	doorway_x(shell, "WallEnd", 30.25, -2.5, 2.5, 0.0)
	var dressing := group(root, "Dressing")
	for index in 7:
		kit(dressing, "pipe_run", "PipeLeft%d" % index, Vector3(-1.75, 3.7, 2.0 + index * 4.0), 90.0)
	for index in 7:
		kit(dressing, "cable_tray", "TrayRight%d" % index, Vector3(1.75, 4.0, 2.0 + index * 4.0), 90.0)
	kit(dressing, "crate", "CrateEntry", Vector3(1.2, 0.0, 5.0), 90.0)
	kit(dressing, "crate", "CrateMid", Vector3(-1.4, 0.0, 20.5), 90.0)
	kit(dressing, "crate", "CrateEnd", Vector3(1.4, 0.0, 25.0), 90.0)
	kit(dressing, "vent_grille", "RecessVent", Vector3(-4.95, 1.0, 13.35), 90.0)
	kit(dressing, "light_strip", "StripEntry", Vector3(-1.95, 2.8, 3.0), 90.0)
	kit(dressing, "light_strip", "StripOffice", Vector3(-4.95, 4.37, 11.0), 90.0)
	kit(dressing, "light_strip", "StripEnd", Vector3(-1.95, 2.8, 27.0), 90.0)
	var lights := group(root, "Lights")
	lamp(lights, "LightEntry", Vector3(0, 3.6, 3.0), COOL, 1.15, 7.6)
	lamp(lights, "LightRecess", Vector3(-3.5, 3.2, 11.0), AMBER, 0.85, 5.5)
	lamp(lights, "LightMiddle", Vector3(0, 3.6, 18.0), COOL, 1.2, 8.0, true)
	lamp(lights, "LightLift", Vector3(0, 3.4, 28.0), ALARM, 1.1, 7.0)
	var signs := group(root, "Signs")
	sign_label(signs, "SignEntry", "SECTOR B\nSECURITY CORRIDOR", Vector3(1.97, 2.9, 1.5), -90.0, COOL)
	sign_label(signs, "SignOffice", "CONTROL OFFICE", Vector3(-4.93, 3.78, 11.0), 90.0, AMBER)
	sign_label(signs, "SignLift", "EXIT LIFT", Vector3(0, 4.45, 29.95), 180.0, ALARM)
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
	solid(shell, "DeskLeft", Vector3(2.2, 0.8, 1.0), Vector3(-3.4, 0.4, 4.0), "frame")
	solid(shell, "DeskRight", Vector3(2.2, 0.8, 1.0), Vector3(2.6, 0.4, 4.0), "frame")
	solid(shell, "DeskCorner", Vector3(1.6, 0.8, 0.9), Vector3(4.7, 0.4, 8.6), "frame")
	solid(shell, "GlassScreen", Vector3(0.1, 2.2, 3.2), Vector3(3.2, 1.1, 7.9), "dark_glass")
	solid(shell, "Cabinet", Vector3(0.6, 2.0, 2.4), Vector3(-5.85, 1.0, 6.5), "frame")
	var dressing := group(root, "Dressing")
	kit(dressing, "console", "ConsoleBackLeft", Vector3(-3.0, 0.0, 9.75), 180.0)
	kit(dressing, "console", "ConsoleBackMid", Vector3(-1.0, 0.0, 9.75), 180.0)
	kit(dressing, "vent_grille", "AirReturn", Vector3(5.95, 2.6, 5.5), -90.0)
	kit(dressing, "light_strip", "StripBack", Vector3(1.5, 3.0, 9.95), 180.0)
	var lights := group(root, "Lights")
	lamp(lights, "LightEntry", Vector3(0, 3.5, 2.0), COOL, 1.1, 7.5)
	lamp(lights, "LightDesks", Vector3(-2.5, 3.0, 5.5), AMBER, 1.15, 7.0, true)
	lamp(lights, "LightConsoles", Vector3(3.5, 2.6, 8.5), CYAN, 0.9, 5.5)
	var signs := group(root, "Signs")
	sign_label(signs, "SignOffice", "CONTROL OFFICE\nSECURITY RECORDS", Vector3(-1.0, 3.6, 9.95), 180.0, COOL)
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
	var dressing := group(root, "Dressing")
	for spot in [Vector3(-4, 0, 5), Vector3(4, 0, 5), Vector3(-4, 0, 10), Vector3(4, 0, 10)]:
		kit(dressing, "pillar", "Pillar_%d_%d" % [int(spot.x), int(spot.z)], spot)
	kit(dressing, "crate", "CoverLeft", Vector3(-2.2, 0.0, 7.5))
	kit(dressing, "crate", "CoverRight", Vector3(2.6, 0.0, 3.2), 90.0)
	kit(dressing, "console", "LiftConsole", Vector3(3.6, 0.0, 13.75), 180.0)
	kit(dressing, "light_strip", "StripLift", Vector3(0.0, 4.37, 13.95), 180.0)
	var lights := group(root, "Lights")
	lamp(lights, "LightHall", Vector3(0, 3.8, 6.0), COOL, 1.06, 10.0, true)
	lamp(lights, "LightLift", Vector3(0, 3.0, 16.0), CYAN, 1.0, 5.0)
	lamp(lights, "LightAlarm", Vector3(-5.5, 3.2, 12.0), ALARM, 0.9, 7.0)
	lamp(lights, "FreightInspectionLight", Vector3(-10.8, 3.2, 12.2), AMBER, 0.95, 4.7)
	var signs := group(root, "Signs")
	sign_label(signs, "SignLift", "EXIT LIFT  /  SURFACE", Vector3(0, 3.78, 13.95), 180.0, CYAN)
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


func stain(parent: Node3D, node_name: String, point: Vector3, radius: Vector2, material: String) -> void:
	var outline := PackedVector2Array()
	for index: int in 13:
		var angle := TAU * float(index) / 13.0
		var edge := 0.79 + 0.16 * cos(angle * 4.0) + 0.09 * sin(angle * 7.0)
		outline.append(Vector2(cos(angle), sin(angle)) * radius * edge)
	var mark := MeshInstance3D.new()
	mark.name = node_name
	mark.mesh = floor_mark(outline, materials[material])
	mark.position = point
	parent.add_child(mark)


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


func tubing(parent: Node3D, node_name: String, start: Vector3, end: Vector3, radius: float, material: String) -> void:
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


func build_maintenance_dressing() -> Node3D:
	var root := Node3D.new()
	root.name = "MaintenanceDressing"
	var station := group(root, "TransferEquipment")
	for index: int in 3:
		var z: float = -7.2 + 2.3 * index
		var cabinet := solid(station, "Pump%d" % index, Vector3(0.58, 1.86, 1.52),
			Vector3(-10.51, 0.93, z), "frame")
		visual(cabinet, "Door", Vector3(0.08, 1.37, 1.27), Vector3(0.31, -0.1, 0), "oxidized_steel")
		visual(cabinet, "Control", Vector3(0.055, 0.25, 0.60), Vector3(0.36, 0.52, 0), "gasket")
		visual(cabinet, "Pilot", Vector3(0.06, 0.035, 0.12), Vector3(0.39, 0.52, -0.16), "indicator")
		tubing(station, "SupplyDrop%d" % index, Vector3(-10.1, 1.86, z),
			Vector3(-10.1, 3.0, z), 0.065, "pipe")
	tubing(station, "SupplyManifold", Vector3(-10.1, 3.0, -8.2), Vector3(-10.1, 3.0, 5.6), 0.13, "pipe")
	tubing(station, "ReturnManifold", Vector3(-10.5, 3.39, -8.2), Vector3(-10.5, 3.39, 5.6), 0.09, "oxidized_steel")
	for index: int in 5:
		var z: float = -11.2 + 4.2 * index
		visual(station, "CeilingBeam%d" % index, Vector3(16.8, 0.24, 0.18),
			Vector3(-2.44, 4.53, z), "frame").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual(station, "BeamConduit%d" % index, Vector3(16.8, 0.06, 0.07),
			Vector3(-2.44, 4.39, z + 0.12), "oxidized_steel").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pump_label := sign_label(station, "PumpBankIdentification", "TRANSFER PUMPS",
		Vector3(-10.075, 1.51, -7.2), 90, Color(0.74, 0.84, 0.82))
	pump_label.pixel_size = 0.0032
	var ceiling := visual(station, "MaintenanceCeiling", Vector3(16.8, 0.14, 23.8),
		Vector3(-2.44, 4.80, -1.7), "wall_panel")
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Existing cover remains the collision envelope for this work surface.
	visual(station, "Worktop", Vector3(2.5, 0.07, 1.42), Vector3(-3.8, 1.78, -3.0), "oxidized_steel")
	visual(station, "OpenToolTray", Vector3(0.54, 0.09, 0.35), Vector3(-4.36, 1.865, -3.18), "gasket")
	visual(station, "WorkOrder", Vector3(0.27, 0.006, 0.19), Vector3(-3.14, 1.824, -2.86), "paper").rotation.y = 0.24
	for index: int in 4:
		visual(station, "Tool%d" % index, Vector3(0.021, 0.021, 0.19 - 0.018 * index),
			Vector3(-4.52 + 0.092 * index, 1.923, -3.18), "pipe").rotation.y = 0.17 * index - 0.23

	visual(station, "TestBenchTop", Vector3(2.29, 0.064, 1.48), Vector3(4, 1.782, 1.0), "frame")
	visual(station, "InsulatedCase", Vector3(0.53, 0.19, 0.32), Vector3(4.59, 1.906, 1.22), "gasket")
	visual(station, "CaseLatch", Vector3(0.075, 0.055, 0.03), Vector3(4.59, 1.903, 1.048), "pipe")
	add_maintenance_workstation(root)
	var evidence := group(root, "TransferLockEvidence")
	for index: int in 4:
		var point := Vector3(1.821, 3.37 - index * 0.16, 7.1 + index * 0.115)
		visual(evidence, "FrameGouge%d" % index, Vector3(0.008, 0.019, 0.48 - 0.056 * index),
			point, "oxidized_steel").rotation.x = -0.46
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
			Vector3(side, -0.045, 0), "oxidized_steel")
	visual(work, "CRT", Vector3(0.48, 0.36, 0.39), Vector3(-4.12, 1.04, -12.04), "gasket")
	visual(work, "CRTGlass", Vector3(0.40, 0.26, 0.018), Vector3(-4.12, 1.066, -11.838), "dark_glass")
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
		visual(shelf, "Tray%d" % tier, Vector3(0.65, 0.065, 1.75), Vector3(0, y, 0), "frame")
		visual(shelf, "PartsBin%d" % tier, Vector3(0.43, 0.24, 0.52), Vector3(-0.04, y + 0.15, 0.39 - tier * 0.36),
			"hazard_trim" if tier == 0 else "gasket")
	for end: float in [-0.83, 0.83]:
		visual(shelf, "Upright%d" % roundi(end * 100), Vector3(0.55, 1.83, 0.076), Vector3(0, 0.915, end), "pipe")
	var takeoff := marker(work, "TableJump", Vector3(-1.08, 0, -11.8))
	takeoff.add_to_group("arca_raptor_jump", true)
	marker(takeoff, "Landing", Vector3(-2.47, 0.905, 0))
	var descent := marker(work, "TableDescent", Vector3(-3.55, 0.87, -11.8))
	descent.add_to_group("arca_raptor_jump", true)
	marker(descent, "Landing", Vector3(-2.21, -0.825, 0))


func dress_security(parent: Node3D) -> void:
	var evidence := group(parent, "CondensateAndTracks")
	visual(evidence, "CondensateHousing", Vector3(0.20, 0.85, 0.78), Vector3(-4.90, 0.49, 8.61), "frame")
	tubing(evidence, "CondensateFeed", Vector3(-4.87, 2.75, 8.55), Vector3(-4.87, 0.89, 8.55), 0.065, "oxidized_steel")
	tubing(evidence, "DrainSpout", Vector3(-4.86, 0.70, 8.55), Vector3(-4.55, 0.58, 8.55), 0.043, "pipe")
	stain(evidence, "WaterAtDrain", Vector3(-4.53, 0.022, 8.64), Vector2(0.56, 0.39), "water")
	visual(evidence, "FeedTray", Vector3(0.47, 0.085, 0.32), Vector3(-4.67, 0.06, 9.31), "oxidized_steel").rotation.y = -0.49
	for index: int in 3:
		visual(evidence, "FeedWrapper%d" % index, Vector3(0.17, 0.014, 0.14),
			Vector3(-4.53 + index * 0.13, 0.022, 9.43 + index * 0.105), "paper").rotation.y = index * 0.68
	tracks(evidence, Vector3(0.36, 0.026, 28.25), Vector3(-0.33, 0.026, 24.5), 6)
	var alcove := group(evidence, "AlcoveTracks")
	tracks(alcove, Vector3(-0.4, 0.026, 12.8), Vector3(-3.75, 0.026, 9.45), 7)
	# Emergency storage is recessed into the side of the circulation path.
	var locker := solid(parent, "RescueLocker", Vector3(0.44, 1.36, 1.18),
		Vector3(1.77, 0.68, 15.25), "frame")
	visual(locker, "DoorPanel", Vector3(0.034, 1.12, 0.99), Vector3(-0.236, 0, 0), "oxidized_steel")
	visual(locker, "Latch", Vector3(0.043, 0.15, 0.065), Vector3(-0.264, 0.12, 0.39), "pipe")
	sign_label(parent, "RescueLockerLabel", "EMERGENCY\nRESPONSE", Vector3(1.503, 1.08, 15.25), -90, COOL)


func dress_office(parent: Node3D) -> void:
	var desk := group(parent, "EvacuationRecords")
	for index: int in 3:
		var x: float = -4.2 + index * 1.43
		visual(desk, "FileBay%d" % index, Vector3(1.26, 0.72, 0.29), Vector3(x, 2.15, 9.84), "frame")
		for slot: int in 3:
			visual(desk, "File%d_%d" % [index, slot], Vector3(0.33, 0.38, 0.17),
				Vector3(x - 0.38 + slot * 0.38, 2.12, 9.65), "paper" if slot == 1 else "oxidized_steel")
	var board := visual(desk, "TransferBoard", Vector3(2.12, 0.91, 0.065), Vector3(0.33, 2.35, 9.95), "gasket")
	visual(board, "Line", Vector3(1.86, 0.014, 0.012), Vector3(0, 0.11, -0.037), "pipe")
	var board_text := sign_label(desk, "TransferStatus", "FREIGHT STATUS\n01   LIVE CARGO\n02   HOLD / LOCKDOWN",
		Vector3(0.33, 2.38, 9.905), 180, Color(0.69, 0.86, 0.79))
	board_text.pixel_size = 0.0036
	visual(desk, "TerminalScreen", Vector3(0.58, 0.36, 0.08), Vector3(2.79, 1.11, 4.18), "gasket")
	visual(desk, "ScreenImage", Vector3(0.48, 0.26, 0.015), Vector3(2.79, 1.11, 4.131), "dark_glass")
	visual(desk, "Keyboard", Vector3(0.42, 0.026, 0.16), Vector3(2.79, 0.826, 3.86), "gasket")
	for index: int in 4:
		visual(desk, "LooseReport%d" % index, Vector3(0.21, 0.006, 0.30),
			Vector3(3.05 + 0.14 * index, 0.818 + 0.007 * index, 4.05 - 0.12 * index),
			"paper").rotation.y = 0.9 * index
	visual(desk, "TippedTray", Vector3(0.32, 0.052, 0.26), Vector3(4.98, 0.17, 9.37), "oxidized_steel").rotation.z = 0.63


func dress_freight(parent: Node3D) -> void:
	var breach := group(parent, "DamagedFreightEntrance")
	var steel := "oxidized_steel"
	# Broken shutter pieces face the hall. All remnants stay clear of the usable bore.
	visual(breach, "ShutterDrum", Vector3(0.29, 0.45, 3.33), Vector3(-6.92, 3.78, 11.5), steel)
	for index: int in 4:
		var rib := visual(breach, "BentSlat%d" % index, Vector3(0.11, 0.11, 1.48 - 0.23 * index),
			Vector3(-6.86 + 0.035 * index, 3.38 + 0.15 * index, 12.27 + 0.09 * index), steel)
		rib.rotation.x = 0.12 + 0.10 * index
	visual(breach, "PulledGuide", Vector3(0.11, 2.66, 0.12), Vector3(-6.95, 1.45, 13.16), "pipe").rotation.x = -0.12
	visual(breach, "FallenSection", Vector3(0.95, 0.065, 0.53), Vector3(-6.47, 0.068, 12.88), steel).rotation.y = 0.44
	tubing(breach, "TrunkCable", Vector3(-7.02, 3.62, 9.78), Vector3(-7.02, 2.5, 9.78), 0.025, "gasket")
	tubing(breach, "TornCableTail", Vector3(-7.02, 2.5, 9.78), Vector3(-6.63, 2.15, 9.77), 0.025, "gasket")
	sign_label(breach, "FreightDesignation", "LIVE CARGO TRANSFER", Vector3(-6.82, 4.22, 11.5), 90, AMBER)
	visual(breach, "FreightBulkheadLeaf", Vector3(0.31, 3.3, 2.96), Vector3(-12.41, 1.65, 11.94), "frame")
	for index: int in 5:
		visual(breach, "BulkheadRib%d" % index, Vector3(0.11, 0.12, 2.81),
			Vector3(-12.22, 0.45 + 0.54 * index, 11.94), steel)
	sign_label(breach, "BulkheadNotice", "FREIGHT SHAFT  /  SEALED", Vector3(-12.20, 3.60, 11.94), 90, COOL)
	for z: float in [10.84, 12.12]:
		visual(breach, "TransportGuide%d" % roundi(z * 100), Vector3(4.7, 0.027, 0.10), Vector3(-9.9, 0.022, z), "pipe")
	tracks(breach, Vector3(-11.69, 0.029, 11.44), Vector3(-4.72, 0.029, 11.75), 10)
	stain(breach, "DraggedBlood", Vector3(-7.01, 0.032, 12.04), Vector2(0.98, 0.19), "dried_blood")
	visual(parent, "CabinKickPlate", Vector3(2.78, 0.24, 0.1), Vector3(0, 0.12, 17.452), steel)
	for sign_x: float in [-1.97, 1.97]:
		tubing(parent, "CabinHandrail%d" % roundi(sign_x * 100), Vector3(sign_x, 1.08, 15.27),
			Vector3(sign_x, 1.08, 17.33), 0.049, "pipe")
