extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://Scenes/main.tscn")
const FLAME_SCENE: PackedScene = preload("res://Scenes/Projectiles/FlameSpirit.tscn")
const SHADOW_SCENE: PackedScene = preload("res://Scenes/Enemies/ShadowCrawler.tscn")

var victory_count: int = 0
var game_over_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not await _test_focused_flame_finale():
		return
	if not await _test_wide_radiance_finale():
		return
	if not await _test_steady_light_failure_and_reset():
		return
	print("MILESTONE_F_INTEGRATION_TEST: PASS")
	quit(0)


func _open_finale(lens_id: StringName) -> Dictionary:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var manager: Node = main.get_node("GameManager")
	manager.day_number = 5
	if not _check(not manager.begin_lens_selection(), "Day 5 lens selection must require all three shards"):
		return {}
	manager.secured_shard_ids.assign([&"shipbreaker_prism_shard", &"saltwood_prism_shard", &"chapel_prism_shard"])
	if not _check(manager.begin_lens_selection(), "All secured shards should unlock Day 5 lens selection"):
		return {}
	if not _check(manager.select_lens(lens_id), "Selected lens should start the boss encounter"):
		return {}
	await process_frame
	if not _check(manager.current_state == manager.Phase.BOSS, "Lens selection should enter the boss phase"):
		return {}
	if not _check(manager.boss_spawned and manager.get_current_boss() != null, "Selecting a lens should spawn one Hollow Shepherd"):
		return {}
	if not _check(not manager.get_current_spawner().can_spawn, "Night waves must stop during the boss encounter"):
		return {}
	if not _check(not manager._spawn_hollow_shepherd(), "The boss must not spawn twice"):
		return {}
	return {"main": main, "manager": manager, "boss": manager.get_current_boss()}


