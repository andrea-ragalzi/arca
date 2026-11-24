extends ArcaInteractionPoint
## Reusable pickup for a unique, mission-local key item.

@export var item_id: StringName = &"keycard"
@export var display_name: String = "Keycard"


func get_prompt(_room: Node) -> String:
	return "Collect " + display_name


func interact(room: Node) -> bool:
	if not enabled or not room.add_key_item(item_id):
		return false
	room._collect_supply(self, display_name.to_upper() + " COLLECTED")
	return true
