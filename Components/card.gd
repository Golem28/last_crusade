class_name Card
extends Dragable

var _acted: bool = false

@export var card_data: Dictionary = {}

func _ready() -> void:
	var card_mng = get_node("/root/Game/CardManager")
	card_mng.register_card(self)
	GameManager.turn_started.connect(func(): _acted = false)
	_setup_card_data()

func start_drag() -> void:
	_acted = true
	super.start_drag()

func _setup_card_data() -> void:
	var front_label = get_child(4)
	var support_label = get_child(5)
	var range_label = get_child(6)
	(front_label as RichTextLabel).text = card_data["front_label"]
	(support_label as RichTextLabel).text = card_data["support_label"]
	(range_label as RichTextLabel).text = card_data["range_label"]

func acted_this_turn() -> bool:
	return _acted
