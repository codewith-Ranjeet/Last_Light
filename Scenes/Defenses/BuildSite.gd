extends Node2D

@export var defense_name: String = "Thorn Barricade"
@export var salvage_cost: int = 4
@export var structure_scene: PackedScene

var built: bool = false
var building: bool = false

const DAY_PHASE := 0


func _ready() -> void:
	add_to_group("player_interactable")
	queue_redraw()


func get_interaction_prompt() -> String:
	if built:
		return "Site occupied"
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return "%s · %d Salvage" % [defense_name, salvage_cost]
	if manager.current_state != DAY_PHASE:
		return "%s · %d Salvage · Build during Day" % [defense_name, salvage_cost]
	if manager.salvage < salvage_cost:
		return "%s · Need %d Salvage" % [defense_name, salvage_cost]
	return "E Build %s · %d Salvage" % [defense_name, salvage_cost]


func interact() -> bool:
	if built or building or structure_scene == null:
		return false
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null or manager.current_state != DAY_PHASE:
		return false
	building = true
	var structure := structure_scene.instantiate()
	if not manager.spend_salvage(salvage_cost):
		structure.free()
		building = false
		return false
	built = true
	get_parent().add_child(structure)
	structure.global_position = global_position
	if manager.has_method("apply_defense_upgrades"):
		manager.apply_defense_upgrades(structure)
	if structure.has_method("apply_campaign_upgrades"):
		structure.apply_campaign_upgrades()
	CombatFeedback.burst(get_parent(), global_position, Color(0.72, 0.91, 0.68), 22.0)
	queue_redraw()
	return true


func _draw() -> void:
	if built:
		return
	var pulse := 0.84 + 0.16 * sin(Time.get_ticks_msec() * 0.003)
	var marker_color := Color(0.68, 0.8, 0.48, 0.65 * pulse)
	draw_rect(Rect2(-22, -22, 44, 44), Color(0.09, 0.12, 0.1, 0.64), true)
	draw_rect(Rect2(-22, -22, 44, 44), marker_color, false, 2.0)
	draw_line(Vector2(-12, 0), Vector2(12, 0), marker_color, 2.0, true)
	draw_line(Vector2(0, -12), Vector2(0, 12), marker_color, 2.0, true)
