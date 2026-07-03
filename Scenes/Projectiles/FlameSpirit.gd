extends Area2D

@export var speed = 500.0
@export var damage = 20

var direction = Vector2.ZERO

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.damage_to_enemy(damage)
		queue_free()

func _process(delta):
	position += direction * speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
