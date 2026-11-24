extends "res://player/player.gd"
## ARCA keeps the TPS controller while replacing its visible robot with Regina.

const REGINA_MODEL: PackedScene = preload("res://arca/player/regina_model.tscn")
const REGINA_WEAPON_SOCKET: PackedScene = preload("res://arca/player/regina_weapon_socket.tscn")
const REGINA_GRIP: AnimationLibrary = preload("res://arca/assets/characters/regina/grip.tres")
const REGINA_SKIN_PATH := "Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"

@export var contact_damage: int = 25
@onready var health_component: ArcaHealth = $HealthComponent
@onready var ammo_component: ArcaAmmo = $AmmoComponent
var grounded_once: bool = false
var landing_armed: bool = false


func _ready() -> void:
	directional_locomotion = true
	jump_speed = 2.6
	super._ready()
	_install_regina()
	add_to_group("arca_player")
	$BulletCache.process_mode = Node.PROCESS_MODE_DISABLED
	health_component.died.connect(_on_died)
	# The spring arm should collide with walls, never its owner's capsule.
	$CameraBase/CameraRot/SpringArm3D.add_excluded_object(get_rid())


func _install_regina() -> void:
	var model: Node3D = REGINA_MODEL.instantiate() as Node3D
	player_model.add_child(model)
	var regina: Node3D = model.get_node("Regina") as Node3D
	# The F6 wrapper faces -Z; the inherited TPS camera/motion uses +Z.
	regina.rotation.y = 0.0
	var skeleton: Skeleton3D = regina.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
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
	var effects: Array[Node] = robot_muzzle.get_children()
	for effect: Node in effects:
		effect.reparent(muzzle, false)
	var shot_effect: CPUParticles3D = muzzle.get_node("ShootParticle") as CPUParticles3D
	var flash_effect: CPUParticles3D = muzzle.get_node("MuzzleFlash") as CPUParticles3D
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
	if grounded_once and not is_on_floor():
		landing_armed = true
	super._physics_process(delta)
	grounded_once = grounded_once or is_on_floor()


@rpc("call_local")
func jump() -> void:
	landing_armed = true
	animation_tree["parameters/land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	super.jump()


@rpc("call_local")
func land() -> void:
	if landing_armed:
		animation_tree["parameters/land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		landing_armed = false
	super.land()


@rpc("call_local")
func hit() -> void:
	take_damage(contact_damage)


func take_damage(amount: int) -> void:
	if health_component.take_damage(amount):
		add_camera_shake_trauma(0.75)
		if health_component.current > 0:
			animation_tree["parameters/chest_hit/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reload") and not event.is_echo() and health_component.current > 0:
		ammo_component.start_reload()
		get_viewport().set_input_as_handled()


func can_fire() -> bool:
	if ammo_component.try_consume():
		return true
	if not ammo_component.reloading:
		$DryFire.play()
		fire_cooldown.start()
		ammo_component.start_reload()
	return false


func _on_died() -> void:
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
