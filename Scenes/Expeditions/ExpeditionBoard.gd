extends Node2D

const DAY_PHASE := 0

func _ready() -> void:
	add_to_group("player_interactable")
	queue_redraw()


func get_interaction_prompt() -> String:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return "Expedition board unavailable"
	if manager.current_state != DAY_PHASE:
		return "Expeditions are only available during Day"
	var expedition_id: StringName = manager.get_available_expedition_id()
	if expedition_id == &"":
		return "All three Prism Shards are secured"
	var expedition_name := _name_for(expedition_id)
	if not manager.can_enter_expedition(expedition_id):
		return "%s opens on Day %d" % [expedition_name, _day_for(expedition_id)]
	return "E Depart for %s" % expedition_name


func interact() -> bool:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return false
	var expedition_id: StringName = manager.get_available_expedition_id()
	return manager.enter_expedition(expedition_id) if expedition_id != &"" else false


func _name_for(expedition_id: StringName) -> String:
	match expedition_id:
		&"shipbreaker_beach":
			return "Shipbreaker Beach"
		&"saltwood_forest":
			return "Saltwood Forest"
		&"drowned_chapel":
			return "Drowned Chapel"
	return "Expedition"


func _day_for(expedition_id: StringName) -> int:
	match expedition_id:
		&"shipbreaker_beach":
			return 2
		&"saltwood_forest":
			return 3
		&"drowned_chapel":
			return 4
	return 2


func _draw() -> void:
	draw_circle(Vector2(0, 0), 22.0, Color(0.16, 0.19, 0.16, 0.9))
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(0.78, 0.69, 0.43, 0.9), 2.0, true)
	draw_line(Vector2(-10, 8), Vector2(10, 8), Color(0.78, 0.69, 0.43), 2.0, true)
	draw_line(Vector2(0, -12), Vector2(0, 7), Color(0.78, 0.69, 0.43), 2.0, true)
	draw_line(Vector2(-7, -5), Vector2(0, -12), Color(0.78, 0.69, 0.43), 2.0, true)
	draw_line(Vector2(7, -5), Vector2(0, -12), Color(0.78, 0.69, 0.43), 2.0, true)
