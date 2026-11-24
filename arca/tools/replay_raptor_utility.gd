extends SceneTree
## Pass a JSONL filename and optionally a res:// behavior resource after --.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or args.size() > 2:
		printerr("Pass a JSONL filename and optionally an ArcaRaptorBehavior resource.")
		quit(2)
		return
	var file := FileAccess.open(args[0], FileAccess.READ)
	var weights := (load(args[1]) as ArcaRaptorBehavior) if args.size() == 2 else ArcaRaptorBehavior.new()
	if file == null or weights == null:
		printerr("Could not load the requested replay or weights.")
		quit(2)
		return
	var rows := 0
	var differences := 0
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges().is_empty():
			continue
		var value: Variant = JSON.parse_string(line)
		if not value is Dictionary or not value.has("snapshot") or not value.has("rng"):
			printerr("Invalid replay line ", rows + 1)
			quit(2)
			return
		var frame: Dictionary = value
		var utility := ArcaRaptorUtility.new(int(frame.seed))
		utility.rng.state = int(frame.rng)
		utility.current = frame.previous
		utility.committed_until = int(frame.held_until)
		var outcome := utility.choose(frame.snapshot, weights, int(frame.tick), frame.interrupt)
		if outcome.decision != frame.decision or not _scores_match(outcome.scores, frame.scores):
			differences += 1
		rows += 1
	print("RAPTOR REPLAY: ", rows, " snapshots, ", differences, " changed rankings")
	quit(1 if rows == 0 or (args.size() == 1 and differences != 0) else 0)


func _scores_match(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for candidate: String in actual:
		if not expected.has(candidate) or actual[candidate] != int(expected[candidate]):
			return false
	return true
