extends Area2D

@export var value: int = 1
var collected: bool = false

func _on_body_entered(body):
	if collected or not body.is_in_group("player"):
		return
	collected = true
	body.collect_beacon(value)
	queue_free()
