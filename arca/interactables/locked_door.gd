extends ArcaInteractionPoint
## The room owns the key. The composed slider owns the door mesh, collision and motion.

@export var required_item: StringName = &"keycard"
@export var consume_item: bool = false
@export var locked_text: String = "Keycard"

@onready var slider: Node3D = $SlidingDoor


func _ready() -> void:
	super._ready()
	$SlidingDoor/Status.text = "LOCKED / " + locked_text.to_upper()


func get_prompt(room: Node) -> String:
	if room.has_key_item(required_item):
		return "Unlock door"
	return "Locked - " + locked_text


func interact(room: Node) -> bool:
	if not enabled:
		return false
	if not room.has_key_item(required_item):
		$Denied.play()
		room._notify("Locked - requires " + locked_text)
		return false
	enabled = false
	$Denied.stop()
	$Accepted.play()
	if consume_item:
		room.consume_key_item(required_item)
	room.player.health_component.died.connect(_freeze_opening, CONNECT_ONE_SHOT)
	slider.open()
	return true


func _freeze_opening() -> void:
	if slider.is_opening:
		slider.process_mode = Node.PROCESS_MODE_DISABLED
