extends "res://Scenes/Enemies/ShadowEnemy.gd"
class_name HollowShepherd

signal encounter_phase_changed(phase_id: int)

enum EncounterPhase { HERD, BLACKOUT, LAST_LIGHT }
enum StrikeState { COOLDOWN, TELEGRAPH, STRIKE, RECOVERY }

const HERD_ENEMY_SCENE: PackedScene = preload("res://Scenes/Enemies/ShadowCrawler.tscn")
const LIGHT_LEECH_SCENE: PackedScene = preload("res://Scenes/Enemies/LightLeech.tscn")
const BOSS_GAME_PHASE := 8
const HERD_SUMMON_LIMIT := 4

@export var herd_duration: float = 18.0
@export var herd_summon_interval: float = 3.5
@export var blackout_duration: float = 28.0
@export var lighthouse_attack_damage: int = 14
@export var player_attack_damage: int = 22
@export var attack_radius: float = 108.0
@export var telegraph_duration: float = 1.35
@export var strike_duration: float = 0.3
@export var recovery_duration: float = 2.4

@onready var eclipse_modulate: CanvasModulate = $EclipseModulate

var campaign_manager: Node
var encounter_phase: int = EncounterPhase.HERD
var strike_state: int = StrikeState.COOLDOWN
var phase_elapsed: float = 0.0
var summon_timer: float = 0.7
var strike_timer: float = 2.2
var herd_summons_created: int = 0
var blackout_leech: Node
var blackout_leech_defeated: bool = false
var encounter_finished: bool = false


func _ready() -> void:
	super._ready()
	enemy_kind = &"hollow_shepherd"
	drops_beacon = false
	add_to_group("light_sensitive")
	add_to_group("hollow_shepherd")
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	eclipse_modulate.color = Color.WHITE
	queue_redraw()


func _process(delta: float) -> void:
	var was_exposed := focused_exposure_timer > 0.0
	super._process(delta)
	if was_exposed != (focused_exposure_timer > 0.0):
		queue_redraw()
	if encounter_finished or not is_instance_valid(campaign_manager) or campaign_manager.current_state != BOSS_GAME_PHASE:
		return
	phase_elapsed += delta
	match encounter_phase:
		EncounterPhase.HERD:
			_process_herd(delta)
		EncounterPhase.BLACKOUT:
			if phase_elapsed >= blackout_duration or health <= roundi(float(max_health) * 0.36):
				_enter_last_light()
		EncounterPhase.LAST_LIGHT:
			_process_last_light(delta)


func _process_herd(delta: float) -> void:
	summon_timer -= delta
	if summon_timer <= 0.0:
		_spawn_herd_summon()
		summon_timer = maxf(herd_summon_interval, 0.5)
	if phase_elapsed >= herd_duration or health <= roundi(float(max_health) * 0.68):
		_enter_blackout()


func _spawn_herd_summon() -> void:
	if herd_summons_created >= HERD_SUMMON_LIMIT or not is_instance_valid(get_parent()):
		return
	var summon := HERD_ENEMY_SCENE.instantiate()
	get_parent().add_child(summon)
	summon.add_to_group("boss_summon")
	var offset := Vector2(-175.0 if herd_summons_created % 2 == 0 else 175.0, 105.0 + float(herd_summons_created % 2) * 38.0)
	summon.global_position = global_position + offset
	herd_summons_created += 1


func _enter_blackout() -> void:
	if encounter_phase != EncounterPhase.HERD or encounter_finished:
		return
	encounter_phase = EncounterPhase.BLACKOUT
	phase_elapsed = 0.0
	focused_exposure_timer = 0.0
	eclipse_modulate.color = Color(0.36, 0.39, 0.52)
	encounter_phase_changed.emit(encounter_phase)
	if is_instance_valid(campaign_manager):
		campaign_manager.trigger_darkness_pulse(2.5, 22.0)
	_spawn_blackout_leech()
	queue_redraw()


