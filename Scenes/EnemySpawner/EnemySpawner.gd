extends Node2D

signal night_completed(night_number: int, cleared: bool, reason: String)
signal night_progress_changed(wave_index: int, wave_count: int, enemies_remaining: int)

@export var enemy_scene: PackedScene
@export var spawn_distance: float = 500.0

const NIGHT_CONFIGS: Array[Resource] = [
	preload("res://Scenes/EnemySpawner/Configs/Night1.tres"),
	preload("res://Scenes/EnemySpawner/Configs/Night2.tres"),
	preload("res://Scenes/EnemySpawner/Configs/Night3.tres"),
	preload("res://Scenes/EnemySpawner/Configs/Night4.tres")
]

var can_spawn: bool = false
var night_number: int = 0
var wave_index: int = -1
var active_enemies: Dictionary = {}
var current_config: NightConfig
var current_wave: NightWaveConfig
var night_elapsed: float = 0.0
var spawn_timer: float = 0.0
var spawn_remaining: int = 0
var waiting_for_wave_clear: bool = false
var red_moon_wave_active: bool = false
var night_finished: bool = false
var night_had_spawn_failure: bool = false


func _process(delta: float) -> void:
	if not can_spawn or night_finished:
		return
	night_elapsed += delta
	_prune_invalid_enemies()
	if night_elapsed >= get_night_timeout():
		_complete_night(false, "The night limit passed before every wave was cleared.")
		return

	if current_wave == null:
		if not _begin_next_wave():
			var cleared := not night_had_spawn_failure
			var reason := "All night waves were cleared." if cleared else "A wave could not spawn its authored enemies; the night schedule was safely retired."
			_complete_night(cleared, reason)
		return

	if spawn_remaining > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_one_enemy()
			spawn_remaining -= 1
			spawn_timer = maxf(current_wave.spawn_interval * (0.75 if red_moon_wave_active else 1.0), 0.05)
			_publish_progress()
		if spawn_remaining == 0:
			waiting_for_wave_clear = true
	elif waiting_for_wave_clear and active_enemies.is_empty():
		current_wave = null
		waiting_for_wave_clear = false
		_publish_progress()


func set_spawning_enabled(enabled: bool) -> void:
	if enabled == can_spawn:
		return
	can_spawn = enabled
	if not enabled:
		return
	_start_night(_current_day())


func _start_night(number: int) -> void:
	night_number = number
	current_config = _config_for_night(number)
	wave_index = -1
	current_wave = null
	active_enemies.clear()
	night_elapsed = 0.0
	spawn_timer = 0.0
	spawn_remaining = 0
	waiting_for_wave_clear = false
	red_moon_wave_active = false
	night_finished = false
	night_had_spawn_failure = false
	if current_config == null or current_config.waves.is_empty():
		_complete_night(true, "This night has no authored waves.")
		return
	_publish_progress()


func _config_for_night(number: int) -> NightConfig:
	for resource in NIGHT_CONFIGS:
		var config := resource as NightConfig
		if config != null and config.night_number == number:
			return config
	return null


func _begin_next_wave() -> bool:
	if current_config == null:
		return false
	wave_index += 1
	if wave_index >= current_config.waves.size():
		return false
	current_wave = current_config.waves[wave_index] as NightWaveConfig
	if current_wave == null:
		# A malformed wave is skipped so a bad resource cannot strand the campaign.
		night_had_spawn_failure = true
		return true
	spawn_remaining = maxi(current_wave.spawn_count, 0)
	red_moon_wave_active = current_config.special_event == &"red_moon" and wave_index + 1 == current_config.special_event_wave
	if current_config.special_event != &"" and wave_index + 1 == current_config.special_event_wave:
		if red_moon_wave_active:
			spawn_remaining += 2
		var manager := get_tree().get_first_node_in_group("campaign_manager")
		if manager != null and manager.has_method("start_night_event"):
			manager.start_night_event(current_config.special_event, current_config.special_event_duration)
	spawn_timer = maxf(current_wave.initial_delay, 0.0)
	waiting_for_wave_clear = spawn_remaining == 0
	_publish_progress()
	return true


func _spawn_one_enemy() -> void:
	var world := get_parent()
	if world == null or current_wave == null:
		night_had_spawn_failure = true
		return
	var available_scenes: Array[PackedScene] = []
	for scene in current_wave.enemy_scenes:
		if scene != null:
			available_scenes.append(scene)
	if available_scenes.is_empty() and enemy_scene != null:
		available_scenes.append(enemy_scene)
	if available_scenes.is_empty():
		night_had_spawn_failure = true
		return
	var instance: Node = available_scenes.pick_random().instantiate()
	if instance == null or not (instance is Node2D):
		if instance != null:
			instance.free()
		night_had_spawn_failure = true
		return
	var enemy := instance as Node2D
	enemy.position = get_random_spawn_position()
	if red_moon_wave_active:
		enemy.set_meta("red_moon_reward", true)
	world.add_child(enemy)
	var enemy_id := enemy.get_instance_id()
	active_enemies[enemy_id] = weakref(enemy)
	if enemy.has_signal("defeated"):
		enemy.defeated.connect(_on_enemy_defeated.bind(enemy_id))
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy_id), CONNECT_ONE_SHOT)
	_publish_progress()


func _on_enemy_defeated(_enemy_kind: StringName, _world_position: Vector2, enemy_id: int) -> void:
	active_enemies.erase(enemy_id)
	_publish_progress()


func _on_enemy_tree_exited(enemy_id: int) -> void:
	active_enemies.erase(enemy_id)
	_publish_progress()


func _prune_invalid_enemies() -> void:
	for enemy_id in active_enemies.keys():
		var enemy_ref: WeakRef = active_enemies[enemy_id]
		var enemy := enemy_ref.get_ref() as Node
		if enemy == null or not enemy.is_inside_tree() or enemy.is_queued_for_deletion():
			active_enemies.erase(enemy_id)


func _complete_night(cleared: bool, reason: String) -> void:
	if night_finished:
		return
	night_finished = true
	can_spawn = false
	_publish_progress()
	night_completed.emit(night_number, cleared, reason)


func get_night_timeout() -> float:
	return maxf(current_config.maximum_duration, 0.1) if current_config != null else 20.0


func get_progress_text() -> String:
	var count := current_config.waves.size() if current_config != null else 0
	if count == 0:
		return "No scheduled waves"
	var display_wave := clampi(wave_index + 1, 1, count)
	var remaining := active_enemies.size() + spawn_remaining
	var wave_name: String = current_wave.wave_name if current_wave != null else "Next wave"
	return "Wave %d/%d · %s · %d threat%s" % [display_wave, count, wave_name, remaining, "" if remaining == 1 else "s"]


func _publish_progress() -> void:
	var count := current_config.waves.size() if current_config != null else 0
	night_progress_changed.emit(maxi(wave_index + 1, 0), count, active_enemies.size() + spawn_remaining)


func _current_day() -> int:
	var manager := get_tree().get_first_node_in_group("campaign_manager")
	return maxi(int(manager.day_number), 1) if manager != null else 1


func get_random_spawn_position() -> Vector2:
	match randi() % 4:
		0:
			return Vector2(randf_range(-spawn_distance, spawn_distance), -spawn_distance)
		1:
			return Vector2(randf_range(-spawn_distance, spawn_distance), spawn_distance)
		2:
			return Vector2(-spawn_distance, randf_range(-spawn_distance, spawn_distance))
		_:
			return Vector2(spawn_distance, randf_range(-spawn_distance, spawn_distance))
