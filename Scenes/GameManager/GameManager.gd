extends Node

enum GameState {
	DAY,
	DUSK,
	NIGHT,
	DAWN
}

@onready var enemy_spawner = $"../EnemySpawner"
@onready var lighthouse = $"../LightHouse"

@export var day_duration: float = 20.0
@export var dusk_duration: float = 5.0
@export var night_duration: float = 20.0
@export var dawn_duration: float = 5.0

var current_phase: String = "🌙 Night"
var current_state: GameState = GameState.DAY
var time_elapsed: float = 0.0
var is_game_over: bool = false


func _ready():
	start_night()


func _process(delta):
	if is_game_over:
		return

	time_elapsed += delta

	match current_state:
		GameState.DAY:
			if time_elapsed >= day_duration:
				start_dusk()

		GameState.DUSK:
			if time_elapsed >= dusk_duration:
				start_night()

		GameState.NIGHT:
			if time_elapsed >= night_duration:
				start_dawn()

		GameState.DAWN:
			if time_elapsed >= dawn_duration:
				start_day()


func start_day():
	current_phase = "☀ Day"
	current_state = GameState.DAY
	time_elapsed = 0.0

	enemy_spawner.can_spawn = false
	lighthouse.can_repair = true

	print("===== DAY =====")


func start_dusk():
	current_phase = "🌇 Dusk"
	current_state = GameState.DUSK
	time_elapsed = 0.0

	print("===== DUSK =====")


func start_night():
	current_phase = "🌙 Night"
	current_state = GameState.NIGHT
	time_elapsed = 0.0

	enemy_spawner.can_spawn = true
	lighthouse.can_repair = false

	print("===== NIGHT =====")


func start_dawn():
	current_phase = "🌅 Dawn"
	current_state = GameState.DAWN
	time_elapsed = 0.0

	enemy_spawner.can_spawn = false

	print("===== DAWN =====")

	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.retreat()


func game_over():
	if is_game_over:
		return

	is_game_over = true

	print("===== GAME OVER =====")

	await get_tree().process_frame

	get_tree().paused = true
