extends CanvasLayer

@onready var fill_mask: Control = $StatusPanel/StatusRows/HPContainer/FillMask
@onready var hp_fill: TextureRect = $StatusPanel/StatusRows/HPContainer/FillMask/HPFill
@onready var keeper_label: Label = $StatusPanel/StatusRows/KeeperLabel
@onready var focus_label: Label = $StatusPanel/StatusRows/FocusRow/FocusLabel
@onready var focus_meter: ProgressBar = $StatusPanel/StatusRows/FocusRow/FocusMeter
@onready var status_panel: PanelContainer = $StatusPanel
@onready var resource_panel: PanelContainer = $ResourcePanel
@onready var beacon_label: Label = $ResourcePanel/ResourceRows/BeaconRow/BeaconCount
@onready var salvage_label: Label = $ResourcePanel/ResourceRows/SalvageLabel
@onready var shard_label: Label = $ResourcePanel/ResourceRows/ShardLabel
@onready var objective_panel: PanelContainer = $ObjectivePanel
@onready var phase_label: Label = $ObjectivePanel/ObjectiveRows/PhaseLabel
@onready var objective_label: Label = $ObjectivePanel/ObjectiveRows/ObjectiveLabel
@onready var alert_label: Label = $ObjectivePanel/ObjectiveRows/AlertLabel
@onready var prompt_panel: PanelContainer = $PromptPanel
@onready var prompt_label: Label = $PromptPanel/PromptLabel

@onready var game_manager: Node = $"../GameManager"

@onready var full_fill_width: float = fill_mask.size.x
@onready var fill_start_x: float = fill_mask.position.x

const FONT_SMALL: int = 9
const FONT_BODY: int = 10
const FONT_NOTICE: int = 11
const COLOR_TEXT: Color = Color(0.9, 0.9, 0.83)
const COLOR_AMBER: Color = Color(0.97, 0.86, 0.62)
const COLOR_BLUE: Color = Color(0.72, 0.88, 1.0)
const COLOR_MUTED: Color = Color(0.78, 0.84, 0.82)

var expedition_notice: Label
var notice_timer: float = 0.0
var choice_overlay: Control
var choice_panel: PanelContainer
var choice_title: Label
var choice_subtitle: Label
var choice_buttons: VBoxContainer
var displayed_choice_phase: int = -1
var displayed_choice_ids: Array[StringName] = []
var ending_overlay: Control
var ending_title: Label
var ending_body: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_style_hud()
	expedition_notice = _make_bottom_banner(-104, -48, -300, 300)
	_create_choice_overlay()
	_create_ending_overlay()
	if game_manager != null:
		game_manager.story_clue_discovered.connect(_on_story_clue_discovered)
		game_manager.shard_secured.connect(_on_shard_secured)
		game_manager.expedition_time_warning.connect(_on_expedition_time_warning)
		game_manager.expedition_finished.connect(_on_expedition_finished)
		game_manager.light_suppression_changed.connect(_on_light_suppression_changed)
		game_manager.darkness_pulse_started.connect(_on_darkness_pulse_started)
		game_manager.night_event_changed.connect(_on_night_event_changed)


func _process(_delta: float) -> void:
	if game_manager == null:
		return
	if notice_timer > 0.0:
		notice_timer = maxf(notice_timer - _delta, 0.0)
		expedition_notice.visible = notice_timer > 0.0
	update_hp()
	keeper_label.text = "KEEPER %d/%d" % [game_manager.player_health, game_manager.player_max_health]
	beacon_label.text = "Beacons: %d" % game_manager.beacon_count
	salvage_label.text = "Salvage: %d" % game_manager.salvage
	shard_label.text = "Shards: %d/3" % game_manager.get_secured_shard_count()
	phase_label.text = _clean_phase(game_manager.current_phase)
	objective_label.text = game_manager.get_current_objective()
	focus_meter.max_value = game_manager.focus_max
	focus_meter.value = game_manager.focus_energy
	focus_label.text = "FOCUS %d%%" % roundi(game_manager.focus_energy / maxf(game_manager.focus_max, 1.0) * 100.0)
	_update_alert()
	var player: Node = game_manager.get_current_player()
	var prompt: String = player.interaction_prompt if player != null else ""
	prompt_label.text = prompt
	prompt_panel.visible = not prompt.is_empty()
	_refresh_choice_overlay()
	_refresh_ending_overlay()

