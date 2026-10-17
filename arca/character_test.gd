extends Node3D
## Isolated locomotion viewer, deliberately separate from the TPS controller.

const LIBRARY: AnimationLibrary = preload("res://arca/assets/characters/regina/locomotion.tres")
const CLIPS: Array[StringName] = [&"idle", &"walk", &"run"]
const SKELETON_PATH := "ModelPivot/Regina/Sketchfab_model/Mesh_fbx/RootNode/Armature/Object_4/Skeleton3D"
const LANE_LENGTH: float = 12.0

var animation_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var selected_clip: StringName = &"idle"
var paused: bool = false
var translating: bool = false
var lane_finished: bool = false
var valid: bool = false
var view_index: int = 0
var last_root_delta := Vector3.ZERO
var initial_position := Vector3.ZERO
var camera_offset := Vector3.ZERO

@onready var model_pivot: Node3D = $ModelPivot
@onready var camera: Camera3D = $Camera3D
@onready var instructions: Label = $Instructions/Label
@onready var skeleton: Skeleton3D = get_node(SKELETON_PATH)


func _ready() -> void:
	initial_position = model_pivot.position
	camera_offset = camera.position
	var motion := Node3D.new()
	motion.name = "RootMotion"
	add_child(motion)
	for clip: StringName in CLIPS:
		if not LIBRARY.has_animation(clip):
			_fail("Missing locomotion clip: " + clip)
			return
		var animation: Animation = LIBRARY.get_animation(clip)
		for track in animation.get_track_count():
			var path: NodePath = animation.track_get_path(track)
			if get_node_or_null(NodePath(path.get_concatenated_names())) == null \
					or (path.get_subname_count() > 0 and skeleton.find_bone(path.get_subname(0)) < 0):
				_fail("Unresolved locomotion track: " + str(path))
				return
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.root_node = NodePath("..")
	add_child(player)
	player.add_animation_library("", LIBRARY)
	var machine := AnimationNodeStateMachine.new()
	for clip: StringName in CLIPS:
		var node := AnimationNodeAnimation.new()
		node.animation = clip
		machine.add_node(clip, node)
	for from: StringName in CLIPS:
		for to: StringName in CLIPS:
			if from != to:
				var transition := AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.18
				machine.add_transition(from, to, transition)
	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	animation_tree.root_node = NodePath("..")
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	animation_tree.tree_root = machine
	animation_tree.root_motion_track = NodePath("RootMotion")
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(animation_tree)
	playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	var ground: MeshInstance3D = $Ground
	var plane: PlaneMesh = ground.mesh.duplicate() as PlaneMesh
	plane.size = Vector2(10, 32)
	ground.mesh = plane
	ground.position.z -= 10.0
	valid = true
	reset_preview()


func _fail(message: String) -> void:
	push_error(message)
	instructions.text = "REGINA / LOCOMOTION ERROR\n" + message
	set_physics_process(false)
	set_process(false)


func _physics_process(delta: float) -> void:
	advance_locomotion(delta)


func advance_locomotion(delta: float) -> void:
	last_root_delta = Vector3.ZERO
	if not valid or paused:
		return
	animation_tree.advance(delta)
	last_root_delta = animation_tree.get_root_motion_position()
	if translating:
		# The baked proxy is already in scene/TPS axes (-Z), not in the
		# rotated Regina skeleton's coordinates. Do not apply ModelPivot again.
		model_pivot.position += Vector3(last_root_delta.x, 0, last_root_delta.z)
		if model_pivot.position.distance_to(initial_position) >= LANE_LENGTH:
			paused = true
			lane_finished = true


func select_clip(clip: StringName) -> void:
	if not valid or clip not in CLIPS:
		return
	selected_clip = clip
	playback.travel(clip)


func set_translating(enabled: bool) -> void:
	translating = enabled
	_restart(selected_clip)


func reset_preview() -> void:
	translating = false
	_restart(&"idle")


func _restart(clip: StringName) -> void:
	if not valid:
		return
	paused = false
	lane_finished = false
	selected_clip = clip
	model_pivot.position = initial_position
	last_root_delta = Vector3.ZERO
	animation_tree.active = false
	skeleton.reset_bone_poses()
	animation_tree.active = true
	playback.start(clip, true)
	animation_tree.advance(0.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not valid:
		return
	match event.physical_keycode:
		KEY_1: select_clip(&"idle")
		KEY_2: select_clip(&"walk")
		KEY_3: select_clip(&"run")
		KEY_SPACE: paused = not paused
		KEY_R: reset_preview()
		KEY_M: set_translating(not translating)
		KEY_V: view_index = (view_index + 1) % 4
		_: return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not valid:
		return
	var views: Array[Vector3] = [camera_offset, Vector3(0, 1.1, -3.5),
		Vector3(3.5, 1.1, 0), Vector3(0, 1.1, 3.5)]
	var origin: Vector3 = model_pivot.position - initial_position
	camera.position = views[view_index] + origin
	camera.look_at(Vector3(0, 0.95, 0) + origin)
	var state: String = "LANE END - R resets" if lane_finished else ("PAUSED" if paused else "PLAYING")
	instructions.text = "REGINA / LOCOMOTION - %s / %s / %s\n" % [selected_clip.to_upper(),
		"ROOT TRAVEL" if translating else "CENTERED", state] \
		+ "1 idle  2 walk  3 run  |  M travel/center  |  SPACE pause  R reset  V view\n" \
		+ "1 unit = 1 meter. -Z forward. CC0 Quaternius animations retargeted to Regina.\n" \
		+ "Travel: %.2f m / 12 m. F5 still uses the original TPS robot." % origin.length()
