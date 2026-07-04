extends Node

enum GameState {
	DAY,
	DUSK,
	NIGHT,
	DAWN
}

@onready var enemy_spawner = $"../EnemySpawner"
@onready var repair = $"../LightHouse"

@export var day_duration = 20.0
@export var dusk_duration = 5.0
@export var night_duration = 20.0
@export var dawn_duration = 5.0

var current_state = GameState.DAY
var time_elapsed = 0.0

func _process(delta):

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

func _ready():
	start_night()

func start_day():
	current_state = GameState.DAY
	time_elapsed = 0.0
	enemy_spawner.can_spawn = false
	repair.can_repair = true
	print("===== DAY =====")

func start_night():
	current_state = GameState.NIGHT
	time_elapsed = 0.0
	enemy_spawner.can_spawn = true
	repair.can_repair = false
	print("===== NIGHT =====")

func start_dusk():
	current_state = GameState.DUSK
	time_elapsed = 0
	print("===== DUSK =====")

func start_dawn():
	current_state = GameState.DAWN
	time_elapsed = 0
	enemy_spawner.can_spawn = false
	print("===== DAWN =====")
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.retreat()
