extends CharacterBody2D

signal interaction_prompt_changed(prompt: String)

@export var speed: float = 100.0
@export var interaction_range: float = 70.0
@export var max_health: int = 100
@export var invulnerability_duration: float = 0.9
@export var fire_interval: float = 0.36

@onready var sprite = $Sprite2D

const KEEPER_DOWN = preload("res://Assets/Sprites/Player/keeper_down.png")
const KEEPER_UP = preload("res://Assets/Sprites/Player/keeper_up.png")
const KEEPER_LEFT = preload("res://Assets/Sprites/Player/keeper_left.png")
const KEEPER_RIGHT = preload("res://Assets/Sprites/Player/keeper_right.png")

const FLAME_SCENE = preload("res://Scenes/Projectiles/FlameSpirit.tscn")

var interaction_prompt: String = ""
var nearest_interactable: Node
var interaction_scan_timer: float = 0.0
var health: int = 100
var invulnerability_timer: float = 0.0
var fire_cooldown_timer: float = 0.0
var campaign_manager: Node


func _ready() -> void:
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	if campaign_manager != null and campaign_manager.has_method("register_player"):
		campaign_manager.register_player(self)

func _physics_process(_delta: float) -> void:
	if campaign_manager != null and (campaign_manager.current_state == campaign_manager.Phase.UPGRADE or campaign_manager.current_state == campaign_manager.Phase.LENS_SELECTION):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_tick_damage_state(_delta)
	fire_cooldown_timer = maxf(fire_cooldown_timer - _delta, 0.0)

	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()

	update_facing_direction()

	if Input.is_action_just_pressed("shoot"):
		shoot()

	interaction_scan_timer -= _delta
	if interaction_scan_timer <= 0.0 or Input.is_action_just_pressed("interact"):
		interaction_scan_timer = 0.12
		_update_interaction_prompt()
	if Input.is_action_just_pressed("interact") and is_instance_valid(nearest_interactable):
		call_deferred("_interact_with", nearest_interactable)


func _interact_with(target: Node) -> void:
	if is_instance_valid(target) and target.has_method("interact"):
		target.interact()
	_update_interaction_prompt()


func take_damage(amount: int) -> bool:
	if amount <= 0 or health <= 0 or invulnerability_timer > 0.0:
		return false
	health = maxi(health - amount, 0)
	invulnerability_timer = maxf(invulnerability_duration, 0.0)
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager != null and manager.has_method("record_player_health"):
		manager.record_player_health(health)
	CombatFeedback.burst(get_parent(), global_position, Color(1.0, 0.3, 0.32), 20.0)
	if health > 0:
		var flash := create_tween()
		flash.tween_property(self, "modulate", Color(1.0, 0.38, 0.38), 0.06)
		flash.tween_property(self, "modulate", Color.WHITE, 0.2)
	return true


func _tick_damage_state(delta: float) -> void:
	if invulnerability_timer <= 0.0:
		modulate = Color.WHITE
		return
	invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)
	if invulnerability_timer > 0.0:
		var flash := int(Time.get_ticks_msec() / 100) % 2 == 0
		modulate = Color(1.0, 0.48, 0.48) if flash else Color.WHITE


func update_facing_direction() -> void:

	var mouse_direction = get_global_mouse_position() - global_position

	if abs(mouse_direction.x) > abs(mouse_direction.y):
		if mouse_direction.x > 0:
			sprite.texture = KEEPER_RIGHT
		else:
			sprite.texture = KEEPER_LEFT
	else:
		if mouse_direction.y > 0:
			sprite.texture = KEEPER_DOWN
		else:
			sprite.texture = KEEPER_UP


func shoot() -> void:
	if fire_cooldown_timer > 0.0:
		return

	var flame = FLAME_SCENE.instantiate()
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	if manager != null:
		flame.damage = roundi(float(flame.damage) * manager.get_projectile_damage_multiplier())
		fire_cooldown_timer = fire_interval * manager.get_fire_interval_multiplier()
	else:
		fire_cooldown_timer = fire_interval

	get_parent().add_child(flame)

	var shoot_direction = (
		get_global_mouse_position() - global_position
	).normalized()

	flame.global_position = global_position + shoot_direction * 20
	flame.direction = shoot_direction


func _update_interaction_prompt() -> void:
	# Interacting with an expedition board replaces the current world immediately.
	# The old player's deferred interaction then returns here after it has left the tree.
	if not is_inside_tree():
		return
	var closest: Node
	var closest_distance := interaction_range
	for candidate in get_tree().get_nodes_in_group("player_interactable"):
		if not is_instance_valid(candidate) or not candidate.has_method("interact") or not candidate.has_method("get_interaction_prompt"):
			continue
		if candidate.has_method("is_interaction_available") and not candidate.is_interaction_available():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= closest_distance:
			closest = candidate
			closest_distance = distance

	nearest_interactable = closest
	var next_prompt := ""
	if is_instance_valid(nearest_interactable):
		next_prompt = nearest_interactable.get_interaction_prompt()
	if interaction_prompt != next_prompt:
		interaction_prompt = next_prompt
		interaction_prompt_changed.emit(interaction_prompt)


func collect_beacon(amount: int):
	var campaign_manager := get_tree().get_first_node_in_group("campaign_manager")
	if campaign_manager != null:
		campaign_manager.add_beacons(amount)
