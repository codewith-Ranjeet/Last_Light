extends Node2D

@export var clue_id: StringName
@export var clue_title: String = "Journal Fragment"
@export_multiline var clue_text: String = ""

var discovered: bool = false


func _ready() -> void:
	add_to_group("player_interactable")
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager != null:
		discovered = manager.has_discovered_story_clue(clue_id)
	queue_redraw()


func get_interaction_prompt() -> String:
	return "%s · already recorded" % clue_title if discovered else "E Read %s" % clue_title


func interact() -> bool:
	if discovered:
		return false
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null or not manager.record_story_clue(clue_id, clue_title, clue_text):
		return false
	discovered = true
	CombatFeedback.burst(get_parent(), global_position, Color(0.83, 0.75, 0.54), 18.0)
	queue_redraw()
	return true


func _draw() -> void:
	var paper := Color(0.64, 0.53, 0.35, 0.9) if not discovered else Color(0.47, 0.64, 0.54, 0.8)
	draw_rect(Rect2(-12, -15, 24, 30), Color(0.12, 0.1, 0.08, 0.9), true)
	draw_rect(Rect2(-9, -12, 18, 24), paper, true)
	for y in [-6.0, 0.0, 6.0]:
		draw_line(Vector2(-6, y), Vector2(6, y), Color(0.19, 0.17, 0.13, 0.8), 1.0, true)
