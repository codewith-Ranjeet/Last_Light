extends CharacterBody2D

@export var speed: float = 100.0

@onready var sprite = $Sprite2D

const KEEPER_DOWN = preload("res://Assets/Sprites/Player/keeper_down.png")
const KEEPER_UP = preload("res://Assets/Sprites/Player/keeper_up.png")
const KEEPER_LEFT = preload("res://Assets/Sprites/Player/keeper_left.png")
const KEEPER_RIGHT = preload("res://Assets/Sprites/Player/keeper_right.png")

const FLAME_SCENE = preload("res://Scenes/Projectiles/FlameSpirit.tscn")

var beacons: int = 0


func _physics_process(_delta):

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


func update_facing_direction():

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


func shoot():

	var flame = FLAME_SCENE.instantiate()

	get_parent().add_child(flame)

	var shoot_direction = (
		get_global_mouse_position() - global_position
	).normalized()

	flame.global_position = global_position + shoot_direction * 20
	flame.direction = shoot_direction


func collect_beacon(amount: int):
	beacons += amount
	print("Beacons:", beacons)
