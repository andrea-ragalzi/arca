extends RefCounted
## Gameplay-only costume fitted to the imported neutral figure. It shares the original Skin.

const FABRIC := Color(0.076, 0.088, 0.102)
const ARMOR := Color(0.125, 0.137, 0.149)
const STRAP := Color(0.14, 0.133, 0.122)
const RED := Color(0.42, 0.065, 0.075)
const STEEL := Color(0.38, 0.38, 0.37)

static var suit: ArrayMesh
static var gear: Dictionary[Vector3, Mesh] = {}
var figure: Node3D
var skeleton: Skeleton3D
var materials: Dictionary[Color, StandardMaterial3D] = {}


func fit(model: Node3D, rig: Skeleton3D) -> void:
	figure = model
	skeleton = rig
	var body: MeshInstance3D = _body_mesh()
	if body == null:
		return
	_darken_legacy_gear()
	if suit == null:
		suit = _make_suit(body)
	body.mesh = suit
	var torso := _joint("spine upper_05", "FieldHarness")
	_part(torso, "FieldPack", Vector3(0, 1.314, 0.131), Vector3(0.254, 0.311, 0.119), FABRIC)
	_part(torso, "PackPanel", Vector3(0, 1.312, 0.190), Vector3(0.217, 0.267, 0.041), ARMOR)
	_part(torso, "GrabLoop", Vector3(0, 1.474, 0.156), Vector3(0.08, 0.019, 0.03), STRAP)
	for index: int in 5:
		var y := 1.212 + 0.043 * index
		_part(torso, "Webbing%d" % index, Vector3(0, y, 0.213), Vector3(0.204, 0.015, 0.014), STRAP)
	_part(torso, "PullTab", Vector3(0.011, 1.389, 0.223), Vector3(0.022, 0.057, 0.006), RED)
	for side: float in [-1.0, 1.0]:
		_part(torso, "ShoulderStrap", Vector3(side * 0.119, 1.432, -0.100), Vector3(0.031, 0.156, 0.022), STRAP)
		_part(torso, "StrapBuckle", Vector3(side * 0.12, 1.387, -0.129), Vector3(0.041, 0.027, 0.018), STEEL)
	_part(torso, "ChestStrap", Vector3(0, 1.394, -0.167), Vector3(0.218, 0.023, 0.014), STRAP)
	_part(torso, "ChestBuckle", Vector3(0, 1.394, -0.179), Vector3(0.049, 0.033, 0.012), STEEL)
	_part(torso, "CollarFront", Vector3(0, 1.505, -0.031), Vector3(0.116, 0.066, 0.105), FABRIC)
	_part(torso, "CollarTrim", Vector3(0, 1.531, -0.086), Vector3(0.111, 0.012, 0.012), RED)
	var belt := _joint("root hips_02", "UtilityBelt")
	_part(belt, "Belt", Vector3(0, 1.003, -0.036), Vector3(0.287, 0.045, 0.195), STRAP)
	_part(belt, "BeltBuckle", Vector3(0, 1.005, -0.142), Vector3(0.067, 0.045, 0.023), STEEL)
	for side: float in [-1.0, 1.0]:
		_part(belt, "Pouch", Vector3(0.136 * side, 0.967, -0.105), Vector3(0.065, 0.105, 0.067), FABRIC)
	_fit_limb_details()
	var shoulder := _joint("arm right shoulder 2_019", "UnitPatchMount")
	_part(shoulder, "SORTPatch", Vector3(0.207, 1.479, -0.045), Vector3(0.016, 0.079, 0.079), ARMOR)
	_patch_text(shoulder, Vector3(0.216, 1.479, -0.045), "▲\nS.O.R.T.")


func _body_mesh() -> MeshInstance3D:
	for mesh: MeshInstance3D in figure.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null or mesh.mesh.get_surface_count() != 1:
			continue
		var material := mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if material != null and material.resource_name.begins_with("24_reginau1"):
			return mesh
	return null



func _darken_legacy_gear() -> void:
	for mesh: MeshInstance3D in figure.find_children("*", "MeshInstance3D", true, false):
		var material := mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if material != null and (material.resource_name.begins_with("24_costume.") or
				material.resource_name.begins_with("24_holster.") or material.resource_name.begins_with("25_4tga")):
			var textile := material.duplicate() as StandardMaterial3D
			textile.albedo_color = Color(0.35, 0.39, 0.45)
			textile.metallic = 0.06
			textile.roughness = 0.79
			mesh.set_surface_override_material(0, textile)


