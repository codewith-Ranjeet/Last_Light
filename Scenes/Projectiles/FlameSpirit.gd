extends Area2D

@export var speed: float = 500.0
@export var damage: int = 20

var direction: Vector2 = Vector2.ZERO


func _process(delta):
	position += direction * speed * delta


func _on_body_entered(body):
	if body.is_in_group("enemy"):
		var damage_to_deal := damage
		var manager := get_tree().get_first_node_in_group("campaign_manager")
		if manager != null and manager.selected_lens == &"focused_flame" and body.has_method("is_exposed_to_focused_light") and body.is_exposed_to_focused_light():
			damage_to_deal = roundi(float(damage_to_deal) * manager.get_focused_attack_multiplier())
		body.damage_to_enemy(damage_to_deal)
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
