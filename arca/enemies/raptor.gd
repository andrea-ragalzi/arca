class_name ArcaRaptor
extends CharacterBody3D
## A single prototype predator: navigation, readable melee and interruptible death.

signal exploded
signal state_changed(value: int)
signal attack_landed
signal staggered

# New states are appended so existing integer values and HUD labels stay stable.
enum State { WAIT, ALERT, CHASE, WINDUP, ATTACK, RECOVER, DEAD, DORMANT, EMERGE, HURT, SLEEP, WAKE }
enum StartMode { ACTIVE, SLEEPING }

const EMERGENCE_SPEED: float = 1.6
const ALERT_DURATION: float = 0.7
const WAKE_PROXIMITY_DURATION: float = 1.0
# States in which an accepted hit can interrupt the predator. WINDUP is included so
# accurate fire cancels a pending bite; a committed ATTACK is never interrupted.
const STAGGER_STATES: Array[State] = [State.ALERT, State.CHASE, State.WINDUP, State.RECOVER]

const ROARS := [
	preload("res://arca/audio/raptor/roar_01.wav"), preload("res://arca/audio/raptor/roar_02.wav"),
]
const HIT_VOICES := [
	preload("res://arca/audio/raptor/hurt_01.wav"), preload("res://arca/audio/raptor/hurt_02.wav"),
]
const STEPS := [
	preload("res://arca/audio/raptor/footstep_01.wav"), preload("res://arca/audio/raptor/footstep_02.wav"),
	preload("res://arca/audio/raptor/footstep_03.wav"),
]
const BITE := preload("res://arca/audio/raptor/bite_01.wav")
const DEATH_VOICE := preload("res://arca/audio/raptor/death_01.wav")

@export var start_mode: StartMode = StartMode.ACTIVE
@export var wake_noise_radius: float = 12.0
@export var wake_proximity: float = 2.5
@export var move_speed: float = 3.2
@export var detection_range: float = 10.0
@export var attack_range: float = 1.8
@export var attack_damage: int = 20
@export var windup_duration: float = 0.45
@export var recovery_duration: float = 0.95
## Length of the hit reaction. The baked Ferocious_Hurt clip is timed to the default.
@export var stagger_duration: float = 0.5
## Minimum time between stagger starts, so sustained fire cannot stun-lock the predator.
@export var stagger_cooldown: float = 1.5

@onready var health_component: ArcaHealth = $HealthComponent
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var skin: Node3D = $Skin
@onready var animation: AnimationPlayer = $Skin/AnimationPlayer
@onready var warning: Label3D = $Warning
@onready var voice: AudioStreamPlayer3D = $Voice
@onready var breath: AudioStreamPlayer3D = $Breath
@onready var steps: AudioStreamPlayer3D = $Steps

var roar_index: int = 0
var hurt_index: int = 0
var step_index: int = 0
var step_remaining: float = 0.0

var player: Node3D
var state: State = State.WAIT
var elapsed: float = 0.0
var swing_checked: bool = false
var retarget_remaining: float = 0.0
var combat_enabled: bool = true
var clips: Dictionary = {}
var active_collision_layer: int
var active_collision_mask: int
var emergence_target: Vector3
var stagger_cooldown_remaining: float = 0.0
var wake_proximity_elapsed: float = 0.0
var dead: bool:
	get: return state == State.DEAD
var health: int:
	get: return health_component.current


