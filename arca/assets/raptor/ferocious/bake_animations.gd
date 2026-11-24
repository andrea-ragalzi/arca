extends SceneTree
## Adapt licensed source presentation to the unchanged predator animation contract.

const SOURCE: String = "res://arca/assets/raptor/ferocious/source/scene.gltf"
const OUTPUT: String = "res://arca/assets/raptor/ferocious/gameplay.tres"
const MAPPING: Dictionary = {
	"Idle": "Idle_02", "Walk": "Walk", "Run": "Jog",
	"Attack": "Bite_02", "Death": "Death_01", "Jump": "Leap_01",
	"Hurt": "Hurt_01", "Roar": "Roar_03",
}
# Distances measured from the original FBX root-motion equivalents, in metres.
const WALK_DISTANCE: float = 2.9
const JOG_DISTANCE: float = 3.2453
const ATTACK_START: float = 14.0 / 24.0
# Reaction windows [start, end] in source seconds, retimed to gameplay durations.
# Hurt_01 recoils at 0.25-0.62 s and is back near rest by 1.0 s.
# Roar_03 opens its jaw at 0.5-1.25 s (peak ~0.62 s) and is back near rest by 1.375 s.
const WINDOWS: Dictionary = {"Hurt": [0.0, 1.0], "Roar": [0.25, 1.375]}
# Must match ArcaRaptor.stagger_duration and the unchanged 0.7 s ALERT phase.
const REACTION_DURATIONS: Dictionary = {"Hurt": 0.5, "Roar": 0.7}

func _initialize() -> void:
	call_deferred("run")

func sample(animation: Animation, track: int, time: float) -> Variant:
	match animation.track_get_type(track):
		Animation.TYPE_POSITION_3D: return animation.position_track_interpolate(track, time)
		Animation.TYPE_ROTATION_3D: return animation.rotation_track_interpolate(track, time)
		Animation.TYPE_SCALE_3D: return animation.scale_track_interpolate(track, time)
		Animation.TYPE_VALUE: return animation.value_track_interpolate(track, time)
		Animation.TYPE_BLEND_SHAPE: return animation.blend_shape_track_interpolate(track, time)
	assert(false, "Unexpected source track type")
	return null

func run() -> void:
	var source: Node3D = load(SOURCE).instantiate() as Node3D
	var player: AnimationPlayer = source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	assert(player.get_node(player.root_node) == source, "Source animation root changed")
	var legacy: Node3D = load("res://arca/assets/raptor/raptor.glb").instantiate() as Node3D
	var reference: AnimationPlayer = legacy.get_node("AnimationPlayer")
	var library := AnimationLibrary.new()
	for action: String in MAPPING:
		var original: Animation = player.get_animation(MAPPING[action])
		assert(original != null, "Required source clip missing: " + str(MAPPING[action]))
		var start: float = ATTACK_START if action == "Attack" else 0.0
		var end: float = original.length
		if WINDOWS.has(action):
			start = WINDOWS[action][0]
			end = WINDOWS[action][1]
		var duration: float = original.length
		match action:
			"Walk": duration = WALK_DISTANCE / 1.6
			"Run": duration = JOG_DISTANCE / 3.2
			"Attack", "Death", "Jump":
				for name: StringName in reference.get_animation_list():
					if str(name).ends_with("_" + action):
						duration = reference.get_animation(name).length
			"Hurt", "Roar": duration = REACTION_DURATIONS[action]
		var animation: Animation = original.duplicate(true) as Animation
		animation.resource_name = "Ferocious_" + action
		animation.resource_local_to_scene = true
		animation.set_meta("source_clip", MAPPING[action])
		animation.set_meta("source_start", start)
		animation.set_meta("source_duration", original.length)
		if WINDOWS.has(action):
			animation.set_meta("source_end", end)
		animation.length = duration
		animation.loop_mode = Animation.LOOP_LINEAR if action in ["Idle", "Walk", "Run"] else Animation.LOOP_NONE
		for track: int in animation.get_track_count():
			var path: NodePath = original.track_get_path(track)
			animation.track_set_path(track, NodePath("Model/" + str(path)))
			for key: int in range(animation.track_get_key_count(track) - 1, -1, -1):
				animation.track_remove_key(track, key)
			var anchored: bool = original.track_get_type(track) == Animation.TYPE_POSITION_3D and str(path).ends_with(":Root_02")
			if anchored:
				# Physics owns world travel, including after death; preserve local body motion.
				animation.track_insert_key(track, 0.0, sample(original, track, 0.0))
				continue
			animation.track_insert_key(track, 0.0, sample(original, track, start))
			for key: int in original.track_get_key_count(track):
				var time: float = original.track_get_key_time(track, key)
				if time > start and time < end:
					var mapped: float = (time - start) * duration / (end - start)
					animation.track_insert_key(track, mapped, original.track_get_key_value(track, key), original.track_get_key_transition(track, key))
			animation.track_insert_key(track, duration, sample(original, track, end))
		assert(library.add_animation(animation.resource_name, animation) == OK)
		print(action, " <- ", MAPPING[action], " | start ", start, " | end ", end, " | duration ", duration)
	assert(ResourceSaver.save(library, OUTPUT) == OK, "Cannot save predator animation library")
	source.free()
	legacy.free()
	print("RAPTOR BAKE: %d presentation bindings saved; source files unchanged" % MAPPING.size())
	quit()
