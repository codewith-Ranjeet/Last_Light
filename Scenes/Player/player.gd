extends CharacterBody2D

@export var speed = 100.0

@onready var sprite = $Sprite2D

var keeper_down = preload("res://Assets/Sprites/Player/keeper_down.png")
var keeper_up = preload("res://Assets/Sprites/Player/keeper_up.png")
var keeper_left = preload("res://Assets/Sprites/Player/keeper_left.png")
var keeper_right = preload("res://Assets/Sprites/Player/keeper_right.png")

#summon flame (keep ready in memory)
var flame_scene = preload("res://Scenes/Projectiles/FlameSpirit.tscn")

#----------------ACTION---------------------
func _physics_process(delta):

	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	move_and_slide()

	var mouse_direction = get_global_mouse_position() - global_position
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if abs(mouse_direction.x) > abs(mouse_direction.y):
		if mouse_direction.x > 0:
			sprite.texture = keeper_right
		else:
			sprite.texture = keeper_left
	else:
		if mouse_direction.y > 0:
			sprite.texture = keeper_down
		else:
			sprite.texture = keeper_up

#---------------shooting---------------
func shoot():

	var flame = flame_scene.instantiate()

	get_parent().add_child(flame)

	var shoot_direction = (get_global_mouse_position() - global_position).normalized()

	flame.global_position = global_position + shoot_direction * 20
	flame.direction = shoot_direction
