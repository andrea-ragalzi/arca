extends SceneTree
## Render a normally hidden laser light and an exploding bullet.
## Needs a real/virtual display; a headless test cannot validate shadow passes.
## Use -- --reproduce-old-mode to demonstrate the original Compatibility error.


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(640, 360)
	var scene: Node3D = load("res://arca/test_room.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.enemy.set_physics_process(false)
	var light: OmniLight3D = scene.enemy.get_node("ShootLight")
	if "--reproduce-old-mode" in OS.get_cmdline_user_args():
		light.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
	light.visible = true
	light.light_energy = 3.0
	light.shadow_enabled = true
	for i in 30:
		await physics_frame
	await RenderingServer.frame_post_draw
	var bullet: CharacterBody3D = load("res://player/bullet/bullet.tscn").instantiate()
	scene.add_child(bullet)
	bullet.global_position = Vector3(0, 1, -6)
	bullet.hit = true
	bullet.explode()
	var failures: int = 0
	for node in scene.find_children("*", "OmniLight3D", true, false):
		if node.shadow_enabled and node.omni_shadow_mode != OmniLight3D.SHADOW_CUBE:
			failures += 1
	for i in 40:
		await physics_frame
	await RenderingServer.frame_post_draw
	print("SHADOW TEST: %d incompatible active lights" % failures)
	scene.stop_audio()
	scene.queue_free()
	Engine.max_fps = 60
	for i in 15:
		await process_frame
	quit(0 if failures == 0 else 1)
