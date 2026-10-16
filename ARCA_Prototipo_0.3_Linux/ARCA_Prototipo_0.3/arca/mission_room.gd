extends "res://arca/raptor_room.gd"
## Regia della missione: inventario minimo, obiettivi e collegamento dei segnali.

@onready var fuse: ArcaInteractionPoint = $FusePickup
@onready var panel: ArcaInteractionPoint = $PowerPanel
@onready var door: Node3D = $ExitDoor
var has_fuse: bool = false
var power_restored: bool = false
var mission_complete: bool = false
var interaction_target: ArcaInteractionPoint
var notice_remaining: float = 0.0

func _ready() -> void:
	super._ready()
	fuse.collected.connect(_on_fuse_pickup_collected)
	panel.powered.connect(_on_panel_powered)
	$ExitZone.body_entered.connect(_on_exit_entered)
	door.opened.connect(func(): _notify("Porta aperta. Raggiungi l'uscita verde."))
	hud.get_node("Frame/Subtitle").text = "STAZIONE DI CONTINUITÀ   /   PROTOTIPO 0.3"
	hud.get_node("Frame/Tag").text = "SETTORE 01 / RIPRISTINO ALIMENTAZIONE\nASSET E AMBIENTE PROVVISORI"
	hud.get_node("Frame/Controls").text = "WASD  movimento    /    MOUSE  camera\nDX  mira    /    SX  spara    /    SPAZIO  salta\nE  interagisci    /    R  riavvia    /    ESC  pausa"
	_update_objective()
	_notify("Recupera il fusibile giallo. Attenzione al predatore.")

func _physics_process(delta: float) -> void:
	if mission_complete or player.health_component.current <= 0:
		return
	interaction_target = _find_interaction_target()
	var text: String = ""
	if is_instance_valid(interaction_target):
		text = "[ E ]  " + interaction_target.action_text
		if interaction_target == panel and not has_fuse:
			text = "[ E ]  Esamina quadro — fusibile mancante"
	hud.set_interaction(text)
	if notice_remaining > 0.0:
		notice_remaining -= delta
		if notice_remaining <= 0.0:
			hud.set_notice("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		if try_interact():
			get_viewport().set_input_as_handled()

func _find_interaction_target() -> ArcaInteractionPoint:
	var nearest: ArcaInteractionPoint = null
	var nearest_distance: float = INF
	for point in [fuse, panel]:
		if not is_instance_valid(point) or not point.is_available_to(player):
			continue
		var distance: float = point.global_position.distance_squared_to(player.global_position)
		if distance < nearest_distance:
			nearest = point
			nearest_distance = distance
	return nearest

func try_interact() -> bool:
	if get_tree().paused or mission_complete or player.health_component.current <= 0:
		return false
	interaction_target = _find_interaction_target()
	if not is_instance_valid(interaction_target):
		return false
	if interaction_target == fuse:
		fuse.collect()
	elif interaction_target == panel:
		if not panel.activate(has_fuse):
			_notify("Manca il fusibile. Cercalo sul supporto giallo vicino all'ingresso.")
	return true

func _on_fuse_pickup_collected() -> void:
	has_fuse = true
	$PickupSound.play()
	hud.set_interaction("")
	_update_objective()
	_notify("FUSIBILE RACCOLTO — portalo al quadro elettrico 02.")
	print("Fusibile raccolto: inventario aggiornato")

func _on_panel_powered() -> void:
	has_fuse = false
	power_restored = true
	$PowerSound.play()
	door.open()
	hud.set_interaction("")
	_update_objective()
	_notify("ALIMENTAZIONE RIPRISTINATA — porta in apertura.")

func _update_objective() -> void:
	if power_restored:
		hud.set_status("03 / Raggiungi l'uscita oltre la porta verde.")
		hud.set_inventory("FUSIBILE  /  INSTALLATO")
	elif has_fuse:
		hud.set_status("02 / Porta il fusibile al quadro elettrico sul lato sinistro della stanza.")
		hud.set_inventory("FUSIBILE  /  IN INVENTARIO")
	else:
		hud.set_status("01 / Recupera il fusibile giallo vicino all'ingresso. E per raccoglierlo.")
		hud.set_inventory("FUSIBILE  /  MANCANTE")

func _notify(message: String) -> void:
	notice_remaining = 4.5
	hud.set_notice(message)

func _on_enemy_destroyed() -> void:
	_notify("PREDATORE ABBATTUTO — continua il ripristino del settore.")

func _on_player_died() -> void:
	super._on_player_died()
	hud.set_interaction("")
	hud.set_notice("")

func _on_exit_entered(body: Node3D) -> void:
	if body != player or not power_restored or not door.is_open or mission_complete:
		return
	if player.health_component.current <= 0:
		return
	mission_complete = true
	enemy.stop_combat()
	stop_audio()
	hud.set_interaction("")
	hud.set_notice("")
	hud.set_status("SETTORE RIPRISTINATO / Percorso 0.3 completato.")
	hud.show_success()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func set_paused(value: bool) -> void:
	if not mission_complete:
		super.set_paused(value)
