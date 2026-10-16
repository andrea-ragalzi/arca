extends ArcaInteractionPoint
## Un oggetto nel mondo annuncia la raccolta; la stanza conserva l'inventario.

signal collected

func collect() -> void:
	if not enabled:
		return
	enabled = false
	collected.emit()
	queue_free()
