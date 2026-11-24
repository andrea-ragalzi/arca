extends "res://player/player.gd"
## ARCA keeps the TPS controller while replacing its visible robot with Regina.

signal movement_noise(origin: Vector3)
signal physical_audio(event: StringName)
signal shot_resolved(surface: StringName, position: Vector3)
signal equipped_ammo_changed(component: ArcaAmmo)

enum Reaction { READY, DODGING, DOWN, RISING }
const DODGE_TIME: float = 0.34
const DODGE_SPEED: float = 6.4
const RISE_TIME: float = 0.55
## Radius of the sphere swept by the TPS spring arm; covers the camera near plane.
const CAMERA_CLEARANCE: float = 0.12

const TRAVERSAL := preload("res://arca/player/regina_traversal.gd")
const EFFORT := preload("res://arca/audio/regina/effort.wav")
const HIT_VOICE := preload("res://arca/audio/regina/hit.wav")
const FALL_VOICE := preload("res://arca/audio/regina/fall.wav")
const FIELD_OUTFIT := preload("res://arca/player/regina_field_outfit.gd")
const REGINA_MODEL: PackedScene = preload("res://arca/player/regina_model.tscn")
const REGINA_WEAPON_SOCKET: PackedScene = preload("res://arca/player/regina_weapon_socket.tscn")
const REGINA_GRIP: AnimationLibrary = preload("res://arca/assets/characters/regina/grip.tres")
const REGINA_SKIN_PATH := "Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"

@export var contact_damage: int = 25
@onready var health_component: ArcaHealth = $HealthComponent
@onready var ammo_component: ArcaAmmo = $AmmoComponent
@onready var backup_ammo: ArcaAmmo = $BackupAmmo
var weapon_slot := 0
var grounded_once: bool = false
var landing_armed: bool = false
var movement_noise_interval: float = 0.0
var reaction: Reaction = Reaction.READY
var reaction_remaining: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_velocity: Vector3 = Vector3.ZERO
var impact_velocity: Vector3 = Vector3.ZERO
var dodge_side: float = 1.0
var regina_visual: Node3D
var weapon_audio: AudioStreamPlayer3D
var regina_voice: AudioStreamPlayer3D
var regina_steps: AudioStreamPlayer3D
var step_distance: float = 0.0
var fall_pending: bool = false
var fall_floor_thud: bool = false
var fall_side := 1.0
var reaction_pose := 0.0
var reserved_top := Vector3.INF
var traversal_delay := 0.0
var traversal_drift := Vector3.ZERO
var traversal_probe_remaining := 0.0
var down_volume: CollisionShape3D


func _ready() -> void:
	directional_locomotion = true
	jump_speed = 3.04
	super._ready()
	_install_regina()
	down_volume = CollisionShape3D.new()
	down_volume.name = "DownedBody"
	var low_capsule := CapsuleShape3D.new()
	low_capsule.radius = 0.31
	low_capsule.height = 1.45
	down_volume.shape = low_capsule
	down_volume.disabled = true
	add_child(down_volume)
	sound_effect_shoot.volume_db = -8.0
	regina_voice = AudioStreamPlayer3D.new()
	regina_voice.name = "ReginaVoice"
	regina_voice.position.y = 1.42
	regina_voice.unit_size = 3.0
	regina_voice.volume_db = -7.5
	add_child(regina_voice)
	regina_steps = AudioStreamPlayer3D.new()
	regina_steps.name = "ReginaSteps"
	regina_steps.stream = $SoundEffects/Step.stream
	regina_steps.volume_db = -13.0
	regina_steps.unit_size = 2.0
	add_child(regina_steps)
	add_to_group("arca_player")
	$BulletCache.process_mode = Node.PROCESS_MODE_DISABLED
	health_component.died.connect(_on_died)
	# The spring arm should collide with walls, never its owner's capsule.
	var spring_arm: SpringArm3D = $CameraBase/CameraRot/SpringArm3D
	spring_arm.add_excluded_object(get_rid())
	# Sweep a sphere instead of the inherited ray so the camera stops clear of
	# walls, floors and the 2.50-2.65 m soffits. The ray left 1 cm, which put the
	# 5 cm near plane inside the surface when the arm contracted.
	var camera_volume := SphereShape3D.new()
	camera_volume.radius = CAMERA_CLEARANCE
	spring_arm.shape = camera_volume


