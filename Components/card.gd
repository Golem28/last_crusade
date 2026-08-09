class_name Card
extends Dragable

var _acted: bool = false
var is_enemy := false

@export var card_data: Dictionary = {}

var card_name := ""
var attack := 0
var health := 1
var has_range := false

func _ready() -> void:
	GameManager.turn_started.connect(func(): _acted = false)
	_parse_card_data()
	_setup_card_data()

	if is_enemy:
		_apply_zone_display()
	else:
		super._ready()

func _parse_card_data() -> void:
	card_name = card_data.get("name", "Mystic")
	attack = card_data.get("attack", 1)
	health = card_data.get("health", 1)
	has_range = card_data.get("has_range", false)

func _setup_card_data() -> void:
	var front_label = get_node("Content/Front/Label")
	var support_label = get_node("Content/Flank/Label")
	var range_label = get_node("Content/Rear/Label")
	(front_label as RichTextLabel).text = card_data.get("front_label", "")
	(support_label as RichTextLabel).text = card_data.get("support_label", "")
	(range_label as RichTextLabel).text = card_data.get("range_label", "")
	(get_node("Content/Heading/Label") as Label).text = card_name
	(get_node("Content/Heading/Attack/Label") as RichTextLabel).text = str(attack)
	(get_node("Content/Heading/Health/Label") as RichTextLabel).text = str(health)

func handle_valid_drop(drop_zone: DropZone) -> void:
	_acted = true

	super.handle_valid_drop(drop_zone)

	_apply_zone_display()

func _apply_zone_display() -> void:
	self.custom_minimum_size = Vector2(100, 100)
	self.set_size(Vector2(100, 100))

	var zone := get_drop_zone()
	if zone == null:
		return

	self.global_position = zone.global_position

	(get_node("Content/Front") as Control).visible = zone.get_drop_zone_type() == DropZone.ZONE_TYPE.FRONT
	(get_node("Content/Flank") as Control).visible = zone.get_drop_zone_type() == DropZone.ZONE_TYPE.FLANK
	(get_node("Content/Rear") as Control).visible = zone.get_drop_zone_type() == DropZone.ZONE_TYPE.REAR

func get_drop_zone() -> DropZone:
	return get_parent() as DropZone

func take_damage(amount: int) -> void:
	health -= amount
	(get_node("Content/Heading/Health/Label") as RichTextLabel).text = str(max(health, 0))
	if health <= 0:
		queue_free()

func acted_this_turn() -> bool:
	return _acted
