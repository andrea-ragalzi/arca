extends SceneTree
## Bake static, material-batched meshes and independent box collision from metre dimensions.

const KIT := "res://arca/assets/environment/kit/"
var materials: Dictionary[String, StandardMaterial3D] = {}
var surfaces: Dictionary[String, SurfaceTool] = {}
var piece: Node3D
var first_error: Error = OK


func _initialize() -> void:
	var error := DirAccess.make_dir_recursive_absolute(KIT)
	if error != OK:
		printerr("Cannot create kit directory: ", error_string(error))
		quit(1)
		return

	build_materials()
	build_wall(1)
	build_wall(2)
	build_doorway()
	build_floor()
	build_pillar()
	build_services()
	build_props()
	if first_error == OK:
		build_preview()
	print("Environment kit bake: ", error_string(first_error))
	quit(0 if first_error == OK else 1)


func save(resource: Resource, filename: String) -> void:
	var error := ResourceSaver.save(resource, KIT + filename, ResourceSaver.FLAG_CHANGE_PATH)
	if error == OK:
		resource.take_over_path(KIT + filename)
	else:
		printerr("Cannot save ", filename, ": ", error_string(error))
		if first_error == OK:
			first_error = error


func build_materials() -> void:
	# Fixed-seed fine grain and directional abrasion, shared by all painted metals.
	var noise := FastNoiseLite.new()
	noise.seed = 731
	noise.frequency = 0.083
	var image := Image.create_empty(128, 128, false, Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):
			var grain := noise.get_noise_2d(x * 3.3, y * 3.3)
			var wear := noise.get_noise_2d(x * 0.35, y * 4.0)
			var value := clampf(0.86 + grain * 0.083 + wear * 0.075, 0.59, 1.0)
			image.set_pixel(x, y, Color(value, value, value))
	image.generate_mipmaps()
	var abrasion := ImageTexture.create_from_image(image)
	save(abrasion, "metal_grain.res")

	material("wall_panel", Color("#70848a"), 0.25, 0.67, abrasion)
	material("floor_plate", Color("#526168"), 0.35, 0.78, abrasion)
	material("hazard_trim", Color("#bf8934"), 0.25, 0.62, abrasion)
	material("pipe", Color("#91a19e"), 0.55, 0.44, abrasion)
	material("light_emissive", Color("#b5edf3"), 0.0, 0.42)
	material("dark_glass", Color("#203438"), 0.29, 0.22)
	material("frame", Color("#394b52"), 0.37, 0.54, abrasion)
	material("gasket", Color("#222b30"), 0.08, 0.84)
	material("indicator", Color("#d66331"), 0.0, 0.55)
	for key: String in materials:
		save(materials[key], key + ".tres")


func material(key: String, color: Color, metal: float, roughness: float,
		texture: Texture2D = null) -> void:
	var mat := StandardMaterial3D.new()
	mat.resource_name = key.capitalize()
	mat.albedo_color = color
	mat.albedo_texture = texture
	mat.metallic = metal
	mat.roughness = roughness
	if key in ["light_emissive", "indicator"]:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.35 if key == "light_emissive" else 0.65
	materials[key] = mat


func start_piece(piece_name: String) -> void:
	piece = Node3D.new()
	piece.name = piece_name.to_pascal_case()
	surfaces.clear()


func add(parent: Node, child: Node, node_name: String) -> void:
	child.name = node_name
	parent.add_child(child)
	child.owner = piece


func finish_piece(filename: String) -> void:
	var mesh := ArrayMesh.new()
	for key: String in surfaces:
		surfaces[key].commit(mesh)
		mesh.surface_set_name(mesh.get_surface_count() - 1, key)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add(piece, visual, "Visual")
	pack(filename + ".tscn")


func pack(filename: String) -> void:
	var packed := PackedScene.new()
	var error := packed.pack(piece)
	if error == OK:
		save(packed, filename)
	else:
		printerr("Cannot pack ", filename, ": ", error_string(error))
		if first_error == OK:
			first_error = error
	piece.free()


func collision(center: Vector3, size: Vector3, shape_name: String = "Hull") -> void:
	var body: StaticBody3D = piece.get_node_or_null("Solid")
	if body == null:
		body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		add(piece, body, "Solid")
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = center
	add(body, shape, shape_name)


func surface(key: String) -> SurfaceTool:
	if not surfaces.has(key):
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(materials[key])
		surfaces[key] = builder
	return surfaces[key]


