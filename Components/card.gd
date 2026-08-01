class_name Card
extends Dragable

var _acted: bool = false

@export var card_data: Dictionary = {}

func _ready() -> void:
	GameManager.turn_started.connect(func(): _acted = false)
	_setup_card_data()
	super._ready()

func handle_valid_drop(drop_zone: DropZone) -> void:
	_acted = true
	
	super.handle_valid_drop(drop_zone)

	self.custom_minimum_size = Vector2(120, 120)
	self.set_size(Vector2(120, 120))
	
	var drop_zone_type := drop_zone.get_drop_zone_type()
	
	(get_node("Content/Front") as Control).visible = drop_zone_type == DropZone.ZONE_TYPE.FRONT
	(get_node("Content/Flank") as Control).visible = drop_zone_type == DropZone.ZONE_TYPE.FLANK
	(get_node("Content/Rear") as Control).visible = drop_zone_type == DropZone.ZONE_TYPE.REAR

func _setup_card_data() -> void:
	var front_label = get_node("Content/Front/Label")
	var support_label = get_node("Content/Flank/Label")
	var range_label = get_node("Content/Rear/Label")
	(front_label as RichTextLabel).text = card_data.get("front_label", "")
	(support_label as RichTextLabel).text = card_data.get("support_label", "")
	(range_label as RichTextLabel).text = card_data.get("range_label", "")

func acted_this_turn() -> bool:
	return _acted
