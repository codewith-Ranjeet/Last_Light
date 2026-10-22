extends Area2D

@export var trigger_damage: int = 10
@export var snare_duration: float = 1.5
@export var lifetime: float = 45.0

var triggered: bool = false
var elapsed: float = 0.0


func _ready() -> void:
	add_to_group("defense_structure")


func _process(delta: float) -> void:
	if triggered:
		return
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("enemy"):
		return
	triggered = true
	set_deferred("monitoring", false)
	if body.has_method("apply_snare"):
		body.apply_snare(snare_duration)
	if body.has_method("damage_to_enemy"):
		body.damage_to_enemy(trigger_damage)
	CombatFeedback.burst(get_parent(), global_position, Color(0.35, 0.95, 0.8), 30.0)
	queue_redraw()
	var timer := get_tree().create_timer(0.22)
	timer.timeout.connect(queue_free)


func _draw() -> void:
	if triggered:
		return
	var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.008)
	var color := Color(0.36, 0.8, 0.67, 0.8 * pulse)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, color, 2.0, true)
	draw_line(Vector2(-13, -13), Vector2(13, 13), color, 2.0, true)
	draw_line(Vector2(-13, 13), Vector2(13, -13), color, 2.0, true)
	draw_circle(Vector2.ZERO, 3.0, Color(0.76, 1.0, 0.83, 0.9 * pulse))
