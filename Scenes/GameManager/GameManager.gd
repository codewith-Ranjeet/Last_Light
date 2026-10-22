extends Node

signal phase_changed(day_number: int, phase_id: int)
signal campaign_resources_changed(beacon_count: int, salvage: int)
signal shard_secured(shard_id: StringName, secured_count: int)
signal world_changed(world: Node)
signal game_over_started
signal focus_changed(focus_energy: float, focus_max: float)

enum Phase {
	DAY,
	DUSK,
	NIGHT,
	DAWN,
	GAME_OVER
}

const STARTING_WORLD_SCENE = preload("res://Scenes/Worlds/LighthouseYard.tscn")

@export var day_duration: float = 20.0
@export var dusk_duration: float = 5.0
@export var night_duration: float = 20.0
@export var dawn_duration: float = 5.0
@export var focus_max: float = 100.0
@export var focus_drain_per_second: float = 34.0
@export var focus_recovery_per_second: float = 24.0

@onready var world_container: Node2D = get_node_or_null("../WorldContainer")

var current_state: int = Phase.DAY
var current_phase: String = "☀ Day 1"
var day_number: int = 1
var time_elapsed: float = 0.0
var is_game_over: bool = false
var world_transition_in_progress: bool = false
var active_world: Node2D

# Campaign data lives on this persistent root node, outside the replaceable world.
var beacon_count: int = 0
var salvage: int = 0
var lighthouse_health: int = 100
var lighthouse_max_health: int = 100
var secured_shard_ids: Array[StringName] = []
var selected_upgrades: Array[StringName] = []
var selected_lens: StringName = &""
var focus_energy: float = 100.0


func _ready() -> void:
	# The world scene is a sibling and may still be completing _ready when this node does.
	call_deferred("_initialize_campaign")


func _process(delta: float) -> void:
	if is_game_over:
		return

	time_elapsed += delta
	if time_elapsed < _duration_for_phase():
		return

	match current_state:
		Phase.DAY:
			_set_phase(Phase.DUSK)
		Phase.DUSK:
			_set_phase(Phase.NIGHT)
		Phase.NIGHT:
			_set_phase(Phase.DAWN)
		Phase.DAWN:
			day_number += 1
			_set_phase(Phase.DAY)


func _initialize_campaign() -> void:
	if world_container != null and world_container.get_child_count() > 0:
		active_world = world_container.get_child(0) as Node2D
	begin_new_campaign()


func begin_new_campaign() -> void:
	if world_transition_in_progress:
		return
	focus_max = maxf(focus_max, 1.0)
	get_tree().paused = false
	day_number = 1
	beacon_count = 0
	salvage = 0
	secured_shard_ids.clear()
	selected_upgrades.clear()
	selected_lens = &""
	focus_energy = focus_max
	is_game_over = false
	time_elapsed = 0.0
	lighthouse_health = lighthouse_max_health

	if world_container != null:
		replace_world(STARTING_WORLD_SCENE)

	_set_phase(Phase.DAY, true)
	campaign_resources_changed.emit(beacon_count, salvage)
	focus_changed.emit(focus_energy, focus_max)


func _set_phase(next_phase: int, force: bool = false) -> bool:
	if is_game_over and next_phase != Phase.GAME_OVER:
		return false
	if current_state == next_phase and not force:
		return false
	if not force and not _is_valid_phase_transition(current_state, next_phase):
		return false

	current_state = next_phase
	time_elapsed = 0.0
	current_phase = _label_for_phase(next_phase)
	_apply_phase_to_world()
	phase_changed.emit(day_number, current_state)
	print("===== %s =====" % current_phase)
	return true


func _is_valid_phase_transition(from_phase: int, to_phase: int) -> bool:
	if to_phase == Phase.GAME_OVER:
		return true
	match from_phase:
		Phase.DAY:
			return to_phase == Phase.DUSK
		Phase.DUSK:
			return to_phase == Phase.NIGHT
		Phase.NIGHT:
			return to_phase == Phase.DAWN
		Phase.DAWN:
			return to_phase == Phase.DAY
	return false


func _label_for_phase(phase_id: int) -> String:
	match phase_id:
		Phase.DAY:
			return "☀ Day %d" % day_number
		Phase.DUSK:
			return "🌇 Dusk"
		Phase.NIGHT:
			return "🌙 Night %d" % day_number
		Phase.DAWN:
			return "🌅 Dawn"
		Phase.GAME_OVER:
			return "Game Over"
	return "Unknown"


