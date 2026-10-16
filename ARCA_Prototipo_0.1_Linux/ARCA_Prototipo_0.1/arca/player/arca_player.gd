extends "res://player/player.gd"
## ARCA adds health; the TPS input, root motion, camera and weapon stay upstream.

@export var contact_damage: int = 25
@onready var health_component: ArcaHealth = $HealthComponent


func _ready() -> void:
	super._ready()
	add_to_group("arca_player")
	$BulletCache.process_mode = Node.PROCESS_MODE_DISABLED
	health_component.died.connect(_on_died)
	# The spring arm should collide with walls, never its owner's capsule.
	$CameraBase/CameraRot/SpringArm3D.add_excluded_object(get_rid())


@rpc("call_local")
func hit() -> void:
	take_damage(contact_damage)


func take_damage(amount: int) -> void:
	if health_component.take_damage(amount):
		add_camera_shake_trauma(0.75)


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


func _on_died() -> void:
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
	animation_tree.active = false
	crosshair.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
