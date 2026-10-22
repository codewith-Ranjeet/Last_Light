extends StaticBody2D

@export var barrier_size: Vector2 = Vector2(170, 32)
@export var reveal_seconds: float = 1.15

var reveal_progress: float = 0.0
var revealed: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("light_sensitive")
	(collision_shape.shape as RectangleShape2D).size = barrier_size
	queue_redraw()


func apply_focused_light(delta: float = 0.08) -> void:
	if revealed:
		return
	reveal_progress = minf(reveal_progress + maxf(delta, 0.01), maxf(reveal_seconds, 0.01))
	if reveal_progress >= maxf(reveal_seconds, 0.01):
		revealed = true
		collision_shape.set_deferred("disabled", true)
		CombatFeedback.burst(get_parent(), global_position, Color(0.46, 0.91, 0.78), 28.0)
	queue_redraw()


func _process(_delta: float) -> void:
	if not revealed:
		queue_redraw()


func _draw() -> void:
	if revealed:
		draw_arc(Vector2.ZERO, barrier_size.x * 0.32, PI, TAU, 20, Color(0.51, 0.91, 0.72, 0.58), 2.0, true)
		return
	var alpha := 0.55 + 0.12 * sin(Time.get_ticks_msec() * 0.006)
	draw_rect(Rect2(-barrier_size.x * 0.5, -barrier_size.y * 0.5, barrier_size.x, barrier_size.y), Color(0.035, 0.07, 0.09, alpha), true)
	draw_rect(Rect2(-barrier_size.x * 0.5, -barrier_size.y * 0.5, barrier_size.x, barrier_size.y), Color(0.35, 0.7, 0.74, alpha), false, 2.0)
	var progress_width := barrier_size.x * clampf(reveal_progress / maxf(reveal_seconds, 0.01), 0.0, 1.0)
	draw_rect(Rect2(-barrier_size.x * 0.5, barrier_size.y * 0.5 + 4.0, progress_width, 3.0), Color(0.53, 0.96, 0.79, 0.95), true)
