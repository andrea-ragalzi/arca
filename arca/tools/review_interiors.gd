extends "res://arca/tests/route_test.gd"
## X11/Compatibility. Pass an existing output directory, optionally followed by "walk".
## Both modes render at 720p. Omit --fixed-fps to collect real frame timings.

const VIEWS := {
	"maintenance": [
		[Vector3(0.6, 2.15, -8.15), Vector3(-3.4, 1.30, -11.62)],
		[Vector3(-6.7, 2.15, 4.2), Vector3(-10.5, 2.1, -2.8)],
		[Vector3(-3.0, 2.05, 4.9), Vector3(2.1, 2.2, 9.7)],
	],
	"security": [
		[Vector3(0.85, 1.75, 21.7), Vector3(-3.3, 1.46, 25.7)],
		[Vector3(-0.65, 2.05, 16.2), Vector3(0.35, 2.7, 29.0)],
		[Vector3(1.05, 1.85, 33.2), Vector3(-0.32, 2.7, 43.9)],
		[Vector3(-3.0, 1.3, 26.8), Vector3(-4.85, 1.1, 27.65)],
	],
	"office": [
		[Vector3(-7, 1.85, 25.15), Vector3(-13.5, 1.5, 26.1)],
		[Vector3(-11.7, 1.85, 21.1), Vector3(-14.9, 1.98, 26.1)],
		[Vector3(-12.0, 1.7, 28.4), Vector3(-14.8, 1.85, 23.7)],
	],
	"lift": [
		[Vector3(-3.7, 1.90, 55.5), Vector3(-9, 1.9, 56.3)],
		[Vector3(1.3, 2.0, 49.7), Vector3(-0.55, 2.5, 59.9)],
		[Vector3(-0.92, 1.60, 59.75), Vector3(0.68, 1.60, 62.05)],
		[Vector3(3.9, 1.95, 52.4), Vector3(6.75, 1.8, 54.5)],
	],
	# Room 1 (maintenance airlock) against the security corridor in one frame.
	"junction": [
		[Vector3(1.35, 1.65, 17.4), Vector3(-0.55, 1.15, 12.2)],
		[Vector3(-1.2, 1.65, 11.6), Vector3(0.9, 1.2, 16.6)],
	],
}
## Orthographic elevations: [eye, look target, room floor point, door bore point, staff point].
const ELEVATIONS := {
	"maintenance": [Vector3(0, 1.55, 6.8), Vector3(0, 1.55, 10.8), Vector3(0, 0, 8.0), Vector3(0, 0, 10.8),
		Vector3(-2.4, 0, 10.45)],
	"security": [Vector3(0, 1.55, 40.6), Vector3(0, 1.55, 44.45), Vector3(0, 0, 41.2), Vector3(0, 0, 44.45),
		Vector3(1.8, 0, 44.1)],
	"security-bay": [Vector3(1.6, 1.75, 34.2), Vector3(-2.0, 1.75, 34.2), Vector3(0, 0, 27.2), Vector3(0, 0, 33.7),
		Vector3(-1.85, 0, 31.6)],
	"office": [Vector3(-9.3, 1.55, 25.2), Vector3(-5.75, 1.55, 25.2), Vector3(-7.5, 0, 25.2), Vector3(-5.75, 0, 25.2),
		Vector3(-6.1, 0, 27.4)],
	"lift": [Vector3(0, 1.55, 55.2), Vector3(0, 1.55, 58.95), Vector3(0, 0, 57.2), Vector3(0, 0, 58.95),
		Vector3(-2.2, 0, 58.6)],
}
const STATION := "res://arca/assets/environment/station/"

var output: String
var review_viewport: Viewport
var walk_samples: Array[float]
var previous_draw: int
var returned := false
var captured: Array[String] = []


func run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty() or arguments.size() > 2 or not DirAccess.dir_exists_absolute(arguments[0]) \
			or (arguments.size() == 2 and arguments[1] != "walk"):
		printerr("Pass an existing absolute output directory, optionally followed by walk.")
		quit(2)
		return
	output = arguments[0]
	var walking := arguments.size() == 2 and arguments[1] == "walk"
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	review_viewport = viewport
	room = load("res://arca/mission_room.tscn").instantiate()
	viewport.add_child(room)
	room.stop_all_predators()
	await frames(15)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	print("REVIEW DEVICE: ", RenderingServer.get_video_adapter_name(), " | ",
		review_viewport.get_texture().get_size())
	if walking:
		previous_draw = Time.get_ticks_usec()
		RenderingServer.frame_post_draw.connect(record_walk_frame)
		await walk_route(room.get_node("ControlOffice"))
		RenderingServer.frame_post_draw.disconnect(record_walk_frame)
		print_samples("gameplay-route", walk_samples)
	else:
		await review_architecture()
	room.stop_audio()
	paused = false
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)


