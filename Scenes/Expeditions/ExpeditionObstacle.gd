extends StaticBody2D

@export var obstacle_size: Vector2 = Vector2(70, 42)
@export var obstacle_color: Color = Color(0.31, 0.27, 0.2)
@export_enum("wreck", "rock", "tree", "pillar") var style: String = "rock"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	(collision_shape.shape as RectangleShape2D).size = obstacle_size
	queue_redraw()


func _draw() -> void:
	match style:
		"wreck":
			_draw_wreck()
		"tree":
			_draw_tree()
		"pillar":
			_draw_pillar()
		_:
			_draw_rock()


func _draw_wreck() -> void:
	draw_rect(Rect2(-obstacle_size.x * 0.5, -obstacle_size.y * 0.35, obstacle_size.x, obstacle_size.y * 0.7), obstacle_color, true)
	for index in range(4):
		var x := -obstacle_size.x * 0.4 + float(index) * obstacle_size.x * 0.26
		draw_line(Vector2(x, -obstacle_size.y * 0.35), Vector2(x + 8, obstacle_size.y * 0.35), obstacle_color.lightened(0.24), 3.0, true)
	draw_line(Vector2(-obstacle_size.x * 0.5, 0), Vector2(obstacle_size.x * 0.5, 0), obstacle_color.darkened(0.18), 2.0, true)


func _draw_tree() -> void:
	draw_rect(Rect2(-obstacle_size.x * 0.12, -obstacle_size.y * 0.5, obstacle_size.x * 0.24, obstacle_size.y), obstacle_color.darkened(0.26), true)
	draw_circle(Vector2(0, -obstacle_size.y * 0.32), obstacle_size.x * 0.42, obstacle_color)
	draw_circle(Vector2(-obstacle_size.x * 0.18, -obstacle_size.y * 0.36), obstacle_size.x * 0.24, obstacle_color.lightened(0.16))


func _draw_pillar() -> void:
	draw_rect(Rect2(-obstacle_size.x * 0.34, -obstacle_size.y * 0.5, obstacle_size.x * 0.68, obstacle_size.y), obstacle_color, true)
	draw_rect(Rect2(-obstacle_size.x * 0.5, -obstacle_size.y * 0.5, obstacle_size.x, 8.0), obstacle_color.lightened(0.2), true)
	draw_line(Vector2(-obstacle_size.x * 0.2, -obstacle_size.y * 0.3), Vector2(-obstacle_size.x * 0.2, obstacle_size.y * 0.4), obstacle_color.darkened(0.2), 2.0, true)


func _draw_rock() -> void:
	var half := obstacle_size * 0.5
	var points := PackedVector2Array([Vector2(-half.x * 0.8, half.y * 0.2), Vector2(-half.x * 0.52, -half.y * 0.36), Vector2(half.x * 0.06, -half.y * 0.52), Vector2(half.x * 0.48, -half.y * 0.2), Vector2(half.x * 0.72, half.y * 0.32), Vector2(-half.x * 0.1, half.y * 0.48)])
	draw_colored_polygon(points, obstacle_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[0]]), obstacle_color.lightened(0.22), 2.0, true)
