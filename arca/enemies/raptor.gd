class_name ArcaRaptor
extends CharacterBody3D
## A single prototype predator: navigation, readable melee and interruptible death.

signal exploded
signal state_changed(value: int)
signal attack_landed
signal staggered

# New states are appended so existing integer values and HUD labels stay stable.
enum State { WAIT, ALERT, CHASE, WINDUP, ATTACK, RECOVER, DEAD, DORMANT, EMERGE, HURT, SLEEP, WAKE, STALK, INVESTIGATE, SEARCH, FLANK, RETREAT, PATROL, JUMP, POUNCE, SLASH, JUMP_LOAD, JUMP_LAND, DESCEND, GUARD_DECK }
enum StartMode { ACTIVE, SLEEPING }

const POUNCE_TIME: float = 0.65
const ENVIRONMENT_JUMP_TIME: float = 0.86
const POUNCE_DAMAGE: int = 26
const POUNCE_CONTACT_START: float = 0.24
const POUNCE_CONTACT_END: float = 0.61
const EMERGENCE_SPEED: float = 1.6
const ALERT_DURATION: float = 0.7
const WAKE_PROXIMITY_DURATION: float = 1.0
# States in which an accepted hit can interrupt the predator. WINDUP is included so
# accurate fire cancels a pending bite; a committed ATTACK is never interrupted.
const STAGGER_STATES: Array[State] = [State.ALERT, State.CHASE, State.WINDUP, State.RECOVER, State.STALK, State.FLANK, State.INVESTIGATE, State.SEARCH, State.JUMP_LOAD, State.DESCEND, State.GUARD_DECK]

const ROARS := [
	preload("res://arca/audio/raptor/roar_01.wav"), preload("res://arca/audio/raptor/roar_02.wav"),
]
const PERFORMANCE := preload("res://arca/enemies/raptor_performance.gd")
const REPERTOIRE := {
	"call": [preload("res://arca/audio/raptor/language/raptor_call_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_call_b.wav")],
	"reply": [preload("res://arca/audio/raptor/language/raptor_reply_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_reply_b.wav")],
	"alert": [preload("res://arca/audio/raptor/language/raptor_alert_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_alert_b.wav")],
	"flank": [preload("res://arca/audio/raptor/language/raptor_flank_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_flank_b.wav")],
	"hold": [preload("res://arca/audio/raptor/language/raptor_hold_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_hold_b.wav")],
	"threat": [preload("res://arca/audio/raptor/language/raptor_threat_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_threat_b.wav")],
	"burst": [preload("res://arca/audio/raptor/language/raptor_burst_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_burst_b.wav")],
	"retreat": [preload("res://arca/audio/raptor/language/raptor_retreat_a.wav"),
		preload("res://arca/audio/raptor/language/raptor_retreat_b.wav")],
}
const HIT_VOICES := [
	preload("res://arca/audio/raptor/hurt_01.wav"), preload("res://arca/audio/raptor/hurt_02.wav"),
]
const STEPS := [
	preload("res://arca/audio/raptor/footstep_01.wav"), preload("res://arca/audio/raptor/footstep_02.wav"),
	preload("res://arca/audio/raptor/footstep_03.wav"),
]
const BITE := preload("res://arca/audio/raptor/bite_01.wav")
const DEATH_VOICE := preload("res://arca/audio/raptor/death_01.wav")

@export_enum("Auto", "A", "B") var preferred_voice: int = 0
@export var decision_seed: int = 0
@export var behavior: ArcaRaptorBehavior
@export var start_mode: StartMode = StartMode.ACTIVE
@export var wake_noise_radius: float = 12.0
@export var wake_proximity: float = 2.5
@export var move_speed: float = 3.2
@export var detection_range: float = 10.0
@export var gunshot_hearing_range: float = 0.0
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
var last_known_position: Vector3 = Vector3.INF
var last_heard_position: Vector3 = Vector3.INF
var time_out_of_sight: float = 0.0
var maneuver_target: Vector3 = Vector3.INF
var patrol_origin: Vector3
var patrol_initialized: bool = false
var call_cooldown: float = 0.0
var reply_remaining: float = 0.0
var voice_variant: int
var cue_age := INF
var cue_length := 0.0
var cue_kind := ""
var reply_origin := Vector3.INF
var perception_remaining := 0.0
var perceived := false
var perception_samples := 0
var visibility_checks := 0
var path_requests := 0
var pack: ArcaRaptorPack
var utility: ArcaRaptorUtility
var decision_due := 0
var decision_cost_usec := 0
var ai_update_cost_usec := 0
var link_arrival_pending := false
var navigation_link_arrivals := 0
var decision_samples := 0
var physical_queries := 0
var last_wounded_location := Vector3.INF
var wound_memory_until := 0
var replay_log: FileAccess
var active_tick := 0
var gunshot_memory_until := 0
var last_gunshot_position := Vector3.INF
var sighting_tick := -1
var pack_sighting := Vector3.INF
var pack_sighting_tick := -1
var role := ""
var flank_cue_pending := false
var attack_space := Vector3.INF
var courtesy_pause := 0.0
var courtesy_remaining := 0.0
var courtesy_direction := Vector3.ZERO
var role_until := 0
var tactic_tick := 0
var reserved_jump: Marker3D
var jump_goal := Vector3.INF
var jump_resume_flank := false
var jump_retry := 0.0
var planned_jump: Marker3D
var descent_point: Marker3D
var guarded_deck: ArcaRaptorJumpSurface
var deck_check_tick := 0
var approach_best_distance := INF
var approach_progress_tick := 0
var descent_retry_tick := 0
var descent_progress_tick := 0
var descent_best_distance := INF
var failed_jump_until: Dictionary[int, int] = {}
var cached_path_target := Vector3.INF
var stalled_for := 0.0
var reposition_remaining: float = 0.0
var shutter_noise_cooldown: float = 0.0
var flank_side: float = 1.0
var scan_heading: float = 0.0
var misses: int = 0
var melee_count: int = 0
var pounce_remaining: float = 0.0
var leap_direction: Vector3 = Vector3.ZERO
var attack_target: Vector3 = Vector3.INF
var dead: bool:
	get: return state == State.DEAD
var health: int:
	get: return health_component.current


