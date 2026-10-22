extends Node

signal phase_changed(day_number: int, phase_id: int)
signal campaign_resources_changed(beacon_count: int, salvage: int)
signal shard_secured(shard_id: StringName, secured_count: int)
signal world_changed(world: Node)
signal game_over_started
signal focus_changed(focus_energy: float, focus_max: float)
signal story_clue_discovered(clue_id: StringName, title: String, text: String)
signal expedition_time_warning(seconds_remaining: float)
signal expedition_finished(expedition_id: StringName, objective_complete: bool, reason: String)
signal light_suppression_changed(is_suppressed: bool)
signal darkness_pulse_started(duration: float)
signal player_health_changed(current_health: int, maximum_health: int)
signal night_progress_changed(wave_index: int, wave_count: int, enemies_remaining: int)
signal night_event_changed(event_id: StringName, duration: float)
signal upgrade_options_changed(upgrade_ids: Array[StringName])
signal upgrade_selected(upgrade_id: StringName)
signal lens_selection_started
signal lens_selected(lens_id: StringName)

enum Phase {
	DAY = 0,
	DUSK = 1,
	NIGHT = 2,
	DAWN = 3,
	EXPEDITION = 4,
	GAME_OVER = 5,
	UPGRADE = 6,
	LENS_SELECTION = 7,
	BOSS = 8,
	VICTORY = 9
}

const STARTING_WORLD_SCENE = preload("res://Scenes/Worlds/LighthouseYard.tscn")
const SHIPBREAKER_SCENE = preload("res://Scenes/Expeditions/ShipbreakerBeach.tscn")
const SALTWOOD_SCENE = preload("res://Scenes/Expeditions/SaltwoodForest.tscn")
const DROWNED_CHAPEL_SCENE = preload("res://Scenes/Expeditions/DrownedChapel.tscn")
const SHARD_SHIPBREAKER: StringName = &"shipbreaker_prism_shard"
const SHARD_SALTWOOD: StringName = &"saltwood_prism_shard"
const SHARD_CHAPEL: StringName = &"chapel_prism_shard"
const UPGRADE_IDS: Array[StringName] = [
	&"white_flame", &"lantern_grip", &"keepers_resolve",
	&"quick_hands", &"echoing_light", &"patient_repair"
]
const LENS_IDS: Array[StringName] = [&"focused_flame", &"wide_radiance", &"steady_light"]

@export var day_duration: float = 20.0
@export var dusk_duration: float = 5.0
@export var night_duration: float = 20.0
@export var dawn_duration: float = 5.0
@export var focus_max: float = 100.0
@export var focus_drain_per_second: float = 34.0
@export var focus_recovery_per_second: float = 24.0
@export var expedition_time_limit: float = 150.0
@export var expedition_warning_seconds: float = 35.0
@export var player_max_health: int = 100

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
var offered_upgrade_ids: Array[StringName] = []
var rewarded_night_numbers: Array[int] = []
var installed_shard_lens: bool = false
var night_complete: bool = false
var night_was_cleared: bool = false
var night_completion_reason: String = ""
var active_night_event: StringName = &""
var night_event_remaining: float = 0.0
var focus_energy: float = 100.0
var completed_expedition_ids: Array[StringName] = []
var discovered_story_clue_ids: Array[StringName] = []
var story_clue_entries: Dictionary = {}
var latest_story_clue_title: String = ""
var latest_story_clue_text: String = ""
var active_expedition_id: StringName = &""
var expedition_elapsed: float = 0.0
var expedition_warning_sent: bool = false
var focus_disrupted_timer: float = 0.0
var player_health: int = 100
var _light_suppressors: Dictionary = {}


func _ready() -> void:
	# The world scene is a sibling and may still be completing _ready when this node does.
	call_deferred("_initialize_campaign")


func _process(delta: float) -> void:
	if is_game_over:
		return
	if focus_disrupted_timer > 0.0:
		focus_disrupted_timer = maxf(focus_disrupted_timer - delta, 0.0)
	_process_night_event(delta)

	if current_state == Phase.EXPEDITION:
		_process_expedition_time(delta)
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
			_finish_night(false, "Night limit reached; remaining threats retreated at dawn.")
		Phase.DAWN:
			if day_number <= 4 and not rewarded_night_numbers.has(day_number):
				_prepare_upgrade_choice()
			else:
				_advance_after_night()