func _duration_for_phase() -> float:
	match current_state:
		Phase.DAY:
			return maxf(day_duration, 0.0)
		Phase.DUSK:
			return maxf(dusk_duration, 0.0)
		Phase.NIGHT:
			return maxf(night_duration, 0.0)
		Phase.DAWN:
			return maxf(dawn_duration, 0.0)
	return INF


func _apply_phase_to_world() -> void:
	var spawner := get_current_spawner()
	if spawner != null:
		spawner.set_spawning_enabled(current_state == Phase.NIGHT)

	var lighthouse := get_current_lighthouse()
	if lighthouse != null:
		lighthouse.can_repair = current_state == Phase.DAY

	if current_state == Phase.DAWN:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.has_method("retreat"):
				enemy.retreat()


func get_current_lighthouse() -> Node:
	if not is_instance_valid(active_world):
		return null
	return active_world.get_node_or_null("LightHouse")


func get_current_player() -> Node:
	if not is_instance_valid(active_world):
		return null
	return active_world.get_node_or_null("Player")


func get_current_spawner() -> Node:
	if not is_instance_valid(active_world):
		return null
	return active_world.get_node_or_null("EnemySpawner")


func replace_world(scene: PackedScene) -> bool:
	if world_transition_in_progress or is_game_over or scene == null or world_container == null:
		return false

	var next_world := scene.instantiate() as Node2D
	if next_world == null:
		return false

	world_transition_in_progress = true
	var previous_world := active_world
	active_world = next_world
	if is_instance_valid(previous_world):
		world_container.remove_child(previous_world)
		previous_world.queue_free()
	world_container.add_child(next_world)
	_apply_phase_to_world()
	world_changed.emit(next_world)
	world_transition_in_progress = false
	return true


func register_lighthouse(lighthouse: Node) -> void:
	if lighthouse == null:
		return
	lighthouse_max_health = maxi(int(lighthouse.max_health), 1)
	lighthouse_health = clampi(lighthouse_health, 0, lighthouse_max_health)
	lighthouse.health = lighthouse_health
	if lighthouse.has_method("update_damage_stage"):
		lighthouse.update_damage_stage()


func record_lighthouse_health(value: int) -> void:
	lighthouse_health = clampi(value, 0, lighthouse_max_health)


func add_beacons(amount: int = 1) -> void:
	if is_game_over or amount <= 0:
		return
	beacon_count += amount
	campaign_resources_changed.emit(beacon_count, salvage)


func spend_beacons(amount: int = 1) -> bool:
	if amount <= 0 or beacon_count < amount or is_game_over:
		return false
	beacon_count -= amount
	campaign_resources_changed.emit(beacon_count, salvage)
	return true


func add_salvage(amount: int = 1) -> void:
	if is_game_over or amount <= 0:
		return
	salvage += amount
	campaign_resources_changed.emit(beacon_count, salvage)


func spend_salvage(amount: int) -> bool:
	if amount <= 0 or salvage < amount or is_game_over:
		return false
	salvage -= amount
	campaign_resources_changed.emit(beacon_count, salvage)
	return true


func update_focus(delta: float, requesting_focus: bool) -> bool:
	if is_game_over or delta <= 0.0:
		return false

	var previous_energy := focus_energy
	if requesting_focus:
		if focus_energy > 0.0:
			focus_energy = maxf(focus_energy - focus_drain_per_second * delta, 0.0)
	else:
		focus_energy = minf(focus_energy + focus_recovery_per_second * delta, focus_max)

	if not is_equal_approx(previous_energy, focus_energy):
		focus_changed.emit(focus_energy, focus_max)
	return requesting_focus and focus_energy > 0.0


func secure_shard(shard_id: StringName) -> bool:
	if is_game_over or shard_id == &"" or secured_shard_ids.has(shard_id):
		return false
	secured_shard_ids.append(shard_id)
	shard_secured.emit(shard_id, secured_shard_ids.size())
	return true


func game_over() -> void:
	if is_game_over:
		return

	is_game_over = true
	_set_phase(Phase.GAME_OVER, true)
	game_over_started.emit()

	var spawner := get_current_spawner()
	if spawner != null:
		spawner.set_spawning_enabled(false)

	await get_tree().process_frame
	get_tree().paused = true
