extends StaticBody2D

signal health_changed(current_health: int, maximum_health: int)

@export var max_health: int = 100
@export var repair_amount: int = 5

@onready var sprite: Sprite2D = $Sprite2D
@onready var game_manager: Node = get_tree().get_first_node_in_group("campaign_manager")

var health: int = 100
var destroyed: bool = false
var can_repair: bool = false
var current_stage: int = -1

const DAMAGE_STAGES = [
	preload("res://Assets/Sprites/LightHouse/LH100.png"),
	preload("res://Assets/Sprites/LightHouse/LH75.png"),
	preload("res://Assets/Sprites/LightHouse/LH25.png"),
	preload("res://Assets/Sprites/LightHouse/LH0.png"),
	preload("res://Assets/Sprites/LightHouse/LHDestroyed.png")
]


func _ready() -> void:
	max_health = maxi(max_health, 1)
	add_to_group("player_interactable")
	if game_manager != null:
		game_manager.register_lighthouse(self)
	else:
		health = max_health
	update_damage_stage()


func damage(amount: int) -> void:
	if destroyed or amount <= 0:
		return
	if game_manager != null and game_manager.has_method("get_lighthouse_damage_multiplier"):
		amount = maxi(roundi(float(amount) * game_manager.get_lighthouse_damage_multiplier()), 1)

	health = maxi(health - amount, 0)
	if game_manager != null:
		game_manager.record_lighthouse_health(health)
	CombatFeedback.burst(get_parent(), global_position + Vector2(0, -36), Color(1.0, 0.42, 0.32), 22.0)
	update_damage_stage()
	health_changed.emit(health, max_health)

	if health == 0:
		destroyed = true
		if game_manager != null:
			game_manager.game_over()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("start_attacking"):
		body.start_attacking(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("stop_attacking"):
		body.stop_attacking()


func repair(amount: int) -> bool:
	if destroyed or not can_repair or amount <= 0 or health >= max_health:
		return false
	if game_manager == null or not game_manager.spend_beacons(1):
		return false

	health = mini(health + amount, max_health)
	game_manager.record_lighthouse_health(health)
	update_damage_stage()
	health_changed.emit(health, max_health)
	CombatFeedback.burst(get_parent(), global_position + Vector2(0, -40), Color(0.52, 1.0, 0.66), 18.0)
	return true


func get_interaction_prompt() -> String:
	if destroyed:
		return "Lighthouse destroyed"
	if not can_repair:
		return "Repair available during Day"
	if health >= max_health:
		return "Lighthouse stable"
	if game_manager == null or game_manager.beacon_count < 1:
		return "Need 1 Beacon to repair"
	var effective_repair: int = game_manager.get_repair_amount(repair_amount) if game_manager != null and game_manager.has_method("get_repair_amount") else repair_amount
	return "E Repair Lighthouse +%d HP · 1 Beacon" % effective_repair


func interact() -> bool:
	var effective_repair: int = game_manager.get_repair_amount(repair_amount) if game_manager != null and game_manager.has_method("get_repair_amount") else repair_amount
	return repair(effective_repair)


func update_damage_stage() -> void:
	var percent := health / float(max_health)
	var stage := 0

	if percent <= 0.0:
		stage = 4
	elif percent <= 0.25:
		stage = 3
	elif percent <= 0.50:
		stage = 2
	elif percent <= 0.75:
		stage = 1

	if stage != current_stage:
		current_stage = stage
		sprite.texture = DAMAGE_STAGES[stage]
