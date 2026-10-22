extends Resource
class_name NightConfig

@export_range(1, 4, 1) var night_number: int = 1
@export var waves: Array[Resource] = []
@export var special_event: StringName = &""
@export_range(1, 8, 1) var special_event_wave: int = 1
@export_range(0.0, 60.0, 0.5) var special_event_duration: float = 18.0
@export_range(15.0, 240.0, 1.0) var maximum_duration: float = 120.0
