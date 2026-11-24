class_name ArcaReginaBallistics
extends RefCounted
## The game pistol resolves the camera aim against the physical muzzle and cover.

const RANGE := 110.0
const SHOT_MASK := 3
const METAL := Color(1.0, 0.76, 0.38)
const WALL := Color(0.65, 0.61, 0.53)
const PREDATOR := Color(0.60, 0.16, 0.13)

const IMPACTS := {
	&"metal": preload("res://arca/audio/regina/impact_metal.wav"),
	&"wall": preload("res://arca/audio/regina/impact_wall.wav"),
	&"raptor": preload("res://arca/audio/regina/impact_raptor.wav"),
}


static func resolve(body: CharacterBody3D, muzzle: Vector3, aim: Vector3) -> Dictionary:
	var chest := body.global_position + Vector3.UP * 1.4
	var direction := (aim - muzzle).normalized()
	var query := PhysicsRayQueryParameters3D.create(chest, muzzle, SHOT_MASK, [body.get_rid()])
	query.hit_from_inside = true
	var space := body.get_world_3d().direct_space_state
	var collision := space.intersect_ray(query)
	var visual_start := muzzle
	if collision.is_empty():
		query.from = muzzle
		query.to = muzzle + direction * minf(muzzle.distance_to(aim) + 0.14, RANGE)
		collision = space.intersect_ray(query)
	else:
		visual_start = chest.lerp(collision.position, 0.83)
	if collision.is_empty():
		return {"start": visual_start, "end": query.to, "normal": -direction, "surface": &"miss", "collider": null}
	var collider: Node = collision.collider
	var surface: StringName = &"wall"
	if collider is ArcaRaptor:
		surface = &"raptor"
	elif collider.is_in_group("arca_shutter") or collider.is_in_group("arca_metal") or collider.has_signal("exploded"):
		surface = &"metal"
	var normal: Vector3 = collision.normal if collision.normal.length_squared() > 0.10 else -direction
	return {"start": visual_start, "end": collision.position, "normal": normal, "surface": surface, "collider": collider}


static func muzzle_particles(spark: bool) -> CPUParticles3D:
	var tint := Color(1.0, 0.63, 0.25) if spark else Color(1.0, 0.89, 0.60)
	var emitter := _particles(tint, 0.024 if spark else 0.052, 4 if spark else 2)
	emitter.name = "ShootParticle" if spark else "MuzzleFlash"
	emitter.direction = Vector3.FORWARD
	emitter.spread = 18.0
	emitter.lifetime = 0.055
	emitter.initial_velocity_min = 3.0 if spark else 0.45
	emitter.initial_velocity_max = 5.0 if spark else 0.85
	emitter.local_coords = true
	return emitter


static func present(room: Node, packet: Dictionary) -> void:
	var start: Vector3 = packet.start
	var end: Vector3 = packet.end
	var offset := end - start
	var effects := Node3D.new()
	effects.name = "ReginaShotEffects"
	room.add_child(effects)
	effects.global_position = start
	if offset.length_squared() > 0.09:
		var tracer := MeshInstance3D.new()
		var mesh := ImmediateMesh.new()
		var glow := _material(Color(0.95, 0.75, 0.44, 0.58))
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, glow)
		mesh.surface_add_vertex(offset * 0.02)
		mesh.surface_add_vertex(offset * minf(1.0, 2.85 / offset.length()))
		mesh.surface_end()
		tracer.mesh = mesh
		effects.add_child(tracer)
		effects.get_tree().create_timer(0.043, false).timeout.connect(tracer.queue_free)
	if packet.surface != &"miss":
		var color: Color = METAL if packet.surface == &"metal" else (PREDATOR if packet.surface == &"raptor" else WALL)
		var emitter := _particles(color, 0.018 if packet.surface == &"metal" else 0.037, 7)
		emitter.direction = packet.normal
		emitter.spread = 35.0 if packet.surface == &"metal" else 57.0
		emitter.initial_velocity_min = 1.0
		emitter.initial_velocity_max = 4.1 if packet.surface == &"metal" else 1.8
		effects.add_child(emitter)
		emitter.position = offset + Vector3(packet.normal) * 0.012
		emitter.restart()
		emitter.emitting = true
		var sound := AudioStreamPlayer3D.new()
		sound.stream = IMPACTS[packet.surface]
		sound.position = offset
		sound.volume_db = -14.0
		sound.max_distance = 22.0
		sound.unit_size = 3.5
		effects.add_child(sound)
		sound.play()
	room.get_tree().create_timer(0.35, false).timeout.connect(effects.queue_free)


static func _particles(color: Color, size: float, count: int) -> CPUParticles3D:
	var emitter := CPUParticles3D.new()
	emitter.amount = count
	emitter.one_shot = true
	emitter.emitting = false
	emitter.lifetime = 0.21
	emitter.explosiveness = 1.0
	emitter.gravity = Vector3.ZERO
	var primitive := BoxMesh.new()
	primitive.size = Vector3.ONE * size
	primitive.material = _material(color)
	emitter.mesh = primitive
	return emitter


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