func primitive(mesh: PrimitiveMesh, center: Vector3, key: String, basis: Basis = Basis.IDENTITY) -> void:
	surface(key).append_from(mesh, 0, Transform3D(basis, center))


func box(center: Vector3, size: Vector3, key: String, bevel: float = 0.0) -> void:
	if bevel == 0.0:
		var mesh := BoxMesh.new()
		mesh.size = size
		primitive(mesh, center, key)
		return

	# Six inset faces, twelve edge bevels and eight clipped corners.
	var builder := surface(key)
	var half := size * 0.5
	var inner := half - Vector3.ONE * bevel
	for axis in range(3):
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for sign in [-1, 1]:
			var a := Vector3.ZERO
			a[axis] = sign * half[axis]
			a[u] = -inner[u]
			a[v] = -inner[v]
			var b := a
			b[u] = inner[u]
			var c := b
			c[v] = inner[v]
			var d := a
			d[v] = inner[v]
			face(builder, center, [a, b, c, d])
		for su in [-1, 1]:
			for sv in [-1, 1]:
				var a := Vector3.ZERO
				a[axis] = -inner[axis]
				a[u] = su * half[u]
				a[v] = sv * inner[v]
				var b := a
				b[axis] = inner[axis]
				var d := a
				d[u] = su * inner[u]
				d[v] = sv * half[v]
				var c := d
				c[axis] = inner[axis]
				face(builder, center, [a, b, c, d])
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var signs := Vector3(sx, sy, sz)
				face(builder, center, [
					Vector3(half.x, inner.y, inner.z) * signs,
					Vector3(inner.x, half.y, inner.z) * signs,
					Vector3(inner.x, inner.y, half.z) * signs,
				])


func face(builder: SurfaceTool, center: Vector3, points: Array[Vector3]) -> void:
	var normal := (points[2] - points[0]).cross(points[1] - points[0]).normalized()
	if normal.dot(points[0]) < 0:
		points.reverse()
		normal = -normal
	var axis := normal.abs().max_axis_index()
	for i in range(1, points.size() - 1):
		for index in [0, i, i + 1]:
			var vertex := center + points[index]
			builder.set_normal(normal)
			builder.set_uv(Vector2(vertex[(axis + 1) % 3], vertex[(axis + 2) % 3]) * 0.65)
			builder.add_vertex(vertex)


func tube(center: Vector3, radius: float, length: float, key: String) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 16
	mesh.rings = 0
	primitive(mesh, center, key, Basis(Vector3.BACK, PI / 2))


func build_wall(bays: int) -> void:
	var width := float(bays * 2)
	var filename := "wall_%dm" % int(width)
	start_piece(filename)
	box(Vector3(0, 2.25, 0), Vector3(width, 4.5, 0.34), "frame")
	for bay in range(bays):
		var x := -width / 2 + 1 + bay * 2
		for side: float in [-1.0, 1.0]:
			box(Vector3(x, 2.17, 0.185 * side), Vector3(1.94, 3.92, 0.042), "gasket", 0.012)
			box(Vector3(x, 2.06, 0.214 * side), Vector3(1.82, 2.85, 0.072), "wall_panel", 0.032)
			box(Vector3(x, 3.81, 0.214 * side), Vector3(1.82, 0.53, 0.072), "wall_panel", 0.025)
			box(Vector3(x, 0.34, 0.216 * side), Vector3(1.87, 0.28, 0.068), "frame", 0.02)
			box(Vector3(x, 0.55, 0.221 * side), Vector3(1.8, 0.045, 0.058), "hazard_trim")
			for offset: float in [-0.82, 0.82]:
				for y: float in [0.76, 3.37, 3.87]:
					box(Vector3(x + offset, y, 0.245 * side), Vector3(0.042, 0.042, 0.01), "pipe")
	collision(Vector3(0, 2.25, 0), Vector3(width, 4.5, 0.5))
	finish_piece(filename)


