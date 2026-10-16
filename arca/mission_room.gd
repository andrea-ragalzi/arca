extends "res://arca/raptor_room.gd"
## Mission flow: minimal inventory, objectives and signal connections.

signal ambush_started

enum AmbushPhase { IDLE, WARNING, OPENING, EMERGING, ACTIVE, CANCELLED }

const HATCH_OPEN_DURATION: float = 1.0
const HATCH_LIFT: float = 3.3

@export var ambush_delay: float = 1.4
@onready var fuse: ArcaInteractionPoint = $FusePickup
@onready var panel: ArcaInteractionPoint = $PowerPanel
@onready var door: Node3D = $ExitDoor
@onready var hatch: AnimatableBody3D = $ServiceHatch/Leaf
var has_fuse: bool = false
var power_restored: bool = false
var mission_complete: bool = false
var interaction_target: ArcaInteractionPoint
var notice_remaining: float = 0.0
var ambush_remaining: float = -1.0
var ambush_triggered: bool = false
var ambush_phase: AmbushPhase = AmbushPhase.IDLE
var hatch_elapsed: float = 0.0
var hatch_closed_y: float

func _ready() -> void:
	super._ready()
	player.player_input.camera_base.rotation.y = 1.1
	enemy.position = $AmbushSpawn.position
	enemy.prepare_ambush()
	hatch_closed_y = hatch.position.y
	fuse.collected.connect(_on_fuse_pickup_collected)
	panel.powered.connect(_on_panel_powered)
	$ExitZone.body_entered.connect(_on_exit_entered)
	door.opened.connect(_on_door_opened)
	hud.get_node("Frame/Subtitle").text = "CONTINUITY STATION   /   POWER RESTORATION"
	hud.get_node("Frame/Tag").text = "MAINTENANCE SECTOR / POWER RESTORATION\nTEMPORARY ART AND ENVIRONMENT"
	hud.get_node("Frame/Controls").text = "WASD  move    /    MOUSE  camera\nRMB  aim    /    LMB  fire    /    SPACE  jump\nE  interact    /    R  restart    /    ESC  pause"
	_update_objective()
	_notify("Find the marked service corridor. Search inside for the fuse.")

func _physics_process(delta: float) -> void:
	if mission_complete or player.health_component.current <= 0:
		return
	_advance_ambush(delta)
	interaction_target = _find_interaction_target()
	var text: String = ""
	if is_instance_valid(interaction_target):
		text = "[ E ]  " + interaction_target.action_text
		if interaction_target == panel and not has_fuse:
			text = "[ E ]  Inspect panel - fuse missing"
	hud.set_interaction(text)
	if notice_remaining > 0.0:
		notice_remaining -= delta
		if notice_remaining <= 0.0:
			hud.set_notice("")

func _advance_ambush(delta: float) -> void:
	match ambush_phase:
		AmbushPhase.WARNING:
			ambush_remaining = maxf(ambush_remaining - delta, 0.0)
			$AlarmLight.light_energy = 1.8 + sin(Time.get_ticks_msec() * 0.012) * 1.2
			if ambush_remaining == 0.0:
				ambush_remaining = -1.0
				ambush_phase = AmbushPhase.OPENING
				_notify("SERVICE HATCH OPENING - stand clear! Fight or reach the green exit.")
		AmbushPhase.OPENING:
			hatch_elapsed = minf(hatch_elapsed + delta, HATCH_OPEN_DURATION)
			var progress: float = smoothstep(0.0, HATCH_OPEN_DURATION, hatch_elapsed)
			hatch.position.y = hatch_closed_y + HATCH_LIFT * progress
			if hatch_elapsed >= HATCH_OPEN_DURATION:
				_start_ambush()
		AmbushPhase.EMERGING:
			if enemy.state != ArcaRaptor.State.EMERGE:
				ambush_phase = AmbushPhase.ACTIVE

