extends ArcaInteractionPoint

signal powered
var is_powered: bool = false

func _ready() -> void:
	super._ready()
	$Indicator.material_override = $Indicator.material_override.duplicate()

func get_prompt(room: Node) -> String:
	if not room.has_fuse:
		return "Inspect panel - fuse missing"
	return action_text

func interact(room: Node) -> bool:
	if activate(room.has_fuse):
		return true
	room._notify("Fuse missing. Search the marked service corridor.")
	return false

func activate(has_fuse: bool) -> bool:
	if is_powered or not has_fuse:
		return false
	restore_powered()
	powered.emit()
	return true


func restore_powered() -> void:
	is_powered = true
	enabled = false
	$Status.text = "POWER RESTORED"
	$Status.modulate = Color(0.45, 1.0, 0.7)
	$Indicator.material_override.albedo_color = Color(0.15, 0.9, 0.5)
