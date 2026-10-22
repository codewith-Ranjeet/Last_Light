extends Node2D

@export var sweep_speed: float = 0.42
@export var beam_range: float = 380.0
@export_range(1.0, 45.0, 1.0) var beam_half_angle: float = 12.0
@export var effect_interval: float = 0.2

const NIGHT_PHASE := 2

@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var campaign_manager: Node
var sector_polygon := PackedVector2Array()
var effect_timer: float = 0.0


func _ready() -> void:
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	sector_polygon = _make_sector(beam_range, deg_to_rad(beam_half_angle), 12)
	(collision_shape.shape as CircleShape2D).radius = beam_range
	rotation = -PI * 0.5


func _process(delta: float) -> void:
	rotation += sweep_speed * delta
	queue_redraw()
	if campaign_manager == null or campaign_manager.current_state != NIGHT_PHASE:
		return
	if campaign_manager.has_method("is_light_suppressed") and campaign_manager.is_light_suppressed():
		return
	effect_timer -= delta
	if effect_timer > 0.0:
		return
	effect_timer = effect_interval
	for enemy in detection_area.get_overlapping_bodies():
		if enemy.is_in_group("enemy") and enemy.has_method("apply_lighthouse_light") and contains_point(enemy.global_position):
			enemy.apply_lighthouse_light(effect_interval)


func contains_point(world_point: Vector2) -> bool:
	var local_point := to_local(world_point)
	return local_point.x > 0.0 and local_point.length() <= beam_range and absf(local_point.angle()) <= deg_to_rad(beam_half_angle)


func _make_sector(radius: float, half_angle: float, arc_steps: int) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	for index in range(arc_steps + 1):
		var angle := lerpf(-half_angle, half_angle, float(index) / float(arc_steps))
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


func _draw() -> void:
	var nighttime: bool = campaign_manager != null and campaign_manager.current_state == NIGHT_PHASE
	var suppressed: bool = campaign_manager != null and campaign_manager.has_method("is_light_suppressed") and campaign_manager.is_light_suppressed()
	var alpha := 0.11 if nighttime else 0.035
	var beam_color := Color(0.38, 0.29, 0.48) if suppressed else Color(1.0, 0.82, 0.48)
	draw_colored_polygon(sector_polygon, Color(beam_color.r, beam_color.g, beam_color.b, alpha))
	draw_polyline(PackedVector2Array([sector_polygon[1], Vector2.ZERO, sector_polygon[-1]]), Color(beam_color.r, beam_color.g, beam_color.b, alpha * 2.6), 1.0, true)
