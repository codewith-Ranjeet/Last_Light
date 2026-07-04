extends CharacterBody2D

@export var speed = 80.0
@export var damage = 10
@export var attack_interval = 1.0
@export var max_health = 20

var target
var attacking = false
var tower = null
var attack_timer = 0.0
var health = max_health
var retreating = false
var retreat_direction = Vector2.ZERO

func _ready():
	target = get_parent().get_node("LightHouse")

func _physics_process(delta):
	#retreat
	if retreating:
		velocity = retreat_direction * speed
		move_and_slide()
		if !get_viewport_rect().has_point(global_position):
			queue_free()
		return
	
	#stop movement while attacking
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		#damage and interval
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			if tower:
				tower.damage(damage)
		return
	
	if target == null:
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


#------------------ATTACKING-----------------
func start_attacking(target):
	attacking = true
	tower = target
	attack_timer = 0.0
	#print("attack start")
	
func stop_attacking():
	attacking = false
	tower = null
	#print("attack stop")

#---------------Damage---------------
func damage_to_enemy(amount):
	health -= amount
	if(health <= 0):
		die()
		
func die():
	queue_free()

#----------------Retreat-------------
func retreat():
	retreat_direction = (global_position - target.global_position).normalized()
	retreating = true
	attacking = false
