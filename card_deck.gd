extends Node

func _on_deck_pressed() -> void:
	if GameManager.try_spend(1):
		_draw_card()

func _draw_card() -> void:
	var hand = get_node("/root/Game/Hand")
	var scene_file: PackedScene = load("res://Components/card.tscn")
	var scene_instance: Node = scene_file.instantiate()
	(scene_instance as Card).card_data = {
		"name": "Mystic",
		"front_label": "Attack 3, Melee",
		"support_label": "Activate a character in the front line",
		"range_label": "Attack 2, Ranged",
		"attack": 3,
		"health": 9,
		"has_range": false
	}
	hand.add_child(scene_instance)
