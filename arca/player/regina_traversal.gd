extends RefCounted
## Measures the top and sweeps the same two-stage ballistic path used by the TPS body.

class Arc extends RefCounted:
	var vertical: float
	var drift: Vector3
	var delay: float
	var target: Vector3

const MAX_APPROACH := 1.46


static func launch(actor: CharacterBody3D, capsule: CollisionShape3D, direction: Vector3) -> Arc:
	if direction.length_squared() < 0.04:
		return null
	var candidate: ArcaRaptorJumpPoint
	var best := MAX_APPROACH * MAX_APPROACH
	for point: ArcaRaptorJumpPoint in actor.get_tree().get_nodes_in_group("arca_regina_jump"):
		if point.get_world_3d() != actor.get_world_3d():
			continue
		var distance := actor.global_position.distance_squared_to(point.global_position)
		if distance >= best:
			continue
		var toward := (point.landing.global_position - actor.global_position).slide(Vector3.UP).normalized()
		if direction.dot(toward) > 0.65:
			candidate = point
			best = distance
	if candidate == null or not candidate.available(actor):
		return null
	var target := candidate.landing.global_position
	target.x = candidate.global_position.x
	return _safe_arc(actor, capsule, target)


static func _safe_arc(actor: CharacterBody3D, capsule: CollisionShape3D, target: Vector3) -> Arc:
	var space := actor.get_world_3d().direct_space_state
	var floor := space.intersect_ray(PhysicsRayQueryParameters3D.create(target + Vector3.UP * 0.24,
		target + Vector3.DOWN * 0.20, 1, [actor.get_rid()]))
	if floor.is_empty() or floor.normal.y < 0.8:
		return null
	target.y = floor.position.y + 0.060
	var offset := target - actor.global_position
	var horizontal := offset.slide(Vector3.UP)
	if offset.y < 0.37 or offset.y > 1.15 or horizontal.length() > 3.25:
		return null
	var shape := capsule.shape as CapsuleShape3D
	for axis: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var edge := target + axis * shape.radius * 0.94
		var support := space.intersect_ray(PhysicsRayQueryParameters3D.create(edge + Vector3.UP * 0.12,
			edge + Vector3.DOWN * 0.18, 1, [actor.get_rid()]))
		if support.is_empty() or absf(support.position.y - floor.position.y) > 0.075:
			return null
	var flight := 0.80
	var arc := Arc.new()
	arc.delay = 0.28 if horizontal.length() < 1.68 else 0.0
	arc.drift = horizontal / (flight - arc.delay)
	arc.vertical = (offset.y - actor.get_gravity().y * 0.5 * flight * flight) / flight
	arc.target = target
	var probe := _probe(actor, capsule)
	var start := probe.transform.origin
	probe.transform.origin += Vector3.UP * 0.025
	for slice in range(1, 17):
		var time := flight * slice / 16.0
		var height := arc.vertical * time + actor.get_gravity().y * 0.5 * time * time
		var position := start + arc.drift * maxf(0.0, time - arc.delay) + Vector3.UP * height
		probe.motion = position - probe.transform.origin
		if space.cast_motion(probe)[0] < 0.998:
			return null
		probe.transform.origin = position
		if not space.intersect_shape(probe, 1).is_empty():
			return null
	return arc


static func occupied(actor: CharacterBody3D, capsule: CollisionShape3D, target: Vector3) -> bool:
	var probe := _probe(actor, capsule)
	probe.transform.origin += target - actor.global_position
	return not actor.get_world_3d().direct_space_state.intersect_shape(probe, 1).is_empty()


static func _probe(actor: CharacterBody3D, capsule: CollisionShape3D) -> PhysicsShapeQueryParameters3D:
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = capsule.shape
	probe.transform = capsule.global_transform
	probe.exclude = [actor.get_rid()]
	probe.collision_mask = actor.collision_mask
	return probe