func review_architecture() -> void:
	room.player.hide()
	room.get_node("HUD").hide()
	var camera := Camera3D.new()
	camera.fov = 66.0
	review_viewport.add_child(camera)
	camera.make_current()
	for area: String in VIEWS:
		var views: Array = VIEWS[area]
		for index: int in views.size():
			camera.position = views[index][0]
			camera.look_at(views[index][1])
			camera.reset_physics_interpolation()
			await screenshot("%s-%02d" % [area, index + 1])
			await profile("%s-%02d" % [area, index + 1])
	for area: String in ELEVATIONS:
		await elevation(camera, area, ELEVATIONS[area])
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE


## Orthographic side view with heights measured from the local finished floor.
func elevation(camera: Camera3D, area: String, view: Array) -> void:
	var space := room.get_world_3d().direct_space_state
	var floor_y := cast_y(space, view[2] + Vector3.UP, view[2] + Vector3.DOWN)
	var soffit := cast_y(space, view[2] + Vector3.UP, view[2] + Vector3.UP * 4.0) - floor_y
	var second := cast_y(space, view[3] + Vector3.UP, view[3] + Vector3.UP * 4.0) - floor_y
	var bands := nearest_bay_heights(view[4], floor_y)
	var staff := Node3D.new()
	room.add_child(staff)
	var marks := {"skirting": bands.x, "band": bands.y, "soffit": soffit}
	marks["raised soffit" if area == "security-bay" else "door head"] = second
	var offset := 0
	for label: String in marks:
		var height: float = marks[label]
		var tick := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 0.014, 0.7)
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.albedo_color = Color(1, 0.2, 0.75)
		box.material = paint
		tick.mesh = box
		tick.position = view[4] + Vector3.UP * (floor_y + height)
		staff.add_child(tick)
		var text := Label3D.new()
		text.text = "%s %.2f m" % [label, height]
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.no_depth_test = true
		text.pixel_size = 0.0032
		text.font_size = 40
		text.outline_size = 8
		text.modulate = Color(1, 0.85, 0.95)
		text.position = tick.position + Vector3.UP * 0.07 + (view[0] - view[1]).normalized().cross(Vector3.UP) * (0.0 if offset % 2 == 0 else 0.0)
		staff.add_child(text)
		offset += 1
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.7
	camera.position = view[0]
	camera.look_at(view[1])
	camera.reset_physics_interpolation()
	print("ELEVATION | %s | floor %.3f | skirting top %.2f | band top %.2f | soffit %.2f | %s %.2f" % [
		area, floor_y, bands.x, bands.y, soffit, "raised soffit" if area == "security-bay" else "door head", second])
	await screenshot("elevation-" + area)
	staff.queue_free()
	await frames(2)