func _make_suit(body: MeshInstance3D) -> ArrayMesh:
	var source := body.mesh
	var arrays := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var transforms: Array[Transform3D] = []
	for index in body.skin.get_bind_count():
		var bone := skeleton.find_bone(body.skin.get_bind_name(index))
		transforms.append(skeleton.global_transform * skeleton.get_bone_global_rest(bone) * body.skin.get_bind_pose(index))
	var colors := PackedColorArray()
	var stride := int(float(bones.size()) / vertices.size())
	for index in vertices.size():
		var world := Vector3.ZERO
		for slot in stride:
			var offset := index * stride + slot
			world += (transforms[bones[offset]] * vertices[index]) * weights[offset]
		var p := figure.to_local(world)
		var shade := FABRIC.lerp(ARMOR, 0.24 + 0.12 * sin(p.y * 124.0 + p.x * 31.0))
		if (p.y < 0.83 and p.y > 0.21 and absf(p.x) > 0.169 and absf(p.z) < 0.075) or (
				absf(p.x) > 0.32 and absf(p.x) < 0.56 and p.z < -0.085):
			shade = RED
		elif p.y < 0.235 or absf(p.x) > 0.59:
			shade = FABRIC.darkened(0.27)
		colors.append(shade)
	arrays[Mesh.ARRAY_COLOR] = colors
	var fitted := ArrayMesh.new()
	var flags: int = source.surface_get_format(0) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	fitted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	var textile := StandardMaterial3D.new()
	textile.resource_name = "ARCA Field Suit"
	textile.vertex_color_use_as_albedo = true
	textile.vertex_color_is_srgb = true
	textile.roughness = 0.83
	fitted.surface_set_material(0, textile)
	return fitted


func _fit_limb_details() -> void:
	for side: float in [-1.0, 1.0]:
		var right := side > 0.0
		var knee := _joint("leg right knee_060" if right else "leg left knee_064", "KneeArmor")
		_part(knee, "KneeShell", Vector3(side * 0.112, 0.595, -0.101), Vector3(0.104, 0.126, 0.041), ARMOR)
		_part(knee, "KneeRim", Vector3(side * 0.112, 0.539, -0.117), Vector3(0.094, 0.016, 0.024), RED)
		var ankle := _joint("leg right ankle_061" if right else "leg left ankle_065", "FieldBoot")
		_part(ankle, "BootSole", Vector3(side * 0.135, 0.028, -0.053), Vector3(0.092, 0.031, 0.165), FABRIC)
		_part(ankle, "BootVamp", Vector3(side * 0.135, 0.082, -0.061), Vector3(0.087, 0.063, 0.142), ARMOR)
		_part(ankle, "BootCuff", Vector3(side * 0.134, 0.142, 0.002), Vector3(0.081, 0.084, 0.091), FABRIC)
		for index: int in 3:
			_part(ankle, "Lace%d" % index, Vector3(side * 0.136, 0.119, -0.04 - 0.013 * index),
				Vector3(0.057, 0.009, 0.007), STRAP)
		var elbow := _joint("arm right elbow_020" if right else "arm left elbow_039", "ForearmGuard")
		_part(elbow, "Guard", Vector3(side * 0.476, 1.384, -0.072), Vector3(0.133, 0.044, 0.066), ARMOR)
		_part(elbow, "GuardStripe", Vector3(side * 0.476, 1.403, -0.102), Vector3(0.092, 0.014, 0.014), RED)


func _joint(bone_name: String, node_name: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = node_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	return attachment


func _rest_mount(joint: BoneAttachment3D, position: Vector3) -> Transform3D:
	var rest := skeleton.get_bone_global_rest(joint.bone_idx)
	return (skeleton.global_transform * rest).affine_inverse() * figure.global_transform * Transform3D(Basis.IDENTITY, position)


func _part(joint: BoneAttachment3D, part_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	if not materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.73
		materials[color] = material
	if not gear.has(size):
		gear[size] = _beveled_mesh(size)
	part.mesh = gear[size]
	part.material_override = materials[color]
	part.transform = _rest_mount(joint, position)
	joint.add_child(part)
	return part


func _beveled_mesh(size: Vector3) -> Mesh:
	var half := size * 0.5
	var bevel := minf(0.018, minf(half.x, minf(half.y, half.z)) * 0.69)
	if bevel < 0.005:
		var flat := BoxMesh.new()
		flat.size = size
		return flat
	var inner := half - Vector3.ONE * bevel
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
	for axis in 3:
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		var columns := [-half[u], -inner[u], inner[u], half[u]]
		var rows := [-half[v], -inner[v], inner[v], half[v]]
		for direction: float in [-1.0, 1.0]:
			for col in 3:
				for row in 3:
					for corner: Vector2i in corners:
						var position := Vector3.ZERO
						position[axis] = direction * half[axis]
						position[u] = columns[col + corner.x]
						position[v] = rows[row + (corner.y if direction > 0.0 else 1 - corner.y)]
						var center := position.clamp(-inner, inner)
						var normal := (position - center).normalized()
						surface.set_normal(normal)
						surface.add_vertex(center + normal * bevel)
	return surface.commit()


func _patch_text(joint: BoneAttachment3D, position: Vector3, text: String) -> void:
	var patch := Label3D.new()
	patch.name = "UnitMark"
	patch.text = text
	patch.font_size = 40
	patch.pixel_size = 0.00048
	patch.outline_size = 3
	patch.modulate = Color(0.8, 0.18, 0.23)
	patch.transform = _rest_mount(joint, position) * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
	joint.add_child(patch)
