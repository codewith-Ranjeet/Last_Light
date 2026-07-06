extends StaticBody2D

@export var max_health = 100
@onready var player = get_parent().get_node("Player")

var health = max_health
var destroyed = false
var player_near = false
var repair_timer = 0.0
var can_repair = false
const REPAIR_AMOUNT = 5

func _physics_process(delta):
#------------Repair---------------
	if !can_repair:
		return
	if player_near and Input.is_action_just_pressed("repair"):
		repair(REPAIR_AMOUNT)

#-------------Damage & Attack------------
func damage(amount):
	if destroyed:
		return
	health -= amount
	print("Tower HP:", health)
	if(health <= 0):
		destroyed = true
		print("GAME OVER")
		get_tree().paused = true
		return

func _on_area_2d_body_entered(body):
	#attack
	if body.is_in_group("enemy"):
		body.start_attacking(self)

func _on_area_2d_body_exited(body):
	if body.is_in_group("enemy"):
		body.stop_attacking()

#----------------REPAIR---------------------
func _on_repair_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_near = true

func _on_repair_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false

func repair(amount):
	if destroyed:
		return
	if health >= max_health:
		print("Health Full")
		return
	if player.beacons > 0:
		player.beacons -= 1
		health = min(health + amount, max_health)
		print("Tower HP:", health)
	else:
		print("Need more Beacon")
