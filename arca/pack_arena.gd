extends "res://arca/raptor_room.gd"
## Independent, resettable drill. The mission inventory and checkpoint are untouched.

# The test bay measures 22 by 28 metres.
const BAY_SIGHT_RANGE := 36.0
const BAY_SHOT_RANGE := 44.0
const BEHAVIOR := preload("res://arca/enemies/velociraptor_behavior.tres")

func _ready() -> void:
	super._ready()
	enemy.position = $CenterStart.position
	enemy.rotation.y = 0.0
	enemy.reset_physics_interpolation()
	for predator: ArcaRaptor in get_predators():
		predator.behavior = BEHAVIOR
		predator.detection_range = BAY_SIGHT_RANGE
		predator.gunshot_hearing_range = BAY_SHOT_RANGE
	hud.get_node("Frame/Subtitle").text = "CONTINUITY STATION   /   PACK TRAINING"
	hud.get_node("Frame/Tag").text = "THREE PREDATORS\nBREAK SIGHT BEHIND COVER"
	hud.get_node("Frame/Controls").text = "SPACE + MOVE  jump onto cover\nQ + A/D  sidestep   /   Q  break free\n1/2  sidearm   /   R  reload   /   BACKSPACE  restart"
	hud.get_node("Frame/Modal/Center/Panel/Margin/VBox/ReturnToTitle").show()
	$SignFront.text = "ARCA  /  PACK TRAINING"
	$SignSide.text = "CONTINUITY STATION\nPREDATOR DRILL"
	for index: int in 3:
		var surface := ArcaRaptorJumpSurface.new()
		surface.name = ["Desk", "Workbench", "Platform"][index]
		add_child(surface)
		surface.configure(get_node("Cover%d" % index), get_node("CoverTop%d" % index),
			get_node("CoverStripe%d" % index), [0.76, 0.85, 0.90][index])
	_update_drill()


func set_paused(value: bool) -> void:
	super.set_paused(value)
	if paused:
		hud.get_node("Frame/Modal/Center/Panel/Margin/VBox/Text").text = "ARCA / pack training"


func _on_enemy_destroyed() -> void:
	_update_drill()


func _on_predator_destroyed() -> void:
	_update_drill()


func _update_drill() -> void:
	var active := 0
	for predator: ArcaRaptor in get_predators():
		if not predator.dead:
			active += 1
	hud.set_status("PACK ACTIVE  /  %d" % active if active else "DRILL CLEAR  /  Backspace to restart")
