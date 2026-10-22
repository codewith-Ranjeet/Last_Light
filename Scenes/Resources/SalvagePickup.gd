extends Area2D

@export var value: int = 3

var collected: bool = false


func _ready() -> void:
	add_to_group("resource_pickup")


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return
	collected = true
	manager.add_salvage(value)
	CombatFeedback.burst(get_parent(), global_position, Color(0.95, 0.71, 0.35), 20.0)
	queue_free()


func _draw() -> void:
	var pulse := 0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.006)
	var gold := Color(0.95, 0.68, 0.3, pulse)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -3), Vector2(-4, -9), Vector2(5, -7), Vector2(8, 0), Vector2(3, 8), Vector2(-7, 6)]), Color(0.24, 0.17, 0.11, 0.9))
	draw_polyline(PackedVector2Array([Vector2(-8, -3), Vector2(-4, -9), Vector2(5, -7), Vector2(8, 0), Vector2(3, 8), Vector2(-7, 6), Vector2(-8, -3)]), gold, 2.0, true)
	draw_line(Vector2(-4, -2), Vector2(4, 3), Color(1.0, 0.89, 0.6, pulse), 1.0, true)
