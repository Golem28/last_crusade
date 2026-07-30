extends Control
class_name Card

var card_data: Dictionary = {}

func _ready() -> void:
	var card_mng = get_node("/root/Game/CardManager")
	card_mng.register_card(self)