func _initialize_campaign() -> void:
	if world_container != null and world_container.get_child_count() > 0:
		active_world = world_container.get_child(0) as Node2D
	begin_new_campaign()


func begin_new_campaign() -> void:
	if world_transition_in_progress:
		return
	focus_max = maxf(focus_max, 1.0)
	player_max_health = maxi(player_max_health, 1)
	get_tree().paused = false
	day_number = 1
	beacon_count = 0
	salvage = 0
	secured_shard_ids.clear()
	completed_expedition_ids.clear()
	discovered_story_clue_ids.clear()
	story_clue_entries.clear()
	latest_story_clue_title = ""
	latest_story_clue_text = ""
	active_expedition_id = &""
	expedition_elapsed = 0.0
	expedition_warning_sent = false
	_light_suppressors.clear()
	selected_upgrades.clear()
	selected_lens = &""
	offered_upgrade_ids.clear()
	rewarded_night_numbers.clear()
	installed_shard_lens = false
	night_complete = false
	night_was_cleared = false
	night_completion_reason = ""
	active_night_event = &""
	night_event_remaining = 0.0
	focus_energy = focus_max
	player_health = player_max_health
	focus_disrupted_timer = 0.0
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
			return to_phase == Phase.DUSK or to_phase == Phase.EXPEDITION or to_phase == Phase.LENS_SELECTION
		Phase.EXPEDITION:
			return to_phase == Phase.DAY
		Phase.DUSK:
			return to_phase == Phase.NIGHT
		Phase.NIGHT:
			return to_phase == Phase.DAWN
		Phase.DAWN:
			return to_phase == Phase.DAY or to_phase == Phase.UPGRADE
		Phase.UPGRADE:
			return to_phase == Phase.DAY
		Phase.LENS_SELECTION:
			return to_phase == Phase.BOSS
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
		Phase.EXPEDITION:
			return "🧭 Expedition · %s" % _expedition_name(active_expedition_id)
		Phase.UPGRADE:
			return "✨ Memory Echo · Night %d" % day_number
		Phase.LENS_SELECTION:
			return "🔆 Dawn Lens Tuning"
		Phase.BOSS:
			return "🌑 The Black Eclipse"
		Phase.VICTORY:
			return "Greyreach Endures"
		Phase.GAME_OVER:
			return "Game Over"
	return "Unknown"


func _duration_for_phase() -> float:
	match current_state:
		Phase.DAY:
			if day_number >= 5:
				return INF
			return maxf(day_duration, 0.0)
		Phase.DUSK:
			return maxf(dusk_duration, 0.0)
		Phase.NIGHT:
			var spawner := get_current_spawner()
			if spawner != null and spawner.has_method("get_night_timeout"):
				var configured_limit: float = spawner.get_night_timeout()
				# Let the director emit its completion signal first; this timer is only a final safety net.
				return maxf(maxf(night_duration, configured_limit), 0.1) + 1.0
			return maxf(night_duration, 0.1)
		Phase.DAWN:
			return maxf(dawn_duration, 0.0)
		Phase.EXPEDITION:
			return INF
		Phase.UPGRADE, Phase.LENS_SELECTION, Phase.BOSS, Phase.VICTORY:
			return INF
	return INF


func _apply_phase_to_world() -> void:
	var spawner := get_current_spawner()
	if spawner != null:
		if spawner.has_signal("night_completed") and not spawner.night_completed.is_connected(_on_night_completed):
			spawner.night_completed.connect(_on_night_completed)
		if spawner.has_signal("night_progress_changed") and not spawner.night_progress_changed.is_connected(_on_night_progress_changed):
			spawner.night_progress_changed.connect(_on_night_progress_changed)
		if current_state == Phase.NIGHT:
			night_complete = false
			night_was_cleared = false
			night_completion_reason = ""
			active_night_event = &""
			night_event_remaining = 0.0
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
	if is_game_over or delta <= 0.0 or focus_disrupted_timer > 0.0:
		return false

	var previous_energy := focus_energy
	if requesting_focus:
		if focus_energy > 0.0:
			focus_energy = maxf(focus_energy - focus_drain_per_second * get_focus_drain_multiplier() * delta, 0.0)
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


