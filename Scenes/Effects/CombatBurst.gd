extends Node2D

var tint: Color = Color.WHITE
var burst_radius: float = 18.0
var progress: float = 0.0


func configure(effect_tint: Color, effect_radius: float) -> void:
	tint = effect_tint
	burst_radius = maxf(effect_radius, 1.0)


func _ready() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, 0.28)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	progress = value
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - progress
	var color := Color(tint.r, tint.g, tint.b, tint.a * fade)
	var ring_radius := lerpf(burst_radius * 0.22, burst_radius, progress)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 20, color, 2.0, true)
	for index in range(8):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 8.0)
		var inner := direction * ring_radius * 0.72
		var outer := direction * (ring_radius + burst_radius * 0.28)
		draw_line(inner, outer, color, 1.5, true)
