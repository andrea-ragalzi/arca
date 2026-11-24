class_name ArcaRaptorJumpSurface
extends Node3D
## Fits a walkable top and directional links to a rectangular test-bay fixture.

var deck_height: float
var half_width: float
var half_depth: float


func contains_top(world_position: Vector3, height_margin: float = 0.21) -> bool:
	var local := to_local(world_position)
	return (absf(local.y - deck_height) <= height_margin and absf(local.x) <= half_width + 0.13
		and absf(local.z) <= half_depth + 0.13)


func configure(cover: StaticBody3D, top: MeshInstance3D, stripe: MeshInstance3D, height: float) -> void:
	cover.add_to_group("arca_metal")
	var shape_node := cover.get_node("Collision") as CollisionShape3D
	var shape := shape_node.shape.duplicate() as BoxShape3D
	shape.size.y = height
	deck_height = height
	half_width = shape.size.x * 0.5
	half_depth = shape.size.z * 0.5
	add_to_group("arca_raptor_deck")
	shape_node.shape = shape
	cover.position.y = height * 0.5
	var body := cover.get_node("Mesh") as MeshInstance3D
	var mesh := body.mesh.duplicate() as BoxMesh
	mesh.size = shape.size
	body.mesh = mesh
	top.position.y = height
	stripe.position.y = height - 0.17
	position = cover.position.slide(Vector3.UP)
	if name == &"Desk":
		_add_player_ramp(height, mesh.material)
	var deck := NavigationRegion3D.new()
	deck.position.y = height + 0.023
	var nav := NavigationMesh.new()
	nav.cell_size = 0.2
	nav.cell_height = 0.2
	nav.vertices = PackedVector3Array([
		Vector3(-0.75, 0, -0.41), Vector3(0.75, 0, -0.41),
		Vector3(0.75, 0, 0.41), Vector3(-0.75, 0, 0.41)])
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	deck.navigation_mesh = nav
	deck.use_edge_connections = false
	add_child(deck)
	for side: float in [-1.0, 1.0]:
		var floor_point := Vector3(0, 0, side * 2.37)
		var deck_point := Vector3(side * 0.43, height + 0.04, 0)
		_add_jump(floor_point, deck_point, "Up" if side < 0.0 else "UpFar")
		_add_jump(deck_point, floor_point, "Down" if side > 0.0 else "DownNear")


func _add_jump(start: Vector3, finish: Vector3, point_name: String) -> void:
	var link := NavigationLink3D.new()
	link.navigation_layers = 2
	link.bidirectional = false
	link.start_position = start
	link.end_position = finish
	add_child(link)
	var point := ArcaRaptorJumpPoint.new()
	point.name = point_name
	if finish.y > start.y:
		point.add_to_group("arca_regina_jump")
	point.position = start
	point.link = link
	var landing := Marker3D.new()
	landing.position = finish - start
	point.add_child(landing)
	point.landing = landing
	add_child(point)

func _add_player_ramp(height: float, material: Material) -> void:
	var run := 1.95
	var ramp := StaticBody3D.new()
	ramp.name = "AccessRamp"
	ramp.position = Vector3(1.2 + run * 0.5, height * 0.5 - 0.047, 0)
	ramp.rotation.z = -atan2(height, run)
	var size := Vector3(Vector2(run, height).length(), 0.10, 0.94)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	ramp.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	visual.mesh = mesh
	ramp.add_child(visual)
	add_child(ramp)