func _install_regina() -> void:
	var model: Node3D = REGINA_MODEL.instantiate() as Node3D
	player_model.add_child(model)
	regina_visual = model
	var regina: Node3D = model.get_node("Regina") as Node3D
	# The F6 wrapper faces -Z; the inherited TPS camera/motion uses +Z.
	var skeleton: Skeleton3D = regina.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	FIELD_OUTFIT.new().fit(model, skeleton)
	regina.rotation.y = 0.0
	var wrist_name: StringName = &"arm right wrist_021"
	if skeleton.find_bone(wrist_name) < 0:
		push_error("Regina weapon attachment bone is missing: " + String(wrist_name))
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "WeaponAttachment"
	attachment.bone_name = wrist_name
	skeleton.add_child(attachment)
	var socket: Marker3D = REGINA_WEAPON_SOCKET.instantiate() as Marker3D
	attachment.add_child(socket)
	var gun: Node3D = socket.get_node("ReginaHandgun") as Node3D
	var grip: Marker3D = gun.get_node("GripPose") as Marker3D
	gun.transform = grip.transform.affine_inverse()
	var muzzle: Marker3D = gun.get_node("ShootFrom") as Marker3D
	var robot_muzzle: Marker3D = player_model.get_node(
		^"Robot_Skeleton/Skeleton3D/GunBone/ShootFrom") as Marker3D
	var shot_effect := ArcaReginaBallistics.muzzle_particles(true)
	var flash_effect := ArcaReginaBallistics.muzzle_particles(false)
	muzzle.add_child(shot_effect)
	muzzle.add_child(flash_effect)
	weapon_audio = AudioStreamPlayer3D.new()
	weapon_audio.name = "Gunshot"
	weapon_audio.stream = sound_effect_shoot.stream
	weapon_audio.volume_db = -8.0
	weapon_audio.unit_size = 4.0
	weapon_audio.max_distance = 34.0
	muzzle.add_child(weapon_audio)
	bind_weapon_nodes(muzzle, shot_effect, flash_effect)
	robot_muzzle.queue_free()
	player_model.get_node("Robot_Skeleton").visible = false
	var robot_animation: AnimationPlayer = player_model.get_node("AnimationPlayer") as AnimationPlayer
	robot_animation.stop()
	robot_animation.speed_scale = 0.0
	animation_tree.active = false
	animation_tree.root_node = NodePath("../PlayerModel/ReginaModel")
	animation_tree.anim_player = NodePath("../PlayerModel/ReginaModel/AnimationPlayer")
	animation_tree.root_motion_track = NodePath("RootMotion")
	var regina_animation: AnimationPlayer = model.get_node("AnimationPlayer") as AnimationPlayer
	regina_animation.add_animation_library("grip", REGINA_GRIP)
	var graph := animation_tree.tree_root as AnimationNodeBlendTree
	var wrist_pose := AnimationNodeAnimation.new()
	wrist_pose.animation = &"grip/RightWristGrip"
	graph.add_node("wrist_pose", wrist_pose)
	var wrist_add := AnimationNodeAdd2.new()
	wrist_add.filter_enabled = true
	wrist_add.filters = PackedStringArray([REGINA_SKIN_PATH + ":arm right wrist_021"])
	graph.add_node("wrist_grip", wrist_add)
	graph.disconnect_node("output", 0)
	graph.connect_node("wrist_grip", 0, "eye_blend")
	graph.connect_node("wrist_grip", 1, "wrist_pose")
	animation_tree["parameters/wrist_grip/add_amount"] = 1.0
	var hand_pose := AnimationNodeAnimation.new()
	hand_pose.animation = &"grip/RightHandGrip"
	graph.add_node("hand_pose", hand_pose)
	var hand_blend := AnimationNodeBlend2.new()
	hand_blend.filter_enabled = true
	var hand_filters := PackedStringArray()
	var grip_animation: Animation = REGINA_GRIP.get_animation("RightHandGrip")
	for track in grip_animation.get_track_count():
		hand_filters.append(String(grip_animation.track_get_path(track)))
	hand_blend.filters = hand_filters
	graph.add_node("hand_grip", hand_blend)
	graph.connect_node("hand_grip", 0, "wrist_grip")
	graph.connect_node("hand_grip", 1, "hand_pose")
	regina_animation.add_animation_library("reactions",
		preload("res://arca/assets/characters/regina/reactions.tres"))
	var hit_clip := AnimationNodeAnimation.new()
	hit_clip.animation = &"reactions/Hit_Chest"
	graph.add_node("hit_chest_clip", hit_clip)
	var chest_hit := AnimationNodeOneShot.new()
	chest_hit.mix_mode = AnimationNodeOneShot.MIX_MODE_ADD
	chest_hit.fadein_time = 0.04
	chest_hit.fadeout_time = 0.08
	graph.add_node("chest_hit", chest_hit)
	graph.connect_node("chest_hit", 0, "hand_grip")
	graph.connect_node("chest_hit", 1, "hit_chest_clip")

	graph.connect_node("output", 0, "chest_hit")
	animation_tree["parameters/hand_grip/blend_amount"] = 1.0
	var aim := graph.get_node("aim") as AnimationNodeAdd3
	aim.filter_enabled = true
	aim.filters = PackedStringArray([
		REGINA_SKIN_PATH + ":head neck lower_06",
		REGINA_SKIN_PATH + ":head neck upper_07",
		REGINA_SKIN_PATH + ":arm right shoulder 1_018",
		REGINA_SKIN_PATH + ":arm right shoulder 2_019",
		REGINA_SKIN_PATH + ":arm right elbow_020",
		REGINA_SKIN_PATH + ":arm right wrist_021",
	])
	var walk := AnimationNodeBlendSpace2D.new()
	var clips: Array[StringName] = [&"Idle", &"running_nogun", &"strafe_back", &"strafe_right", &"strafe_left"]
	var points: Array[Vector2] = [Vector2.ZERO, Vector2(0, 1), Vector2(0, -1), Vector2.LEFT, Vector2.RIGHT]
	for index in clips.size():
		var clip := AnimationNodeAnimation.new()
		clip.animation = clips[index]
		walk.add_blend_point(clip, points[index])
	graph.remove_node("walk")
	graph.add_node("walk", walk)
	graph.connect_node("walk_speed", 0, "walk")
	var landing := graph.get_node("land") as AnimationNodeOneShot
	landing.fadein_time = 0.05
	landing.fadeout_time = 0.05
	var transition := graph.get_node("state") as AnimationNodeTransition
	transition.xfade_time = 0.05
	animation_tree["parameters/walk_speed/scale"] = 0.94
	animation_tree.active = true


