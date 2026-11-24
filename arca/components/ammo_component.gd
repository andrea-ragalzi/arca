class_name ArcaAmmo
extends Node

signal changed(magazine: int, reserve: int)
signal reload_started
signal reload_finished

@export_range(1, 100) var magazine_size: int = 12
@export_range(0, 100) var magazine: int = 12
@export_range(0, 1000) var reserve: int = 12
@export_range(0.1, 15.0) var reload_duration: float = 1.5

var reload_remaining: float = 0.0
var reloading: bool:
	get:
		return reload_remaining > 0.0


func _ready() -> void:
	magazine = clampi(magazine, 0, magazine_size)
	reserve = maxi(reserve, 0)


func _physics_process(delta: float) -> void:
	if not reloading:
		return
	reload_remaining = maxf(reload_remaining - delta, 0.0)
	if not reloading:
		var rounds: int = mini(magazine_size - magazine, reserve)
		magazine += rounds
		reserve -= rounds
		changed.emit(magazine, reserve)
		reload_finished.emit()


func try_consume() -> bool:
	if reloading or magazine <= 0:
		return false
	magazine -= 1
	changed.emit(magazine, reserve)
	return true


func start_reload() -> bool:
	if reloading or magazine >= magazine_size or reserve <= 0:
		return false
	reload_remaining = reload_duration
	reload_started.emit()
	return true


func add_reserve(amount: int) -> void:
	if amount > 0:
		reserve += amount
		changed.emit(magazine, reserve)


func cancel_reload() -> void:
	if reloading:
		reload_remaining = 0.0
		changed.emit(magazine, reserve)
