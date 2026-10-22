extends CharacterBody2D

@export var speed: float = 80.0
@export var damage: int = 10
@export var attack_interval: float = 1.0
@export var max_health: int = 20
@export var beacon_scene: PackedScene

const VEIL_LIMIT = 650

var target: Node2D
var attacking: bool = false
var tower = null
var attack_timer: float = 0.0
var health: int
var is_dead: bool = false
var retreating: bool = false
var retreat_direction: Vector2 = Vector2.ZERO


func _ready():
	target = get_parent().get_node_or_null("LightHouse")
	health = maxi(max_health, 1)


func _physics_process(delta):
	# Retreat
	if retreating:
		velocity = retreat_direction * speed
		move_and_slide()

		if reached_veil():
			queue_free()

		return

	# Stop movement while attacking
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()

		attack_timer += delta

		if attack_timer >= attack_interval:
			attack_timer = 0.0

			if is_instance_valid(tower):
				tower.damage(damage)
			else:
				stop_attacking()

		return

	if not is_instance_valid(target):
		queue_free()
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


#------------------ ATTACK ------------------

func start_attacking(target):
	if is_dead or retreating or not is_instance_valid(target):
		return
	attacking = true
	tower = target
	attack_timer = 0.0


func stop_attacking():
	attacking = false
	tower = null


#------------------ DAMAGE ------------------

func damage_to_enemy(amount):
	if is_dead or amount <= 0:
		return

	health = maxi(health - amount, 0)

	if health <= 0:
		die()


func die():
	if is_dead:
		return
	is_dead = true
	stop_attacking()
	velocity = Vector2.ZERO
	remove_from_group("enemy")

	if beacon_scene:
		var beacon = beacon_scene.instantiate()
		get_parent().add_child(beacon)
		beacon.global_position = global_position

	queue_free()


#------------------ RETREAT ------------------

func retreat():
	if is_dead or retreating:
		return
	if not is_instance_valid(target):
		queue_free()
		return

	retreat_direction = (global_position - target.global_position).normalized()
	if retreat_direction.is_zero_approx():
		retreat_direction = Vector2.RIGHT
	retreating = true
	stop_attacking()


func reached_veil():
	return (
		abs(global_position.x) > VEIL_LIMIT
		or abs(global_position.y) > VEIL_LIMIT
	)
