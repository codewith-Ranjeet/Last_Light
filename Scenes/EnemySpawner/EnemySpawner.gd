extends Node2D

@export var enemy_scene : PackedScene
@export var spawn_interval = 2.0

var timer = 0.0
var can_spawn = false

func _process(delta):
	if !can_spawn:
		return

	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_enemy()


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = get_random_spawn_position()

func get_random_spawn_position():
	var distance = 500
	match randi() % 4:
		0:
			return Vector2(
				randf_range(-distance, distance),
				-distance
			)

		1:
			return Vector2(
				randf_range(-distance, distance),
				distance
			)

		2:
			return Vector2(
				-distance,
				randf_range(-distance, distance)
			)

		3:
			return Vector2(
				distance,
				randf_range(-distance, distance)
			)

	return Vector2.ZERO