#----------------Hp update-----------------
func update_hp():
	var lighthouse = game_manager.get_current_lighthouse()
	if lighthouse == null:
		return
	var percent = clampf(lighthouse.health / float(maxi(lighthouse.max_health, 1)), 0.0, 1.0)

	fill_mask.position.x = fill_start_x
	fill_mask.size.x = full_fill_width * percent


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
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", FONT_NOTICE)
	label.add_theme_color_override("font_color", COLOR_AMBER)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.05, 0.05, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.visible = false
	add_child(label)
	return label


func _style_hud() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.07, 0.1, 0.72)
	panel_style.border_color = Color(0.46, 0.58, 0.58, 0.55)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(3)
	panel_style.content_margin_left = 5
	panel_style.content_margin_right = 5
	panel_style.content_margin_top = 3
	panel_style.content_margin_bottom = 3
	for panel in [status_panel, resource_panel, objective_panel, prompt_panel]:
		panel.add_theme_stylebox_override("panel", panel_style)
		_ignore_mouse(panel)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = COLOR_BLUE
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	focus_meter.add_theme_stylebox_override("fill", fill_style)
	var meter_bg := StyleBoxFlat.new()
	meter_bg.bg_color = Color(0.08, 0.12, 0.17, 0.92)
	meter_bg.border_color = Color(0.45, 0.66, 0.76, 0.8)
	meter_bg.set_border_width_all(1)
	focus_meter.add_theme_stylebox_override("background", meter_bg)
	_style_label(keeper_label, FONT_SMALL, COLOR_MUTED)
	_style_label(focus_label, FONT_SMALL, COLOR_BLUE)
	_style_label(beacon_label, FONT_BODY, COLOR_AMBER)
	_style_label(salvage_label, FONT_BODY, COLOR_MUTED)
	_style_label(shard_label, FONT_BODY, COLOR_BLUE)
	_style_label(phase_label, FONT_SMALL, COLOR_AMBER)
	_style_label(objective_label, FONT_BODY, COLOR_TEXT)
	_style_label(alert_label, FONT_SMALL, COLOR_BLUE)
	_style_label(prompt_label, FONT_BODY, COLOR_AMBER)


func _style_label(target: Label, size: int, color: Color) -> void:
	target.add_theme_font_size_override("font_size", size)
	target.add_theme_color_override("font_color", color)
	target.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.9))
	target.add_theme_constant_override("shadow_offset_x", 1)
	target.add_theme_constant_override("shadow_offset_y", 1)


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


func _update_alert() -> void:
	var text := ""
	var color := COLOR_BLUE
	if game_manager.is_light_suppressed():
		text = "LIGHT SUPPRESSED"
		color = Color(0.74, 0.56, 0.96)
	if game_manager.focus_disrupted_timer > 0.0:
		text = "DARKNESS PULSE" if text.is_empty() else text + " · DARKNESS PULSE"
	alert_label.text = text
	alert_label.add_theme_color_override("font_color", color)
	alert_label.visible = not text.is_empty()


func _clean_phase(raw: String) -> String:
	var out := ""
	for i in raw.length():
		var cp := raw.unicode_at(i)
		if cp < 128 or cp == 183:
			out += raw[i]
	return out.strip_edges().to_upper()


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
	var source := "The Hollow Shepherd's blackout" if game_manager.current_state == game_manager.Phase.BOSS else "The Bell-Taker's darkness pulse"
	_show_notice("%s disrupts Focus for %.1f seconds." % [source, duration], 3.0)


