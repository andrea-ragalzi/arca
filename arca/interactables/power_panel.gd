extends ArcaInteractionPoint

signal powered
var is_powered: bool = false

func _ready() -> void:
	$Indicator.material_override = $Indicator.material_override.duplicate()

func activate(has_fuse: bool) -> bool:
	if is_powered or not has_fuse:
		return false
	is_powered = true
	enabled = false
	$Status.text = "POWER RESTORED"
	$Status.modulate = Color(0.45, 1.0, 0.7)
	$Indicator.material_override.albedo_color = Color(0.15, 0.9, 0.5)
	powered.emit()
	return true
