extends "res://arca/tests/mission_test.gd"


func run() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	check(path == "res://arca/ui/title_screen.tscn", "F5 launches the ARCA title")
	if path.ends_with("title_screen.tscn"):
		await check_title_flow(path)
	print("TITLE RESULT: %d checks, %d failures" % [checks, failures])
	if is_instance_valid(room):
		room.stop_audio()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)


func check_title_flow(path: String) -> void:
	change_scene_to_file(path)
	await frames(6)
	var title := current_scene
	var new_game := title.find_child("NewGame") as Button
	var training := title.find_child("PackTraining") as Button
	var controls := title.find_child("Controls") as Button
	var quit_button := title.find_child("Quit") as Button
	check(new_game != null and training != null and controls != null and quit_button != null,
		"Title exposes all four actions")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and new_game.has_focus(),
		"Title shows the cursor and starts with keyboard focus")
	controls.pressed.emit()
	await frames(2)
	check(title.find_child("ControlsText").visible, "Controls opens the input guide")
	controls.pressed.emit()
	new_game.pressed.emit()
	await frames(10)
	room = current_scene
	check(room.scene_file_path == "res://arca/mission_room.tscn", "New Game opens the real mission")
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "New Game captures the mouse under a window driver")
	room.stop_all_predators()
	await open_lift_for_exit_fixture()
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	await frames(70)
	await move_to_exit_fixture()
	var return_button := room.hud.find_child("ReturnToTitle") as Button
	check(room.mission_complete and room.hud.modal_title.text == "DEMO COMPLETE" and return_button.visible,
		"Victory offers an explicit return to title")
	return_button.pressed.emit()
	await frames(10)
	check(current_scene.scene_file_path == path and not paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"Return to title restores the menu, mouse and tree processing")