func cast_y(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
	return NAN if hit.is_empty() else hit.position.y


## Skirting and band tops of the nearest instanced wall bay, from its rendered bounds.
func nearest_bay_heights(point: Vector3, floor_y: float) -> Vector2:
	var best: Node3D
	var best_distance := INF
	for node: Node in room.find_children("*", "Node3D", true, false):
		if node.scene_file_path != STATION + "wall_bay.tscn":
			continue
		var distance := (node as Node3D).global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = node
	if best == null:
		return Vector2(NAN, NAN)
	var skirting := best.get_node("Skirting") as MeshInstance3D
	var band := best.get_node("Band") as MeshInstance3D
	return Vector2((skirting.global_transform * skirting.get_aabb()).end.y - floor_y,
		(band.global_transform * band.get_aabb()).end.y - floor_y)


func screenshot(label: String, settle_frames: int = 4) -> void:
	for frame in settle_frames:
		await RenderingServer.frame_post_draw
	var result := review_viewport.get_texture().get_image().save_png(output.path_join(label + ".png"))
	check(result == OK, "Wrote " + label)


func profile(label: String) -> void:
	for frame in 60:
		await RenderingServer.frame_post_draw
	var samples: Array[float] = []
	var start := Time.get_ticks_usec()
	var previous := start
	while previous - start < 2000000:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	print_samples(label, samples)


func record_walk_frame() -> void:
	var now := Time.get_ticks_usec()
	if Input.is_action_pressed("move_forward"):
		walk_samples.append((now - previous_draw) / 1000.0)
	previous_draw = now


func print_samples(label: String, samples: Array[float]) -> void:
	if samples.is_empty():
		return
	var total := 0.0
	for duration: float in samples:
		total += duration
	samples.sort()
	print("INTERIOR PROFILE | %s | %.1f FPS | P95 %.2f ms | P99 %.2f ms | %s draw calls (last frame)" % [
		label, samples.size() * 1000.0 / total,
		samples[int((samples.size() - 1) * 0.95)], samples[int((samples.size() - 1) * 0.99)],
		review_viewport.get_render_info(
			Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
	])


func walk_to(target: Vector3, max_frames: int = 600) -> int:
	var capture := ""
	if target.is_equal_approx(Vector3(-8.8, 0.05, 5.1)):
		capture = "gameplay-maintenance"
	elif target.is_equal_approx(Vector3(0, 0.05, CORRIDOR_Z + 3)):
		capture = "gameplay-security"
	elif target.is_equal_approx(Vector3(-12.85, 0.05, 30.4)):
		capture = "gameplay-office"
	elif target.is_equal_approx(EXIT_APPROACH):
		capture = "gameplay-lift"
	if capture.is_empty() or captured.has(capture):
		return await super.walk_to(target, max_frames)
	captured.append(capture)

	# Start the cabin sweep before its completion trigger pauses the spring arm.
	var capture_distance := 1.85 if target.is_equal_approx(EXIT_APPROACH) else 0.85
	var walked := 0
	while walked < max_frames:
		var offset: Vector3 = target - room.player.position
		offset.y = 0.0
		if offset.length() < capture_distance:
			await screenshot(capture, 1)
			Input.action_release("move_forward")
			await check_camera_sweep(capture)
			break
		room.player.player_input.camera_base.rotation.y = atan2(offset.x, offset.z)
		Input.action_press("move_forward")
		await frames(1)
		walked += 1
	return walked + await super.walk_to(target, max_frames)


func press_e() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	review_viewport.push_input(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	review_viewport.push_input(event)
	await frames(2)


func check_camera_sweep(label: String) -> void:
	check(not paused, label + " samples the live spring arm before completion")
	if paused:
		return
	var input: Node = room.player.player_input
	var yaw: float = input.camera_base.rotation.y
	var pitch: float = input.camera_rot.rotation.x
	var camera: Camera3D = input.camera_camera
	var arm := camera.get_parent() as SpringArm3D
	var space := room.get_world_3d().direct_space_state
	var near_probe := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = camera.near + 0.01
	near_probe.shape = sphere
	near_probe.collision_mask = 1
	near_probe.exclude = [room.player.get_rid()]
	var aiming := false
	# Full yaw at the default pitch, then looking down (arm rising to the soffit),
	# looking up, and aiming down the sights.
	for mode: int in 4:
		if mode == 3:
			Input.action_press("aim")
			aiming = true
			await frames(20)
		input.camera_rot.rotation.x = [pitch, -1.2, 0.9, pitch][mode]
		var steps := 8 if mode == 0 else 4
		for direction: int in steps:
			input.camera_base.rotation.y = yaw + direction * TAU / steps
			await frames(6)
			if paused:
				check(false, label + " reached completion during the camera sweep")
				if aiming:
					Input.action_release("aim")
				return
			var query := PhysicsRayQueryParameters3D.create(arm.global_position, camera.global_position, 1)
			var hit := space.intersect_ray(query)
			check(hit.is_empty(), "%s TPS camera clears mode %d step %d from %s to %s (%s)" % [
				label, mode, direction, query.from, query.to, hit.get("collider", "clear"),
			])
			near_probe.transform = Transform3D(Basis.IDENTITY, camera.global_position)
			var touching := space.intersect_shape(near_probe, 1)
			check(touching.is_empty(), "%s camera near plane stays out of geometry in mode %d step %d at %s (%s)" % [
				label, mode, direction, camera.global_position,
				touching[0].collider.name if not touching.is_empty() else "clear"])
	if aiming:
		Input.action_release("aim")
	input.camera_rot.rotation.x = pitch
	input.camera_base.rotation.y = yaw
	await frames(4)


## Walk back from the lift hall to the maintenance airlock and return, so every
## connected threshold is crossed in both directions before the exit.
func walk_leg(points: Array[Vector3]) -> int:
	if points.size() == 2 and points[1].is_equal_approx(EXIT_APPROACH) and not returned:
		returned = true
		var back: Array[Vector3] = [points[0], Vector3(0, 0.05, CORRIDOR_Z + 3), Vector3(0, 0.05, 12.4),
			Vector3(0, 0.05, 9.0)]
		var walked := await super.walk_leg(back)
		await check_camera_sweep("return-airlock")
		var forward: Array[Vector3] = [Vector3(0, 0.05, 12.4), Vector3(0, 0.05, CORRIDOR_Z + 3),
			Vector3(0, 0.05, CORRIDOR_Z + 19.5)]
		walked += await super.walk_leg(forward)
		await check_camera_sweep("crate-bay")
		var finish: Array[Vector3] = [Vector3(0, 0.05, CORRIDOR_Z + 28.4)]
		finish.append_array(points)
		return walked + await super.walk_leg(finish)
	return await super.walk_leg(points)
