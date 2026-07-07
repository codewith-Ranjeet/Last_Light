extends StaticBody2D

@export var max_health: int = 100
const REPAIR_AMOUNT: int = 5

@onready var player = $"../Player"
@onready var game_manager = $"../GameManager"
@onready var sprite = $Sprite2D

var health: int
var destroyed: bool = false
var player_near: bool = false
var can_repair: bool = false
var current_stage := -1
const DAMAGE_STAGES = [
	preload("res://Assets/Sprites/LightHouse/LH100.png"),
	preload("res://Assets/Sprites/LightHouse/LH75.png"),
	preload("res://Assets/Sprites/LightHouse/LH25.png"),
	preload("res://Assets/Sprites/LightHouse/LH0.png"),
	preload("res://Assets/Sprites/LightHouse/LHDestroyed.png")
]

#---------------Ready state----------------
func _ready():
	health = max_health
	update_damage_stage()

func _physics_process(_delta):
	if !can_repair:
		return

	if player_near and Input.is_action_just_pressed("repair"):
		repair(REPAIR_AMOUNT)


#---------------- DAMAGE ----------------

func damage(amount: int):
	if destroyed:
		return

	health -= amount
	health = max(health, 0)

	print("Tower HP:", health)
	
	update_damage_stage()
	
	if health == 0:
		destroyed = true
		game_manager.game_over()


#---------------- ENEMY ATTACK ----------------

func _on_area_2d_body_entered(body):
	if body.is_in_group("enemy"):
		body.start_attacking(self)


func _on_area_2d_body_exited(body):
	if body.is_in_group("enemy"):
		body.stop_attacking()


#---------------- REPAIR AREA ----------------

func _on_repair_area_body_entered(body):
	if body.is_in_group("player"):
		player_near = true


func _on_repair_area_body_exited(body):
	if body.is_in_group("player"):
		player_near = false


#---------------- REPAIR ----------------

func repair(amount: int):
	if destroyed:
		return

	if health >= max_health:
		print("Health Full")
		return

	if player.beacons <= 0:
		print("Need more Beacon")
		return

	player.beacons -= 1
	health = min(health + amount, max_health)
	
	update_damage_stage()
	print("Tower HP:", health)

#-------------HPStage-------------
func update_damage_stage():

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
