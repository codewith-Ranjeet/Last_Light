extends "res://Scenes/Enemies/ShadowEnemy.gd"

@export var speed: float = 80.0
@export var damage: int = 10
@export var attack_interval: float = 1.0
const VEIL_LIMIT = 650

var target: Node2D
var attacking: bool = false
var tower = null
var attack_timer: float = 0.0
var retreating: bool = false
var retreat_direction: Vector2 = Vector2.ZERO


func _ready():
	super._ready()
	target = get_parent().get_node_or_null("LightHouse")


func _physics_process(delta):
	if _tick_status_effects(delta):
		return

	# Retreat
	if retreating:
		velocity = retreat_direction * speed * movement_slow_factor
		move_and_slide()

		if reached_veil():
			queue_free()

		return

	# Stop movement while attacking
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()

		attack_timer += delta

		if attack_timer >= maxf(attack_interval, 0.05):
			attack_timer = 0.0

			if is_instance_valid(tower):
				if tower.has_method("damage_structure"):
					tower.damage_structure(damage)
				elif tower.has_method("damage"):
					tower.damage(damage)
			else:
				stop_attacking()

		return

	if not is_instance_valid(target):
		queue_free()
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed * movement_slow_factor
	move_and_slide()
	_attack_contacted_structure()


func _attack_contacted_structure() -> void:
	if attacking:
		return
	for index in range(get_slide_collision_count()):
		var collider := get_slide_collision(index).get_collider() as Node
		if is_instance_valid(collider) and collider.is_in_group("defense_structure") and collider.has_method("damage_structure"):
			start_attacking(collider)
			return


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
