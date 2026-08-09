class_name Card
extends Dragable

var _acted: bool = false
var is_enemy := false

@export var card_data: Dictionary = {}

var card_name := ""
var attack := 0
var health := 1
var has_range := false

var _is_selected := false
var _is_attack_target := false
var _highlight: ColorRect = null

func _ready() -> void:
	GameManager.turn_started.connect(func(): _acted = false)
	_parse_card_data()
	_setup_card_data()
	_make_children_input_pass_through()
	_highlight = get_node("Highlight")

	if is_enemy:
		_apply_zone_display()

	super._ready()

## Let the card root handle all mouse input so clicks work on every part of
## the card (children are purely visual).
func _make_children_input_pass_through() -> void:
	_set_input_pass_through(self)

func _set_input_pass_through(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_input_pass_through(child)

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

	# A card's role follows the row it stands in: the rear line fights at
	# range, the front and flank lines fight in melee.
	has_range = zone.get_drop_zone_type() == DropZone.ZONE_TYPE.REAR

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

func mark_acted() -> void:
	_acted = true

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_highlight()

func set_attack_target(is_target: bool) -> void:
	_is_attack_target = is_target
	_update_highlight()

func _update_highlight() -> void:
	if _highlight == null:
		return
	if _is_attack_target:
		_highlight.color = Color(1, 0.2, 0.2, 0.5)
		_highlight.visible = true
	elif _is_selected:
		_highlight.color = Color(1, 0.8, 0.1, 0.4)
		_highlight.visible = true
	else:
		_highlight.visible = false

## Enemy cards this card may attack this turn:
## ranged can hit anything, melee only hits the enemy front line.
func get_attackable_targets() -> Array[Card]:
	var board := get_tree().get_first_node_in_group("game_board")
	if board == null:
		return []
	return (board as GameBoard).get_attackable_targets(self)
