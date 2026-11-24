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
	hud.bind_ammo(player.ammo_component)
	hud.bind_predators(get_predators, player)
	player.health_component.died.connect(_on_player_died)
	enemy.exploded.connect(_on_enemy_destroyed)
	# The primary enemy keeps its dedicated handler; every other predator in the
	# room is tracked through the shared group so lifecycle calls reach all of them.
	for predator: ArcaRaptor in get_predators():
		register_predator(predator)
	hud.restart_requested.connect(restart_room)
	hud.resume_requested.connect(set_paused.bind(false))
	hud.quit_requested.connect(_quit_game)
	hud.pause_requested.connect(func(): set_paused(not paused))
	# A robot is intentionally used to validate the original hit/laser pipeline.
	hud.set_status("Neutralize the test robot. Use the blocks as cover.")


## Every predator belonging to this room, including the primary `enemy` when it is one.
func get_predators() -> Array[ArcaRaptor]:
	var result: Array[ArcaRaptor] = []
	for node: Node in get_tree().get_nodes_in_group("arca_predator"):
		if node is ArcaRaptor and is_ancestor_of(node) and not node.is_queued_for_deletion():
			result.append(node)
	return result


## Track a predator that is not the primary enemy. Safe to call more than once.
func register_predator(predator: ArcaRaptor) -> void:
	if predator == enemy or predator.exploded.is_connected(_on_predator_destroyed):
		return
	predator.exploded.connect(_on_predator_destroyed)


func stop_all_predators() -> void:
	for predator: ArcaRaptor in get_predators():
		predator.stop_combat()


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
	stop_all_predators()
	if not is_instance_valid(enemy):
		hud.show_death(get_mission_summary())
		return
	if enemy.has_method("stop_combat"):
		enemy.stop_combat()
		hud.show_death(get_mission_summary())
		return
	enemy.player = null
	enemy.set_physics_process(false)
	enemy.get_node("ShootAnimation").stop()
	hud.show_death(get_mission_summary())


func get_mission_summary() -> Dictionary:
	return {}


func _on_enemy_destroyed() -> void:
	hud.set_status("TEST COMPLETE  /  Movement, aiming and damage connected. Press Backspace to restart.")


func _on_predator_destroyed() -> void:
	pass


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
