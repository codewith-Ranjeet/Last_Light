extends Node2D

@export var defense_name: String = "Thorn Barricade"
@export var salvage_cost: int = 4
@export var structure_scene: PackedScene

var built: bool = false
var building: bool = false
var site_key: StringName = &""
var structure: Node = null

const DAY_PHASE := 0


func _ready() -> void:
	add_to_group("player_interactable")
	add_to_group("build_site")
	site_key = StringName(name)
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
	var instance := structure_scene.instantiate()
	if not manager.spend_salvage(salvage_cost):
		instance.free()
		building = false
		return false
	_place_structure(instance)
	building = false
	if manager.has_method("record_built_defense"):
		manager.record_built_defense(site_key, structure_scene.resource_path)
	return true


# Recreate a defense recorded on the persistent campaign root. Called when the
# replaceable world (the Lighthouse Yard) is reloaded, e.g. after an expedition.
func restore_built_defense(structure_path: String) -> void:
	if built or structure_path.is_empty():
		return
	var scene := load(structure_path) as PackedScene
	if scene == null:
		return
	_place_structure(scene.instantiate())


func _place_structure(instance: Node) -> void:
	if instance == null:
		return
	built = true
	structure = instance
	get_parent().add_child(instance)
	instance.global_position = global_position
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager != null and manager.has_method("apply_defense_upgrades"):
		manager.apply_defense_upgrades(instance)
	if instance.has_method("apply_campaign_upgrades"):
		instance.apply_campaign_upgrades()
	CombatFeedback.burst(get_parent(), global_position, Color(0.72, 0.91, 0.68), 22.0)
	instance.tree_exited.connect(_on_structure_gone, CONNECT_ONE_SHOT)
	queue_redraw()


func _on_structure_gone() -> void:
	structure = null
	if not is_inside_tree():
		return
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager == null:
		return
	# A world swap frees the whole Yard; keep the campaign record so the defense
	# is rebuilt on return. Only a defense that leaves while its own world is
	# still active is a genuine removal (destroyed or expired) -> free the site.
	if manager.has_method("is_active_world") and not manager.is_active_world(get_parent()):
		return
	built = false
	if manager.has_method("release_built_defense"):
		manager.release_built_defense(site_key)
	queue_redraw()


func _draw() -> void:
	if built:
		return
	var pulse := 0.84 + 0.16 * sin(Time.get_ticks_msec() * 0.003)
	var marker_color := Color(0.68, 0.8, 0.48, 0.65 * pulse)
	draw_rect(Rect2(-22, -22, 44, 44), Color(0.09, 0.12, 0.1, 0.64), true)
	draw_rect(Rect2(-22, -22, 44, 44), marker_color, false, 2.0)
	draw_line(Vector2(-12, 0), Vector2(12, 0), marker_color, 2.0, true)
	draw_line(Vector2(0, -12), Vector2(0, 12), marker_color, 2.0, true)
