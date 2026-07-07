extends CanvasLayer

@onready var hp_background = $MarginContainer/VBoxContainer/HPContainer/HPBackground
@onready var fill_mask = $MarginContainer/VBoxContainer/HPContainer/FillMask
@onready var hp_fill = $MarginContainer/VBoxContainer/HPContainer/FillMask/HPFill
@onready var beacon_label = $MarginContainer/VBoxContainer/BeaconContainer/BeaconCount
@onready var phase_label = $MarginContainer/VBoxContainer/Phase

@onready var lighthouse = $"../LightHouse"
@onready var player = $"../Player"
@onready var game_manager = $"../GameManager"

@onready var full_fill_width = fill_mask.size.x
@onready var fill_start_x = fill_mask.position.x

func _process(_delta):

	update_hp()
	beacon_label.text = "Beacons: %d" % player.beacons
	phase_label.text = game_manager.current_phase

#----------------Hp update-----------------
func update_hp():
	var percent = lighthouse.health / float(lighthouse.max_health)

	fill_mask.position.x = fill_start_x
	fill_mask.size.x = full_fill_width * percent
