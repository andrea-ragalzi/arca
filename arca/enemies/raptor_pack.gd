class_name ArcaRaptorPack
extends Node
## Encounter-scoped acoustic events and exclusive spatial reservations.

signal vocalized(source: ArcaRaptor, position: Vector3, cue: StringName)

var reservations: Dictionary[int, Dictionary] = {}


func claim(actor: ArcaRaptor, kind: StringName, position: Vector3, radius: float) -> bool:
	if occupied(actor, position, radius):
		return false
	var claims: Dictionary = reservations.get(actor.get_instance_id(), {})
	claims[kind] = {"position": position, "radius": radius}
	reservations[actor.get_instance_id()] = claims
	return true


func occupied(actor: ArcaRaptor, position: Vector3, radius: float) -> bool:
	for key: int in reservations:
		if key == actor.get_instance_id() or not is_instance_id_valid(key):
			continue
		for claim_data: Dictionary in reservations[key].values():
			var separation: float = maxf(radius, claim_data.radius)
			if position.distance_squared_to(claim_data.position) < separation * separation:
				return true
	return false


func release(actor: ArcaRaptor, kind: StringName = &"") -> void:
	var key := actor.get_instance_id()
	if not reservations.has(key):
		return
	if kind != &"":
		reservations[key].erase(kind)
	if kind == &"" or reservations[key].is_empty():
		reservations.erase(key)


func listener_for(source: ArcaRaptor) -> ArcaRaptor:
	var closest: ArcaRaptor
	var best := source.behavior.call_range * source.behavior.call_range
	for actor: ArcaRaptor in get_parent().get_predators():
		if actor == source or actor.voice_variant == source.voice_variant or not actor.can_receive_call():
			continue
		var distance := source.global_position.distance_squared_to(actor.global_position)
		if distance < best:
			best = distance
			closest = actor
	return closest


func emit_voice(source: ArcaRaptor, position: Vector3, cue: StringName) -> void:
	vocalized.emit(source, position, cue)
	if cue == &"call":
		var listener := listener_for(source)
		if listener != null:
			listener.receive_pack_call(source, position)
