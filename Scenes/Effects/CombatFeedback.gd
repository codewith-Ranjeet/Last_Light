extends RefCounted
class_name CombatFeedback

const BURST_SCENE: PackedScene = preload("res://Scenes/Effects/CombatBurst.tscn")


static func burst(parent: Node, world_position: Vector2, tint: Color, radius: float = 18.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var effect := BURST_SCENE.instantiate()
	effect.configure(tint, radius)
	parent.add_child(effect)
	effect.global_position = world_position