func build_doorway() -> void:
	start_piece("doorway_frame")
	for side: float in [-1.0, 1.0]:
		var x := 1.45 * side
		box(Vector3(x, 1.3, -0.0275), Vector3(1.1, 2.6, 0.445), "frame", 0.047)
		box(Vector3(1.49 * side, 1.35, 0.209), Vector3(0.86, 2.22, 0.07), "wall_panel", 0.03)
		box(Vector3(0.98 * side, 1.3, 0.216), Vector3(0.14, 2.46, 0.068), "gasket")
		for segment in range(7):
			var stripe := BoxMesh.new()
			stripe.size = Vector3(0.12, 0.09, 0.011)
			primitive(stripe, Vector3(1.015 * side, 0.33 + segment * 0.18, 0.244),
				"hazard_trim", Basis(Vector3.BACK, side * 0.52))
		box(Vector3(1.42 * side, 1.42, 0.245), Vector3(0.15, 0.21, 0.01), "dark_glass")
		box(Vector3(1.42 * side, 1.46, 0.248), Vector3(0.075, 0.026, 0.004), "indicator")
		collision(Vector3(x, 1.3, 0), Vector3(1.1, 2.6, 0.5),
			"LeftJamb" if side < 0 else "RightJamb")
	box(Vector3(0, 3.55, -0.0275), Vector3(4, 1.9, 0.445), "frame", 0.045)
	box(Vector3(0, 3.57, 0.209), Vector3(3.82, 1.55, 0.07), "wall_panel", 0.045)
	box(Vector3(0, 2.9, 0.223), Vector3(1.97, 0.3, 0.054), "gasket", 0.016)
	box(Vector3(0, 2.9, 0.243), Vector3(1.75, 0.06, 0.014), "light_emissive")
	collision(Vector3(0, 3.55, 0), Vector3(4, 1.9, 0.5), "Header")
	finish_piece("doorway_frame")


func build_floor() -> void:
	start_piece("floor_tile")
	box(Vector3(0, -0.268, 0), Vector3(4, 0.464, 4), "gasket")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			box(Vector3(x, -0.029, z), Vector3(1.985, 0.052, 1.985), "floor_plate", 0.012)
			for offset: float in [-0.84, 0.84]:
				box(Vector3(x + offset, -0.004, z + 0.83), Vector3(0.072, 0.008, 0.052), "frame")
	for x: float in [-1.75, 1.75]:
		box(Vector3(x, -0.004, 0), Vector3(0.045, 0.008, 3.93), "frame")
	collision(Vector3(0, -0.25, 0), Vector3(4, 0.5, 4))
	finish_piece("floor_tile")


func build_pillar() -> void:
	start_piece("pillar")
	box(Vector3(0, 2.25, 0), Vector3(0.38, 4.5, 0.38), "frame", 0.036)
	for y: float in [0.14, 4.36]:
		box(Vector3(0, y, 0), Vector3(0.5, 0.28, 0.5), "frame", 0.034)
	box(Vector3(0, 2.25, 0.181), Vector3(0.27, 3.87, 0.088), "wall_panel", 0.032)
	box(Vector3(0, 2.25, 0.228), Vector3(0.07, 3.62, 0.016), "gasket")
	box(Vector3(0, 0.56, 0.238), Vector3(0.27, 0.06, 0.024), "hazard_trim")
	collision(Vector3(0, 2.25, 0), Vector3(0.5, 4.5, 0.5))
	finish_piece("pillar")


func build_services() -> void:
	start_piece("pipe_run")
	tube(Vector3(0, 0.25, 0), 0.16, 4.0, "pipe")
	for x: float in [-1.88, -0.85, 0.85, 1.88]:
		tube(Vector3(x, 0.25, 0), 0.25, 0.18, "frame")
		tube(Vector3(x, 0.25, 0), 0.22, 0.23, "hazard_trim" if absf(x) > 1.0 else "gasket")
	finish_piece("pipe_run")

	start_piece("cable_tray")
	for z: float in [-0.22, 0.22]:
		box(Vector3(0, 0.16, z), Vector3(4, 0.19, 0.06), "frame", 0.014)
	for i in range(12):
		box(Vector3(-1.87 + i * 0.34, 0.057, 0), Vector3(0.084, 0.114, 0.43), "frame")
	for z: float in [-0.12, 0.0, 0.12]:
		tube(Vector3(0, 0.143, z), 0.034, 4, "gasket" if z == 0.0 else "pipe")
	for x: float in [-1.55, 1.55]:
		box(Vector3(x, 0.305, 0), Vector3(0.12, 0.39, 0.49), "frame", 0.025)
		box(Vector3(x, 0.19, 0.24), Vector3(0.15, 0.09, 0.02), "hazard_trim")
	finish_piece("cable_tray")

	start_piece("light_strip")
	box(Vector3(0, 0.25, -0.034), Vector3(2, 0.5, 0.432), "frame", 0.065)
	box(Vector3(0, 0.25, 0.196), Vector3(1.83, 0.34, 0.056), "gasket", 0.025)
	box(Vector3(0, 0.25, 0.24), Vector3(1.72, 0.155, 0.018), "light_emissive", 0.008)
	for x: float in [-0.87, 0.87]:
		box(Vector3(x, 0.25, 0.236), Vector3(0.055, 0.24, 0.028), "pipe")
	finish_piece("light_strip")

	start_piece("vent_grille")
	box(Vector3(0, 0.5, -0.045), Vector3(1.5, 1, 0.41), "frame", 0.046)
	box(Vector3(0, 0.5, 0.169), Vector3(1.32, 0.81, 0.03), "gasket")
	for i in range(8):
		var slat := BoxMesh.new()
		slat.size = Vector3(1.22, 0.058, 0.08)
		primitive(slat, Vector3(0, 0.18 + i * 0.09, 0.2), "wall_panel", Basis(Vector3.RIGHT, -0.42))
	for x: float in [-0.689, 0.689]:
		box(Vector3(x, 0.5, 0.205), Vector3(0.075, 0.88, 0.09), "frame", 0.02)
	finish_piece("vent_grille")