func _ready() -> void:
	add_to_group("arca_predator")
	voice_variant = preferred_voice - 1 if preferred_voice > 0 else (
		get_tree().get_node_count_in_group("arca_predator") - 1) % 2
	perception_remaining = 0.017 * (get_tree().get_node_count_in_group("arca_predator") % 3)
	var rig := skin.find_children("*", "Skeleton3D", true, false).front() as Skeleton3D
	var acting := PERFORMANCE.new()
	acting.actor = self
	rig.add_child(acting)
	var slot := get_tree().get_node_count_in_group("arca_predator")
	utility = ArcaRaptorUtility.new(decision_seed if decision_seed != 0 else hash(str(get_path())))
	decision_due = slot * 4
	agent.link_reached.connect(_on_navigation_link)
	if OS.is_debug_build() and OS.has_environment("ARCA_AI_REPLAY"):
		var path := OS.get_environment("ARCA_AI_REPLAY").path_join("%s-%d.jsonl" % [name, slot])
		replay_log = FileAccess.open(path, FileAccess.WRITE)
	active_collision_layer = collision_layer
	active_collision_mask = collision_mask
	for clip in animation.get_animation_list():
		for action in ["Idle", "Walk", "Run", "Attack", "Death", "Jump", "Hurt", "Roar", "Sleep", "Wake", "Rush"]:
			if String(clip).ends_with("_" + action):
				clips[action] = clip
				if action in ["Idle", "Walk", "Run"]:
					animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	health_component.died.connect(_die)
	state_changed.connect(_on_audio_state_changed)
	staggered.connect(_play_hurt)
	player = get_tree().get_first_node_in_group("arca_player") as Node3D
	if is_instance_valid(player):
		player.shot_fired.connect(_on_player_shot)
		player.movement_noise.connect(_on_movement_noise)
	_change_state(State.SLEEP if start_mode == StartMode.SLEEPING else State.WAIT)


func _exit_tree() -> void:
	if is_instance_valid(pack):
		pack.release(self)


func _physics_process(delta: float) -> void:
	if dead or not combat_enabled:
		return
	if not is_instance_valid(player):
		return
	var timing_start := Time.get_ticks_usec()
	decision_cost_usec = 0
	var difference: Vector3 = player.global_position - global_position
	difference.y = 0.0
	var distance: float = difference.length()
	active_tick += 1
	elapsed += delta
	courtesy_pause = maxf(0.0, courtesy_pause - delta)
	courtesy_remaining = maxf(0.0, courtesy_remaining - delta)
	cue_age += delta
	jump_retry = maxf(0.0, jump_retry - delta)
	stalled_for = stalled_for + delta if get_slide_collision_count() > 0 and (
		get_real_velocity() - Vector3.UP * get_real_velocity().y).length_squared() < 0.16 else 0.0
	retarget_remaining -= delta
	stagger_cooldown_remaining = maxf(stagger_cooldown_remaining - delta, 0.0)
	pounce_remaining = maxf(pounce_remaining - delta, 0.0)
	shutter_noise_cooldown = maxf(shutter_noise_cooldown - delta, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	if state in [State.JUMP, State.POUNCE]:
		velocity.x = leap_direction.x
		velocity.z = leap_direction.z
	var seen: bool = false
	if behavior != null:
		seen = _sample_perception(delta)
		if seen and state in [State.STALK, State.ALERT]:
			_face(difference, delta)
		reposition_remaining = maxf(reposition_remaining - delta, 0.0)
		_advance_reply(delta)
	elif state not in [State.WAIT, State.EMERGE, State.HURT, State.SLEEP, State.WAKE]:
		_face(difference, delta)
	if behavior != null and _should_leave_deck():
		_change_state(State.DESCEND)
	match state:
		State.DESCEND:
			_advance_descent(seen)
		State.GUARD_DECK:
			_advance_deck_guard(seen, delta)
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
			if seen or (behavior == null and distance <= detection_range and _can_see_player()):
				_change_state(State.ALERT)
			elif behavior != null and elapsed > 4.0:
				_begin_patrol()
		State.ALERT:
			if seen and _tracking_gunfire() and elapsed >= 0.16:
				_change_state(State.CHASE)
			elif elapsed >= ALERT_DURATION:
				_change_state(State.STALK if behavior != null else State.CHASE)
		State.STALK:
			if not seen:
				_resume_hunt(false)
			elif _tracking_gunfire():
				_change_state(State.CHASE)
			elif elapsed >= behavior.observation_duration:
				_choose_approach()
		State.CHASE:
			if behavior != null:
				_chase_sighting(seen, distance)
			elif distance <= attack_range and _can_see_player():
				_change_state(State.WINDUP)
			else:
				_follow_path(player.global_position, move_speed)
		State.INVESTIGATE:
			if seen and (reply_remaining <= 0.0 or elapsed > 0.34):
				_change_state(State.CHASE if _tracking_gunfire() else State.ALERT)
			elif _tracking_gunfire():
				if _near_target(last_gunshot_position):
					_change_state(State.SEARCH)
				else:
					_follow_path(last_gunshot_position, move_speed)
					_face(last_gunshot_position - global_position, delta * 0.7)
			elif reply_remaining > 0.0:
				if _tactical_choice(["listen", "investigate"], false) == "investigate":
					_follow_path(last_heard_position, move_speed * behavior.cautious_speed)
			elif elapsed > 4.0 or _near_target(last_heard_position):
				if pack_sighting.is_finite() and active_tick - pack_sighting_tick < 165:
					last_heard_position = pack_sighting
					pack_sighting = Vector3.INF
					elapsed = 0.0
				else:
					_change_state(State.SEARCH)
			else:
				_follow_path(last_heard_position, move_speed * behavior.cautious_speed)
		State.PATROL, State.FLANK, State.RETREAT:
			_advance_maneuver(seen)
		State.SEARCH:
			if seen:
				_change_state(State.STALK)
			elif elapsed >= behavior.search_duration:
				last_known_position = Vector3.INF
				_change_state(State.WAIT)
			else:
				rotation.y = scan_heading + sin(elapsed * 2.8) * 1.05
		State.WINDUP:
			if elapsed >= windup_duration:
				if attack_target.is_finite():
					var destination := attack_target
					attack_target = Vector3.INF
					if not try_pounce(destination):
						pounce_remaining = 1.3
						_resume_hunt(seen)
				else:
					melee_count += 1
					_change_state(State.SLASH if behavior != null and clips.has("Rush")
						and melee_count % 3 == 2 else State.ATTACK)
		State.ATTACK, State.SLASH:
			var claw := state == State.SLASH
			if elapsed >= (0.31 if claw else 0.24) and not swing_checked:
				swing_checked = true
				if distance <= attack_range + 0.25 and _can_see_player() and _strike_faces_player() \
						and (behavior == null or absf(global_position.y - player.global_position.y) <= 1.05):
					player.take_damage(ceili(attack_damage * 0.7) if claw else attack_damage)
					attack_landed.emit()
				else:
					misses += 1
			if elapsed >= animation.get_animation(clips["Rush" if claw else "Attack"]).length:
				_change_state(State.RECOVER)
		State.JUMP_LOAD:
			if elapsed >= 0.19:
				_launch_reserved_jump(seen)
		State.JUMP_LAND:
			if elapsed >= 0.25:
				if jump_resume_flank and active_tick < role_until:
					_change_state(State.FLANK)
				else:
					_resume_hunt(seen)
		State.POUNCE, State.JUMP:
			_advance_leap(distance)
		State.RECOVER:
			if elapsed >= recovery_duration:
				if behavior != null and seen and _ally_in_pursuit():
					reposition_remaining = 2.5
					_begin_retreat()
				else:
					_resume_hunt(seen)
		State.HURT:
			if elapsed >= stagger_duration:
				if behavior != null and seen and not _tracking_gunfire() and health <= health_component.max_health / 2:
					_begin_retreat()
				else:
					_resume_hunt(seen)
	ai_update_cost_usec = Time.get_ticks_usec() - timing_start
	velocity += get_gravity() * delta
	move_and_slide()
	if behavior != null and state in [State.CHASE, State.INVESTIGATE] and shutter_noise_cooldown <= 0.0:
		_check_shutter_contact()
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
			if behavior == null or not last_known_position.is_finite():
				_play_voice(ROARS[roar_index])
				roar_index = (roar_index + 1) % ROARS.size()
			elif reply_remaining <= 0.0:
				if call_cooldown <= 0.0 and _call_nearby_predators():
					_signal_voice("call", -7.0)
				else:
					_signal_voice("alert", -8.0)
		State.WINDUP:
			if behavior != null:
				_signal_voice("threat", -8.0)
		State.INVESTIGATE, State.WAKE:
			if behavior != null:
				_play_voice(HIT_VOICES[1], -20.0, 0.87)
		State.FLANK:
			flank_cue_pending = true
		State.SEARCH, State.STALK:
			if reply_remaining <= 0.0 and (not voice.playing):
				_signal_voice("hold", -16.0)
		State.RETREAT:
			_signal_voice("retreat", -13.0)
		State.SLASH, State.POUNCE:
			_signal_voice("burst", -5.0)
		State.ATTACK:
			_play_voice(BITE)
		State.DEAD:
			steps.stop()
			_play_voice(DEATH_VOICE)


func _play_hurt() -> void:
	if combat_enabled:
		_play_voice(HIT_VOICES[hurt_index])
		hurt_index = (hurt_index + 1) % HIT_VOICES.size()


func _signal_voice(kind: String, gain: float, variant: int = -1) -> void:
	cue_kind = kind
	cue_age = 0.0
	var sample: AudioStream = REPERTOIRE[kind][voice_variant if variant < 0 else variant]
	_play_voice(sample, gain)
	voice.pitch_scale = 1.0
	cue_length = sample.get_length()
	if is_instance_valid(pack):
		pack.emit_voice(self, global_position, StringName(kind))


func performance_focus() -> Vector3:
	if reply_remaining > 0.0 or (cue_kind == "reply" and cue_age < cue_length):
		return reply_origin
	if state in [State.WAIT, State.INVESTIGATE, State.SEARCH] and last_heard_position.is_finite():
		return last_heard_position
	return last_known_position


func _play_voice(stream: AudioStream, gain: float = -11.0, pitch: float = 1.0) -> void:
	voice.stream = stream
	voice.pitch_scale = pitch * (1.0 if behavior == null else 0.95 + 0.025 * float((step_index + roar_index) % 5))
	voice.volume_db = gain
	if behavior != null and is_instance_valid(player) and is_inside_tree() and _cover_between(
			global_position + Vector3.UP * 1.1, player.global_position + Vector3.UP * 1.4):
		voice.volume_db -= 5.0
	voice.play()


func _play_footstep() -> void:
	steps.stream = STEPS[step_index]
	steps.play()
	step_index = (step_index + 1) % STEPS.size()


func _follow_path(target: Vector3, speed: float) -> void:
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	if not target.is_finite():
		return
	if not cached_path_target.is_finite() or (retarget_remaining <= 0.0 and (
			target.distance_squared_to(cached_path_target) > 0.64 or stalled_for > 0.26)):
		var elevated := global_position.y > 0.50
		agent.path_height_offset = 0.03 if elevated else 0.4
		agent.target_desired_distance = 0.30 if elevated or is_instance_valid(planned_jump) else 1.25
		agent.target_position = target
		cached_path_target = target
		path_requests += 1
		retarget_remaining = 0.32
	var finished := agent.is_navigation_finished()
	if _consume_navigation_link():
		return
	if finished:
		if is_instance_valid(planned_jump):
			_delay_failed_jump(planned_jump)
			_clear_approach()
			jump_retry = 0.18
		return
	var direction: Vector3 = agent.get_next_path_position() - global_position
	if _consume_navigation_link():
		return
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		if behavior != null:
			direction = _clear_pack_lane(direction)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.25)