func _physics_process(delta: float) -> void:
	var was_grounded := is_on_floor()
	var before := global_position
	super._physics_process(delta)
	var grounded := is_on_floor()
	if grounded_once and was_grounded and not grounded:
		landing_armed = true
	if grounded and landing_armed and not was_grounded:
		land()
	grounded_once = grounded_once or grounded
	var travel := (global_position - before).slide(Vector3.UP)
	if grounded and was_grounded and reaction == Reaction.READY and travel.length_squared() > 0.00018:
		step_distance += travel.length()
		if step_distance >= 0.88:
			step_distance -= 0.88
			regina_steps.play()
			physical_audio.emit(&"step")
	movement_noise_interval = maxf(0.0, movement_noise_interval - delta)
	if grounded and travel.length_squared() >= 7.84 * delta * delta and movement_noise_interval == 0.0:
		movement_noise_interval = 0.65
		movement_noise.emit(global_position)


func get_jump_launch() -> Vector3:
	var basis := player_input.camera_camera.global_basis
	var intent := player_input.motion
	var direction := (basis.x * intent.x + basis.z * intent.y).slide(Vector3.UP).normalized()
	var arc := TRAVERSAL.launch(self, $CapsuleShape3D, direction)
	if arc == null:
		return super.get_jump_launch()
	reserved_top = arc.target
	traversal_delay = arc.delay
	traversal_drift = arc.drift
	traversal_probe_remaining = 0.0
	return Vector3.UP * arc.vertical + (arc.drift if arc.delay == 0.0 else Vector3.ZERO)


