extends Node3D
## Muoviamo insieme mesh e collisione della porta, con un Tween.

signal opened
var is_open: bool = false
var is_opening: bool = false

func open() -> void:
	if is_open or is_opening:
		return
	is_opening = true
	$Status.text = "APERTURA IN CORSO"
	$Status.modulate = Color(0.45, 1.0, 0.7)
	var tween := create_tween()
	tween.tween_property($DoorBody, "position:y", 5.3, 1.0).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func():
		is_open = true
		is_opening = false
		$Status.text = "USCITA SBLOCCATA"
		opened.emit())
