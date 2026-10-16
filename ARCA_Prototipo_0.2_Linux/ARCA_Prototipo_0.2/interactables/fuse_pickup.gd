extends Area3D

# Il quadro elettrico potrà ascoltare questo segnale nel prossimo passo.
signal collected

@onready var prompt: Label3D = $Prompt

var player_nearby: bool = false
var is_collected: bool = false


func _ready() -> void:
	# Rileva il livello fisico 2, usato dal giocatore nel prototipo ARCA.
	collision_layer = 0
	collision_mask = 2
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby or is_collected:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		is_collected = true
		get_viewport().set_input_as_handled()
		print("Fusibile raccolto")
		collected.emit()
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("arca_player"):
		player_nearby = true
		prompt.show()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("arca_player"):
		player_nearby = false
		prompt.hide()
