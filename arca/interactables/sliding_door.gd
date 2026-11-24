extends Node3D
## Move the door mesh and collision together using a Tween.

signal opened

const OPEN_HEIGHT: float = 5.3
var is_open: bool = false
var is_opening: bool = false

func open() -> void:
	if is_open or is_opening:
		return
	is_opening = true
	$Servo.play()
	$Status.text = "OPENING"
	$Status.modulate = Color(0.45, 1.0, 0.7)
	var tween := create_tween()
	tween.tween_property($DoorBody, "position:y", OPEN_HEIGHT, 1.0).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func():
		_mark_open()
		opened.emit())


func restore_open() -> void:
	$DoorBody.position.y = OPEN_HEIGHT
	$DoorBody.reset_physics_interpolation()
	_mark_open()


func _mark_open() -> void:
	is_open = true
	is_opening = false
	$Status.text = "EXIT UNLOCKED"
	$Status.modulate = Color(0.45, 1.0, 0.7)
