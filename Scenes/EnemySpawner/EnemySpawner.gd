extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_distance: float = 500.0

const NIGHTSTALKER_SCENE: PackedScene = preload("res://Scenes/Enemies/Nightstalker.tscn")
const LIGHT_LEECH_SCENE: PackedScene = preload("res://Scenes/Enemies/LightLeech.tscn")
const ASHEN_BRUTE_SCENE: PackedScene = preload("res://Scenes/Enemies/AshenBrute.tscn")

var timer: float = 0.0
var can_spawn: bool = false


func _process(delta: float) -> void:
	if not can_spawn:
		return

	timer += delta

	if timer >= maxf(spawn_interval, 0.05):
		timer = 0.0
		spawn_enemy()


func set_spawning_enabled(enabled: bool) -> void:
	if can_spawn == enabled:
		return
	can_spawn = enabled
	timer = 0.0


func spawn_enemy() -> void:
	var world := get_parent()
	if enemy_scene == null or world == null:
		return

	var roster := get_roster_for_day(_current_day())
	if roster.is_empty():
		return
	var scene: PackedScene = roster[randi_range(0, roster.size() - 1)]
	var enemy = scene.instantiate()
	world.add_child(enemy)
	enemy.global_position = get_random_spawn_position()


func get_roster_for_day(day: int) -> Array[PackedScene]:
	var roster: Array[PackedScene] = []
	if enemy_scene != null:
		roster.append(enemy_scene)
	if day >= 2:
		roster.append(NIGHTSTALKER_SCENE)
	if day >= 3:
		roster.append(LIGHT_LEECH_SCENE)
	if day >= 4:
		roster.append(ASHEN_BRUTE_SCENE)
	return roster


func _current_day() -> int:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	return maxi(int(manager.day_number), 1) if manager != null else 1


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