func is_shard_secured(shard_id: StringName) -> bool:
	return secured_shard_ids.has(shard_id)


func get_secured_shard_count() -> int:
	return secured_shard_ids.size()


func get_available_expedition_id() -> StringName:
	if not is_shard_secured(SHARD_SHIPBREAKER):
		return &"shipbreaker_beach"
	if not is_shard_secured(SHARD_SALTWOOD):
		return &"saltwood_forest"
	if not is_shard_secured(SHARD_CHAPEL):
		return &"drowned_chapel"
	return &""


func can_enter_expedition(expedition_id: StringName) -> bool:
	if is_game_over or current_state != Phase.DAY or world_transition_in_progress:
		return false
	if expedition_id == &"shipbreaker_beach":
		return day_number >= 2 and day_number <= 4 and not is_shard_secured(SHARD_SHIPBREAKER)
	if expedition_id == &"saltwood_forest":
		return day_number >= 3 and day_number <= 4 and is_shard_secured(SHARD_SHIPBREAKER) and not is_shard_secured(SHARD_SALTWOOD)
	if expedition_id == &"drowned_chapel":
		return day_number >= 4 and day_number <= 4 and is_shard_secured(SHARD_SHIPBREAKER) and is_shard_secured(SHARD_SALTWOOD) and not is_shard_secured(SHARD_CHAPEL)
	return false


func enter_expedition(expedition_id: StringName) -> bool:
	if not can_enter_expedition(expedition_id):
		return false
	var expedition_scene: PackedScene
	match expedition_id:
		&"shipbreaker_beach":
			expedition_scene = SHIPBREAKER_SCENE
		&"saltwood_forest":
			expedition_scene = SALTWOOD_SCENE
		&"drowned_chapel":
			expedition_scene = DROWNED_CHAPEL_SCENE
		_:
			return false

	active_expedition_id = expedition_id
	expedition_elapsed = 0.0
	expedition_warning_sent = false
	if not _set_phase(Phase.EXPEDITION):
		active_expedition_id = &""
		return false
	if not replace_world(expedition_scene):
		active_expedition_id = &""
		_set_phase(Phase.DAY, true)
		return false
	return true


func return_from_expedition(reason: String = "") -> bool:
	if current_state != Phase.EXPEDITION or world_transition_in_progress:
		return false
	var returned_id := active_expedition_id
	var shard_id := _shard_id_for_expedition(returned_id)
	var objective_complete := shard_id != &"" and is_shard_secured(shard_id)
	if objective_complete and not completed_expedition_ids.has(returned_id):
		completed_expedition_ids.append(returned_id)
	active_expedition_id = &""
	expedition_elapsed = 0.0
	expedition_warning_sent = false
	_set_phase(Phase.DAY, true)
	var replaced := replace_world(STARTING_WORLD_SCENE)
	if replaced:
		time_elapsed = maxf(day_duration - 8.0, 0.0)
		expedition_finished.emit(returned_id, objective_complete, reason)
	return replaced


func get_expedition_time_remaining() -> float:
	return maxf(expedition_time_limit - expedition_elapsed, 0.0)


func _process_expedition_time(delta: float) -> void:
	expedition_elapsed += delta
	var seconds_remaining := get_expedition_time_remaining()
	if not expedition_warning_sent and seconds_remaining <= maxf(expedition_warning_seconds, 0.0):
		expedition_warning_sent = true
		expedition_time_warning.emit(seconds_remaining)
	if seconds_remaining <= 0.0:
		return_from_expedition("The Keeper was returned safely as dusk fell.")


func record_story_clue(clue_id: StringName, title: String, text: String) -> bool:
	if clue_id == &"" or discovered_story_clue_ids.has(clue_id):
		return false
	discovered_story_clue_ids.append(clue_id)
	var entry := {"title": title, "text": text}
	story_clue_entries[clue_id] = entry
	latest_story_clue_title = title
	latest_story_clue_text = text
	story_clue_discovered.emit(clue_id, title, text)
	return true


func has_discovered_story_clue(clue_id: StringName) -> bool:
	return discovered_story_clue_ids.has(clue_id)


func is_light_suppressed() -> bool:
	return not _light_suppressors.is_empty()