func _ready() -> void:
	add_to_group("arca_predator")
	active_collision_layer = collision_layer
	active_collision_mask = collision_mask
	for clip in animation.get_animation_list():
		for action in ["Idle", "Walk", "Run", "Attack", "Death", "Jump", "Hurt", "Roar", "Sleep", "Wake"]:
			if String(clip).ends_with("_" + action):
				clips[action] = clip
				if action in ["Idle", "Walk", "Run"]:
					animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	health_component.died.connect(_die)
	state_changed.connect(_on_audio_state_changed)
	staggered.connect(_play_hurt)
	player = get_tree().get_first_node_in_group("arca_player") as Node3D
	if start_mode == StartMode.SLEEPING and is_instance_valid(player):
		player.shot_fired.connect(_on_player_shot)
	_change_state(State.SLEEP if start_mode == StartMode.SLEEPING else State.WAIT)


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
	stagger_cooldown_remaining = maxf(stagger_cooldown_remaining - delta, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	if state not in [State.WAIT, State.EMERGE, State.HURT, State.SLEEP, State.WAKE] and difference.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-difference.x, -difference.z), minf(1.0, delta * 8.0))
	match state:
		State.SLEEP:
			if distance <= wake_proximity:
				wake_proximity_elapsed += delta
				if wake_proximity_elapsed >= WAKE_PROXIMITY_DURATION:
					_change_state(State.WAKE)
			else:
				wake_proximity_elapsed = 0.0
		State.WAKE:
			if elapsed >= animation.get_animation(clips["Wake"]).length:
				_change_state(State.ALERT)
		State.EMERGE:
			var direction: Vector3 = emergence_target - global_position
			direction.y = 0.0
			if direction.length() <= 0.08:
				_change_state(State.ALERT)
			else:
				var step: Vector3 = direction.normalized() * minf(EMERGENCE_SPEED, direction.length() / delta)
				velocity.x = step.x
				velocity.z = step.z
		State.WAIT:
			if distance <= detection_range and _can_see_player():
				_change_state(State.ALERT)
		State.ALERT:
			if elapsed >= ALERT_DURATION:
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
		State.HURT:
			if elapsed >= stagger_duration:
				_change_state(State.CHASE)
	velocity += get_gravity() * delta
	move_and_slide()
	if is_on_floor() and Vector2(get_real_velocity().x, get_real_velocity().z).length_squared() > 0.25:
		step_remaining -= delta
		if step_remaining <= 0.0:
			_play_footstep()
			step_remaining = 0.32 if state == State.CHASE else 0.52
	else:
		step_remaining = 0.0


func _on_audio_state_changed(value: State) -> void:
	if value != State.SLEEP:
		breath.stop()
	if not combat_enabled:
		return
	match value:
		State.SLEEP:
			breath.play()
		State.EMERGE:
			voice.stop()
		State.ALERT:
			_play_voice(ROARS[roar_index])
			roar_index = (roar_index + 1) % ROARS.size()
		State.ATTACK:
			_play_voice(BITE)
		State.DEAD:
			steps.stop()
			_play_voice(DEATH_VOICE)


func _play_hurt() -> void:
	if combat_enabled:
		_play_voice(HIT_VOICES[hurt_index])
		hurt_index = (hurt_index + 1) % HIT_VOICES.size()


func _play_voice(stream: AudioStream) -> void:
	voice.stream = stream
	voice.play()


func _play_footstep() -> void:
	steps.stream = STEPS[step_index]
	steps.play()
	step_index = (step_index + 1) % STEPS.size()


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


func _on_player_shot() -> void:
	if state == State.SLEEP and combat_enabled and can_process() \
			and global_position.distance_to(player.global_position) <= wake_noise_radius:
		_change_state(State.WAKE)


@rpc("call_local")
func hit() -> void:
	if dead or state == State.DORMANT:
		return
	if not health_component.take_damage(1) or dead:
		return
	if state == State.SLEEP and combat_enabled:
		_change_state(State.WAKE)
	elif state == State.WAIT:
		_change_state(State.ALERT)
	elif state in STAGGER_STATES and stagger_cooldown_remaining <= 0.0:
		stagger_cooldown_remaining = stagger_cooldown
		_change_state(State.HURT)
		staggered.emit()


func _change_state(value: State) -> void:
	state = value
	elapsed = 0.0
	swing_checked = false
	warning.visible = value in [State.ALERT, State.WINDUP]
	match value:
		State.SLEEP: _play("Sleep")
		State.WAKE: _play("Wake")
		State.EMERGE: _play("Walk")
		State.ALERT: _play("Roar")
		State.HURT: _play("Hurt")
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
	voice.stop()
	breath.stop()
	steps.stop()
	velocity = Vector3.ZERO
	warning.hide()
	if not dead:
		_play("Sleep" if state in [State.SLEEP, State.WAKE] else "Idle")


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


func emerge_from_hatch(target: Vector3) -> bool:
	if not activate_ambush():
		return false
	emergence_target = target
	var direction: Vector3 = target - global_position
	rotation.y = atan2(-direction.x, -direction.z)
	reset_physics_interpolation()
	_change_state(State.EMERGE)
	return true


func get_status_text() -> String:
	if state == State.DORMANT:
		return "NO CONTACT"
	var labels := [
		"WAITING", "ALERT", "CHASING", "WINDUP", "ATTACK",
		"RECOVERY", "DOWN", "DORMANT", "EMERGING", "STAGGERED", "SLEEPING", "WAKING",
	]
	return "PREDATOR %d/%d  /  %s" % [health, health_component.max_health, labels[state]]