func _test_focused_flame_finale() -> bool:
	victory_count = 0
	var context: Dictionary = await _open_finale(&"focused_flame")
	if context.is_empty():
		return false
	var main: Node = context.main
	var manager: Node = context.manager
	var boss: Node = context.boss
	manager.campaign_victory_started.connect(_on_victory_started)
	if not _check(manager.get_focused_attack_multiplier() == 1.5, "Focused Flame should increase exposed boss damage"):
		return false

	var player: Node2D = manager.get_current_player()
	var player_light: Node = player.get_node("LightFocus")
	player.global_position = boss.global_position + Vector2(-125.0, 30.0)
	var unexposed_health: int = boss.health
	boss.damage_to_enemy(10)
	if not _check(boss.health == unexposed_health, "The boss should ignore attacks before focused illumination"):
		return false
	player_light.call("update_focus", 0.08, true, boss.global_position)
	if not _check(boss.is_exposed_to_focused_light(), "Focused Light should expose the Hollow Shepherd"):
		return false
	var boss_health: int = boss.health
	var flame := FLAME_SCENE.instantiate()
	manager.active_world.add_child(flame)
	flame.call("_on_body_entered", boss)
	if not _check(boss.health == boss_health - 30, "Focused Flame should deal its 50% bonus damage to the exposed boss"):
		return false

	for _index in range(8):
		boss.call("_spawn_herd_summon")
	if not _check(boss.herd_summons_created == 4, "The Herd must stop at its four-summon cap"):
		return false
	if not _check(get_nodes_in_group("boss_summon").size() == 4, "Only the bounded herd summons should exist before blackout"):
		return false

	boss.health = 177
	boss.apply_focused_light(0.08)
	var focus_before_blackout: float = manager.focus_energy
	boss.damage_to_enemy(1)
	if not _check(boss.encounter_phase == 1, "The Herd should transition to the Blackout at its health threshold"):
		return false
	if not _check(manager.focus_energy == focus_before_blackout - 22.0 and manager.focus_disrupted_timer > 0.0 and boss.eclipse_modulate.color != Color.WHITE, "Blackout should dim the arena and disrupt the Keeper's Focus"):
		return false
	var leech: Node = manager.active_world.get_node_or_null("LightLeech")
	if leech == null:
		leech = boss.blackout_leech
	if not _check(is_instance_valid(leech), "Blackout should summon a Light Leech"):
		return false
	await physics_frame
	leech.call("_physics_process", 0.1)
	if not _check(leech.is_suppressing and manager.is_light_suppressed(), "The Blackout Light Leech should suppress the Lighthouse beam"):
		return false

	manager.focus_disrupted_timer = 0.0
	player.global_position = leech.global_position + Vector2(-80.0, 0.0)
	leech.focused_damage_interval = 0.01
	var leech_health: int = leech.health
	player_light.call("update_focus", 0.08, true, leech.global_position)
	if not _check(leech.health < leech_health, "Focused Light should damage the summoned Light Leech"):
		return false
	var protected_health: int = boss.health
	boss.apply_focused_light(0.08)
	boss.damage_to_enemy(10)
	if not _check(boss.health == protected_health, "The boss must remain protected while the blackout Leech is alive"):
		return false
	leech.damage_to_enemy(1000)
	if not _check(boss.blackout_leech_defeated and not manager.is_light_suppressed(), "Defeating the Leech should restore light and unlock the boss"):
		return false

	boss.health = 94
	boss.apply_focused_light(0.08)
	boss.damage_to_enemy(2)
	if not _check(boss.encounter_phase == 2, "The Blackout should transition to The Last Light"):
		return false
	if not _check(boss.eclipse_modulate.color == Color.WHITE, "The Last Light should restore arena illumination"):
		return false
	boss.strike_state = 0
	boss.strike_timer = 0.0
	boss._process_last_light(0.01)
	if not _check(boss.strike_state == 1 and boss.get_attack_status().contains("MOVE"), "The Last Light attack should show a telegraphed warning"):
		return false
	boss.apply_focused_light(0.08)
	if not _check(not boss.can_take_boss_damage(), "The boss should be invulnerable during its warning window"):
		return false
	var lighthouse: Node = manager.get_current_lighthouse()
	var lighthouse_health: int = lighthouse.health
	boss.strike_timer = 0.0
	boss._process_last_light(0.01)
	if not _check(boss.strike_state == 2 and lighthouse.health < lighthouse_health, "The active strike should damage the Lighthouse"):
		return false
	boss.apply_focused_light(0.08)
	if not _check(not boss.can_take_boss_damage(), "The boss should be invulnerable during its active strike"):
		return false
	boss.strike_timer = 0.0
	boss._process_last_light(0.01)
	if not _check(boss.strike_state == 3, "The boss should enter a recovery window after its strike"):
		return false
	boss.apply_focused_light(0.08)
	if not _check(boss.can_take_boss_damage(), "The exposed boss should be vulnerable during recovery"):
		return false

	var extra_enemy := SHADOW_SCENE.instantiate()
	manager.active_world.add_child(extra_enemy)
	boss.health = 1
	boss.apply_focused_light(0.08)
	boss.damage_to_enemy(5)
	if not _check(manager.current_state == manager.Phase.VICTORY and victory_count == 1, "Defeating the boss should trigger victory exactly once"):
		return false
	if not _check(manager.get_ending_text().contains("Keeper") and manager.get_ending_text().contains("Veil"), "The ending should resolve the Keeper and Greyreach story"):
		return false
	if not _check(manager.get_current_boss() == null and not manager.complete_campaign(), "Victory must prevent duplicate completion"):
		return false
	manager.game_over()
	if not _check(manager.current_state == manager.Phase.VICTORY and not manager.is_game_over, "Game Over must not overwrite a completed victory"):
		return false
	await process_frame
	await process_frame
	var hud: Node = main.get_node("HUD")
	if not _check(hud.ending_overlay.visible, "Victory should display the campaign ending screen"):
		return false
	if not _check(get_nodes_in_group("enemy").is_empty() and not is_instance_valid(extra_enemy), "Victory should clean up the boss and all remaining enemies"):
		return false
	hud.call("_on_restart_campaign_pressed")
	await process_frame
	if not _check(manager.current_state == manager.Phase.DAY and manager.active_boss == null and not manager.boss_spawned and not manager.victory_triggered and manager.get_secured_shard_count() == 0, "Restart after victory should clear boss and campaign state"):
		return false
	main.queue_free()
	await process_frame
	return true


