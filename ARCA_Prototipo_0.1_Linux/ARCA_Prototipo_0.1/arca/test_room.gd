extends Node3D

signal restarted

@onready var player: Player = $Player
@onready var enemy: CharacterBody3D = $RedRobot
@onready var hud: CanvasLayer = $HUD
var restart_pending: bool = false
var paused: bool = false


func _ready() -> void:
	add_to_group("arca_room")
	hud.bind(player.health_component, enemy)
	player.health_component.died.connect(_on_player_died)
	enemy.exploded.connect(_on_enemy_destroyed)
	hud.restart_requested.connect(restart_room)
	hud.resume_requested.connect(set_paused.bind(false))
	hud.quit_requested.connect(_quit_game)
	hud.pause_requested.connect(func(): set_paused(not paused))
	# A robot is intentionally used to validate the original hit/laser pipeline.
	hud.set_status("Neutralizza il robot di collaudo. Usa i blocchi come copertura.")


func set_paused(value: bool) -> void:
	if player.health_component.current <= 0:
		return
	paused = value
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	hud.show_pause(value)


func restart_room() -> void:
	if restart_pending:
		return
	restart_pending = true
	get_tree().paused = false
	stop_audio()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	restarted.emit()
	get_tree().call_deferred("reload_current_scene")


func _on_player_died() -> void:
	# Stop pending animation callbacks and all further enemy attacks.
	enemy.player = null
	enemy.set_physics_process(false)
	enemy.get_node("ShootAnimation").stop()
	hud.show_death()


func _on_enemy_destroyed() -> void:
	hud.set_status("COLLAUDO SUPERATO  /  Movimento, mira e danni collegati. R per ripetere.")


func stop_audio() -> void:
	# Stop animation audio before removing the room during rapid restarts.
	for tree in find_children("*", "AnimationTree", true, false):
		tree.active = false
	for animation in find_children("*", "AnimationPlayer", true, false):
		animation.stop()
	for audio in find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	for audio in find_children("*", "AudioStreamPlayer3D", true, false):
		audio.stop()


func _quit_game() -> void:
	stop_audio()
	get_tree().quit()