func _clear_pack_lane(direction: Vector3) -> Vector3:
	if courtesy_remaining > 0.0:
		return courtesy_direction
	if courtesy_pause > 0.0:
		return direction
	courtesy_pause = 0.10 + 0.03 * voice_variant
	var collision := KinematicCollision3D.new()
	physical_queries += 1
	if not test_move(global_transform, direction * 0.68, collision):
		return direction
	var ally := collision.get_collider() as ArcaRaptor
	if ally == null or ally.dead:
		return direction
	# Front has first use of the lane; ties favor a stable spawn order.
	var give_way := (role != "front" and ally.role == "front") or (
		role == ally.role and get_instance_id() > ally.get_instance_id())
	var side := Vector3.UP.cross(direction) * flank_side
	for candidate: Vector3 in [side, -side]:
		physical_queries += 1
		if not test_move(global_transform, candidate * 0.62):
			courtesy_direction = (candidate - direction * 0.32).normalized() if give_way else candidate
			courtesy_remaining = 0.27
			return courtesy_direction
	physical_queries += int(give_way)
	if give_way and not test_move(global_transform, -direction * 0.42):
		courtesy_direction = -direction
	else:
		courtesy_direction = Vector3.ZERO
	courtesy_remaining = 0.20
	return courtesy_direction


func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	visibility_checks += 1
	physical_queries += 1
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.9,
		player.global_position + Vector3.UP,
		3, [get_rid()])
	var collision: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not collision.is_empty() and collision.collider == player


func _on_player_shot() -> void:
	if not combat_enabled or not can_process() or not is_instance_valid(player):
		return
	if behavior == null:
		if state == State.SLEEP and global_position.distance_to(player.global_position) <= wake_noise_radius:
			_change_state(State.WAKE)
		return
	if state in [State.DORMANT, State.EMERGE, State.DEAD]:
		return
	var origin := player.global_position
	var reach := gunshot_hearing_range if gunshot_hearing_range > 0.0 else behavior.hearing_range
	if not _can_hear(origin, reach):
		return
	last_gunshot_position = origin
	last_heard_position = origin
	gunshot_memory_until = active_tick + 180
	perception_remaining = 0.0
	if state == State.SLEEP:
		_change_state(State.WAKE)
	elif state in [State.WAIT, State.PATROL, State.SEARCH] or (
			state == State.GUARD_DECK and is_instance_valid(guarded_deck) and not guarded_deck.contains_top(origin)):
		_change_state(State.INVESTIGATE)


func _tracking_gunfire() -> bool:
	return active_tick < gunshot_memory_until and last_gunshot_position.is_finite()


func _on_movement_noise(origin: Vector3) -> void:
	if behavior != null:
		hear_noise(origin, behavior.hearing_range * 0.38, false)


@rpc("call_local")
func hit() -> void:
	if dead or state == State.DORMANT:
		return
	if not health_component.take_damage(1) or dead:
		return
	last_wounded_location = global_position
	wound_memory_until = active_tick + 420
	decision_due = active_tick
	if state == State.SLEEP and combat_enabled:
		_change_state(State.WAKE)
	elif state == State.WAIT:
		if behavior == null or (perceived and active_tick - sighting_tick <= 6):
			_change_state(State.ALERT)
		else:
			_change_state(State.SEARCH)
	elif state in STAGGER_STATES and stagger_cooldown_remaining <= 0.0:
		stagger_cooldown_remaining = stagger_cooldown
		_change_state(State.HURT)
		staggered.emit()


