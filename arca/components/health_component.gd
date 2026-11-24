class_name ArcaHealth
extends Node
## Each accepted hit is one damage packet. Death is emitted only once.

signal changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export_range(1, 1000) var max_health: int = 100
@export_range(0.0, 5.0) var hit_cooldown: float = 0.75

var current: int
var cooldown_remaining: float = 0.0


func _ready() -> void:
	current = max_health
	changed.emit(current, max_health)


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func take_damage(amount: int) -> bool:
	if amount <= 0 or current <= 0 or cooldown_remaining > 0.0:
		return false
	var lost: int = mini(current, amount)
	current -= lost
	cooldown_remaining = hit_cooldown
	damaged.emit(lost)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> bool:
	if amount <= 0 or current <= 0 or current >= max_health:
		return false
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)
	return true