func _test_wide_radiance_finale() -> bool:
	var context: Dictionary = await _open_finale(&"wide_radiance")
	if context.is_empty():
		return false
	var main: Node = context.main
	var manager: Node = context.manager
	var boss: Node = context.boss
	var lighthouse: Node = manager.get_current_lighthouse()
	var beam: Node = lighthouse.get_node("LighthouseBeam")
	await process_frame
	if not _check(is_equal_approx(manager.get_beam_range_multiplier(), 1.3) and beam.effective_beam_range > beam.beam_range, "Wide Radiance should extend the Lighthouse beam for group control"):
		return false
	var shadow := SHADOW_SCENE.instantiate()
	manager.active_world.add_child(shadow)
	shadow.global_position = lighthouse.global_position + Vector2(0.0, -205.0)
	beam.rotation = -PI * 0.5
	beam.sweep_speed = 0.0
	await physics_frame
	await physics_frame
	beam.effect_timer = 0.0
	beam.call("_process", 0.21)
	if not _check(shadow.movement_slow_factor < 1.0, "The widened Lighthouse sweep should control a summoned shadow"):
		return false
	manager.begin_new_campaign()
	await process_frame
	if not _check(manager.current_state == manager.Phase.DAY and manager.get_current_boss() == null and not manager.boss_spawned, "Reset should clear a live boss encounter"):
		return false
	main.queue_free()
	await process_frame
	return true


func _test_steady_light_failure_and_reset() -> bool:
	game_over_count = 0
	var context: Dictionary = await _open_finale(&"steady_light")
	if context.is_empty():
		return false
	var main: Node = context.main
	var manager: Node = context.manager
	var boss: Node = context.boss
	manager.game_over_started.connect(_on_game_over_started)
	var lighthouse: Node = manager.get_current_lighthouse()
	if not _check(is_equal_approx(manager.get_lighthouse_damage_multiplier(), 0.75), "Steady Light should reduce Lighthouse damage"):
		return false
	var health_before: int = lighthouse.health
	boss.call("_perform_lighthouse_strike")
	if not _check(lighthouse.health == health_before - 11, "Steady Light should reduce the boss's 14 damage strike"):
		return false
	lighthouse.health = 10
	manager.record_lighthouse_health(10)
	lighthouse.damage(1000)
	if not _check(manager.current_state == manager.Phase.GAME_OVER and manager.is_game_over and game_over_count == 1, "Lighthouse destruction should enter Game Over exactly once"):
		return false
	await process_frame
	await process_frame
	var hud: Node = main.get_node("HUD")
	if not _check(hud.ending_overlay.visible and get_nodes_in_group("enemy").is_empty(), "Game Over should show its ending screen and clear remaining enemies"):
		return false
	if not _check(paused, "Game Over should pause gameplay after presenting the failure state"):
		return false
	hud.call("_on_restart_campaign_pressed")
	await process_frame
	if not _check(not paused and manager.current_state == manager.Phase.DAY and not manager.is_game_over, "Restart after failure should resume a clean campaign"):
		return false
	if not _check(manager.active_boss == null and not manager.boss_spawned and not manager.victory_triggered and manager.selected_lens == &"", "Failure reset should not retain boss or lens state"):
		return false
	if not _check(not hud.ending_overlay.visible, "Restart should dismiss the failure screen"):
		return false
	main.queue_free()
	await process_frame
	return true


func _on_victory_started() -> void:
	victory_count += 1


func _on_game_over_started() -> void:
	game_over_count += 1


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("MILESTONE_F_INTEGRATION_TEST: FAIL · " + message)
	quit(1)
	return false
