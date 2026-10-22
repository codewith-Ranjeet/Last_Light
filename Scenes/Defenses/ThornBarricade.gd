extends StaticBody2D

@export var max_durability: int = 60

var durability: int = 60
var is_destroyed: bool = false


func _ready() -> void:
	add_to_group("defense_structure")
	durability = maxi(max_durability, 1)
	queue_redraw()


func damage_structure(amount: int) -> void:
	if is_destroyed or amount <= 0:
		return
	durability = maxi(durability - amount, 0)
	CombatFeedback.burst(get_parent(), global_position, Color(0.9, 0.45, 0.25), 13.0)
	queue_redraw()
	if durability == 0:
		is_destroyed = true
		CombatFeedback.burst(get_parent(), global_position, Color(1.0, 0.67, 0.36), 28.0)
		queue_free()


func _draw() -> void:
	var health_ratio := float(durability) / float(maxi(max_durability, 1))
	var plank := Color(0.34, 0.17, 0.12)
	var edge := Color(0.83, 0.48, 0.27)
	draw_rect(Rect2(-26.0, -10.0, 52.0, 20.0), plank, true)
	draw_rect(Rect2(-26.0, -10.0, 52.0, 20.0), edge, false, 2.0)
	for x in [-18.0, -6.0, 6.0, 18.0]:
		draw_line(Vector2(x, -9.0), Vector2(x + 7.0, 9.0), edge, 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-23, -9), Vector2(-20, -19), Vector2(-15, -9)]), edge)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -9), Vector2(-4, -20), Vector2(0, -9)]), edge)
	draw_colored_polygon(PackedVector2Array([Vector2(9, -9), Vector2(13, -20), Vector2(17, -9)]), edge)
	draw_rect(Rect2(-24.0, -17.0, 48.0, 3.0), Color(0.09, 0.08, 0.08), true)
	draw_rect(Rect2(-24.0, -17.0, 48.0 * health_ratio, 3.0), Color(0.85, 0.62, 0.3), true)
