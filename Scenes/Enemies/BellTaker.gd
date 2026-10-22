extends "res://Scenes/Enemies/ShadowEnemy.gd"

@export var pulse_interval: float = 3.1
@export var telegraph_duration: float = 1.25
@export var pulse_radius: float = 255.0
@export var pulse_damage: int = 22
@export var darkness_duration: float = 1.8
@export var focused_damage_interval: float = 0.24
@export var focused_damage: int = 3

enum AttackState { REST, TELEGRAPH, RECOVERY }

var attack_state: int = AttackState.REST
var state_timer: float = 1.4
var focus_damage_timer: float = 0.0
var pulse_hit_player: bool = false
var darkness_tween: Tween


func _ready() -> void:
	super._ready()
	enemy_kind = &"bell_taker"


func _process(delta: float) -> void:
	state_timer -= delta
	match attack_state:
		AttackState.REST:
			if state_timer <= 0.0:
				attack_state = AttackState.TELEGRAPH
				state_timer = telegraph_duration
				pulse_hit_player = false
		AttackState.TELEGRAPH:
			if state_timer <= 0.0:
				_perform_darkness_pulse()
				attack_state = AttackState.RECOVERY
				state_timer = 0.78
		AttackState.RECOVERY:
			if state_timer <= 0.0:
				attack_state = AttackState.REST
				state_timer = pulse_interval
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _tick_status_effects(delta):
		return
	velocity = Vector2.ZERO
	move_and_slide()


func apply_focused_light(delta: float = 0.08) -> void:
	super.apply_focused_light(delta)
	if is_dead:
		return
	focus_damage_timer += maxf(delta, 0.0)
	if focus_damage_timer >= focused_damage_interval:
		focus_damage_timer = 0.0
		damage_to_enemy(focused_damage)
	if attack_state == AttackState.TELEGRAPH:
		attack_state = AttackState.RECOVERY
		state_timer = 0.7
		CombatFeedback.burst(get_parent(), global_position, Color(0.71, 0.85, 1.0), 27.0)
	queue_redraw()


func _perform_darkness_pulse() -> void:
	var world := get_parent()
	if world == null:
		return
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager != null:
		manager.trigger_darkness_pulse(darkness_duration)
	var darkness := world.get_node_or_null("BellTakerDarkness") as CanvasModulate
	if darkness == null:
		darkness = CanvasModulate.new()
		darkness.name = "BellTakerDarkness"
		world.add_child(darkness)
	if darkness_tween != null and darkness_tween.is_running():
		darkness_tween.kill()
	darkness.color = Color(0.34, 0.37, 0.49, 1.0)
	darkness_tween = darkness.create_tween()
	darkness_tween.tween_property(darkness, "color", Color.WHITE, darkness_duration)
	CombatFeedback.burst(world, global_position, Color(0.42, 0.37, 0.66), pulse_radius)
	var player := get_tree().get_first_node_in_group("player")
	if not pulse_hit_player and player != null and global_position.distance_to(player.global_position) <= pulse_radius and player.has_method("take_damage"):
		pulse_hit_player = true
		player.take_damage(pulse_damage)


func _draw() -> void:
	var telegraphing := attack_state == AttackState.TELEGRAPH
	var tint := Color(0.38, 0.34, 0.48) if not telegraphing else Color(0.72, 0.38, 0.68)
	draw_circle(Vector2.ZERO, 23.0, Color(0.13, 0.12, 0.18, 0.95))
	draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 32, tint, 3.0, true)
	draw_line(Vector2(-9, -9), Vector2(-9, 8), Color(0.78, 0.68, 0.48), 3.0, true)
	draw_line(Vector2(0, -14), Vector2(0, 12), Color(0.9, 0.78, 0.53), 3.0, true)
	draw_line(Vector2(9, -9), Vector2(9, 8), Color(0.78, 0.68, 0.48), 3.0, true)
	if telegraphing:
		var progress := 1.0 - clampf(state_timer / maxf(telegraph_duration, 0.01), 0.0, 1.0)
		var warning_radius := lerpf(32.0, pulse_radius, progress)
		draw_arc(Vector2.ZERO, warning_radius, 0.0, TAU, 48, Color(0.89, 0.42, 0.83, 0.76), 2.5, true)