func _cancel_ambush() -> void:
	ambush_remaining = -1.0
	ambush_phase = AmbushPhase.CANCELLED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		if try_interact():
			get_viewport().set_input_as_handled()

func _find_interaction_target() -> ArcaInteractionPoint:
	var nearest: ArcaInteractionPoint = null
	var nearest_distance: float = INF
	for point in [fuse, panel]:
		if not is_instance_valid(point) or not point.is_available_to(player):
			continue
		var distance: float = point.global_position.distance_squared_to(player.global_position)
		if distance < nearest_distance:
			nearest = point
			nearest_distance = distance
	return nearest

func try_interact() -> bool:
	if get_tree().paused or mission_complete or player.health_component.current <= 0:
		return false
	interaction_target = _find_interaction_target()
	if not is_instance_valid(interaction_target):
		return false
	if interaction_target == fuse:
		fuse.collect()
	elif interaction_target == panel:
		if not panel.activate(has_fuse):
			_notify("Fuse missing. Search the marked service corridor.")
	return true

func _on_fuse_pickup_collected() -> void:
	has_fuse = true
	$PickupSound.play()
	hud.set_interaction("")
	_update_objective()
	_notify("FUSE COLLECTED - retrace the corridor to the main room and power panel.")
	print("Fuse collected: inventory updated")

func _on_panel_powered() -> void:
	if power_restored or mission_complete or player.health_component.current <= 0:
		return
	has_fuse = false
	power_restored = true
	$PowerSound.play()
	door.open()
	hud.set_interaction("")
	_update_objective()
	ambush_remaining = maxf(ambush_delay, 0.0)
	ambush_phase = AmbushPhase.WARNING
	$AlarmLight.show()
	$BreachWarning.show()
	_notify("POWER RESTORED - containment failure! Watch the marked service hatch.")

func _on_door_opened() -> void:
	if ambush_phase == AmbushPhase.IDLE:
		_notify("Door open. Reach the green exit marker.")

func _start_ambush() -> void:
	if ambush_phase != AmbushPhase.OPENING or hatch_elapsed < HATCH_OPEN_DURATION:
		return
	if ambush_triggered or mission_complete or player.health_component.current <= 0:
		return
	if enemy.emerge_from_hatch($HatchClearance.global_position):
		ambush_triggered = true
		ambush_phase = AmbushPhase.EMERGING
		_update_objective()
		_notify("PREDATOR EMERGING - fight or reach the green exit!")
		ambush_started.emit()

func _update_objective() -> void:
	if power_restored:
		hud.set_status("03 / Escape through the green door. Fight or evade the predator.")
		hud.set_inventory("FUSE  /  INSTALLED")
	elif has_fuse:
		hud.set_status("02 / Return through the corridor to the power panel on the left.")
		hud.set_inventory("FUSE  /  CARRIED")
	else:
		hud.set_status("01 / Explore the marked service corridor. Find the fuse and press E.")
		hud.set_inventory("FUSE  /  MISSING")

func _notify(message: String) -> void:
	notice_remaining = 4.5
	hud.set_notice(message)

func _on_enemy_destroyed() -> void:
	_cancel_ambush()
	$AlarmLight.hide()
	$BreachWarning.hide()
	_notify("PREDATOR DOWN - continue to the exit.")

func _on_player_died() -> void:
	_cancel_ambush()
	super._on_player_died()
	hud.set_interaction("")
	hud.set_notice("")

func _on_exit_entered(body: Node3D) -> void:
	if body != player or not power_restored or not door.is_open or mission_complete:
		return
	if player.health_component.current <= 0:
		return
	mission_complete = true
	_cancel_ambush()
	enemy.stop_combat()
	stop_audio()
	hud.set_interaction("")
	hud.set_notice("")
	hud.set_status("SECTOR RESTORED / Exit reached.")
	hud.show_success()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func restart_room() -> void:
	_cancel_ambush()
	enemy.stop_combat()
	super.restart_room()

func set_paused(value: bool) -> void:
	if not mission_complete:
		super.set_paused(value)