func _spawn_blackout_leech() -> void:
	if not is_instance_valid(get_parent()):
		return
	var leech := LIGHT_LEECH_SCENE.instantiate()
	get_parent().add_child(leech)
	leech.add_to_group("boss_summon")
	var lighthouse: Node2D = campaign_manager.get_current_lighthouse() if is_instance_valid(campaign_manager) else null
	leech.global_position = lighthouse.global_position + Vector2(92.0, 30.0) if is_instance_valid(lighthouse) else global_position + Vector2(-70.0, 45.0)
	blackout_leech = leech
	if leech.has_signal("defeated"):
		leech.defeated.connect(_on_summoned_enemy_defeated)


func _on_summoned_enemy_defeated(enemy_kind: StringName, _world_position: Vector2) -> void:
	if encounter_phase == EncounterPhase.BLACKOUT and enemy_kind == &"light_leech":
		blackout_leech_defeated = true
		queue_redraw()


func _enter_last_light() -> void:
	if encounter_phase != EncounterPhase.BLACKOUT or encounter_finished:
		return
	encounter_phase = EncounterPhase.LAST_LIGHT
	phase_elapsed = 0.0
	focused_exposure_timer = 0.0
	eclipse_modulate.color = Color.WHITE
	strike_state = StrikeState.COOLDOWN
	strike_timer = 1.2
	if is_instance_valid(blackout_leech) and blackout_leech.has_method("retreat"):
		blackout_leech.retreat()
	encounter_phase_changed.emit(encounter_phase)
	queue_redraw()


func _process_last_light(delta: float) -> void:
	strike_timer -= delta
	if strike_timer > 0.0:
		return
	match strike_state:
		StrikeState.COOLDOWN:
			strike_state = StrikeState.TELEGRAPH
			strike_timer = maxf(telegraph_duration, 0.4)
		StrikeState.TELEGRAPH:
			strike_state = StrikeState.STRIKE
			strike_timer = maxf(strike_duration, 0.1)
			_perform_lighthouse_strike()
		StrikeState.STRIKE:
			strike_state = StrikeState.RECOVERY
			strike_timer = maxf(recovery_duration, 0.5)
		StrikeState.RECOVERY:
			strike_state = StrikeState.COOLDOWN
			strike_timer = 1.35
	queue_redraw()


func _perform_lighthouse_strike() -> void:
	if not is_instance_valid(campaign_manager) or campaign_manager.current_state != BOSS_GAME_PHASE:
		return
	var lighthouse: Node2D = campaign_manager.get_current_lighthouse() as Node2D
	if is_instance_valid(lighthouse) and lighthouse.has_method("damage"):
		lighthouse.damage(lighthouse_attack_damage)
	if campaign_manager.is_game_over:
		return
	var player: Node2D = campaign_manager.get_current_player()
	if is_instance_valid(player) and is_instance_valid(lighthouse) and lighthouse.global_position.distance_to(player.global_position) <= attack_radius and player.has_method("take_damage"):
		player.take_damage(player_attack_damage)


func apply_focused_light(delta: float = 0.08) -> void:
	super.apply_focused_light(delta)
	if not encounter_finished:
		queue_redraw()


func is_exposed_to_focused_light() -> bool:
	return focused_exposure_timer > 0.0


func can_take_boss_damage() -> bool:
	if focused_exposure_timer <= 0.0:
		return false
	match encounter_phase:
		EncounterPhase.HERD:
			return true
		EncounterPhase.BLACKOUT:
			return blackout_leech_defeated
		EncounterPhase.LAST_LIGHT:
			return strike_state == StrikeState.RECOVERY
	return false


func damage_to_enemy(amount: int) -> void:
	if not can_take_boss_damage():
		return
	super.damage_to_enemy(amount)
	if is_dead or encounter_finished:
		return
	if encounter_phase == EncounterPhase.HERD and health <= roundi(float(max_health) * 0.68):
		_enter_blackout()
	elif encounter_phase == EncounterPhase.BLACKOUT and health <= roundi(float(max_health) * 0.36):
		_enter_last_light()


