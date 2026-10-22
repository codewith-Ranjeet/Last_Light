extends CharacterBody2D

signal interaction_prompt_changed(prompt: String)

@export var speed: float = 100.0
@export var interaction_range: float = 70.0

@onready var sprite = $Sprite2D

const KEEPER_DOWN = preload("res://Assets/Sprites/Player/keeper_down.png")
const KEEPER_UP = preload("res://Assets/Sprites/Player/keeper_up.png")
const KEEPER_LEFT = preload("res://Assets/Sprites/Player/keeper_left.png")
const KEEPER_RIGHT = preload("res://Assets/Sprites/Player/keeper_right.png")

const FLAME_SCENE = preload("res://Scenes/Projectiles/FlameSpirit.tscn")

var interaction_prompt: String = ""
var nearest_interactable: Node
var interaction_scan_timer: float = 0.0

func _physics_process(_delta: float) -> void:

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
		nearest_interactable.interact()
		_update_interaction_prompt()


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

	var flame = FLAME_SCENE.instantiate()

	get_parent().add_child(flame)

	var shoot_direction = (
		get_global_mouse_position() - global_position
	).normalized()

	flame.global_position = global_position + shoot_direction * 20
	flame.direction = shoot_direction


func _update_interaction_prompt() -> void:
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
