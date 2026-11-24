extends CanvasLayer

signal restart_requested
signal resume_requested
signal quit_requested
signal pause_requested

@onready var hp_label: Label = $Frame/HealthPanel/Margin/VBox/Health
@onready var health_bar: ProgressBar = $Frame/HealthPanel/Margin/VBox/Bar
@onready var status_label: Label = $Frame/ObjectivePanel/Margin/Objective
@onready var enemy_label: Label = $Frame/Telemetry/Enemy
@onready var fps_label: Label = $Frame/Telemetry/FPS
@onready var modal: Control = $Frame/Modal
@onready var modal_title: Label = $Frame/Modal/Center/Panel/Margin/VBox/Title
@onready var modal_text: Label = $Frame/Modal/Center/Panel/Margin/VBox/Text
@onready var resume_button: Button = $Frame/Modal/Center/Panel/Margin/VBox/Resume
var enemy: CharacterBody3D
var health: ArcaHealth
var ammo: ArcaAmmo
var predators_provider: Callable
var telemetry_origin: Node3D


func _ready() -> void:
	$Frame/Modal/Center/Panel/Margin/VBox/Restart.pressed.connect(func(): restart_requested.emit())
	$Frame/Modal/Center/Panel/Margin/VBox/Resume.pressed.connect(func(): resume_requested.emit())
	$Frame/Modal/Center/Panel/Margin/VBox/Quit.pressed.connect(func(): quit_requested.emit())


func bind(component: ArcaHealth, target: CharacterBody3D) -> void:
	health = component
	enemy = target
	health.changed.connect(_update_health)
	_update_health(health.current, health.max_health)


## Telemetry follows the nearest active predator when the room has several.
func bind_predators(provider: Callable, origin: Node3D) -> void:
	predators_provider = provider
	telemetry_origin = origin


func _telemetry_target() -> CharacterBody3D:
	if not predators_provider.is_valid() or not is_instance_valid(telemetry_origin):
		return enemy
	var nearest: CharacterBody3D = null
	var nearest_distance: float = INF
	for predator: ArcaRaptor in predators_provider.call():
		if predator.dead or predator.state == ArcaRaptor.State.DORMANT:
			continue
		var distance: float = predator.global_position.distance_squared_to(telemetry_origin.global_position)
		if distance < nearest_distance:
			nearest = predator
			nearest_distance = distance
	return nearest if nearest else enemy


func bind_ammo(component: ArcaAmmo) -> void:
	ammo = component
	ammo.changed.connect(_update_ammo)
	ammo.reload_started.connect(func(): $Frame/AmmoPanel/Margin/VBox/Reload.show())
	$Frame/AmmoPanel.show()
	_update_ammo(ammo.magazine, ammo.reserve)


func _update_ammo(magazine: int, reserve: int) -> void:
	$Frame/AmmoPanel/Margin/VBox/Ammo.text = "AMMO  %02d / %02d" % [magazine, reserve]
	$Frame/AmmoPanel/Margin/VBox/Reload.visible = ammo.reloading


func _process(_delta: float) -> void:
	fps_label.text = "%s  /  %d FPS  /  F3 details" % [RenderingServer.get_current_rendering_method(), Engine.get_frames_per_second()]
	var target: CharacterBody3D = _telemetry_target()
	if is_instance_valid(target):
		if target.has_method("get_status_text"):
			enemy_label.text = target.get_status_text()
		else:
			var state_name: String = ["APPROACH", "AIMING", "FIRING"][target.state]
			enemy_label.text = "TARGET %d/5  /  %s" % [maxi(target.health, 0), "DESTROYED" if target.dead else state_name]
	else:
		enemy_label.text = "TARGET DESTROYED"


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("arca_restart"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quit"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_debug"):
		$Frame/Telemetry.visible = not $Frame/Telemetry.visible


func _update_health(value: int, maximum: int) -> void:
	var damage: bool = value < health_bar.value
	hp_label.text = "HEALTH  %03d / %03d" % [value, maximum]
	health_bar.max_value = maximum
	health_bar.value = value
	if damage:
		$Frame/DamageFlash.color.a = 0.22
		create_tween().tween_property($Frame/DamageFlash, "color:a", 0.0, 0.45)


func set_status(message: String) -> void:
	status_label.text = message


func show_death(summary: Dictionary = {}) -> void:
	modal.show()
	modal_title.text = "SIGNAL LOST"
	modal_text.text = _outcome_text("You were neutralized.", summary)
	resume_button.hide()
	$Frame/Modal/Center/Panel/Margin/VBox/Restart.grab_focus()


func show_pause(value: bool) -> void:
	modal.visible = value
	modal_title.text = "PAUSED"
	modal_text.text = "ARCA / maintenance sector"
	resume_button.show()
	if value:
		resume_button.grab_focus()


func set_interaction(message: String) -> void:
	$Frame/Interaction.text = message
	$Frame/Interaction.visible = not message.is_empty()

func set_inventory(message: String, key_items: Array[StringName] = []) -> void:
	var lines := PackedStringArray([message])
	for item_id: StringName in key_items:
		if item_id != &"fuse":
			lines.append(String(item_id).replace("_", " ").to_upper() + "  /  CARRIED")
	$Frame/Inventory.text = "\n".join(lines)

func set_notice(message: String) -> void:
	$Frame/Notice.text = message
	$Frame/Notice.visible = not message.is_empty()

func show_success(summary: Dictionary = {}) -> void:
	modal.show()
	modal_title.text = "SECTOR RESTORED"
	modal_text.text = _outcome_text("Fuse recovered. Power restored. Exit reached.", summary)
	resume_button.hide()
	$Frame/Modal/Center/Panel/Margin/VBox/Restart.grab_focus()


func _outcome_text(message: String, summary: Dictionary) -> String:
	if not summary.is_empty():
		var seconds: int = floori(summary["seconds"])
		message += "\n\nTIME  %02d:%02d\nSHOTS  %d\nDAMAGE TAKEN  %d HP\nPREDATOR  %s" % [
			floori(seconds / 60.0), seconds % 60, summary["shots"], summary["damage"], summary["predator"],
		]
	return message + "\n\nPress Backspace to restart."
