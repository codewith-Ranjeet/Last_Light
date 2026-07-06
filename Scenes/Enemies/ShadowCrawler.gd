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
var retreating: bool = false
var retreat_direction: Vector2 = Vector2.ZERO


func _ready():
	target = get_parent().get_node_or_null("LightHouse")
	health = max_health


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

			if tower:
				tower.damage(damage)

		return

	if target == null:
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


#------------------ ATTACK ------------------

func start_attacking(target):
	attacking = true
	tower = target
	attack_timer = 0.0


func stop_attacking():
	attacking = false
	tower = null


#------------------ DAMAGE ------------------

func damage_to_enemy(amount):
	health -= amount

	if health <= 0:
		die()


func die():
	if beacon_scene:
		var beacon = beacon_scene.instantiate()
		get_parent().add_child(beacon)
		beacon.global_position = global_position

	queue_free()


#------------------ RETREAT ------------------

func retreat():
	if target == null:
		return

	retreat_direction = (global_position - target.global_position).normalized()
	retreating = true
	stop_attacking()


func reached_veil():
	return (
		abs(global_position.x) > VEIL_LIMIT
		or abs(global_position.y) > VEIL_LIMIT
	)
