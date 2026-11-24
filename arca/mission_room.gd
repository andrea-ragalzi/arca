extends "res://arca/raptor_room.gd"
## Mission flow: minimal inventory, objectives and signal connections.

signal ambush_started

enum AmbushPhase { IDLE, WARNING, OPENING, EMERGING, ACTIVE, CANCELLED }

const HATCH_OPEN_DURATION: float = 1.0
const HATCH_LIFT: float = 3.3

@export var ambush_delay: float = 1.4
@onready var fuse: ArcaInteractionPoint = $FusePickup
@onready var panel: ArcaInteractionPoint = $PowerPanel
@onready var ammo_pickup: ArcaInteractionPoint = $AmmoPickup
@onready var medkit_pickup: ArcaInteractionPoint = $MedkitPickup
@onready var door: Node3D = $ExitDoor
@onready var hatch: AnimatableBody3D = $ServiceHatch/Leaf
var key_items: Array[StringName] = []
var has_fuse: bool:
	get:
		return has_key_item(&"fuse")
var power_restored: bool = false
var mission_complete: bool = false
var interaction_target: ArcaInteractionPoint
var _last_interaction_frame: int = -1
var notice_remaining: float = 0.0
var ambush_remaining: float = -1.0
var ambush_triggered: bool = false
var ambush_phase: AmbushPhase = AmbushPhase.IDLE
var hatch_elapsed: float = 0.0
var hatch_closed_y: float
var mission_seconds: float = 0.0
var shots_fired: int = 0
var damage_taken: int = 0
var predators_killed: int = 0

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
	player.shot_fired.connect(func(): shots_fired += 1)
	player.health_component.damaged.connect(func(amount: int): damage_taken += amount)
	hud.get_node("Frame/Subtitle").text = "CONTINUITY STATION   /   POWER RESTORATION"
	hud.get_node("Frame/Tag").text = "MAINTENANCE SECTOR / POWER RESTORATION\nTEMPORARY ART AND ENVIRONMENT"
	hud.get_node("Frame/Controls").text = "WASD  move    /    MOUSE  camera\nRMB  aim    /    LMB  fire    /    SPACE  jump\nE  interact    /    R  reload\nBACKSPACE  restart    /    ESC  pause"
	_update_objective()
	_notify("Find the marked service corridor. Search inside for the fuse.")

func _physics_process(delta: float) -> void:
	if mission_complete or player.health_component.current <= 0:
		return
	mission_seconds += delta
	_advance_ambush(delta)
	interaction_target = _find_interaction_target()
	var text: String = ""
	if is_instance_valid(interaction_target):
		text = "[ E ]  " + interaction_target.get_prompt(self)
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
	# Any ArcaInteractionPoint under this room is a candidate; no hard-coded list.
	var nearest: ArcaInteractionPoint = null
	var nearest_distance: float = INF
	for node in get_tree().get_nodes_in_group(ArcaInteractionPoint.GROUP):
		var point := node as ArcaInteractionPoint
		if point == null or point.is_queued_for_deletion() or not is_ancestor_of(point):
			continue
		if not point.is_available_to(player):
			continue
		var distance: float = point.global_position.distance_squared_to(player.global_position)
		if distance < nearest_distance:
			nearest = point
			nearest_distance = distance
	return nearest

func try_interact() -> bool:
	if get_tree().paused or mission_complete or player.health_component.current <= 0:
		return false
	# One action per press: a second press delivered in the same frame is ignored.
	var frame: int = Engine.get_process_frames()
	if frame == _last_interaction_frame:
		return false
	interaction_target = _find_interaction_target()
	if not is_instance_valid(interaction_target):
		return false
	_last_interaction_frame = frame
	interaction_target.interact(self)
	return true

func _collect_supply(pickup: ArcaInteractionPoint, message: String) -> void:
	pickup.enabled = false
	pickup.queue_free()
	$PickupSound.play()
	hud.set_interaction("")
	_notify(message)

func has_key_item(item_id: StringName) -> bool:
	return key_items.has(item_id)

func add_key_item(item_id: StringName) -> bool:
	if item_id.is_empty() or has_key_item(item_id):
		return false
	key_items.append(item_id)
	_update_objective()
	return true

func consume_key_item(item_id: StringName) -> void:
	key_items.erase(item_id)
	_update_objective()

func _on_fuse_pickup_collected() -> void:
	add_key_item(&"fuse")
	$PickupSound.play()
	hud.set_interaction("")
	_notify("FUSE COLLECTED - retrace the corridor to the main room and power panel.")
	print("Fuse collected: inventory updated")

func _on_panel_powered() -> void:
	if power_restored or mission_complete or player.health_component.current <= 0:
		return
	power_restored = true
	consume_key_item(&"fuse")
	$PowerSound.play()
	door.open()
	hud.set_interaction("")
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
		hud.set_inventory("FUSE  /  INSTALLED", key_items)
	elif has_fuse:
		hud.set_status("02 / Return through the corridor to the power panel on the left.")
		hud.set_inventory("FUSE  /  CARRIED", key_items)
	else:
		hud.set_status("01 / Explore the marked service corridor. Find the fuse and press E.")
		hud.set_inventory("FUSE  /  MISSING", key_items)

func _notify(message: String) -> void:
	notice_remaining = 4.5
	hud.set_notice(message)

func _on_enemy_destroyed() -> void:
	predators_killed += 1
	_cancel_ambush()
	$AlarmLight.hide()
	$BreachWarning.hide()
	_notify("PREDATOR DOWN - continue to the exit.")

func _on_predator_destroyed() -> void:
	# Secondary predators never affect the hatch ambush, which belongs to `enemy`.
	predators_killed += 1
	if not mission_complete and player.health_component.current > 0:
		_notify("PREDATOR DOWN")


func get_mission_summary() -> Dictionary:
	var predator: String = "STILL ALIVE"
	if enemy.dead:
		predator = "KILLED"
	elif mission_complete:
		predator = "EVADED"
	return {
		"seconds": mission_seconds, "shots": shots_fired, "damage": damage_taken, "predator": predator,
		"kills": predators_killed, "predators_total": get_predators().size(),
	}

func _on_player_died() -> void:
	_cancel_ambush()
	super._on_player_died()
	$EndSound.pitch_scale = 0.72
	$EndSound.play()
	hud.set_interaction("")
	hud.set_notice("")

func _on_exit_entered(body: Node3D) -> void:
	if body != player or not power_restored or not door.is_open or mission_complete:
		return
	if player.health_component.current <= 0:
		return
	mission_complete = true
	player.ammo_component.cancel_reload()
	_cancel_ambush()
	stop_all_predators()
	stop_audio()
	hud.set_interaction("")
	hud.set_notice("")
	hud.set_status("SECTOR RESTORED / Exit reached.")
	hud.show_success(get_mission_summary())
	$EndSound.play()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func restart_room() -> void:
	_cancel_ambush()
	stop_all_predators()
	super.restart_room()

func set_paused(value: bool) -> void:
	if not mission_complete:
		super.set_paused(value)
