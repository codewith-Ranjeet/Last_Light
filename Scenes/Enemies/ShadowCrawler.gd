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
var slow_timer: float = 0.0
var movement_slow_factor: float = 1.0
var snare_timer: float = 0.0


func _ready():
	target = get_parent().get_node_or_null("LightHouse")
	health = maxi(max_health, 1)


func _physics_process(delta):
	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer == 0.0:
			movement_slow_factor = 1.0
	if snare_timer > 0.0:
		snare_timer = maxf(snare_timer - delta, 0.0)
		velocity = Vector2.ZERO
		modulate = Color(0.43, 0.92, 0.83) if snare_timer > 0.0 else Color.WHITE
		move_and_slide()
		return
	if slow_timer <= 0.0:
		modulate = Color.WHITE

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


#------------------ DAMAGE ------------------

func damage_to_enemy(amount):
	if is_dead or amount <= 0:
		return

	health = maxi(health - amount, 0)
	CombatFeedback.burst(get_parent(), global_position, Color(1.0, 0.5, 0.3), 14.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color(1.0, 0.45, 0.38), 0.04)
	flash.tween_property(self, "modulate", Color.WHITE, 0.14)

	if health <= 0:
		die()


func die():
	if is_dead:
		return
	is_dead = true
	stop_attacking()
	velocity = Vector2.ZERO
	remove_from_group("enemy")

	if beacon_scene and is_instance_valid(get_parent()):
		var beacon = beacon_scene.instantiate()
		var reward_parent := get_parent()
		beacon.position = reward_parent.to_local(global_position)
		reward_parent.call_deferred("add_child", beacon)

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


func apply_focused_light(_delta: float = 0.0) -> void:
	_apply_light_slow(0.46, 0.24, Color(0.58, 0.83, 1.0))


func apply_lighthouse_light(_delta: float = 0.0) -> void:
	_apply_light_slow(0.82, 0.28, Color(0.9, 0.82, 0.58))


func apply_ward_light(duration: float = 0.45) -> void:
	_apply_light_slow(0.68, duration, Color(0.63, 0.83, 1.0))


func apply_snare(duration: float) -> void:
	if is_dead:
		return
	snare_timer = maxf(snare_timer, duration)
	modulate = Color(0.43, 0.92, 0.83)


func _apply_light_slow(multiplier: float, duration: float, tint: Color) -> void:
	if is_dead or duration <= 0.0:
		return
	movement_slow_factor = minf(movement_slow_factor, clampf(multiplier, 0.1, 1.0))
	slow_timer = maxf(slow_timer, duration)
	modulate = tint


func reached_veil():
	return (
		abs(global_position.x) > VEIL_LIMIT
		or abs(global_position.y) > VEIL_LIMIT
	)
