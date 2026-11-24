class_name ArcaRaptorJumpPoint
extends Marker3D
## Point, support and reservation shared by the local pack.

@export var landing: Marker3D
@export var link: NavigationLink3D
var occupant: CharacterBody3D


func _ready() -> void:
	add_to_group("arca_raptor_jump")


func available(actor: CharacterBody3D) -> bool:
	return not is_instance_valid(occupant) or occupant == actor