func set_light_suppressor(source_id: int, active: bool) -> void:
	var was_suppressed := is_light_suppressed()
	if active:
		_light_suppressors[source_id] = true
	else:
		_light_suppressors.erase(source_id)
	if was_suppressed != is_light_suppressed():
		light_suppression_changed.emit(is_light_suppressed())


func trigger_darkness_pulse(duration: float, focus_drain: float = 18.0) -> void:
	focus_energy = maxf(focus_energy - maxf(focus_drain, 0.0), 0.0)
	focus_disrupted_timer = maxf(focus_disrupted_timer, duration)
	focus_changed.emit(focus_energy, focus_max)
	darkness_pulse_started.emit(duration)


func register_player(player: Node) -> void:
	if player == null:
		return
	player_max_health = maxi(player_max_health, 1)
	player_health = clampi(player_health, 1, player_max_health)
	player.max_health = player_max_health
	player.health = player_health
	player_health_changed.emit(player_health, player_max_health)


func record_player_health(value: int) -> void:
	player_health = clampi(value, 0, player_max_health)
	player_health_changed.emit(player_health, player_max_health)
	if player_health == 0:
		if current_state == Phase.EXPEDITION:
			player_health = maxi(roundi(player_max_health * 0.5), 1)
			call_deferred("return_from_expedition", "The Keeper was forced to retreat.")
		else:
			game_over()


func get_current_expedition_controller() -> Node:
	if not is_instance_valid(active_world):
		return null
	if active_world.has_method("get_objective_text"):
		return active_world
	return active_world.get_node_or_null("ExpeditionController")


func get_current_objective() -> String:
	if current_state == Phase.EXPEDITION:
		var controller := get_current_expedition_controller()
		if controller != null and controller.has_method("get_objective_text"):
			return controller.get_objective_text()
		return "Explore the expedition and return to the marked extraction point."
	if current_state == Phase.DAY:
		if day_number >= 5:
			return "Install all three Prism Shards and choose a Dawn Lens tuning" if not installed_shard_lens else "Prepare the Lighthouse for the Black Eclipse"
		var next_id := get_available_expedition_id()
		if next_id != &"" and can_enter_expedition(next_id):
			return "Recover Prism Shard %d/3 · Use the expedition board" % (secured_shard_ids.size() + 1)
		if day_number == 1:
			return "Prepare the Lighthouse for Night 1"
		return "Secure Prism Shards · %d/3" % secured_shard_ids.size()
	if current_state == Phase.NIGHT:
		var spawner := get_current_spawner()
		var wave_status: String = spawner.get_progress_text() if spawner != null and spawner.has_method("get_progress_text") else "Waiting for the next wave"
		return "Defend the Lighthouse · %s" % wave_status
	if current_state == Phase.DUSK:
		return "Defend the Lighthouse · %d/3 Prism Shards" % secured_shard_ids.size()
	if current_state == Phase.DAWN:
		return "The Veil retreats · %d/3 Prism Shards secured" % secured_shard_ids.size()
	if current_state == Phase.UPGRADE:
		return "Choose one Memory Echo before the next night"
	if current_state == Phase.LENS_SELECTION:
		return "Tune the restored Dawn Lens for the coming Eclipse"
	if current_state == Phase.BOSS:
		return "The Dawn Lens is tuned. The Black Eclipse is ready."
	return ""


func _on_night_completed(completed_night: int, cleared: bool, reason: String) -> void:
	if current_state != Phase.NIGHT or completed_night != day_number:
		return
	_finish_night(cleared, reason)


func _on_night_progress_changed(wave_index: int, wave_count: int, enemies_remaining: int) -> void:
	night_progress_changed.emit(wave_index, wave_count, enemies_remaining)


func _finish_night(cleared: bool, reason: String) -> void:
	if current_state != Phase.NIGHT or night_complete:
		return
	night_complete = true
	night_was_cleared = cleared
	night_completion_reason = reason
	_clear_night_event()
	var spawner := get_current_spawner()
	if spawner != null:
		spawner.set_spawning_enabled(false)
	_set_phase(Phase.DAWN)