func _change_state(value: State) -> void:
	if value != State.GUARD_DECK:
		guarded_deck = null
	if state == State.DESCEND and value != State.DESCEND:
		_release_descent_approach()
	if value not in [State.FLANK, State.JUMP_LOAD, State.JUMP, State.JUMP_LAND]:
		if is_instance_valid(pack):
			pack.release(self, &"flank")
		flank_cue_pending = false
	if value not in [State.WINDUP, State.ATTACK, State.SLASH, State.POUNCE]:
		if is_instance_valid(pack):
			pack.release(self, &"attack")
		attack_space = Vector3.INF
	if value in [State.SEARCH, State.WAIT, State.HURT, State.RETREAT, State.DEAD]:
		role = ""
		role_until = 0
	if value not in [State.JUMP_LOAD, State.JUMP]:
		_release_jump()
	if value not in [State.CHASE, State.FLANK]:
		_clear_approach()
	state = value
	if value == State.WINDUP and behavior != null and last_known_position.is_finite():
		var toward := last_known_position - global_position
		toward.y = 0.0
		_face(toward, 1.0)
	if value != State.WINDUP:
		attack_target = Vector3.INF
	elapsed = 0.0
	swing_checked = false
	if value != State.JUMP_LOAD:
		cached_path_target = Vector3.INF
	if value == State.SEARCH:
		scan_heading = rotation.y
	warning.visible = value in [State.ALERT, State.WINDUP]
	match value:
		State.SLEEP: _play("Sleep")
		State.WAKE: _play("Wake")
		State.EMERGE: _play("Walk")
		State.ALERT: _play("Roar")
		State.HURT: _play("Hurt")
		State.CHASE: _play("Run")
		State.INVESTIGATE, State.PATROL, State.FLANK, State.RETREAT, State.DESCEND: _play("Walk")
		State.ATTACK: _play("Attack")
		State.SLASH: _play("Rush")
		State.JUMP, State.POUNCE: _play("Jump")
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
	_release_descent_approach()
	gunshot_memory_until = 0
	last_gunshot_position = Vector3.INF
	if is_instance_valid(pack):
		pack.release(self)
	attack_space = Vector3.INF
	role = ""
	_clear_approach()
	flank_cue_pending = false
	_release_jump()
	combat_enabled = false
	reply_remaining = 0.0
	reply_origin = Vector3.INF
	pack_sighting = Vector3.INF
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
		"STALKING", "INVESTIGATING", "SEARCHING", "FLANKING", "RETREATING", "PATROLLING",
		"JUMPING", "POUNCING", "SLASHING", "LOADING JUMP", "LANDING", "FINDING WAY DOWN", "WATCHING COVER",
	]
	return "PREDATOR %d/%d  /  %s" % [health, health_component.max_health, labels[state]]


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 8.0))


func _sample_perception(delta: float) -> bool:
	call_cooldown = maxf(0.0, call_cooldown - delta)
	if not patrol_initialized:
		patrol_initialized = true
		patrol_origin = global_position
		flank_side = -1.0 if global_position.x < 0.0 else 1.0
	if state in [State.SLEEP, State.WAKE, State.DORMANT, State.EMERGE]:
		return false
	var offset := player.global_position - global_position
	if offset.length_squared() < 144.0 and perception_remaining > 0.11:
		perception_remaining = 0.033 + 0.012 * voice_variant
	perception_remaining -= delta
	time_out_of_sight += delta
	if perception_remaining > 0.0:
		return perceived
	perception_samples += 1
	perception_remaining = (0.10 if offset.length_squared() < 144.0 else 0.30) + perception_remaining
	offset.y = 0.0
	var forward := -global_basis.z
	var in_fov := offset.length_squared() < 0.5 		or forward.dot(offset.normalized()) >= cos(deg_to_rad(behavior.field_of_view * 0.5))
	var seen := offset.length_squared() <= detection_range * detection_range and in_fov and _can_see_player()
	perceived = seen
	if seen:
		last_known_position = player.global_position
		sighting_tick = active_tick
		time_out_of_sight = 0.0
	return seen


func _cover_between(start: Vector3, finish: Vector3) -> bool:
	physical_queries += 1
	var ray := PhysicsRayQueryParameters3D.create(start, finish, 1, [get_rid()])
	return not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func hear_noise(origin: Vector3, radius: float, can_wake: bool = true) -> bool:
	if behavior == null or not combat_enabled or not can_process() 			or state not in [State.WAIT, State.PATROL, State.SEARCH, State.INVESTIGATE, State.SLEEP]:
		return false
	if state == State.SLEEP and not can_wake:
		return false
	if not _can_hear(origin, radius):
		return false
	last_heard_position = origin
	_change_state(State.WAKE if state == State.SLEEP else State.INVESTIGATE)
	return true


func _can_hear(origin: Vector3, radius: float) -> bool:
	var distance := global_position.distance_squared_to(origin)
	if distance > radius * radius:
		return false
	var reach := radius
	if _cover_between(global_position + Vector3.UP, origin + Vector3.UP):
		reach *= behavior.hearing_through_cover
	return distance <= reach * reach


func can_receive_call() -> bool:
	return combat_enabled and behavior != null and state in [
		State.WAIT, State.PATROL, State.SEARCH, State.INVESTIGATE, State.SLEEP]


func receive_pack_call(source: ArcaRaptor, position: Vector3) -> void:
	if not hear_noise(position, source.behavior.call_range):
		return
	pack_sighting = source.last_known_position
	pack_sighting_tick = active_tick - (source.active_tick - source.sighting_tick)
	reply_origin = position
	reply_remaining = source.cue_length + 0.42


func _call_nearby_predators() -> bool:
	call_cooldown = 9.0
	return is_instance_valid(pack) and pack.listener_for(self) != null


func _tactical_choice(candidates: Array[String], seen: bool, lateral: bool = false, interrupt: bool = false) -> String:
	if active_tick < decision_due and not interrupt:
		return utility.current if candidates.has(utility.current) else ""
	var start := Time.get_ticks_usec()
	decision_due = active_tick + (12 if seen or time_out_of_sight < behavior.memory_duration else 22)
	var snapshot := {
		"candidates": candidates, "seen": seen, "lateral": lateral,
		"memory": clampf(1.0 - time_out_of_sight / behavior.memory_duration, 0.0, 1.0),
		"injury": 1.0 - float(health) / health_component.max_health,
		"reply": reply_remaining > 0.0,
	}
	var previous := utility.current
	var held_until := utility.committed_until
	var rng_before := utility.rng.state
	var ranking := utility.choose(snapshot, behavior, active_tick, interrupt)
	decision_cost_usec += Time.get_ticks_usec() - start
	decision_samples += 1
	if is_instance_valid(replay_log):
		replay_log.store_line(JSON.stringify({
			"seed": str(utility.rng.seed), "rng": str(rng_before), "tick": active_tick,
			"previous": previous, "held_until": held_until, "interrupt": interrupt,
			"snapshot": snapshot, "scores": ranking.scores, "decision": ranking.decision,
			"last_direct_tick": sighting_tick, "last_direct": str(last_known_position),
			"last_audible": str(last_heard_position),
		}))
	return ranking.decision


