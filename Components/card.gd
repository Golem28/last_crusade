class_name Card
extends Dragable

var _acted: bool = false

@export var card_data: Dictionary = {}

func _ready() -> void:
	GameManager.turn_started.connect(func(): _acted = false)
	_setup_card_data()

func start_drag() -> void:
	_acted = true
	super.start_drag()

func _setup_card_data() -> void:
	var front_label = get_node("HoverControl/Front/Label")
	var support_label = get_node("HoverControl/Flank/Label")
	var range_label = get_node("HoverControl/Rear/Label")
	(front_label as RichTextLabel).text = card_data.get("front_label", "")
	(support_label as RichTextLabel).text = card_data.get("support_label", "")
	(range_label as RichTextLabel).text = card_data.get("range_label", "")

func acted_this_turn() -> bool:
	return _acted
