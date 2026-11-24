class_name ArcaCheckpoint
extends ArcaInteractionPoint
## The checkpoint is session memory and is only carried across an explicit retry.

static var snapshot: Dictionary = {}
static var retry_pending: bool = false


func interact(room: Node) -> bool:
	return room.save_checkpoint(global_transform)