func _near_target(target: Vector3, radius: float = 1.65) -> bool:
	if not target.is_finite():
		return true
	var offset := target - global_position
	return Vector2(offset.x, offset.z).length_squared() <= radius * radius


func _resume_hunt(seen: bool) -> void:
	if behavior == null or seen or (last_known_position.is_finite()
			and time_out_of_sight < behavior.memory_duration):
		_change_state(State.CHASE)
	elif _tracking_gunfire() and not _near_target(last_gunshot_position):
		_change_state(State.INVESTIGATE)
	else:
		_change_state(State.SEARCH)


func _chase_sighting(seen: bool, distance: float) -> void:
	if not seen and (_near_target(last_known_position) or time_out_of_sight >= behavior.memory_duration):
		_change_state(State.INVESTIGATE if _tracking_gunfire() and not _near_target(last_gunshot_position)
			else State.SEARCH)
		return
	if _guard_occupied_deck(last_known_position):
		return
	var elevated := last_known_position.is_finite() and absf(last_known_position.y - global_position.y) > 0.5
	var candidates: Array[String] = ["observe", "investigate"]
	var close := seen and distance <= attack_range
	var attack_ready := seen and not elevated and reposition_remaining <= 0.0 and (
		close or (distance > attack_range + 0.45 and distance <= behavior.pounce_range and pounce_remaining <= 0.0))
	var pack_busy := attack_ready and _ally_committed()
	if attack_ready and not pack_busy:
		candidates.append("attack")
	if elevated and jump_retry <= 0.0:
		candidates.append("jump")
	if close and (pack_busy or reposition_remaining > 0.0):
		candidates.append("flank")
	if seen and not _tracking_gunfire() and health <= health_component.max_health / 3 and active_tick < wound_memory_until:
		candidates.append("retreat")
	var action := _tactical_choice(candidates, seen, pack_busy)
	match action:
		"observe":
			if seen:
				if not _tracking_gunfire():
					_change_state(State.STALK)
					return
		"flank":
			_choose_approach()
			return
		"retreat":
			_begin_retreat()
			return
		"jump":
			if _seek_environment_jump():
				return
			decision_due = active_tick
		"attack":
			var goal := global_position if close else _pounce_landing(last_known_position)
			if not _pack_space_occupied(goal) and (close or (
					_has_takeoff_support() and _leap_velocity(goal, POUNCE_TIME).is_finite())):
				if pack == null or pack.claim(self, &"attack", goal, 1.1):
					attack_space = goal
					if not close:
						attack_target = last_known_position
					_change_state(State.WINDUP)
					return
			decision_due = active_tick + 5
	_follow_path(last_known_position, move_speed)


func _ally_committed() -> bool:
	for node: Node in get_tree().get_nodes_in_group("arca_predator"):
		var ally := node as ArcaRaptor
		if ally == null or ally == self or ally.player != player or not ally.combat_enabled:
			continue
		if global_position.distance_squared_to(ally.global_position) <= 100.0 and (
				ally.state in [State.WINDUP, State.ATTACK, State.POUNCE, State.SLASH]
				or (ally.state == State.RECOVER and ally.elapsed < 0.24)):
			return true
	return false


func _ally_in_pursuit() -> bool:
	for node: Node in get_tree().get_nodes_in_group("arca_predator"):
		var ally := node as ArcaRaptor
		if ally == null or ally == self or ally.player != player or not ally.combat_enabled:
			continue
		if ally.state in [State.CHASE, State.STALK, State.FLANK] and ally.time_out_of_sight < behavior.memory_duration \
				and global_position.distance_squared_to(ally.global_position) <= 36.0:
			return true
	return false


func _ally_front_role() -> bool:
	for node: Node in get_tree().get_nodes_in_group("arca_predator"):
		var ally := node as ArcaRaptor
		if ally != self and ally.player == player and ally.combat_enabled and ally.role == "front" \
				and ally.active_tick < ally.role_until and ally.state in [State.STALK, State.CHASE, State.WINDUP] \
				and global_position.distance_squared_to(ally.global_position) < 64.0:
			return true
	return false


func _choose_approach() -> void:
	var tick := active_tick
	if tick < tactic_tick:
		return
	tactic_tick = tick + 12 + voice_variant * 2
	var prefer_flank := reposition_remaining > 0.0 or _ally_committed() or _ally_front_role() or misses % 2 != 0
	var options: Array[String] = ["observe", "attack"]
	if behavior.flank_distance > 0.0:
		options.append("flank")
	var choice := _tactical_choice(options, true, prefer_flank, true)
	if choice == "observe":
		if state != State.STALK:
			_change_state(State.STALK)
		return
	if choice == "attack":
		role = "front"
		role_until = tick + 70
		_change_state(State.CHASE)
		return
	var lateral := Vector3.UP.cross((last_known_position - global_position).normalized())
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) != 0:
		for side: float in [flank_side, -flank_side]:
			var candidate := last_known_position + lateral * side * behavior.flank_distance
			var reachable := NavigationServer3D.map_get_closest_point(map, candidate)
			if reachable.distance_squared_to(candidate) <= 1.0 and not _lane_occupied(reachable) and not _recently_hurt_at(reachable):
				path_requests += 1
				var path := NavigationServer3D.map_get_path(map, global_position, reachable, true)
				if path.size() >= 2 and path[-1].distance_squared_to(reachable) <= 0.5 and (
						pack == null or pack.claim(self, &"flank", reachable, 1.25)):
					role = "flank"
					role_until = tick + 150
					maneuver_target = reachable
					flank_side = -side
					_change_state(State.FLANK)
					return
	_change_state(State.STALK)


func _recently_hurt_at(target: Vector3) -> bool:
	return active_tick < wound_memory_until and target.distance_squared_to(last_wounded_location) < 2.56


func _lane_occupied(target: Vector3) -> bool:
	for node: Node in get_tree().get_nodes_in_group("arca_predator"):
		var ally := node as ArcaRaptor
		if ally == null or ally == self or ally.player != player or not ally.combat_enabled:
			continue
		var position_to_avoid := ally.maneuver_target if ally.role == "flank" else ally.global_position
		if target.distance_squared_to(position_to_avoid) < 2.56:
			return true
	return _pack_space_occupied(target)


func _pack_space_occupied(target: Vector3) -> bool:
	if is_instance_valid(pack) and pack.occupied(self, target, 1.0):
		return true
	for ally: ArcaRaptor in get_tree().get_nodes_in_group("arca_predator"):
		if ally == self or ally.dead or ally.player != player:
			continue
		if target.distance_squared_to(ally.global_position) < 1.02 				or target.distance_squared_to(ally.jump_goal) < 1.20 				or target.distance_squared_to(ally.attack_space) < 1.20:
			return true
	return false


