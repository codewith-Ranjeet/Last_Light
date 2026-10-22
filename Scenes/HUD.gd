extends CanvasLayer

@onready var hp_background = $MarginContainer/VBoxContainer/HPContainer/HPBackground
@onready var fill_mask = $MarginContainer/VBoxContainer/HPContainer/FillMask
@onready var hp_fill = $MarginContainer/VBoxContainer/HPContainer/FillMask/HPFill
@onready var beacon_label = $MarginContainer/VBoxContainer/BeaconContainer/BeaconCount
@onready var phase_label = $MarginContainer/VBoxContainer/Phase
@onready var salvage_label = $MarginContainer/VBoxContainer/Salvage
@onready var focus_label = $MarginContainer/VBoxContainer/FocusLabel
@onready var focus_meter = $MarginContainer/VBoxContainer/FocusMeter
@onready var interaction_hint = $MarginContainer/VBoxContainer/InteractionHint

@onready var game_manager = $"../GameManager"

@onready var full_fill_width = fill_mask.size.x
@onready var fill_start_x = fill_mask.position.x

var objective_banner: Label
var expedition_notice: Label
var campaign_status: Label
var notice_timer: float = 0.0


func _ready() -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.45, 0.82, 1.0, 0.92)
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	focus_meter.add_theme_stylebox_override("fill", fill_style)
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.08, 0.12, 0.17, 0.92)
	background_style.border_color = Color(0.45, 0.66, 0.76, 0.8)
	background_style.set_border_width_all(1)
	focus_meter.add_theme_stylebox_override("background", background_style)
	objective_banner = _make_banner(18, 64, -410, 410)
	expedition_notice = _make_bottom_banner(-112, -42, -380, 380)
	campaign_status = _make_status_banner()
	if game_manager != null:
		game_manager.story_clue_discovered.connect(_on_story_clue_discovered)
		game_manager.shard_secured.connect(_on_shard_secured)
		game_manager.expedition_time_warning.connect(_on_expedition_time_warning)
		game_manager.expedition_finished.connect(_on_expedition_finished)
		game_manager.light_suppression_changed.connect(_on_light_suppression_changed)
		game_manager.darkness_pulse_started.connect(_on_darkness_pulse_started)


func _process(_delta):
	if game_manager == null:
		return
	if notice_timer > 0.0:
		notice_timer = maxf(notice_timer - _delta, 0.0)
		expedition_notice.visible = notice_timer > 0.0
	update_hp()
	beacon_label.text = "Beacons: %d" % game_manager.beacon_count
	salvage_label.text = "Salvage: %d" % game_manager.salvage
	phase_label.text = game_manager.current_phase
	focus_meter.max_value = game_manager.focus_max
	focus_meter.value = game_manager.focus_energy
	focus_label.text = "Focus: %d%%" % roundi(game_manager.focus_energy / maxf(game_manager.focus_max, 1.0) * 100.0)
	var player: Node = game_manager.get_current_player()
	interaction_hint.text = player.interaction_prompt if player != null else ""
	objective_banner.text = game_manager.get_current_objective()
	var player_health := "%d/%d" % [game_manager.player_health, game_manager.player_max_health]
	campaign_status.text = "Keeper %s HP  ·  Beacons %d  ·  Salvage %d  ·  Shards %d/3" % [player_health, game_manager.beacon_count, game_manager.salvage, game_manager.get_secured_shard_count()]
	if game_manager.is_light_suppressed():
		campaign_status.text += "  ·  LIGHT SUPPRESSED"
	if game_manager.focus_disrupted_timer > 0.0:
		campaign_status.text += "  ·  DARKNESS PULSE"

#----------------Hp update-----------------
func update_hp():
	var lighthouse = game_manager.get_current_lighthouse()
	if lighthouse == null:
		return
	var percent = clampf(lighthouse.health / float(maxi(lighthouse.max_health, 1)), 0.0, 1.0)

	fill_mask.position.x = fill_start_x
	fill_mask.size.x = full_fill_width * percent


func _make_banner(top: float, bottom: float, left: float, right: float) -> Label:
	var label := Label.new()
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = left
	label.offset_right = right
	label.offset_top = top
	label.offset_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.79))
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.05, 0.05, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func _make_bottom_banner(top: float, bottom: float, left: float, right: float) -> Label:
	var label := Label.new()
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = left
	label.offset_right = right
	label.offset_top = top
	label.offset_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.63))
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.05, 0.05, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.visible = false
	add_child(label)
	return label


func _make_status_banner() -> Label:
	var label := Label.new()
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.offset_left = -510
	label.offset_right = -20
	label.offset_top = 20
	label.offset_bottom = 46
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.83, 0.88, 0.83))
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.05, 0.05, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func _show_notice(message: String, duration: float = 4.0) -> void:
	expedition_notice.text = message
	notice_timer = maxf(duration, 0.1)
	expedition_notice.visible = true


func _on_story_clue_discovered(_clue_id: StringName, title: String, text: String) -> void:
	_show_notice("%s\n%s" % [title, text], 7.0)


func _on_shard_secured(shard_id: StringName, count: int) -> void:
	_show_notice("Prism Shard secured · %d/3" % count, 4.0)


func _on_expedition_time_warning(seconds_remaining: float) -> void:
	_show_notice("Dusk is near. Reach the marked extraction point (%d seconds)." % ceili(seconds_remaining), 5.0)


func _on_expedition_finished(_expedition_id: StringName, objective_complete: bool, reason: String) -> void:
	if objective_complete:
		_show_notice("Expedition complete. Your shard and resources are safe. %s" % reason, 5.0)
	else:
		_show_notice("Returned safely. The shard is still waiting; optional loot was not required. %s" % reason, 5.0)


func _on_light_suppression_changed(is_suppressed: bool) -> void:
	if is_suppressed:
		_show_notice("A Light Leech is suppressing the Lighthouse beam. Focus your light on it.", 4.5)
	else:
		_show_notice("Lighthouse illumination restored.", 3.0)


func _on_darkness_pulse_started(duration: float) -> void:
	_show_notice("The Bell-Taker's darkness pulse disrupts Focus for %.1f seconds." % duration, 3.0)