func _prepare_upgrade_choice() -> void:
	var available: Array[StringName] = []
	for upgrade_id in UPGRADE_IDS:
		if not selected_upgrades.has(upgrade_id):
			available.append(upgrade_id)
	available.shuffle()
	offered_upgrade_ids.clear()
	for index in range(mini(3, available.size())):
		offered_upgrade_ids.append(available[index])
	if offered_upgrade_ids.is_empty():
		_advance_after_night()
		return
	upgrade_options_changed.emit(offered_upgrade_ids.duplicate())
	_set_phase(Phase.UPGRADE)


func select_upgrade(upgrade_id: StringName) -> bool:
	if current_state != Phase.UPGRADE or not offered_upgrade_ids.has(upgrade_id) or selected_upgrades.has(upgrade_id):
		return false
	selected_upgrades.append(upgrade_id)
	if not rewarded_night_numbers.has(day_number):
		rewarded_night_numbers.append(day_number)
	upgrade_selected.emit(upgrade_id)
	_apply_upgrade_to_existing_structures(upgrade_id)
	offered_upgrade_ids.clear()
	upgrade_options_changed.emit(offered_upgrade_ids.duplicate())
	if day_number == 4 and get_secured_shard_count() < 3:
		# The fourth reward is one-time; Day 4 remains available until every shard is secured.
		_set_phase(Phase.DAY, true)
	else:
		day_number += 1
		_set_phase(Phase.DAY, true)
	return true


func _advance_after_night() -> void:
	if day_number == 4 and get_secured_shard_count() < 3:
		_set_phase(Phase.DAY, true)
		return
	day_number += 1
	_set_phase(Phase.DAY, true)


func get_upgrade_title(upgrade_id: StringName) -> String:
	return str(_upgrade_details(upgrade_id).get("title", "Unknown Memory Echo"))


func get_upgrade_description(upgrade_id: StringName) -> String:
	return str(_upgrade_details(upgrade_id).get("description", ""))


func _upgrade_details(upgrade_id: StringName) -> Dictionary:
	var catalog: Dictionary = {
		&"white_flame": {"title": "White Flame", "description": "+25% fireball damage."},
		&"lantern_grip": {"title": "Lantern Grip", "description": "Focused light drains 25% less Focus."},
		&"keepers_resolve": {"title": "Keeper's Resolve", "description": "Defenses last 30% longer and barricades gain durability."},
		&"quick_hands": {"title": "Quick Hands", "description": "Fireballs recover 25% faster."},
		&"echoing_light": {"title": "Echoing Light", "description": "Ward Lantern fields reach 30% farther."},
		&"patient_repair": {"title": "Patient Repair", "description": "Each Beacon repairs 50% more Lighthouse health."}
	}
	return catalog.get(upgrade_id, {})


func has_upgrade(upgrade_id: StringName) -> bool:
	return selected_upgrades.has(upgrade_id)


func get_projectile_damage_multiplier() -> float:
	return 1.25 if has_upgrade(&"white_flame") else 1.0


func get_focus_drain_multiplier() -> float:
	return 0.75 if has_upgrade(&"lantern_grip") else 1.0


func get_fire_interval_multiplier() -> float:
	return 0.75 if has_upgrade(&"quick_hands") else 1.0


func get_defense_lifetime_multiplier() -> float:
	return 1.3 if has_upgrade(&"keepers_resolve") else 1.0


func get_ward_radius_multiplier() -> float:
	return 1.3 if has_upgrade(&"echoing_light") else 1.0


func get_repair_amount(base_amount: int) -> int:
	return maxi(roundi(float(base_amount) * (1.5 if has_upgrade(&"patient_repair") else 1.0)), base_amount)


func apply_defense_upgrades(structure: Node) -> void:
	if not is_instance_valid(structure) or not has_upgrade(&"keepers_resolve") or structure.has_meta("keepers_resolve_applied"):
		return
	var multiplier := get_defense_lifetime_multiplier()
	var property_names: Array[StringName] = []
	for property in structure.get_property_list():
		property_names.append(StringName(property.name))
	if property_names.has(&"max_durability"):
		structure.set("max_durability", maxi(roundi(float(structure.get("max_durability")) * multiplier), 1))
		structure.set("durability", maxi(roundi(float(structure.get("durability")) * multiplier), 1))
	if property_names.has(&"lifetime"):
		structure.set("lifetime", float(structure.get("lifetime")) * multiplier)
	structure.set_meta("keepers_resolve_applied", true)
	if structure.has_method("queue_redraw"):
		structure.queue_redraw()


