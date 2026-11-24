class_name ArcaRaptorUtility
extends RefCounted
## Pure tactical ranking. The controller owns perception, physics and action execution.

const ACTIONS: Array[String] = ["listen", "observe", "investigate", "flank", "jump", "attack", "retreat"]
var rng := RandomNumberGenerator.new()
var current := ""
var committed_until := 0


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


func choose(snapshot: Dictionary, weights: ArcaRaptorBehavior, tick: int, interrupt: bool = false) -> Dictionary:
	var available: Array = snapshot.get("candidates", [])
	var seen: bool = snapshot.get("seen", false)
	var memory: float = snapshot.get("memory", 0.0)
	var injury: float = snapshot.get("injury", 0.0)
	var lateral: bool = snapshot.get("lateral", false)
	var scores := {}
	for action: String in ACTIONS:
		if not available.has(action):
			continue
		var value := 0.0
		match action:
			"listen": value = 0.42 + weights.caution + (0.80 if snapshot.get("reply", false) else 0.0)
			"observe": value = 0.24 + weights.caution * (0.7 if seen else 0.3)
			"investigate": value = 0.23 + weights.curiosity * 0.48 + 0.15 * memory
			"flank": value = weights.flank_weight + (0.42 if lateral else 0.0) + 0.08 * memory
			"jump": value = weights.jump_weight + 0.18 * memory - weights.caution * 0.15
			"attack": value = weights.aggression + (0.27 if seen else 0.0) - 0.25 * injury
			"retreat": value = weights.retreat_weight * injury + weights.caution * 0.60
		scores[action] = roundi((value + rng.randf_range(-0.025, 0.025)) * 10000.0)
	var best: String = current if not interrupt and tick < committed_until and scores.has(current) else ""
	if best.is_empty():
		var highest := -INF
		for action: String in ACTIONS:
			if scores.has(action) and scores[action] > highest:
				highest = scores[action]
				best = action
		if best != current or tick >= committed_until or interrupt:
			current = best
			committed_until = tick + weights.decision_hold_ticks
	return {"scores": scores, "decision": best}
