extends SceneTree
## Deterministically generate the Sprint 01 blockout areas from layout data.
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


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	# Match the test room shell. The environment kit supplies the trim and props.
	materials["wall_panel"] = shell_material(Color(0.18, 0.23, 0.25), 0.30, 0.75)
	materials["floor_plate"] = shell_material(Color(0.115, 0.15, 0.17), 0.25, 0.80)
	for name: String in ["hazard_trim", "frame", "dark_glass"]:
		materials[name] = load(KIT + name + ".tres")
	var ok: bool = true
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
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	box.material = materials[material]
	mesh.mesh = box
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


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


func sign_label(parent: Node3D, node_name: String, text: String, position: Vector3, yaw_degrees: float, color: Color) -> void:
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


func marker(parent: Node3D, node_name: String, position: Vector3, yaw_degrees: float = 0.0) -> void:
	var point := Marker3D.new()
	point.name = node_name
	point.position = position
	point.rotation.y = deg_to_rad(yaw_degrees)
	parent.add_child(point)


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
	lamp(lights, "LightEntry", Vector3(0, 3.6, 3.0), COOL, 1.4, 8.0)
	lamp(lights, "LightRecess", Vector3(-3.5, 3.2, 11.0), AMBER, 0.7, 5.5)
	lamp(lights, "LightMiddle", Vector3(0, 3.6, 18.0), COOL, 1.2, 8.0, true)
	lamp(lights, "LightLift", Vector3(0, 3.4, 28.0), ALARM, 1.1, 7.0)
	var signs := group(root, "Signs")
	sign_label(signs, "SignEntry", "SECTOR B\nSECURITY CORRIDOR", Vector3(1.97, 2.9, 1.5), -90.0, COOL)
	sign_label(signs, "SignOffice", "CONTROL OFFICE", Vector3(-4.93, 3.78, 11.0), 90.0, AMBER)
	sign_label(signs, "SignLift", "EXIT LIFT\nKEYCARD REQUIRED", Vector3(0, 3.9, 29.95), 180.0, ALARM)
	var markers := group(root, "Markers")
	marker(markers, "Spawn_SleepingRaptor", Vector3(-4.0, 0.05, 8.95), 90.0)
	marker(markers, "Spawn_CorridorAmbush", Vector3(0.0, 0.05, 27.5), 180.0)
	marker(markers, "Pickup_Ammo", Vector3(1.55, 0.1, 21.5))
	marker(markers, "Note_1", Vector3(1.2, 1.05, 5.0))
	marker(markers, "Door_ToOffice", Vector3(-5.25, 0.0, 11.0), -90.0)
	marker(markers, "Door_ToLift", Vector3(0.0, 0.0, 29.75))
	marker(markers, "Attach_Office", Vector3(-5.5, 0.0, 11.0), -90.0)
	marker(markers, "Attach_Lift", Vector3(0.0, 0.0, 30.5))
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
	kit(dressing, "vent_grille", "AmbushVent", Vector3(5.95, 2.6, 5.5), -90.0)
	kit(dressing, "light_strip", "StripBack", Vector3(1.5, 3.0, 9.95), 180.0)
	var lights := group(root, "Lights")
	lamp(lights, "LightEntry", Vector3(0, 3.5, 2.0), COOL, 1.1, 7.5)
	lamp(lights, "LightDesks", Vector3(-2.5, 3.0, 5.5), AMBER, 1.0, 7.0, true)
	lamp(lights, "LightConsoles", Vector3(3.5, 2.6, 8.5), CYAN, 0.9, 5.5)
	var signs := group(root, "Signs")
	sign_label(signs, "SignOffice", "CONTROL OFFICE\nSECURITY RECORDS", Vector3(-1.0, 3.6, 9.95), 180.0, COOL)
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
	wall_z(shell, "WallLeft", -7.25, 0.0, 14.5)
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
	lamp(lights, "LightHall", Vector3(0, 3.8, 6.0), COOL, 1.2, 10.0, true)
	lamp(lights, "LightLift", Vector3(0, 3.0, 16.0), CYAN, 1.0, 5.0)
	lamp(lights, "LightAlarm", Vector3(-5.5, 3.2, 12.0), ALARM, 0.9, 7.0)
	var signs := group(root, "Signs")
	sign_label(signs, "SignLift", "EXIT LIFT  /  SURFACE", Vector3(0, 3.78, 13.95), 180.0, CYAN)
	var markers := group(root, "Markers")
	marker(markers, "Lift_Panel", Vector3(3.6, 0.0, 13.2), 180.0)
	marker(markers, "Door_Lift", Vector3(0.0, 0.0, 13.75))
	marker(markers, "Exit_Zone", Vector3(0.0, 0.0, 16.3))
	marker(markers, "Spawn_FinalRaptor", Vector3(-5.6, 0.05, 11.5), 120.0)
	marker(markers, "Pickup_Ammo", Vector3(5.9, 0.1, 1.6))
	return root
