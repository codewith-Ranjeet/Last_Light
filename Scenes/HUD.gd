extends CanvasLayer

@onready var hp_bar = $MarginContainer/VBoxContainer/HPContainer/LightHouseHPBar
@onready var hp_text = $MarginContainer/VBoxContainer/HPContainer/HPText
@onready var beacon_label = $MarginContainer/VBoxContainer/BeaconCount
@onready var phase_label = $MarginContainer/VBoxContainer/Phase

@onready var lighthouse = $"../LightHouse"
@onready var player = $"../Player"
@onready var game_manager = $"../GameManager"


func _process(_delta):
	
	hp_bar.max_value = lighthouse.max_health
	hp_bar.value = lighthouse.health
	
	hp_text.text = "%d / %d" % [
	lighthouse.health,
	lighthouse.max_health
	]

	beacon_label.text = "🟠 Beacons: %d" % player.beacons

	phase_label.text = game_manager.current_phase
