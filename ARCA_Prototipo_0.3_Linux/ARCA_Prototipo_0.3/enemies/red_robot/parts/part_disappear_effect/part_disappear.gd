extends CPUParticles3D


func _ready() -> void:
	$MiniBlasts.emitting = true
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(set.bind("emitting", true))
	tween.tween_interval(lifetime * 2.0)
	tween.tween_callback(queue_free)