func _advance_reply(delta: float) -> void:
	if reply_remaining <= 0.0:
		return
	reply_remaining = maxf(reply_remaining - delta, 0.0)
	if reply_remaining == 0.0 and state in [State.WAIT, State.SEARCH, State.INVESTIGATE, State.WAKE, State.ALERT, State.STALK, State.CHASE, State.FLANK]:
		_signal_voice("reply", -11.0)


func _strike_faces_player() -> bool:
	if behavior == null:
		return true
	var difference := player.global_position - global_position
	difference.y = 0.0
	return difference.length_squared() < 0.12 or (-global_basis.z).dot(difference.normalized()) >= 0.62


func _begin_patrol() -> void:
	_set_maneuver(patrol_origin - global_basis.z * flank_side * 2.2, State.PATROL)
	flank_side *= -1.0


func _begin_retreat() -> void:
	var away := (global_position - last_known_position).normalized()
	_set_maneuver(global_position + away * 2.8 + Vector3.UP.cross(away) * flank_side, State.RETREAT)


func _set_maneuver(target: Vector3, next: State) -> void:
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		_change_state(State.WAIT)
		return
	maneuver_target = NavigationServer3D.map_get_closest_point(map, target)
	path_requests += 1
	var path := NavigationServer3D.map_get_path(map, global_position, maneuver_target, true)
	if path.size() < 2 or path[-1].distance_squared_to(maneuver_target) > 0.5:
		_change_state(State.SEARCH if last_known_position.is_finite() else State.WAIT)
	else:
		_change_state(next)


func _advance_maneuver(seen: bool) -> void:
	if state == State.FLANK and flank_cue_pending and reply_remaining <= 0.0 and (
			cue_kind != "reply" or cue_age >= cue_length):
		flank_cue_pending = false
		_signal_voice("flank", -13.0)
	if state == State.PATROL and seen:
		_change_state(State.ALERT)
	elif (_near_target(maneuver_target, 0.38 if state == State.PATROL else 0.70) or elapsed >= (behavior.retreat_duration if state == State.RETREAT else 2.5)
			or (state == State.FLANK and (active_tick >= role_until or stalled_for > 0.46))):
		if state == State.PATROL:
			_change_state(State.WAIT)
		else:
			if state == State.FLANK and last_known_position.is_finite():
				_face(last_known_position - global_position, 1.0)
			_resume_hunt(seen)
	elif state == State.RETREAT and elapsed < 0.26 and last_known_position.is_finite():
		var away := (global_position - last_known_position).slide(Vector3.UP).normalized()
		velocity += away * move_speed * 0.46
		_face(-away, 0.04)
	elif state != State.FLANK or not _seek_environment_jump(maneuver_target):
		_follow_path(maneuver_target, move_speed * behavior.cautious_speed)


func _pounce_landing(target: Vector3) -> Vector3:
	var offset := target - global_position
	offset.y = 0.0
	return target - offset.normalized() * 0.91


func try_pounce(target: Vector3) -> bool:
	if behavior == null or pounce_remaining > 0.0 or not _can_leap():
		return false
	var offset := target - global_position
	if Vector2(offset.x, offset.z).length() > behavior.pounce_range:
		return false
	var destination := _pounce_landing(target)
	var launch := _leap_velocity(destination, POUNCE_TIME)
	if _pack_space_occupied(destination) or not launch.is_finite():
		return false
	pounce_remaining = behavior.pounce_cooldown
	if is_instance_valid(pack) and not pack.claim(self, &"attack", destination, 1.10):
		return false
	attack_space = destination
	_begin_leap(launch, State.POUNCE)
	return true


func _can_leap() -> bool:
	return combat_enabled and can_process() and not dead and _has_takeoff_support() and clips.has("Jump") 		and state not in [State.DORMANT, State.EMERGE, State.SLEEP, State.WAKE, State.JUMP, State.POUNCE, State.JUMP_LOAD]


func _has_takeoff_support() -> bool:
	if is_on_floor():
		return true
	# A resting capsule can alternate floor contact at a slab seam.
	if velocity.y > 0.3:
		return false
	var probe := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.09,
		global_position + Vector3.DOWN * 0.12, 1, [get_rid()])
	physical_queries += 1
	var hit := get_world_3d().direct_space_state.intersect_ray(probe)
	return not hit.is_empty() and hit.normal.y >= 0.75


func _landing_marker(point: Marker3D) -> Marker3D:
	if point is ArcaRaptorJumpPoint:
		return point.landing
	return point.get_node_or_null("Landing") as Marker3D


func _ascent_deck(point: Marker3D) -> ArcaRaptorJumpSurface:
	var landing := _landing_marker(point)
	if landing == null or landing.global_position.y <= point.global_position.y + 0.40:
		return null
	return point.get_parent() as ArcaRaptorJumpSurface


func _deck_occupied(deck: ArcaRaptorJumpSurface) -> bool:
	for actor: ArcaRaptor in get_tree().get_nodes_in_group("arca_predator"):
		if actor == self or actor.get_world_3d() != get_world_3d():
			continue
		# Death disables collision, but the visible body still takes up this narrow top.
		var body_on_top := actor.visible and deck.contains_top(actor.global_position, 0.42 if actor.dead else 0.21)
		var landing_on_top := actor.jump_goal.is_finite() and deck.contains_top(actor.jump_goal)
		var approaching_top := is_instance_valid(actor.planned_jump) and actor._ascent_deck(actor.planned_jump) == deck
		if body_on_top or landing_on_top or approaching_top:
			return true
	return false


func _guard_occupied_deck(target: Vector3) -> bool:
	if not target.is_finite() or target.y < global_position.y + 0.46:
		return false
	for deck: ArcaRaptorJumpSurface in get_tree().get_nodes_in_group("arca_raptor_deck"):
		if deck.get_world_3d() == get_world_3d() and deck.contains_top(target) and not _deck_has_ascent(deck):
			guarded_deck = deck
			deck_check_tick = active_tick + 34
			_change_state(State.GUARD_DECK)
			return true
	return false


func _deck_has_ascent(deck: ArcaRaptorJumpSurface) -> bool:
	if _deck_occupied(deck):
		return false
	for child: Node in deck.get_children():
		var point := child as ArcaRaptorJumpPoint
		if point != null and _ascent_deck(point) == deck and point.link.enabled and (
				point.available(self) and not _jump_is_delayed(point)):
			return true
	return false


func _advance_deck_guard(seen: bool, delta: float) -> void:
	if not is_instance_valid(guarded_deck):
		_resume_hunt(seen)
		return
	if last_known_position.is_finite():
		_face(last_known_position - global_position, delta)
	if active_tick < deck_check_tick:
		return
	deck_check_tick = active_tick + 34
	if seen and not guarded_deck.contains_top(last_known_position):
		_resume_hunt(true)
	elif _tracking_gunfire() and not guarded_deck.contains_top(last_gunshot_position):
		_change_state(State.INVESTIGATE)
	elif not seen and elapsed > 3.0 and time_out_of_sight > behavior.memory_duration:
		_change_state(State.SEARCH)
	elif _deck_has_ascent(guarded_deck):
		_resume_hunt(seen)


