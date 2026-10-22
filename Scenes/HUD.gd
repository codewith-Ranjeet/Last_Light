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


func _process(_delta):
	if game_manager == null:
		return
	update_hp()
	beacon_label.text = "Beacons: %d" % game_manager.beacon_count
	salvage_label.text = "Salvage: %d" % game_manager.salvage
	phase_label.text = game_manager.current_phase
	focus_meter.max_value = game_manager.focus_max
	focus_meter.value = game_manager.focus_energy
	focus_label.text = "Focus: %d%%" % roundi(game_manager.focus_energy / maxf(game_manager.focus_max, 1.0) * 100.0)
	var player: Node = game_manager.get_current_player()
	interaction_hint.text = player.interaction_prompt if player != null else ""

#----------------Hp update-----------------
func update_hp():
	var lighthouse = game_manager.get_current_lighthouse()
	if lighthouse == null:
		return
	var percent = clampf(lighthouse.health / float(maxi(lighthouse.max_health, 1)), 0.0, 1.0)

	fill_mask.position.x = fill_start_x
	fill_mask.size.x = full_fill_width * percent
