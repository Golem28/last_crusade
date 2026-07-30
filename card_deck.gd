extends Node

func _on_deck_pressed() -> void:
	var hand = get_node("/root/Game/Hand")
	var scene_file: PackedScene = load("res://Components/card.tscn")
	var scene_instance: Node = scene_file.instantiate()
	hand.add_child(scene_instance)
