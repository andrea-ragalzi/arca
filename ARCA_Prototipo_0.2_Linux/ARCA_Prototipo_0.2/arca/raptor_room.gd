extends "res://arca/test_room.gd"
## Reuse the tested layout and player, replacing only the test opponent.


func _ready() -> void:
	var spawn: Vector3 = enemy.position
	remove_child(enemy)
	enemy.queue_free()
	enemy = preload("res://arca/enemies/raptor.tscn").instantiate()
	enemy.name = "Raptor"
	add_child(enemy)
	enemy.position = spawn + Vector3(-2.5, 0.0, 0.0)
	super._ready()
	hud.get_node("Frame/Subtitle").text = "STAZIONE DI CONTINUITÀ   /   PROTOTIPO 0.2"
	hud.get_node("Frame/Tag").text = "PRIMO INCONTRO / PREDATORE\nMODELLO E GRAFICA PROVVISORI"
	hud.set_status("Avvicinati al predatore. Quando prepara il morso, arretra o aggira una copertura.")


func _on_enemy_destroyed() -> void:
	hud.set_status("PREDATORE ABBATTUTO  /  Incontro completato. R per riprovare.")
