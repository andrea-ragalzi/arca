extends ArcaInteractionPoint
## The world item announces collection; the room owns the inventory.

signal collected

func interact(_room: Node) -> bool:
	if not enabled:
		return false
	collect()
	return true

func collect() -> void:
	if not enabled:
		return
	enabled = false
	collected.emit()
	queue_free()