func _stop_traversal() -> void:
	reserved_top = Vector3.INF
	traversal_delay = 0.0
	traversal_drift = Vector3.ZERO


func _advance_traversal(delta: float) -> void:
	if not reserved_top.is_finite() or is_on_floor():
		return
	traversal_probe_remaining -= delta
	if is_on_wall() or is_on_ceiling() or (traversal_probe_remaining <= 0.0
			and TRAVERSAL.occupied(self, $CapsuleShape3D, reserved_top)):
		_stop_traversal()
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if traversal_probe_remaining <= 0.0:
		traversal_probe_remaining = 0.08
	if traversal_delay > 0.0:
		traversal_delay = maxf(0.0, traversal_delay - delta)
		if traversal_delay == 0.0:
			velocity.x = traversal_drift.x
			velocity.z = traversal_drift.z


func apply_input(delta: float) -> void:
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	if reaction == Reaction.READY:
		_advance_traversal(delta)
		super.apply_input(delta)
		return

	if reaction != Reaction.DOWN or is_on_floor():
		reaction_remaining = maxf(0.0, reaction_remaining - delta)
	player_input.jumping = false
	motion = Vector2(dodge_side, 0.0) if reaction == Reaction.DODGING else Vector2.ZERO
	animate(Animations.STRAFE if reaction == Reaction.DODGING else Animations.WALK, delta)
	var drive := dodge_velocity if reaction == Reaction.DODGING else impact_velocity
	impact_velocity = impact_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	velocity.x = drive.x
	velocity.z = drive.z
	velocity += get_gravity() * delta
	move_and_slide()
	if is_on_floor() and reaction == Reaction.DOWN and fall_pending and reaction_remaining <= 2.13:
		fall_pending = false
		_play_regina_voice(FALL_VOICE, &"fall")
		if not landing_armed and not fall_floor_thud:
			sound_effect_land.play()
			fall_floor_thud = true

	match reaction:
		Reaction.DODGING:
			_set_reaction_pose(0.0, sin(PI * reaction_remaining / DODGE_TIME) * dodge_side * -0.18)
			if reaction_remaining <= 0.0:
				_finish_reaction()
		Reaction.DOWN:
			reaction_pose = lerpf(reaction_pose, 1.0 if is_on_floor() else 0.29, minf(delta * 12.0, 1.0))
			_apply_floor_pose(reaction_pose)
			if reaction_remaining <= 0.0:
				reaction = Reaction.RISING
				reaction_remaining = RISE_TIME
		Reaction.RISING:
			var down_weight := smoothstep(0.0, RISE_TIME, reaction_remaining)
			_apply_floor_pose(down_weight)
			if reaction_remaining <= 0.0:
				_finish_reaction()


func _apply_floor_pose(weight: float) -> void:
	var side := player_model.global_basis.x * fall_side
	var sweep := PhysicsShapeQueryParameters3D.new()
	var clearance := SphereShape3D.new()
	clearance.radius = 0.24
	sweep.shape = clearance
	sweep.exclude = [get_rid()]
	sweep.collision_mask = collision_mask
	var space := get_world_3d().direct_space_state
	var tilt := 1.40 * weight
	for distance: float in [0.48, 0.86, 1.25, 1.58]:
		sweep.transform.origin = global_position + Vector3.UP * maxf(0.30, distance * cos(tilt)) - side * distance * sin(tilt)
		if not space.intersect_shape(sweep, 1).is_empty():
			tilt = minf(tilt, asin(minf(0.35 / distance, 1.0)))
			break
	_update_downed_volume(-side, tilt, weight)
	_set_reaction_pose(0.05 * weight, tilt * fall_side)


