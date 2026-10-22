extends CharacterBody2D
class_name ShadowEnemy

signal defeated(enemy_kind: StringName, world_position: Vector2)

@export var enemy_kind: StringName = &"shadow_enemy"
@export var max_health: int = 20
@export var beacon_scene: PackedScene
@export var drops_beacon: bool = true

var health: int = 20
var is_dead: bool = false
var slow_timer: float = 0.0
var movement_slow_factor: float = 1.0
var snare_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	health = maxi(max_health, 1)


func _tick_status_effects(delta: float) -> bool:
	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer == 0.0:
			movement_slow_factor = 1.0

	if snare_timer > 0.0:
		snare_timer = maxf(snare_timer - delta, 0.0)
		if snare_timer > 0.0:
			velocity = Vector2.ZERO
			modulate = Color(0.43, 0.92, 0.83)
			move_and_slide()
			return true

	if slow_timer <= 0.0:
		modulate = Color.WHITE
	return false


func damage_to_enemy(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	var scaled_amount := maxi(roundi(float(amount) * maxf(_get_damage_taken_multiplier(), 0.05)), 1)
	health = maxi(health - scaled_amount, 0)
	CombatFeedback.burst(get_parent(), global_position, Color(1.0, 0.5, 0.3), 14.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color(1.0, 0.45, 0.38), 0.04)
	flash.tween_property(self, "modulate", Color.WHITE, 0.14)
	if health == 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	if has_method("stop_attacking"):
		call("stop_attacking")
	remove_from_group("enemy")
	defeated.emit(enemy_kind, global_position)
	on_enemy_dying()
	if drops_beacon and beacon_scene != null and is_instance_valid(get_parent()):
		var reward_parent := get_parent()
		var beacon := beacon_scene.instantiate()
		beacon.position = reward_parent.to_local(global_position)
		reward_parent.call_deferred("add_child", beacon)
	queue_free()


func on_enemy_dying() -> void:
	pass


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


func _get_damage_taken_multiplier() -> float:
	return 1.0
