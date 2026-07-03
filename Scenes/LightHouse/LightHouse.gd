extends StaticBody2D

@export var max_health = 100

var health = max_health
var destroyed = false
var player_near = false
var repair_timer = 0.0
var can_repair = false
const REPAIR_INTERVAL = 0.2
const REPAIR_AMOUNT = 5

func _physics_process(delta):
	if !can_repair:
		return
	if player_near and Input.is_action_pressed("repair"):
		repair_timer += delta
		if repair_timer >= REPAIR_INTERVAL:
			repair(REPAIR_AMOUNT)
			repair_timer = 0.0
	else:
		repair_timer = 0.0

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
		print("press E to repair")

func _on_repair_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
		print("left Repair area")

func repair(amount):
	health = min(health + amount, max_health)
	print("Tower HP:", health)
