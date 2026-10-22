extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://Scenes/main.tscn") as PackedScene
	assert(main_scene != null, "Main scene should load")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var manager: Node = main.get_node("GameManager")
	manager.day_number = 2
	manager.current_state = manager.Phase.DAY
	var old_player: Node = main.get_node("WorldContainer/LighthouseYard/Player")
	var board: Node = main.get_node("WorldContainer/LighthouseYard/ExpeditionBoard")
	old_player.call("_interact_with", board)
	assert(is_instance_valid(old_player), "Old player should remain available until the frame ends")
	assert(not old_player.is_inside_tree(), "World replacement should detach the original player")
	await process_frame

	assert(manager.current_state == manager.Phase.EXPEDITION, "Board interaction should enter expedition phase")
	assert(manager.active_world.scene_file_path.ends_with("ShipbreakerBeach.tscn"), "Board should load Shipbreaker Beach")
	assert(manager.active_world.get_node_or_null("Player") != null, "Shipbreaker Beach should have an active player")
	print("SHIPBREAKER_EXPEDITION_TEST: PASS")
	quit(0)
