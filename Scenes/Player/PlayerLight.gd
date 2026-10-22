extends Node2D

@export var focus_range: float = 230.0
@export_range(1.0, 45.0, 1.0) var focus_half_angle: float = 16.0
@export var effect_interval: float = 0.08

@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var campaign_manager: Node
var sector_polygon := PackedVector2Array()
var focus_active: bool = false
var effect_timer: float = 0.0


func _ready() -> void:
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	sector_polygon = _make_sector(focus_range, deg_to_rad(focus_half_angle), 12)
	(collision_shape.shape as CircleShape2D).radius = focus_range
	detection_area.monitoring = false
	queue_redraw()


func _process(delta: float) -> void:
	update_focus(delta, Input.is_action_pressed("focus_light"), get_global_mouse_position())


func update_focus(delta: float, requesting_focus: bool, aim_point: Vector2) -> void:
	aim_toward(aim_point)

	var was_active := focus_active
	focus_active = false
	if campaign_manager != null:
		focus_active = campaign_manager.update_focus(delta, requesting_focus)

	if focus_active != was_active:
		detection_area.set_deferred("monitoring", focus_active)
		queue_redraw()

	if not focus_active:
		return
	effect_timer -= delta
	if effect_timer > 0.0:
		return
	effect_timer = effect_interval
	for enemy in detection_area.get_overlapping_bodies():
		if enemy.is_in_group("enemy") and enemy.has_method("apply_focused_light") and contains_point(enemy.global_position):
			enemy.apply_focused_light(effect_interval)


func aim_toward(world_point: Vector2) -> void:
	var aim_offset := to_local(world_point)
	if not aim_offset.is_zero_approx():
		rotation = aim_offset.angle()
		queue_redraw()


func contains_point(world_point: Vector2) -> bool:
	var local_point := to_local(world_point)
	return local_point.x > 0.0 and local_point.length() <= focus_range and absf(local_point.angle()) <= deg_to_rad(focus_half_angle)


func _make_sector(radius: float, half_angle: float, arc_steps: int) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	for index in range(arc_steps + 1):
		var angle := lerpf(-half_angle, half_angle, float(index) / float(arc_steps))
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


func _draw() -> void:
	if not focus_active:
		return
	var pulse := 0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.012)
	draw_colored_polygon(sector_polygon, Color(0.56, 0.82, 1.0, 0.13 * pulse))
	draw_polyline(PackedVector2Array([sector_polygon[1], Vector2.ZERO, sector_polygon[-1]]), Color(0.72, 0.91, 1.0, 0.72), 1.5, true)
	draw_arc(Vector2.ZERO, 12.0, -deg_to_rad(focus_half_angle), deg_to_rad(focus_half_angle), 10, Color(0.8, 0.95, 1.0, 0.48), 1.0, true)