func build_props() -> void:
	start_piece("crate")
	box(Vector3(0, 0.48, 0), Vector3(1.43, 0.84, 0.92), "wall_panel", 0.06)
	for y: float in [0.083, 0.917]:
		box(Vector3(0, y, 0), Vector3(1.5, 0.166, 1), "frame", 0.038)
	for x: float in [-0.56, 0.56]:
		for z: float in [-0.451, 0.451]:
			box(Vector3(x, 0.5, z), Vector3(0.12, 0.67, 0.079), "frame", 0.022)
			box(Vector3(x, 0.75, z), Vector3(0.18, 0.105, 0.098), "hazard_trim", 0.015)
	box(Vector3(0, 0.62, 0.463), Vector3(0.29, 0.12, 0.022), "gasket", 0.008)
	collision(Vector3(0, 0.5, 0), Vector3(1.5, 1, 1))
	finish_piece("crate")

	start_piece("console")
	box(Vector3(0, 0.12, 0), Vector3(1.5, 0.24, 0.5), "frame", 0.037)
	box(Vector3(0, 0.6, 0), Vector3(1.29, 1.1, 0.4), "wall_panel", 0.035)
	box(Vector3(0, 1.19, -0.037), Vector3(1.5, 0.62, 0.426), "frame", 0.054)
	box(Vector3(0, 1.216, 0.221), Vector3(1.31, 0.413, 0.053), "gasket", 0.017)
	box(Vector3(-0.24, 1.25, 0.239), Vector3(0.72, 0.28, 0.022), "dark_glass", 0.01)
	for i in range(4):
		box(Vector3(-0.44, 1.18 + i * 0.043, 0.247),
			Vector3(0.23 + i * 0.053, 0.012, 0.006), "pipe")
	for i in range(4):
		box(Vector3(0.24 + i * 0.092, 1.24, 0.244), Vector3(0.049, 0.06, 0.012),
			"light_emissive" if i == 0 else "indicator", 0.004)
	for i in range(5):
		box(Vector3(0, 0.41 + i * 0.047, 0.204), Vector3(0.68, 0.023, 0.014), "gasket")
	collision(Vector3(0, 0.75, 0), Vector3(1.5, 1.5, 0.5))
	finish_piece("console")


func instance(filename: String, node_name: String, position: Vector3, yaw: float = 0.0) -> Node3D:
	var packed: PackedScene = load(KIT + filename + ".tscn")
	var module: Node3D = packed.instantiate()
	module.position = position
	module.rotation_degrees.y = yaw
	add(piece, module, node_name)
	return module


