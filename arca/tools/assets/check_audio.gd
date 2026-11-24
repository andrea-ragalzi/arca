extends SceneTree
## Validate the shipped manifest against the imported PCM files.

const MANIFEST := "res://docs/assets/AUDIO_MANIFEST.md"
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func run() -> void:
	var names: Array[String] = []
	for line: String in FileAccess.get_file_as_string(MANIFEST).split("\n"):
		var columns := line.split("|", false)
		if columns.size() != 5 or not columns[1].strip_edges().begins_with("arca/audio/"):
			continue
		var file := columns[1].strip_edges()
		check(not names.has(file), file + " appears once in the manifest")
		names.append(file)
		var path := "res://" + file
		var audio := load(path) as AudioStreamWAV
		check(FileAccess.file_exists(path) and audio != null, file + " exists and imports")
		if audio == null:
			continue
		check(not audio.stereo and audio.format == AudioStreamWAV.FORMAT_16_BITS
			and audio.mix_rate == 48000, file + " keeps its mono 48 kHz PCM format")
		var loop := AudioStreamWAV.LOOP_FORWARD if columns[3].strip_edges() == "Forward" else AudioStreamWAV.LOOP_DISABLED
		check(audio.loop_mode == loop, file + " has the declared loop mode")
		check(absf(audio.get_length() - columns[2].to_float()) < 0.001, file + " duration matches")
		var pcm := audio.data
		var peak: int = 0
		for offset: int in range(0, pcm.size(), 2):
			peak = maxi(peak, absi(pcm.decode_s16(offset)))
		var db := linear_to_db(float(peak) / 32768.0)
		check(db <= -1.0 and absf(db - columns[4].to_float()) < 0.01, file + " peak matches and stays below -1 dBFS")
		if loop == AudioStreamWAV.LOOP_FORWARD:
			check(audio.loop_begin == 0 and audio.loop_end == pcm.size() / 2 - 1, file + " loops over the complete clip")
	check(names.size() == 16, "All sprint cues are declared")
	print("AUDIO ASSET RESULT: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
