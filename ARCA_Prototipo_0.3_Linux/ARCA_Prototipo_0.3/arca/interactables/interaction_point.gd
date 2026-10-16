class_name ArcaInteractionPoint
extends Area3D
## Zona riutilizzabile. La stanza sceglie un solo oggetto per ogni pressione di E.

@export var action_text: String = "Interagisci"
var enabled: bool = true

func is_available_to(actor: Node3D) -> bool:
	if not enabled or not overlaps_body(actor):
		return false
	# Una parete o una copertura impediscono di interagire attraverso di esse.
	var query := PhysicsRayQueryParameters3D.create(
		actor.global_position + Vector3.UP * 1.4,
		global_position + Vector3.UP * 0.15, 1, [actor.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