func _create_choice_overlay() -> void:
	choice_overlay = Control.new()
	choice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_overlay.visible = false
	add_child(choice_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.035, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_overlay.add_child(shade)
	choice_panel = PanelContainer.new()
	choice_panel.anchor_left = 0.5
	choice_panel.anchor_right = 0.5
	choice_panel.anchor_top = 0.5
	choice_panel.anchor_bottom = 0.5
	choice_panel.offset_left = -226
	choice_panel.offset_right = 226
	choice_panel.offset_top = -169
	choice_panel.offset_bottom = 169
	choice_panel.add_theme_stylebox_override("panel", _choice_panel_style())
	choice_overlay.add_child(choice_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	choice_panel.add_child(content)
	choice_title = Label.new()
	choice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_title.add_theme_font_size_override("font_size", 21)
	choice_title.add_theme_color_override("font_color", Color(0.97, 0.86, 0.62))
	content.add_child(choice_title)
	choice_subtitle = Label.new()
	choice_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_subtitle.add_theme_font_size_override("font_size", 13)
	choice_subtitle.add_theme_color_override("font_color", Color(0.78, 0.84, 0.85))
	content.add_child(choice_subtitle)
	choice_buttons = VBoxContainer.new()
	choice_buttons.add_theme_constant_override("separation", 6)
	content.add_child(choice_buttons)


func _choice_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.08, 0.095, 0.98)
	style.border_color = Color(0.65, 0.74, 0.62, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style


func _refresh_choice_overlay() -> void:
	if game_manager == null or not is_instance_valid(choice_overlay):
		return
	var phase_id: int = game_manager.current_state
	if phase_id != game_manager.Phase.UPGRADE and phase_id != game_manager.Phase.LENS_SELECTION:
		choice_overlay.visible = false
		displayed_choice_phase = -1
		return
	var choices: Array[StringName] = game_manager.offered_upgrade_ids.duplicate() if phase_id == game_manager.Phase.UPGRADE else game_manager.LENS_IDS.duplicate()
	if displayed_choice_phase == phase_id and displayed_choice_ids == choices:
		choice_overlay.visible = true
		return
	displayed_choice_phase = phase_id
	displayed_choice_ids = choices.duplicate()
	choice_overlay.visible = true
	choice_title.text = "Memory Echo · Night %d" % game_manager.day_number if phase_id == game_manager.Phase.UPGRADE else "Tune the Dawn Lens"
	choice_subtitle.text = "Choose one lasting upgrade" if phase_id == game_manager.Phase.UPGRADE else "Install the three shards, then choose one tuning"
	for child in choice_buttons.get_children():
		choice_buttons.remove_child(child)
		child.queue_free()
	for choice_id in choices:
		var button := Button.new()
		button.text = game_manager.get_upgrade_title(choice_id) if phase_id == game_manager.Phase.UPGRADE else game_manager.get_lens_title(choice_id)
		button.custom_minimum_size = Vector2(410, 38)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.94, 0.93, 0.84))
		button.pressed.connect(_on_choice_pressed.bind(choice_id, phase_id))
		choice_buttons.add_child(button)
		var description := Label.new()
		description.text = game_manager.get_upgrade_description(choice_id) if phase_id == game_manager.Phase.UPGRADE else game_manager.get_lens_description(choice_id)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.add_theme_font_size_override("font_size", 12)
		description.add_theme_color_override("font_color", Color(0.7, 0.79, 0.81))
		choice_buttons.add_child(description)
	if choice_buttons.get_child_count() > 0 and choice_buttons.get_child(0) is Button:
		(choice_buttons.get_child(0) as Button).grab_focus()


func _on_choice_pressed(choice_id: StringName, phase_id: int) -> void:
	if phase_id == game_manager.Phase.UPGRADE:
		game_manager.select_upgrade(choice_id)
	else:
		game_manager.select_lens(choice_id)
	_refresh_choice_overlay()


func _on_night_event_changed(event_id: StringName, duration: float) -> void:
	if duration <= 0.0:
		return
	if event_id == &"eclipse_surge":
		_show_notice("Eclipse Surge · Lighthouse sweep range reduced for %.0f seconds." % duration, 4.0)
	elif event_id == &"red_moon":
		_show_notice("Red Moon · Two extra threats approach; defeated enemies carry two Beacons." , 4.0)


func _create_ending_overlay() -> void:
	ending_overlay = Control.new()
	ending_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	ending_overlay.visible = false
	ending_overlay.z_index = 100
	add_child(ending_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.015, 0.025, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -140
	panel.offset_bottom = 140
	panel.add_theme_stylebox_override("panel", _choice_panel_style())
	ending_overlay.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	ending_title = Label.new()
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_title.add_theme_font_size_override("font_size", 25)
	ending_title.add_theme_color_override("font_color", Color(0.97, 0.86, 0.62))
	content.add_child(ending_title)
	ending_body = Label.new()
	ending_body.custom_minimum_size = Vector2(450, 110)
	ending_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_body.add_theme_font_size_override("font_size", 15)
	ending_body.add_theme_color_override("font_color", Color(0.86, 0.89, 0.87))
	content.add_child(ending_body)
	var restart_button := Button.new()
	restart_button.text = "Restart Campaign"
	restart_button.custom_minimum_size = Vector2(180, 38)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.pressed.connect(_on_restart_campaign_pressed)
	content.add_child(restart_button)


func _refresh_ending_overlay() -> void:
	if game_manager == null or not is_instance_valid(ending_overlay):
		return
	var is_terminal: bool = game_manager.current_state == game_manager.Phase.VICTORY or game_manager.current_state == game_manager.Phase.GAME_OVER
	ending_overlay.visible = is_terminal
	if is_terminal:
		ending_title.text = game_manager.get_ending_title()
		ending_body.text = game_manager.get_ending_text()


func _on_restart_campaign_pressed() -> void:
	game_manager.begin_new_campaign()
	displayed_choice_phase = -1
	ending_overlay.visible = false
