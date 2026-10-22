extends Node2D

func _ready() -> void:
	add_to_group("player_interactable")
	queue_redraw()


func get_interaction_prompt() -> String:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return "Dawn Lens unavailable"
	if manager.current_state != manager.Phase.DAY or manager.day_number < 5:
		return "The Dawn Lens awakens on Day 5"
	if manager.get_secured_shard_count() < 3:
		return "Dawn Lens · Need all 3 Prism Shards"
	if manager.installed_shard_lens:
		return "Dawn Lens · Tuning selected"
	return "E Install the three Prism Shards"


func interact() -> bool:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null or not manager.begin_lens_selection():
		return false
	queue_redraw()
	return true


func _draw() -> void:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004)
	var shard_count: int = manager.get_secured_shard_count() if manager != null else 0
	var installed: bool = manager != null and manager.installed_shard_lens
	draw_circle(Vector2.ZERO, 21.0, Color(0.12, 0.17, 0.2, 0.92))
	draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 32, Color(0.8, 0.87, 0.67, 0.92 * pulse) if installed else Color(0.62, 0.84, 0.92, 0.9 * pulse), 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -13), Vector2(8, -1), Vector2(0, 13), Vector2(-8, -1)]), Color(0.96, 0.79, 0.47, pulse) if installed else Color(0.72, 0.9, 1.0, pulse))
	draw_arc(Vector2.ZERO, 28.0, -PI * 0.78, -PI * 0.22, 20, Color(0.95, 0.79, 0.47, 0.68 * pulse), 1.5, true)
	for index in range(shard_count):
		var angle := TAU * float(index) / 3.0 - PI * 0.5
		var shard_position: Vector2 = Vector2.RIGHT.rotated(angle) * (31.0 if installed else 26.0)
		draw_colored_polygon(PackedVector2Array([shard_position + Vector2(0, -4), shard_position + Vector2(3, 0), shard_position + Vector2(0, 4), shard_position + Vector2(-3, 0)]), Color(0.61, 0.86, 1.0, pulse))
