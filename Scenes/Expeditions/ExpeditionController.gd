extends Node2D
class_name ExpeditionController

@export var expedition_id: StringName
@export var expedition_name: String = "Expedition"
@export var shard_id: StringName
@export var shard_name: String = "Prism Shard"
@export var requires_bell_taker: bool = false

var campaign_manager: Node
var bell_taker_defeated: bool = false
var objective_complete: bool = false


func _ready() -> void:
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	if campaign_manager == null:
		return
	objective_complete = campaign_manager.is_shard_secured(shard_id)
	if objective_complete:
		var shard := get_node_or_null("PrismShard")
		if shard != null:
			shard.queue_free()
	if campaign_manager.has_signal("shard_secured"):
		campaign_manager.shard_secured.connect(_on_shard_secured)
	if requires_bell_taker:
		call_deferred("_connect_bell_taker")
	queue_redraw()


func _connect_bell_taker() -> void:
	var bell := find_child("BellTaker", true, false)
	if bell == null:
		return
	if bell.has_signal("defeated"):
		bell.connect("defeated", _on_enemy_defeated)
	else:
		bell_taker_defeated = true
		_unlock_shard()


func _on_enemy_defeated(enemy_kind: StringName, _position: Vector2) -> void:
	if enemy_kind != &"bell_taker":
		return
	bell_taker_defeated = true
	_unlock_shard()


func _unlock_shard() -> void:
	var shard := get_node_or_null("PrismShard")
	if shard != null and shard.has_method("set_locked"):
		shard.set_locked(false)
	queue_redraw()


func _on_shard_secured(secured_id: StringName, _count: int) -> void:
	if secured_id == shard_id:
		objective_complete = true
		queue_redraw()


func get_objective_text() -> String:
	var objective := ""
	if objective_complete or (campaign_manager != null and campaign_manager.is_shard_secured(shard_id)):
		objective = "%s secured · Return to the marked extraction point" % shard_name
	elif requires_bell_taker and not bell_taker_defeated:
		objective = "Defeat the Bell-Taker to reveal the %s" % shard_name
	elif expedition_id == &"saltwood_forest":
		var veil_barrier := get_node_or_null("VeilBarrier")
		if veil_barrier != null and not veil_barrier.revealed:
			objective = "Focus light on the Veil barrier to reveal the safe route to the %s" % shard_name
		else:
			objective = "Find the %s" % shard_name
	else:
		objective = "Find the %s" % shard_name

	if campaign_manager != null:
		var seconds := ceili(campaign_manager.get_expedition_time_remaining())
		if campaign_manager.expedition_warning_sent:
			objective += " · DUSK: extract now (%ds)" % seconds
		else:
			objective += " · Dusk in %ds" % seconds
	return objective


func notify_shard_secured() -> void:
	objective_complete = true
	queue_redraw()


func _draw() -> void:
	# Expeditions that paint their world with layered pixel-art scenery nodes in
	# the scene file (Shipbreaker Beach, Saltwood Forest, Drowned Chapel) skip
	# the procedural ground fill and prop drawing so the two never double up.
	# The shared extraction marker below is always drawn by the controller.
	if not has_node("Scenery"):
		draw_rect(Rect2(-640, -360, 1280, 720), _ground_color(), true)
		match expedition_id:
			&"saltwood_forest":
				_draw_forest()
			&"drowned_chapel":
				_draw_chapel()
	draw_line(Vector2(0, 238), Vector2(0, 170), Color(0.83, 0.72, 0.47, 0.65), 2.0, true)
	draw_circle(Vector2(0, 160), 4.0, Color(0.97, 0.83, 0.54, 0.85))


func _ground_color() -> Color:
	match expedition_id:
		&"shipbreaker_beach":
			return Color(0.19, 0.31, 0.34)
		&"saltwood_forest":
			return Color(0.09, 0.17, 0.15)
		&"drowned_chapel":
			return Color(0.13, 0.23, 0.28)
	return Color(0.1, 0.12, 0.12)


func _draw_forest() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-180, 360), Vector2(-90, -360), Vector2(100, -360), Vector2(205, 360)]), Color(0.21, 0.27, 0.19, 0.75))
	for index in range(17):
		var x := -590.0 + float(index) * 73.0
		var top := -310.0 + float((index * 47) % 180)
		var trunk_color := Color(0.17, 0.13, 0.1, 0.95)
		draw_rect(Rect2(x - 7, top, 14, 390), trunk_color, true)
		draw_circle(Vector2(x, top), 27.0 + float(index % 3) * 5.0, Color(0.12, 0.24, 0.17, 0.8))
		draw_circle(Vector2(x - 10, top + 4), 18.0, Color(0.17, 0.29, 0.18, 0.78))
	draw_line(Vector2(-72, 190), Vector2(-28, -190), Color(0.78, 0.72, 0.5, 0.34), 2.0, true)
	draw_line(Vector2(72, 190), Vector2(28, -190), Color(0.78, 0.72, 0.5, 0.34), 2.0, true)


func _draw_chapel() -> void:
	for index in range(6):
		var x := -470.0 + float(index) * 185.0
		draw_arc(Vector2(x, 170), 52.0, PI, TAU, 24, Color(0.46, 0.57, 0.58, 0.32), 2.0, true)
		draw_circle(Vector2(x + 35, -230 + float((index * 53) % 300)), 26.0, Color(0.28, 0.47, 0.5, 0.24))
	for x in [-245.0, -150.0, 150.0, 245.0]:
		draw_rect(Rect2(x - 13, -185, 26, 370), Color(0.32, 0.39, 0.38, 0.78), true)
		draw_rect(Rect2(x - 18, -185, 36, 9), Color(0.48, 0.52, 0.48, 0.84), true)
	draw_rect(Rect2(-285, -198, 570, 18), Color(0.36, 0.43, 0.41, 0.72), true)
