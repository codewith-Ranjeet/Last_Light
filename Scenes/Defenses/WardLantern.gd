extends Area2D

@export var field_radius: float = 76.0
@export var slow_duration: float = 0.45
@export var effect_interval: float = 0.24
@export var lifetime: float = 90.0

var elapsed: float = 0.0
var effect_timer: float = 0.0
var base_field_radius: float = 76.0


func _ready() -> void:
	add_to_group("defense_structure")
	add_to_group("ward_lantern")
	base_field_radius = field_radius
	apply_campaign_upgrades()


func apply_campaign_upgrades() -> void:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	var multiplier: float = manager.get_ward_radius_multiplier() if manager != null and manager.has_method("get_ward_radius_multiplier") else 1.0
	field_radius = base_field_radius * multiplier
	var shape := $CollisionShape2D.shape as CircleShape2D
	shape.radius = field_radius
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		CombatFeedback.burst(get_parent(), global_position, Color(0.7, 0.85, 1.0), 24.0)
		queue_free()
		return
	queue_redraw()
	effect_timer -= delta
	if effect_timer > 0.0:
		return
	effect_timer = effect_interval
	for enemy in get_overlapping_bodies():
		if enemy.is_in_group("enemy") and enemy.has_method("apply_ward_light"):
			enemy.apply_ward_light(slow_duration)


func _draw() -> void:
	var pulse := 0.82 + 0.12 * sin(Time.get_ticks_msec() * 0.003)
	draw_circle(Vector2.ZERO, field_radius, Color(0.52, 0.77, 1.0, 0.035 * pulse))
	draw_arc(Vector2.ZERO, field_radius, 0.0, TAU, 40, Color(0.57, 0.82, 1.0, 0.36 * pulse), 1.5, true)
	draw_line(Vector2(0, -14), Vector2(0, 14), Color(0.62, 0.82, 1.0, 0.9), 3.0, true)
	draw_line(Vector2(-9, 14), Vector2(9, 14), Color(0.62, 0.82, 1.0, 0.9), 3.0, true)
	draw_line(Vector2(-7, -5), Vector2(7, -5), Color(0.88, 0.96, 1.0, 0.9), 2.0, true)
	draw_circle(Vector2.ZERO, 4.0, Color(0.78, 0.92, 1.0, 0.8 * pulse))
