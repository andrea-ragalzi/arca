extends ArcaInteractionPoint
## A station log stays in the world so it can be read again.

@export var title: String = "Continuity Station Log"
@export_multiline var body: String = ""


func interact(room: Node) -> bool:
	room.set_paused(true)
	room.hud.show_note(title, body)
	return true