func try_environment_jump(point: Marker3D) -> bool:
	if state == State.JUMP and elapsed > 0.1 and is_on_floor():
		_change_state(State.JUMP_LAND)
	var landing := _landing_marker(point)
	if not _can_leap() or landing == null or global_position.distance_squared_to(point.global_position) > 0.8:
		return false
	var deck := _ascent_deck(point)
	if deck != null and _deck_occupied(deck):
		return false
	var rise := landing.global_position.y - global_position.y
	if point is ArcaRaptorJumpPoint and rise > 0.99 and get_real_velocity().slide(Vector3.UP).length_squared() < 4.0:
		return false
	if point is ArcaRaptorJumpPoint and not point.available(self):
		return false
	for node: Node in get_tree().get_nodes_in_group("arca_predator"):
		if node != self and node.get_world_3d() == get_world_3d() and node.jump_goal.distance_squared_to(landing.global_position) < 1.1:
			return false
	if not _environment_launch(landing.global_position).is_finite():
		return false
	if is_instance_valid(pack) and not pack.claim(self, &"landing", landing.global_position, 1.10):
		return false
	reserved_jump = point
	jump_resume_flank = state == State.FLANK
	jump_goal = landing.global_position
	if point is ArcaRaptorJumpPoint:
		point.occupant = self
	_face(jump_goal - global_position, 1.0)
	_change_state(State.JUMP_LOAD)
	return true


func _release_jump() -> void:
	if is_instance_valid(pack):
		pack.release(self, &"landing")
	if is_instance_valid(reserved_jump) and reserved_jump is ArcaRaptorJumpPoint and reserved_jump.occupant == self:
		reserved_jump.occupant = null
	reserved_jump = null
	jump_goal = Vector3.INF


func _launch_reserved_jump(seen: bool) -> void:
	var launch := Vector3.INF
	if is_instance_valid(reserved_jump) and _has_takeoff_support():
		var deck := _ascent_deck(reserved_jump)
		if deck == null or not _deck_occupied(deck):
			launch = _environment_launch(jump_goal)
	if launch.is_finite():
		_begin_leap(launch, State.JUMP)
	else:
		if is_instance_valid(reserved_jump):
			_delay_failed_jump(reserved_jump)
		jump_retry = 0.55
		_resume_hunt(seen)


func _environment_launch(target: Vector3) -> Vector3:
	if is_instance_valid(player) and target.distance_squared_to(player.reserved_top) < 1.20:
		return Vector3.INF
	if (target - global_position).slide(Vector3.UP).length_squared() > 14.44:
		return Vector3.INF
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = $CollisionShape3D.shape
	probe.transform = $CollisionShape3D.global_transform
	probe.transform.origin += target - global_position + Vector3.UP * 0.12
	probe.collision_mask = 3
	probe.exclude = [get_rid()]
	physical_queries += 1
	if not get_world_3d().direct_space_state.intersect_shape(probe, 1).is_empty():
		return Vector3.INF
	return _leap_velocity(target, ENVIRONMENT_JUMP_TIME, 3)


func _seek_environment_jump(destination: Vector3 = Vector3.INF) -> bool:
	if not destination.is_finite():
		destination = last_known_position
		if destination.is_finite() and absf(destination.y - global_position.y) < 0.50:
			return false
	if not destination.is_finite() or not _can_leap() or jump_retry > 0.0:
		return false
	if is_instance_valid(planned_jump):
		var deck := _ascent_deck(planned_jump)
		var remaining := global_position.distance_to(planned_jump.global_position)
		if remaining < approach_best_distance - 0.09:
			approach_best_distance = remaining
			approach_progress_tick = active_tick
		if (deck != null and (not deck.contains_top(destination) or _deck_occupied(deck))) 				or not planned_jump.available(self) or not planned_jump.link.enabled 				or stalled_for > 0.26 or active_tick - approach_progress_tick > 54:
			_delay_failed_jump(planned_jump)
			_clear_approach()
		else:
			_follow_path(planned_jump.landing.global_position, move_speed)
			return true
	var nearby: Array[Marker3D] = []
	for node: Node in get_tree().get_nodes_in_group("arca_raptor_jump"):
		if node.get_world_3d() != get_world_3d() or global_position.distance_squared_to(node.global_position) > 36.0:
			continue
		if _jump_is_delayed(node):
			continue
		var deck := _ascent_deck(node)
		if deck != null and (not deck.contains_top(destination) or _deck_occupied(deck)):
			continue
		var landing := _landing_marker(node)
		if landing != null and absf(node.global_position.y - global_position.y) < 0.45 and (
				landing.global_position.distance_to(destination) + 0.65 < node.global_position.distance_to(destination)):
			nearby.append(node)
	nearby.sort_custom(func(a: Marker3D, b: Marker3D) -> bool:
		return _jump_score(a) < _jump_score(b))
	for point in nearby.slice(0, 2):
		if _jump_is_delayed(point) or (point is ArcaRaptorJumpPoint and not point.available(self)):
			continue
		if global_position.distance_squared_to(point.global_position) <= (0.18 if point is ArcaRaptorJumpPoint else 0.8):
			if try_environment_jump(point):
				return true
			_delay_failed_jump(point)
		elif point is ArcaRaptorJumpPoint and point.link.enabled:
			var map := agent.get_navigation_map()
			path_requests += 1
			var approach := NavigationServer3D.map_get_path(map, global_position, point.global_position, true, 1)
			if approach.size() < 2 or approach[-1].distance_squared_to(point.global_position) > 0.6:
				continue
			path_requests += 1
			var crossing := NavigationServer3D.map_get_path(map, point.global_position, point.landing.global_position, true, 3)
			if crossing.size() < 2 or crossing[-1].distance_squared_to(point.landing.global_position) > 0.6:
				continue
			if is_instance_valid(pack) and not pack.claim(self, &"approach", point.global_position, 1.05):
				continue
			planned_jump = point
			approach_best_distance = INF
			approach_progress_tick = active_tick
			agent.navigation_layers = 3
			cached_path_target = Vector3.INF
			_follow_path(point.landing.global_position, move_speed)
			return true
	jump_retry = 0.15
	return false


func _clear_approach() -> void:
	link_arrival_pending = false
	if not is_instance_valid(planned_jump):
		return
	planned_jump = null
	agent.navigation_layers = 1
	cached_path_target = Vector3.INF
	if is_instance_valid(pack):
		pack.release(self, &"approach")


func _on_navigation_link(details: Dictionary) -> void:
	if not is_instance_valid(planned_jump) or details.get("owner") != planned_jump.link:
		return
	# Native NavigationAgent signals can fire while it is indexing its path.
	link_arrival_pending = true


func _consume_navigation_link() -> bool:
	if not link_arrival_pending:
		return false
	link_arrival_pending = false
	var point := planned_jump
	_clear_approach()
	if is_instance_valid(point):
		navigation_link_arrivals += 1
		if not try_environment_jump(point):
			_delay_failed_jump(point)
			jump_retry = 0.18
			decision_due = active_tick
	return true


