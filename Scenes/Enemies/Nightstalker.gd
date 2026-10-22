extends "res://Scenes/Enemies/ShadowEnemy.gd"

@export var speed: float = 122.0
@export var attack_damage: int = 20
@export var attack_range: float = 52.0
@export var windup_duration: float = 0.62
@export var attack_recovery: float = 1.25

enum AttackState { HUNT, WINDUP, RECOVERY, RETREAT }

var target_player: Node2D
var attack_state: int = AttackState.HUNT
var state_timer: float = 0.0
var windup_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	super._ready()
	enemy_kind = &"nightstalker"
	target_player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	if _tick_status_effects(delta):
		return
	if attack_state == AttackState.RETREAT:
		velocity = windup_direction * speed * movement_slow_factor
		move_and_slide()
		if absf(global_position.x) > 700.0 or absf(global_position.y) > 700.0:
			queue_free()
		return
	if not is_instance_valid(target_player):
		queue_free()
		return

	var to_player := target_player.global_position - global_position
	var distance := to_player.length()
	if attack_state == AttackState.WINDUP:
		state_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if state_timer <= 0.0:
			if distance <= attack_range + 12.0 and target_player.has_method("take_damage"):
				target_player.take_damage(attack_damage)
				CombatFeedback.burst(get_parent(), target_player.global_position, Color(0.82, 0.28, 0.33), 24.0)
			attack_state = AttackState.RECOVERY
			state_timer = attack_recovery
			queue_redraw()
		return
	if attack_state == AttackState.RECOVERY:
		state_timer -= delta
		if state_timer <= 0.0:
			attack_state = AttackState.HUNT
		queue_redraw()
		return

	if distance <= attack_range and state_timer <= 0.0:
		windup_direction = to_player.normalized()
		attack_state = AttackState.WINDUP
		state_timer = windup_duration
		queue_redraw()
		return
	state_timer = maxf(state_timer - delta, 0.0)
	velocity = to_player.normalized() * speed * movement_slow_factor
	move_and_slide()


func retreat() -> void:
	if is_dead or attack_state == AttackState.RETREAT:
		return
	attack_state = AttackState.RETREAT
	var lighthouse := get_parent().get_node_or_null("LightHouse")
	windup_direction = (global_position - lighthouse.global_position).normalized() if lighthouse != null else Vector2.UP
	if windup_direction.is_zero_approx():
		windup_direction = Vector2.UP


func _draw() -> void:
	var stalking := attack_state == AttackState.WINDUP
	var body_color := Color(0.18, 0.13, 0.21) if not stalking else Color(0.5, 0.16, 0.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -9), Vector2(-5, -16), Vector2(8, -12), Vector2(15, 0), Vector2(7, 12), Vector2(-8, 13), Vector2(-15, 3)]), body_color)
	draw_polyline(PackedVector2Array([Vector2(-13, -9), Vector2(-5, -16), Vector2(8, -12), Vector2(15, 0), Vector2(7, 12), Vector2(-8, 13), Vector2(-15, 3), Vector2(-13, -9)]), Color(0.49, 0.4, 0.52, 0.95), 1.5, true)
	draw_circle(Vector2(5, -3), 2.5, Color(1.0, 0.42, 0.26))
	draw_circle(Vector2(5, 4), 2.0, Color(1.0, 0.72, 0.35))
	if stalking:
		draw_arc(Vector2.ZERO, attack_range, -PI * 0.65, PI * 0.65, 28, Color(1.0, 0.28, 0.3, 0.82), 2.0, true)
