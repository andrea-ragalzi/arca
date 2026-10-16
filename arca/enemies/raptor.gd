class_name ArcaRaptor
extends CharacterBody3D
## A single prototype predator: navigation, readable melee and interruptible death.

signal exploded
signal state_changed(value: int)
signal attack_landed

enum State { WAIT, ALERT, CHASE, WINDUP, ATTACK, RECOVER, DEAD, DORMANT }

@export var move_speed: float = 3.2
@export var detection_range: float = 10.0
@export var attack_range: float = 1.8
@export var attack_damage: int = 20
@export var windup_duration: float = 0.45
@export var recovery_duration: float = 0.95

@onready var health_component: ArcaHealth = $HealthComponent
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var skin: Node3D = $Skin
@onready var animation: AnimationPlayer = $Skin/AnimationPlayer
@onready var warning: Label3D = $Warning

var player: Node3D
var state: State = State.WAIT
var elapsed: float = 0.0
var swing_checked: bool = false
var retarget_remaining: float = 0.0
var combat_enabled: bool = true
var clips: Dictionary = {}
var active_collision_layer: int
var active_collision_mask: int
var dead: bool:
	get: return state == State.DEAD
var health: int:
	get: return health_component.current


func _ready() -> void:
	add_to_group("arca_predator")
	active_collision_layer = collision_layer
	active_collision_mask = collision_mask
	for clip in animation.get_animation_list():
		for action in ["Idle", "Walk", "Run", "Attack", "Death", "Jump"]:
			if String(clip).ends_with("_" + action):
				clips[action] = clip
				if action in ["Idle", "Walk", "Run"]:
					animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	health_component.died.connect(_die)
	player = get_tree().get_first_node_in_group("arca_player") as Node3D
	_change_state(State.WAIT)


func _physics_process(delta: float) -> void:
	if dead or not combat_enabled:
		return
	if not is_instance_valid(player):
		return
	var difference: Vector3 = player.global_position - global_position
	difference.y = 0.0
	var distance: float = difference.length()
	elapsed += delta
	retarget_remaining -= delta
	velocity.x = 0.0
	velocity.z = 0.0
	if state != State.WAIT and difference.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-difference.x, -difference.z), minf(1.0, delta * 8.0))
	match state:
		State.WAIT:
			if distance <= detection_range and _can_see_player():
				_change_state(State.ALERT)
		State.ALERT:
			if elapsed >= 0.7:
				_change_state(State.CHASE)
		State.CHASE:
			if distance <= attack_range and _can_see_player():
				_change_state(State.WINDUP)
			else:
				_follow_path()
		State.WINDUP:
			if elapsed >= windup_duration:
				_change_state(State.ATTACK)
		State.ATTACK:
			if elapsed >= 0.24 and not swing_checked:
				swing_checked = true
				if distance <= attack_range + 0.25 and _can_see_player():
					player.take_damage(attack_damage)
					attack_landed.emit()
			if elapsed >= animation.get_animation(clips["Attack"]).length:
				_change_state(State.RECOVER)
		State.RECOVER:
			if elapsed >= recovery_duration:
				_change_state(State.CHASE)
	velocity += get_gravity() * delta
	move_and_slide()


func _follow_path() -> void:
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	if retarget_remaining <= 0.0:
		agent.target_position = player.global_position
		retarget_remaining = 0.2
	if agent.is_navigation_finished():
		return
	var direction: Vector3 = agent.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.25)


func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.9,
		player.global_position + Vector3.UP,
		3, [get_rid()])
	var collision: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not collision.is_empty() and collision.collider == player


@rpc("call_local")
func hit() -> void:
	if dead or state == State.DORMANT:
		return
	if health_component.take_damage(1) and state == State.WAIT:
		_change_state(State.ALERT)


func _change_state(value: State) -> void:
	state = value
	elapsed = 0.0
	swing_checked = false
	warning.visible = value in [State.ALERT, State.WINDUP]
	match value:
		State.CHASE: _play("Run")
		State.ATTACK: _play("Attack")
		State.DEAD: _play("Death")
		_: _play("Idle")
	state_changed.emit(state)


func _play(action: String) -> void:
	if clips.has(action):
		animation.play(clips[action], 0.12)


func _die() -> void:
	velocity = Vector3.ZERO
	collision_layer = 0
	$CollisionShape3D.set_deferred("disabled", true)
	_change_state(State.DEAD)
	exploded.emit()


func stop_combat() -> void:
	combat_enabled = false
	velocity = Vector3.ZERO
	warning.hide()
	if not dead:
		_play("Idle")


func prepare_ambush() -> void:
	# Dormant predators must be invisible, non-solid and immune to stray shots.
	stop_combat()
	_change_state(State.DORMANT)
	hide()
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)


func activate_ambush() -> bool:
	if state != State.DORMANT:
		return false
	show()
	collision_layer = active_collision_layer
	collision_mask = active_collision_mask
	combat_enabled = true
	set_physics_process(true)
	reset_physics_interpolation()
	_change_state(State.ALERT)
	return true


func get_status_text() -> String:
	if state == State.DORMANT:
		return "NO CONTACT"
	var labels := ["WAITING", "ALERT", "CHASING", "WINDUP", "ATTACK", "RECOVERY", "DOWN"]
	return "PREDATOR %d/%d  /  %s" % [health, health_component.max_health, labels[state]]
