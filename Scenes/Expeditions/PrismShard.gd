extends Area2D

@export var shard_id: StringName
@export var shard_title: String = "Prism Shard"
@export var locked: bool = false

var collected: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("prism_shard")
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager != null and manager.is_shard_secured(shard_id):
		collected = true
		queue_free()
		return
	collision_shape.set_deferred("disabled", locked)
	queue_redraw()


func set_locked(value: bool) -> void:
	locked = value
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", locked)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if collected or locked or not body.is_in_group("player"):
		return
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null or not manager.secure_shard(shard_id):
		return
	collected = true
	var controller: Node = manager.get_current_expedition_controller()
	if controller != null and controller.has_method("notify_shard_secured"):
		controller.notify_shard_secured()
	CombatFeedback.burst(get_parent(), global_position, Color(0.78, 0.9, 1.0), 34.0)
	queue_free()


func _draw() -> void:
	var pulse := 0.88 + 0.12 * sin(Time.get_ticks_msec() * 0.005)
	if locked:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 28, Color(0.42, 0.55, 0.56, 0.75 * pulse), 2.0, true)
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color(0.42, 0.55, 0.56, 0.85), 2.0, true)
		return
	draw_colored_polygon(PackedVector2Array([Vector2(0, -19), Vector2(11, -4), Vector2(8, 14), Vector2(0, 20), Vector2(-8, 14), Vector2(-11, -4)]), Color(0.45, 0.67, 0.81, 0.86 * pulse))
	draw_polyline(PackedVector2Array([Vector2(0, -19), Vector2(11, -4), Vector2(8, 14), Vector2(0, 20), Vector2(-8, 14), Vector2(-11, -4), Vector2(0, -19)]), Color(0.88, 0.96, 1.0, pulse), 2.0, true)
	draw_line(Vector2(0, -13), Vector2(0, 15), Color(1.0, 1.0, 1.0, 0.72 * pulse), 1.0, true)
