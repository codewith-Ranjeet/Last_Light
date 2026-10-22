extends Resource
class_name NightWaveConfig

@export var wave_name: String = "Veil Remnants"
@export var enemy_scenes: Array[PackedScene] = []
@export_range(0, 32, 1) var spawn_count: int = 0
@export_range(0.05, 10.0, 0.05) var spawn_interval: float = 1.0
@export_range(0.0, 20.0, 0.1) var initial_delay: float = 0.8