func _update_downed_volume(side: Vector3, tilt: float, weight: float) -> void:
	if not is_on_floor() or tilt < 1.03 or weight < 0.72:
		down_volume.set_deferred("disabled", true)
		return
	if not down_volume.disabled:
		return
	var center := global_position + side * 0.76 + Vector3.UP * 0.33
	var pose := Transform3D(Basis.looking_at(Vector3.UP, side), center)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = down_volume.shape
	query.transform = pose
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		down_volume.global_transform = pose
		down_volume.set_deferred("disabled", false)


func _set_reaction_pose(height: float, tilt: float) -> void:
	regina_visual.position.y = height
	regina_visual.rotation.z = tilt


func _finish_reaction() -> void:
	if is_instance_valid(down_volume):
		down_volume.set_deferred("disabled", true)
	reaction = Reaction.READY
	reaction_remaining = 0.0
	impact_velocity = Vector3.ZERO
	reaction_pose = 0.0
	fall_pending = false
	airborne_time = 0.0 if is_on_floor() else airborne_time
	root_motion = Transform3D.IDENTITY
	_set_reaction_pose(0.0, 0.0)


func try_dodge(side: float) -> bool:
	if not can_process() or not is_on_floor() or not can_use_weapon() or dodge_cooldown > 0.0:
		return false
	var lateral := player_input.get_camera_rotation_basis().x
	lateral.y = 0.0
	if lateral.length_squared() < 0.001:
		return false
	dodge_side = -1.0 if side < 0.0 else 1.0
	dodge_velocity = lateral.normalized() * dodge_side * DODGE_SPEED
	reaction = Reaction.DODGING
	reaction_remaining = DODGE_TIME
	dodge_cooldown = 0.86
	return true


func take_pounce_damage(amount: int, direction: Vector3 = Vector3.ZERO) -> void:
	var before := health_component.current
	take_damage(amount)
	if health_component.current > 0 and health_component.current < before and reaction != Reaction.DOWN:
		reaction = Reaction.DOWN
		_stop_traversal()
		reaction_remaining = 2.35
		fall_pending = true
		fall_floor_thud = false
		fall_side = -1.0 if player_model.global_basis.x.dot(direction) > 0.0 else 1.0
		impact_velocity = Vector3(direction.x, 0.0, direction.z).normalized() * 5.6
		ammo_component.cancel_reload()


func is_downed() -> bool:
	return reaction in [Reaction.DOWN, Reaction.RISING]


func can_use_weapon() -> bool:
	return health_component.current > 0 and reaction == Reaction.READY