func _apply_upgrade_to_existing_structures(upgrade_id: StringName) -> void:
	if upgrade_id == &"keepers_resolve":
		for structure in get_tree().get_nodes_in_group("defense_structure"):
			apply_defense_upgrades(structure)
	elif upgrade_id == &"echoing_light":
		for lantern in get_tree().get_nodes_in_group("ward_lantern"):
			if lantern.has_method("apply_campaign_upgrades"):
				lantern.apply_campaign_upgrades()


func begin_lens_selection() -> bool:
	if is_game_over or current_state != Phase.DAY or day_number != 5 or get_secured_shard_count() < 3 or installed_shard_lens:
		return false
	installed_shard_lens = true
	if not _set_phase(Phase.LENS_SELECTION):
		installed_shard_lens = false
		return false
	lens_selection_started.emit()
	return true


func select_lens(lens_id: StringName) -> bool:
	if current_state != Phase.LENS_SELECTION or not installed_shard_lens or not LENS_IDS.has(lens_id):
		return false
	selected_lens = lens_id
	lens_selected.emit(lens_id)
	_set_phase(Phase.BOSS)
	return true


func get_lens_title(lens_id: StringName) -> String:
	match lens_id:
		&"focused_flame":
			return "Focused Flame"
		&"wide_radiance":
			return "Wide Radiance"
		&"steady_light":
			return "Steady Light"
	return "Unknown Lens"


func get_lens_description(lens_id: StringName) -> String:
	match lens_id:
		&"focused_flame":
			return "Fireballs deal 50% more damage to enemies exposed by focused light."
		&"wide_radiance":
			return "The Lighthouse sweep reaches 30% farther and controls a wider area."
		&"steady_light":
			return "The Lighthouse takes 25% less damage."
	return ""


func get_focused_attack_multiplier() -> float:
	return 1.5 if selected_lens == &"focused_flame" else 1.0


func get_lighthouse_damage_multiplier() -> float:
	return 0.75 if selected_lens == &"steady_light" else 1.0


func get_beam_range_multiplier() -> float:
	var multiplier := 1.3 if selected_lens == &"wide_radiance" else 1.0
	if active_night_event == &"eclipse_surge":
		multiplier *= 0.65
	return multiplier


func start_night_event(event_id: StringName, duration: float) -> void:
	if current_state != Phase.NIGHT or event_id == &"":
		return
	active_night_event = event_id
	night_event_remaining = maxf(duration, 0.1)
	night_event_changed.emit(active_night_event, night_event_remaining)
	_refresh_lighthouse_beam()


func _process_night_event(delta: float) -> void:
	if active_night_event == &"":
		return
	if current_state != Phase.NIGHT:
		_clear_night_event()
		return
	night_event_remaining = maxf(night_event_remaining - delta, 0.0)
	if night_event_remaining <= 0.0:
		_clear_night_event()


func _clear_night_event() -> void:
	if active_night_event == &"":
		return
	active_night_event = &""
	night_event_remaining = 0.0
	night_event_changed.emit(active_night_event, 0.0)
	_refresh_lighthouse_beam()


func _refresh_lighthouse_beam() -> void:
	var lighthouse := get_current_lighthouse()
	if lighthouse == null:
		return
	var beam := lighthouse.get_node_or_null("LighthouseBeam")
	if beam != null:
		if beam.has_method("refresh_range"):
			beam.refresh_range()
		beam.queue_redraw()


func _shard_id_for_expedition(expedition_id: StringName) -> StringName:
	match expedition_id:
		&"shipbreaker_beach":
			return SHARD_SHIPBREAKER
		&"saltwood_forest":
			return SHARD_SALTWOOD
		&"drowned_chapel":
			return SHARD_CHAPEL
	return &""


func _expedition_name(expedition_id: StringName) -> String:
	match expedition_id:
		&"shipbreaker_beach":
			return "Shipbreaker Beach"
		&"saltwood_forest":
			return "Saltwood Forest"
		&"drowned_chapel":
			return "Drowned Chapel"
	return "Unknown"


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