func _should_leave_deck() -> bool:
	if not is_on_floor() or global_position.y < 0.46 or active_tick < descent_retry_tick:
		return false
	var pursuit := state in [State.CHASE, State.STALK, State.ALERT, State.INVESTIGATE, State.FLANK]
	var goal := last_known_position if perceived else (last_gunshot_position if _tracking_gunfire() else last_heard_position)
	if not ((pursuit and goal.is_finite() and goal.y < global_position.y - 0.23)
			or (state == State.SEARCH and elapsed > 0.9) or (state == State.WAIT and elapsed > 2.5)):
		return false
	return not _deck_exits().is_empty()


func _deck_exits() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	for node: Node in get_tree().get_nodes_in_group("arca_raptor_jump"):
		var point := node as Marker3D
		if point == null or point.get_world_3d() != get_world_3d():
			continue
		if point.global_position.distance_squared_to(global_position) > 4.41 				or absf(point.global_position.y - global_position.y) > 0.24:
			continue
		var landing := _landing_marker(point)
		if landing != null and landing.global_position.y < point.global_position.y - 0.40:
			points.append(point)
	return points


func _advance_descent(seen: bool) -> void:
	if seen and absf(last_known_position.y - global_position.y) <= 0.15 and _near_target(last_known_position):
		descent_retry_tick = active_tick + 42
		_resume_hunt(seen)
		return
	if not is_on_floor() or global_position.y < 0.44:
		_resume_hunt(seen)
		return
	if is_instance_valid(descent_point):
		var remaining := (descent_point.global_position - global_position).slide(Vector3.UP).length()
		if remaining <= 0.38:
			var point := descent_point
			if try_environment_jump(point):
				return
			_delay_failed_jump(point)
			_release_descent_approach()
		elif active_tick - descent_progress_tick > 44:
			_delay_failed_jump(descent_point)
			_release_descent_approach()
		else:
			if remaining < descent_best_distance - 0.07:
				descent_best_distance = remaining
				descent_progress_tick = active_tick
			_follow_path(descent_point.global_position, move_speed * 0.70)
			return
	if active_tick < descent_retry_tick:
		return
	descent_retry_tick = active_tick + 18
	var exits := _deck_exits()
	if exits.is_empty():
		_resume_hunt(seen)
		return
	exits.sort_custom(func(a: Marker3D, b: Marker3D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	for point in exits:
		if _jump_is_delayed(point) or (point is ArcaRaptorJumpPoint and (
				not point.available(self) or (is_instance_valid(point.link) and not point.link.enabled))):
			continue
		var landing := _landing_marker(point)
		if _pack_space_occupied(landing.global_position):
			_delay_failed_jump(point)
			continue
		if is_instance_valid(pack) and not pack.claim(self, &"descent", point.global_position, 0.85):
			continue
		descent_point = point
		descent_progress_tick = active_tick
		descent_best_distance = INF
		cached_path_target = Vector3.INF
		_play("Walk")
		return
	if animation.current_animation != clips.get("Idle"):
		_play("Idle")


func _release_descent_approach() -> void:
	descent_point = null
	if is_instance_valid(pack):
		pack.release(self, &"descent")


func _delay_failed_jump(point: Marker3D) -> void:
	failed_jump_until[point.get_instance_id()] = active_tick + 105


func _jump_is_delayed(point: Marker3D) -> bool:
	return active_tick < failed_jump_until.get(point.get_instance_id(), 0)


func _jump_score(point: Marker3D) -> float:
	var approach := (point.global_position - global_position).slide(Vector3.UP)
	var facing := -global_basis.z.dot(approach.normalized())
	return approach.length_squared() + (1.0 - facing) * 0.65 + (4.0 if _recently_hurt_at(point.global_position) else 0.0)


func _leap_velocity(target: Vector3, duration: float, mask: int = 1) -> Vector3:
	var space := get_world_3d().direct_space_state
	var support := PhysicsRayQueryParameters3D.create(target + Vector3.UP * 0.25,
		target + Vector3.DOWN * 0.55, 1, [get_rid()])
	physical_queries += 1
	var floor_hit := space.intersect_ray(support)
	if floor_hit.is_empty() or floor_hit.normal.y < 0.75:
		return Vector3.INF
	target.y = floor_hit.position.y + 0.045
	var offset := target - global_position
	if offset.y - 0.07 > behavior.max_leap_height or offset.y < -behavior.max_drop_height:
		return Vector3.INF
	var gravity := get_gravity()
	var launch := (offset - gravity * (0.5 * duration * duration)) / duration
	var shape_node: CollisionShape3D = $CollisionShape3D
	var sweep := PhysicsShapeQueryParameters3D.new()
	sweep.shape = shape_node.shape
	sweep.collision_mask = mask
	sweep.exclude = [get_rid()]
	sweep.transform = shape_node.global_transform
	var start := sweep.transform.origin
	# The floor solver may leave the resting capsule touching a slab seam.
	sweep.transform.origin += Vector3.UP * 0.018
	for segment: int in range(1, 11):
		var t := duration * float(segment) / 10.0
		var next := start + launch * t + gravity * (0.5 * t * t)
		physical_queries += 1 + int(segment > 1)
		if segment > 1 and not space.intersect_shape(sweep, 1).is_empty():
			return Vector3.INF
		sweep.motion = next - sweep.transform.origin
		var result := space.cast_motion(sweep)
		if result.size() < 2 or result[0] < 0.999:
			return Vector3.INF
		sweep.transform.origin = next
	return launch


func _begin_leap(launch: Vector3, next: State) -> void:
	leap_direction = launch
	velocity = launch
	_face(Vector3(launch.x, 0.0, launch.z), 1.0)
	_change_state(next)


func _advance_leap(distance: float) -> void:
	if state == State.POUNCE and not swing_checked and elapsed >= POUNCE_CONTACT_START 			and elapsed <= POUNCE_CONTACT_END and distance <= 1.35 			and absf(global_position.y - player.global_position.y) <= 1.05 and _can_see_player():
		swing_checked = true
		player.take_pounce_damage(POUNCE_DAMAGE, leap_direction)
		attack_landed.emit()
	if state == State.JUMP and is_on_wall():
		leap_direction.x = 0.0
		leap_direction.z = 0.0
	if elapsed > 0.10 and (is_on_floor() or (state == State.POUNCE and (is_on_wall() or elapsed > 1.0))):
		if state == State.POUNCE and not swing_checked:
			misses += 1
		if is_on_floor():
			_play_footstep()
			if state == State.JUMP and is_instance_valid(reserved_jump) and (
					absf(global_position.y - jump_goal.y) > 0.35
					or (global_position - jump_goal).slide(Vector3.UP).length_squared() > 0.65):
				_delay_failed_jump(reserved_jump)
		leap_direction = Vector3.ZERO
		velocity.x = 0.0
		velocity.z = 0.0
		_change_state(State.JUMP_LAND if state == State.JUMP else State.RECOVER)


func _check_shutter_contact() -> void:
	for index: int in get_slide_collision_count():
		var surface := get_slide_collision(index).get_collider() as Node
		if surface != null and surface.is_in_group("arca_shutter"):
			shutter_noise_cooldown = 1.45
			_play_voice(STEPS[2], -16.0, 1.48)
			return
