extends "res://Scenes/Enemies/ShadowEnemy.gd"

@export var speed: float = 42.0
@export var structure_damage: int = 28
@export var attack_interval: float = 1.35
@export var armored_damage_multiplier: float = 0.25
@export var focus_exposure_duration: float = 0.42

var target: Node2D
var tower: Node
var attacking: bool = false
var attack_timer: float = 0.0
var exposure_timer: float = 0.0
var retreating: bool = false
var retreat_direction: Vector2 = Vector2.UP


func _ready() -> void:
	super._ready()
	enemy_kind = &"ashen_brute"
	target = get_parent().get_node_or_null("LightHouse") as Node2D


func _physics_process(delta: float) -> void:
	if exposure_timer > 0.0:
		exposure_timer = maxf(exposure_timer - delta, 0.0)
	if _tick_status_effects(delta):
		return
	if retreating:
		velocity = retreat_direction * speed * movement_slow_factor
		move_and_slide()
		if absf(global_position.x) > 700.0 or absf(global_position.y) > 700.0:
			queue_free()
		return
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		attack_timer += delta
		if attack_timer >= maxf(attack_interval, 0.05):
			attack_timer = 0.0
			if is_instance_valid(tower):
				if tower.has_method("damage_structure"):
					tower.damage_structure(structure_damage)
				elif tower.has_method("damage"):
					tower.damage(structure_damage)
			else:
				stop_attacking()
		return
	if not is_instance_valid(target):
		queue_free()
		return
	velocity = (target.global_position - global_position).normalized() * speed * movement_slow_factor
	move_and_slide()
	for index in range(get_slide_collision_count()):
		var collider := get_slide_collision(index).get_collider() as Node
		if is_instance_valid(collider) and collider.is_in_group("defense_structure") and collider.has_method("damage_structure"):
			start_attacking(collider)
			break


func apply_focused_light(delta: float = 0.0) -> void:
	super.apply_focused_light(delta)
	exposure_timer = maxf(exposure_timer, focus_exposure_duration)
	queue_redraw()


func _get_damage_taken_multiplier() -> float:
	return 1.0 if exposure_timer > 0.0 else clampf(armored_damage_multiplier, 0.05, 1.0)


func start_attacking(structure: Node) -> void:
	if is_dead or retreating or not is_instance_valid(structure):
		return
	attacking = true
	tower = structure
	attack_timer = 0.0


func stop_attacking() -> void:
	attacking = false
	tower = null


func retreat() -> void:
	if is_dead or retreating:
		return
	var lighthouse := get_parent().get_node_or_null("LightHouse")
	retreat_direction = (global_position - lighthouse.global_position).normalized() if lighthouse != null else Vector2.UP
	if retreat_direction.is_zero_approx():
		retreat_direction = Vector2.UP
	retreating = true
	stop_attacking()


func _draw() -> void:
	var exposed := exposure_timer > 0.0
	var body_color := Color(0.57, 0.31, 0.19) if exposed else Color(0.27, 0.22, 0.19)
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -16), Vector2(-8, -24), Vector2(13, -19), Vector2(21, -4), Vector2(18, 17), Vector2(2, 24), Vector2(-17, 16), Vector2(-23, -3)]), body_color)
	draw_polyline(PackedVector2Array([Vector2(-19, -16), Vector2(-8, -24), Vector2(13, -19), Vector2(21, -4), Vector2(18, 17), Vector2(2, 24), Vector2(-17, 16), Vector2(-23, -3), Vector2(-19, -16)]), Color(0.75, 0.53, 0.36, 0.92), 2.0, true)
	for x in [-11.0, 0.0, 11.0]:
		draw_line(Vector2(x, -13), Vector2(x + 3, 13), Color(0.17, 0.14, 0.13, 0.9), 3.0, true)
	if exposed:
		draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 32, Color(1.0, 0.73, 0.39, 0.9), 2.0, true)
