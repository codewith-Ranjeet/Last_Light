extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_distance: float = 500.0

var timer: float = 0.0
var can_spawn: bool = false


func _process(delta):
	if !can_spawn:
		return

	timer += delta

	if timer >= spawn_interval:
		timer = 0.0
		spawn_enemy()


func spawn_enemy():
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = get_random_spawn_position()


func get_random_spawn_position() -> Vector2:
	match randi() % 4:
		0:
			return Vector2(
				randf_range(-spawn_distance, spawn_distance),
				-spawn_distance
			)

		1:
			return Vector2(
				randf_range(-spawn_distance, spawn_distance),
				spawn_distance
			)

		2:
			return Vector2(
				-spawn_distance,
				randf_range(-spawn_distance, spawn_distance)
			)

		3:
			return Vector2(
				spawn_distance,
				randf_range(-spawn_distance, spawn_distance)
			)

	return Vector2.ZERO
