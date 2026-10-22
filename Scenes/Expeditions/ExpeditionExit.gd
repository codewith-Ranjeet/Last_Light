extends Node2D

const EXPEDITION_PHASE := 4

func _ready() -> void:
	add_to_group("player_interactable")
	queue_redraw()


func get_interaction_prompt() -> String:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null or manager.current_state != EXPEDITION_PHASE:
		return "Extraction unavailable"
	var controller: Node = manager.get_current_expedition_controller()
	if controller != null and controller.objective_complete:
		return "E Extract · Prism Shard secured"
	return "E Return to the Lighthouse · Objective incomplete"


func interact() -> bool:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return false
	return manager.return_from_expedition("The Keeper extracted safely.")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 23.0, Color(0.16, 0.21, 0.18, 0.9))
	draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 32, Color(0.83, 0.76, 0.49, 0.9), 2.0, true)
	draw_line(Vector2(-11, 0), Vector2(11, 0), Color(0.93, 0.85, 0.58), 2.0, true)
	draw_line(Vector2(0, -11), Vector2(0, 11), Color(0.93, 0.85, 0.58), 2.0, true)
