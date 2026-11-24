extends "res://arca/tests/mission_test.gd"
## Exercise the real sound players through the mission and predator events.


func run() -> void:
	await reset_mission()
	var audio := room.get_node_or_null("MissionAudio")
	check(audio != null, "Mission has local ambience and alarm playback")
	if audio != null:
		await check_playback(audio)
	print("AUDIO RESULT: %d checks, %d failures" % [checks, failures])
	room.stop_audio()
	current_scene = null
	room.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures == 0 else 1)


func check_playback(audio: Node) -> void:
	var ambience: AudioStreamPlayer = audio.get_node("Ambience")
	var alarm: AudioStreamPlayer = audio.get_node("Alarm")
	check(ambience.playing and not alarm.playing, "Only the ambience plays at mission start")
	room.set_paused(true)
	await frames(8)
	check(ambience.stream_paused, "Mission pause pauses the ambience stream")
	room.set_paused(false)
	await frames(3)
	check(not ambience.stream_paused, "Resume resumes the ambience stream")

	var sleeper: ArcaRaptor = room.get_node("SecurityCorridor/SleepingRaptor")
	var voice: AudioStreamPlayer3D = sleeper.get_node("Voice")
	var breath: AudioStreamPlayer3D = sleeper.get_node("Breath")
	var step: AudioStreamPlayer3D = sleeper.get_node("Steps")
	sleeper.combat_enabled = true
	sleeper._change_state(ArcaRaptor.State.SLEEP)
	await frames(2)
	check(breath.playing, "A sleeping raptor plays the breathing loop")
	sleeper._change_state(ArcaRaptor.State.WAKE)
	check(not breath.playing, "Waking stops the breathing loop")
	sleeper._change_state(ArcaRaptor.State.ALERT)
	check(voice.stream.resource_path.ends_with("/roar_01.wav"), "Alert selects the roar")
	sleeper._change_state(ArcaRaptor.State.ATTACK)
	check(voice.stream.resource_path.ends_with("/bite_01.wav"), "Attack selects the bite")
	sleeper.staggered.emit()
	check(voice.stream.resource_path.ends_with("/hurt_01.wav"), "Stagger selects a hurt cue")
	sleeper._play_footstep()
	check(step.stream.resource_path.ends_with("/footstep_01.wav"), "Footstep selects the first step cue")
	sleeper.health_component.current = 1
	sleeper.hit()
	check(voice.stream.resource_path.ends_with("/death_01.wav"), "Raptor death selects its one-shot")

	var locked: Node = room.get_node("SecurityCorridor/LiftGate")
	await move_player(Vector3(0, 0.05, 42.6))
	await press_e()
	check(locked.get_node("Denied").playing, "A denied keycard door plays positional feedback")
	room.add_key_item(&"keycard")
	await press_e()
	check(locked.get_node("Accepted").playing and locked.get_node("SlidingDoor/Servo").playing,
		"Unlocking plays keycard and movement feedback")

	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	check(alarm.playing and room.door.get_node("Servo").playing, "Power starts the alarm and main door movement audio")
	room.player.take_damage(1000)
	check(not ambience.playing and not alarm.playing and not voice.playing
		and not room.door.get_node("Servo").playing, "Death silences the route and predator audio")

	await reset_mission()
	audio = room.get_node("MissionAudio")
	check(audio.get_node("Ambience").playing and not audio.get_node("Alarm").playing,
		"Restart creates one fresh ambience player with the alarm off")
	await open_lift_for_exit_fixture()
	await approach_fuse()
	await press_e()
	await move_player(Vector3(-8.8, 0.05, 5.1))
	await press_e()
	await frames(70)
	await move_to_exit_fixture()
	check(room.mission_complete and not audio.get_node("Ambience").playing and not audio.get_node("Alarm").playing,
		"Completion stops the mission loops")