func build_preview() -> void:
	start_piece("kit_preview")
	for x: float in [-2.0, 2.0]:
		for z: float in [-6.0, -2.0, 2.0, 6.0]:
			var tile_id := "%d_%d" % [int(x + 2), int(z + 6)]
			instance("floor_tile", "Deck" + tile_id, Vector3(x, 0, z))
			var ceiling := instance("floor_tile", "Ceiling" + tile_id, Vector3(x, 4.5, z))
			ceiling.rotation_degrees.z = 180
	instance("doorway_frame", "Bulkhead", Vector3(-2, 0, -4))
	instance("wall_4m", "BackWall", Vector3(2, 0, -4))
	instance("wall_4m", "FarWall", Vector3(-2, 0, -7.75))
	instance("wall_4m", "FarLeft", Vector3(-3.75, 0, -6), 90)
	instance("wall_4m", "FarRight", Vector3(-0.25, 0, -6), -90)
	for z: float in [-2.0, 2.0, 6.0]:
		instance("wall_4m", "LeftWall%d" % int(z + 2), Vector3(-3.75, 0, z), 90)
		instance("wall_4m", "RightWall%d" % int(z + 2), Vector3(3.75, 0, z), -90)
	instance("wall_2m", "ServiceDivider", Vector3(2.75, 0, -2.9))
	instance("pillar", "DividerPost", Vector3(1.5, 0, -2.9))
	instance("pillar", "LeftPost", Vector3(-3.38, 0, 0))
	instance("pipe_run", "CoolantRun", Vector3(-3.29, 2.87, -2), 90)
	instance("pipe_run", "CoolantReturn", Vector3(-3.29, 2.87, 2), 90)
	instance("cable_tray", "OverheadTray", Vector3(0, 4.0, -2.85))
	instance("light_strip", "WallFixture", Vector3(-3.26, 2.33, -2), 90)
	instance("light_strip", "DividerFixture", Vector3(2.75, 2.88, -2.53))
	instance("vent_grille", "ReturnAir", Vector3(2.77, 0.68, -2.53))
	instance("crate", "StoresCrate", Vector3(-2.71, 0, 1.13), -13)
	instance("console", "AccessTerminal", Vector3(1.35, 0, -1.88), -19)

	sign_text("BulkheadStencil", "S E C T O R   0 3   /   C O N T A I N M E N T", Vector3(-2, 3.27, -3.735), 40)
	sign_text("ServiceStencil", "AIR RETURN  /  B-04", Vector3(2.75, 1.89, -2.64), 35)
	sign_text("FloorStencil", "03", Vector3(-2, 0.009, -2.81), 90, Vector3(-90, 0, 0))
	sign_text("TerminalStencil", "ACCESS", Vector3(1.39, 1.42, -1.6), 14,
		Vector3(0, -19, 0))

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#11191d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#91adbf")
	environment.ambient_light_energy = 0.29
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add(piece, world, "Environment")

	spot("EntryLight", Vector3(1.9, 4.15, 2.9), Vector3(-1.8, 0.9, -3.9),
		Color("#c3e4fa"), 4.6, 14.0, 57.0)
	spot("GrazingLight", Vector3(-0.45, 3.91, -1.55), Vector3(-3.48, 1.4, -1),
		Color("#96cbd9"), 2.6, 8.0, 55.0)
	spot("ServiceLight", Vector3(2.9, 3.72, -1.3), Vector3(2.02, 0.92, -2.76),
		Color("#ffe1a8"), 2.3, 5.5, 62.0)
	spot("ContainmentLight", Vector3(-2.1, 3.56, -5.7), Vector3(-2.06, 0.91, -7.1),
		Color("#fa7948"), 4.0, 7.0, 58.0)
	spot("FillLight", Vector3(-2.0, 3.7, 4.2), Vector3(0.72, 0.64, -0.5),
		Color("#d2e2ee"), 1.55, 10.0, 56.0, false)
	camera("CorridorCamera", Vector3(2.35, 2.06, 4.95), Vector3(-0.85, 1.91, -3.9), 53.0, true)
	camera("ServiceCamera", Vector3(-2.99, 2.42, 2.85), Vector3(0.58, 1.88, -3.33), 53.0, false)
	pack("kit_preview.tscn")


func sign_text(node_name: String, caption: String, position: Vector3, font_size: int,
		rotation: Vector3 = Vector3.ZERO) -> void:
	var text := Label3D.new()
	text.text = caption
	text.position = position
	text.rotation_degrees = rotation
	text.font_size = font_size
	text.pixel_size = 0.0018
	text.outline_size = 0
	text.modulate = Color("#d1bf95")
	add(piece, text, node_name)


func spot(node_name: String, position: Vector3, target: Vector3, color: Color, energy: float,
		distance: float, angle: float, shadows: bool = true) -> void:
	var light := SpotLight3D.new()
	light.transform = Transform3D(Basis.looking_at(target - position), position)
	light.light_color = color
	light.light_energy = energy
	light.spot_range = distance
	light.spot_angle = angle
	light.shadow_enabled = shadows
	light.shadow_bias = 0.16
	light.shadow_normal_bias = 2.1
	add(piece, light, node_name)


func camera(node_name: String, position: Vector3, target: Vector3, fov: float, current: bool) -> void:
	var view := Camera3D.new()
	view.transform = Transform3D(Basis.looking_at(target - position), position)
	view.fov = fov
	view.current = current
	add(piece, view, node_name)
