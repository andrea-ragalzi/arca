class_name ArcaInteractionPoint
extends Area3D
## Reusable interaction area. The room selects one object per E press.
##
## Contract: every instance joins `GROUP` and the owning room discovers it from
## there. Subclasses override `get_prompt` and `interact`; the room never needs
## to know concrete interactable types.

const GROUP: StringName = &"arca_interactable"

@export var action_text: String = "Interact"
var enabled: bool = true

func _ready() -> void:
	add_to_group(GROUP)

func is_available_to(actor: Node3D) -> bool:
	if not enabled or not overlaps_body(actor):
		return false
	# Walls and cover block interaction through geometry.
	var query := PhysicsRayQueryParameters3D.create(
		actor.global_position + Vector3.UP * 1.4,
		global_position + Vector3.UP * 0.15, 1, [actor.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

## Prompt text shown after "[ E ]" while this point is the nearest target.
func get_prompt(_room: Node) -> String:
	return action_text

## Perform the action for one E press. Return true when the world state changed;
## refusals (with feedback) return false. The base point does nothing.
func interact(_room: Node) -> bool:
	return false
