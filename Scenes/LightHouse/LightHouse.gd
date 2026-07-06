extends StaticBody2D

@export var max_health: int = 100
const REPAIR_AMOUNT: int = 5

@onready var player = $"../Player"
@onready var game_manager = $"../GameManager"

var health: int
var destroyed: bool = false
var player_near: bool = false
var can_repair: bool = false


func _ready():
	health = max_health


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

	print("Tower HP:", health)
