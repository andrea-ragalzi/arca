extends Control

const PACK_ARENA := "res://arca/pack_arena.tscn"
const MISSION := "res://arca/mission_room.tscn"

@onready var new_game: Button = %NewGame
@onready var controls_text: Label = %ControlsText


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	new_game.pressed.connect(_start_scene.bind(MISSION))
	%PackTraining.pressed.connect(_start_scene.bind(PACK_ARENA))
	%Controls.pressed.connect(func(): controls_text.visible = not controls_text.visible)
	%Quit.pressed.connect(get_tree().quit)
	new_game.grab_focus()


func _start_scene(scene_path: String) -> void:
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Cannot load ARCA scene: " + error_string(result))