func get_encounter_phase_name() -> String:
	match encounter_phase:
		EncounterPhase.HERD:
			return "The Herd"
		EncounterPhase.BLACKOUT:
			return "The Blackout"
		EncounterPhase.LAST_LIGHT:
			return "The Last Light"
	return "Unknown"


func get_attack_status() -> String:
	if encounter_phase != EncounterPhase.LAST_LIGHT:
		return ""
	match strike_state:
		StrikeState.TELEGRAPH:
			return "ECLIPSE STRIKE · MOVE"
		StrikeState.STRIKE:
			return "ECLIPSE STRIKE"
		StrikeState.RECOVERY:
			return "CORE EXPOSED · FOCUS AND FIRE"
	return ""


func is_blackout_active() -> bool:
	return encounter_phase == EncounterPhase.BLACKOUT and not encounter_finished


func get_health_ratio() -> float:
	return float(health) / float(maxi(max_health, 1))


func on_enemy_dying() -> void:
	encounter_finished = true
	eclipse_modulate.color = Color.WHITE
	if is_instance_valid(campaign_manager):
		campaign_manager.set_light_suppressor(get_instance_id(), false)


func retreat() -> void:
	if is_dead:
		return
	encounter_finished = true
	eclipse_modulate.color = Color.WHITE
	if is_instance_valid(campaign_manager):
		campaign_manager.set_light_suppressor(get_instance_id(), false)
	queue_free()


func _draw() -> void:
	var core_color := Color(1.0, 0.8, 0.43) if can_take_boss_damage() else Color(0.39, 0.24, 0.43)
	var body := Color(0.08, 0.075, 0.12, 0.98) if encounter_phase != EncounterPhase.BLACKOUT else Color(0.035, 0.035, 0.065, 0.99)
	draw_colored_polygon(PackedVector2Array([Vector2(-31, -22), Vector2(-22, -38), Vector2(-8, -30), Vector2(0, -45), Vector2(10, -30), Vector2(25, -37), Vector2(32, -18), Vector2(27, 18), Vector2(12, 31), Vector2(-14, 30), Vector2(-30, 14)]), body)
	draw_polyline(PackedVector2Array([Vector2(-31, -22), Vector2(-22, -38), Vector2(-8, -30), Vector2(0, -45), Vector2(10, -30), Vector2(25, -37), Vector2(32, -18), Vector2(27, 18), Vector2(12, 31), Vector2(-14, 30), Vector2(-30, 14), Vector2(-31, -22)]), Color(0.52, 0.44, 0.62, 0.9), 2.0, true)
	draw_circle(Vector2(0, -2), 11.0, Color(core_color.r, core_color.g, core_color.b, 0.4))
	draw_circle(Vector2(0, -2), 5.0, core_color)
	draw_rect(Rect2(-31, -55, 62, 5), Color(0.08, 0.07, 0.09), true)
	draw_rect(Rect2(-31, -55, 62.0 * clampf(get_health_ratio(), 0.0, 1.0), 5), Color(0.79, 0.3, 0.41), true)
	if encounter_phase == EncounterPhase.LAST_LIGHT and strike_state == StrikeState.TELEGRAPH:
		var lighthouse: Node2D = campaign_manager.get_current_lighthouse() if is_instance_valid(campaign_manager) else null
		var target_position := to_local(lighthouse.global_position) if is_instance_valid(lighthouse) else Vector2.ZERO
		draw_line(Vector2.ZERO, target_position, Color(1.0, 0.27, 0.22, 0.68), 2.0, true)
		draw_arc(target_position, attack_radius, 0.0, TAU, 48, Color(1.0, 0.27, 0.22, 0.8), 3.0, true)
	if can_take_boss_damage():
		draw_arc(Vector2.ZERO, 43.0, 0.0, TAU, 36, Color(1.0, 0.81, 0.46, 0.85), 2.0, true)
