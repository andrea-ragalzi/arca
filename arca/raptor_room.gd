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
	hud.get_node("Frame/Subtitle").text = "CONTINUITY STATION   /   PREDATOR TEST"
	hud.get_node("Frame/Tag").text = "PREDATOR ENCOUNTER\nTEMPORARY MODEL AND ART"
	hud.set_status("Approach the predator. Retreat or use cover when it prepares to bite.")


func _on_enemy_destroyed() -> void:
	hud.set_status("PREDATOR DOWN  /  Encounter complete. Press R to restart.")