@rpc("call_local")
func jump() -> void:
	landing_armed = true
	animation_tree["parameters/land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	super.jump()
	_play_regina_voice(EFFORT, &"effort")


@rpc("call_local")
func land() -> void:
	if not landing_armed:
		return
	landing_armed = false
	_stop_traversal()
	if reaction == Reaction.READY:
		animation_tree["parameters/land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	sound_effect_land.play()
	fall_floor_thud = reaction == Reaction.DOWN
	physical_audio.emit(&"landing")


func _play_regina_voice(sample: AudioStream, event: StringName) -> void:
	regina_voice.stream = sample
	regina_voice.play()
	physical_audio.emit(event)


@rpc("call_local")
func hit() -> void:
	take_damage(contact_damage)


func take_damage(amount: int) -> void:
	if health_component.take_damage(amount):
		if reserved_top.is_finite():
			_stop_traversal()
			velocity.x = 0.0
			velocity.z = 0.0
		_play_regina_voice(HIT_VOICE, &"hit")
		add_camera_shake_trauma(0.75)
		if health_component.current > 0:
			animation_tree["parameters/chest_hit/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE


func fire_weapon(target: Vector3) -> void:
	var packet := ArcaReginaBallistics.resolve(self, shoot_from.global_position, target)
	var collider: Node = packet.collider
	if is_instance_valid(collider) and collider.has_method(&"hit"):
		collider.hit.rpc()
	ArcaReginaBallistics.present(get_parent(), packet)
	if packet.start.is_equal_approx(shoot_from.global_position):
		shoot()
	else:
		# An obstructed muzzle still consumes the round and plays the shot and impact.
		_play_shot_sound()
	shot_resolved.emit(packet.surface, packet.end)
	shot_fired.emit()


@rpc("call_local")
func shoot() -> void:
	shoot_particle.restart()
	shoot_particle.emitting = true
	muzzle_particle.restart()
	muzzle_particle.emitting = true
	_play_shot_sound()


func _play_shot_sound() -> void:
	fire_cooldown.start()
	weapon_audio.play()
	add_camera_shake_trauma(0.35)


func get_shoot_origin() -> Vector3:
	# The muzzle can cross a thin wall while the player's capsule cannot.
	# Sweep from the chest so projectiles always start on this side of cover.
	var chest: Vector3 = global_position + Vector3.UP * 1.4
	var muzzle: Vector3 = shoot_from.global_position
	var query := PhysicsRayQueryParameters3D.create(chest, muzzle, 1, [get_rid()])
	var collision: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not collision.is_empty():
		return collision.position + collision.normal * 0.2
	return muzzle


func equip_weapon(slot: int) -> bool:
	if not can_use_weapon() or slot not in [0, 1] or slot == weapon_slot:
		return false
	ammo_component.cancel_reload()
	weapon_slot = slot
	ammo_component = $AmmoComponent if slot == 0 else backup_ammo
	equipped_ammo_changed.emit(ammo_component)
	return true


func capture_ammo_state() -> Dictionary:
	return {"slot": weapon_slot, "primary": [$AmmoComponent.magazine, $AmmoComponent.reserve],
		"backup": [backup_ammo.magazine, backup_ammo.reserve]}


func restore_ammo_state(saved: Dictionary) -> void:
	var primary: ArcaAmmo = $AmmoComponent
	var slot: int = saved.get("slot", 0)
	for entry: Dictionary in [{"state": saved.get("primary", []), "ammo": primary},
			{"state": saved.get("backup", []), "ammo": backup_ammo}]:
		if entry.state.size() == 2:
			entry.ammo.cancel_reload()
			entry.ammo.magazine = clampi(entry.state[0], 0, entry.ammo.magazine_size)
			entry.ammo.reserve = maxi(entry.state[1], 0)
	equip_weapon(slot)
	ammo_component.changed.emit(ammo_component.magazine, ammo_component.reserve)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("dodge") and health_component.current > 0:
		if reaction == Reaction.DOWN:
			reaction_remaining = minf(reaction_remaining, 0.2)
		else:
			try_dodge(Input.get_axis("move_left", "move_right"))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("weapon_primary") or event.is_action_pressed("weapon_backup"):
		equip_weapon(1 if event.is_action_pressed("weapon_backup") else 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reload") and can_use_weapon():
		ammo_component.start_reload()
		get_viewport().set_input_as_handled()


func can_fire() -> bool:
	if not can_use_weapon():
		return false
	if ammo_component.try_consume():
		return true
	if not ammo_component.reloading:
		$DryFire.play()
		fire_cooldown.start()
		ammo_component.start_reload()
	return false


func _on_died() -> void:
	_stop_traversal()
	_finish_reaction()
	ammo_component.cancel_reload()
	player_input.set_process(false)
	player_input.set_process_input(false)
	player_input.motion = Vector2.ZERO
	player_input.shooting = false
	player_input.aiming = false
	player_input.toggled_aim = false
	player_input.jumping = false
	player_input.camera_animation.stop()
	motion = Vector2.ZERO
	velocity = Vector3.ZERO
	fire_cooldown.stop()
	set_physics_process(false)
	# Stop the locomotion driver before handing the skeleton to the death clip.
	animation_tree.active = false
	var regina_animation: AnimationPlayer = player_model.get_node("ReginaModel/AnimationPlayer")
	regina_animation.play(&"reactions/Death01")
	crosshair.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
