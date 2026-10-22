extends "res://Scenes/Enemies/ShadowEnemy.gd"

@export var speed: float = 54.0
@export var suppression_radius: float = 132.0
@export var focused_damage_interval: float = 0.24
@export var focused_damage: int = 2

var lighthouse: Node2D
var target_player: Node2D
var campaign_manager: Node
var is_suppressing: bool = false
var beam_damage_timer: float = 0.0
var retreating: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("light_sensitive")
	enemy_kind = &"light_leech"
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	lighthouse = get_parent().get_node_or_null("LightHouse") as Node2D
	target_player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	if _tick_status_effects(delta):
		return
	if retreating:
		velocity = Vector2.UP * speed * movement_slow_factor
		move_and_slide()
		if absf(global_position.x) > 700.0 or absf(global_position.y) > 700.0:
			queue_free()
		return
	if not is_instance_valid(lighthouse):
		lighthouse = get_parent().get_node_or_null("LightHouse") as Node2D
	if not is_instance_valid(lighthouse):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(target_player):
			queue_free()
			return
		lighthouse = target_player

	var distance := global_position.distance_to(lighthouse.global_position)
	var hostile_darkness: bool = campaign_manager != null and campaign_manager.current_state == 2
	if campaign_manager != null and campaign_manager.current_state == 8 and campaign_manager.has_method("is_boss_blackout_active"):
		hostile_darkness = campaign_manager.is_boss_blackout_active()
	_set_suppression(hostile_darkness and distance <= suppression_radius)
	if distance > suppression_radius * 0.72:
		velocity = (lighthouse.global_position - global_position).normalized() * speed * movement_slow_factor
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()


func apply_focused_light(delta: float = 0.08) -> void:
	super.apply_focused_light(delta)
	if is_dead:
		return
	beam_damage_timer += maxf(delta, 0.0)
	if beam_damage_timer >= focused_damage_interval:
		beam_damage_timer = 0.0
		damage_to_enemy(focused_damage)
	queue_redraw()


func retreat() -> void:
	_set_suppression(false)
	retreating = true


func on_enemy_dying() -> void:
	_set_suppression(false)


func _exit_tree() -> void:
	_set_suppression(false)


func _set_suppression(active: bool) -> void:
	if is_suppressing == active:
		return
	is_suppressing = active
	if campaign_manager != null and campaign_manager.has_method("set_light_suppressor"):
		campaign_manager.set_light_suppressor(get_instance_id(), active)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color(0.19, 0.14, 0.28, 0.95))
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, Color(0.73, 0.55, 0.95), 2.0, true)
	draw_circle(Vector2(4, 0), 3.0, Color(0.92, 0.74, 1.0))
	if is_suppressing:
		var pulse := 0.78 + 0.18 * sin(Time.get_ticks_msec() * 0.008)
		draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 32, Color(0.75, 0.34, 0.92, pulse), 2.0, true)
		draw_line(Vector2(-19, 17), Vector2(19, 17), Color(0.8, 0.38, 0.96, pulse), 1.5, true)
