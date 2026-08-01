extends Control
class_name Card

var _acted: bool = false
@export var card_data: Dictionary = {}

func _ready() -> void:
	var card_mng = get_node("/root/Game/CardManager")
	card_mng.register_card(self)
	GameManager.turn_started.connect(func(): _acted = false)
	_setup_card_data()

func handle_valid_drop(drop_zone: DropZone, origin_z_index: int) -> void:
	_acted = true
	var target_pos: Vector2 = drop_zone.get_card_anchor_position()
	self.reparent(drop_zone)
	var tw := self.create_tween()
	tw.tween_property(self, "global_position", target_pos, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	self.z_index = origin_z_index

func _setup_card_data() -> void:
	var front_label = get_child(4)
	var support_label = get_child(5)
	var range_label = get_child(6)
	(front_label as RichTextLabel).text = card_data["front_label"]
	(support_label as RichTextLabel).text = card_data["support_label"]
	(range_label as RichTextLabel).text = card_data["range_label"]

func acted_this_turn() -> bool:
	return _acted
