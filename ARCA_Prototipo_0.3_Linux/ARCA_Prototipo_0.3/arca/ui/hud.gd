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


func _ready() -> void:
	$Frame/Modal/Center/Panel/Margin/VBox/Restart.pressed.connect(func(): restart_requested.emit())
	$Frame/Modal/Center/Panel/Margin/VBox/Resume.pressed.connect(func(): resume_requested.emit())
	$Frame/Modal/Center/Panel/Margin/VBox/Quit.pressed.connect(func(): quit_requested.emit())


func bind(component: ArcaHealth, target: CharacterBody3D) -> void:
	health = component
	enemy = target
	health.changed.connect(_update_health)
	_update_health(health.current, health.max_health)


func _process(_delta: float) -> void:
	fps_label.text = "%s  /  %d FPS  /  F3 dettagli" % [RenderingServer.get_current_rendering_method(), Engine.get_frames_per_second()]
	if is_instance_valid(enemy):
		if enemy.has_method("get_status_text"):
			enemy_label.text = enemy.get_status_text()
		else:
			var state_name: String = ["AVVICINAMENTO", "MIRA", "TIRO"][enemy.state]
			enemy_label.text = "BERSAGLIO %d/5  /  %s" % [maxi(enemy.health, 0), "DISTRUTTO" if enemy.dead else state_name]
	else:
		enemy_label.text = "BERSAGLIO DISTRUTTO"


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
	hp_label.text = "SALUTE  %03d / %03d" % [value, maximum]
	health_bar.max_value = maximum
	health_bar.value = value
	$Frame/DamageFlash.color.a = 0.22 if value < maximum else 0.0
	create_tween().tween_property($Frame/DamageFlash, "color:a", 0.0, 0.45)


func set_status(message: String) -> void:
	status_label.text = message


func show_death() -> void:
	modal.show()
	modal_title.text = "SEGNALE PERSO"
	modal_text.text = "Sei stato neutralizzato. Il riavvio ripristina salute e bersaglio."
	resume_button.hide()
	$Frame/Modal/Center/Panel/Margin/VBox/Restart.grab_focus()


func show_pause(value: bool) -> void:
	modal.visible = value
	modal_title.text = "COLLAUDO IN PAUSA"
	modal_text.text = "ARCA / settore di manutenzione 01"
	resume_button.show()
	if value:
		resume_button.grab_focus()


func set_interaction(message: String) -> void:
	$Frame/Interaction.text = message
	$Frame/Interaction.visible = not message.is_empty()

func set_inventory(message: String) -> void:
	$Frame/Inventory.text = message

func set_notice(message: String) -> void:
	$Frame/Notice.text = message
	$Frame/Notice.visible = not message.is_empty()

func show_success() -> void:
	modal.show()
	modal_title.text = "SETTORE RIPRISTINATO"
	modal_text.text = "Fusibile recuperato. Quadro alimentato. Uscita raggiunta.\nPrototipo 0.3 completato — R per ricominciare."
	resume_button.hide()
	$Frame/Modal/Center/Panel/Margin/VBox/Restart.grab_focus()
