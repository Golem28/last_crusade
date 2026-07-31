extends Node2D
## CardManager
##
## Handles a hand/board of draggable "Card" nodes (Control-based).
## Attach this to a parent node that contains your card scenes,
## or use it as an autoload/singleton if you manage cards from multiple scenes.
##
## Expects each card to be a Control (or Node2D — see note below) with:
##   - A unique instance for drag state
##   - Optional "card_data" property/dictionary for game logic
##
## Drop zones are any node in the "drop_zone" group with a get_rect()/global rect
## you can test against, or you can swap in your own zone detection.

class_name CardManager

signal card_picked_up(card: Control)
signal card_dropped(card: Control, drop_zone: Node)
signal card_drag_cancelled(card: Control)

@export var drag_z_index := 100
@export var return_speed := 12.0        # higher = snappier return-to-origin
@export var snap_to_drop_zone := true
@export var hover_scale := 1.05
@export var drag_scale := 1.1

var _dragging_card: Control = null
var _drag_offset := Vector2.ZERO
var _origin_position := Vector2.ZERO
var _origin_parent: Node = null
var _origin_z_index := 0

func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)


## Call this from each card's _ready(), or connect these from the card
## scene itself via `card_manager.register_card(self)`.
func register_card(card: Control) -> void:
	if not card.gui_input.is_connected(_on_card_gui_input):
		card.gui_input.connect(_on_card_gui_input.bind(card))
	if not card.mouse_entered.is_connected(_on_card_mouse_entered):
		card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
	if not card.mouse_exited.is_connected(_on_card_mouse_exited):
		card.mouse_exited.connect(_on_card_mouse_exited.bind(card))

func _on_card_mouse_entered(card: Control) -> void:
	if _dragging_card == null:
		var tw := card.create_tween()
		tw.tween_property(card, "scale", Vector2.ONE * hover_scale, 0.1)

func _on_card_mouse_exited(card: Control) -> void:
	if _dragging_card != card:
		var tw := card.create_tween()
		tw.tween_property(card, "scale", Vector2.ONE, 0.1)

func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drag(card)
			else:
				_end_drag(card)

func _start_drag(card: Control) -> void:
	if _dragging_card != null:
		return

	_dragging_card = card
	_origin_position = card.position
	_origin_parent = card.get_parent()
	_origin_z_index = card.z_index

	_drag_offset = card.get_global_mouse_position() - card.global_position
	card.z_index = drag_z_index

	var tw := card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE * drag_scale, 0.08)

	card_picked_up.emit(card)

func _process(_delta: float) -> void:
	if _dragging_card:
		# Follow the mouse while dragging.
		_dragging_card.global_position = get_viewport().get_mouse_position() - _drag_offset

func _end_drag(card: Control) -> void:
	if _dragging_card != card:
		return

	var drop_zone := _find_drop_zone_under(card)

	var tw := card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.1)

	if drop_zone:
		_handle_valid_drop(card, drop_zone)
	else:
		_return_to_origin(card)

	_dragging_card = null

func _handle_valid_drop(card: Control, drop_zone: Node) -> void:
	if snap_to_drop_zone and drop_zone.has_method("get_card_anchor_position"):
		var target_pos: Vector2 = drop_zone.get_card_anchor_position()
		card.reparent(drop_zone)
		var tw := card.create_tween()
		tw.tween_property(card, "global_position", target_pos, 0.15)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	card.z_index = _origin_z_index
	card_dropped.emit(card, drop_zone)

func _return_to_origin(card: Control) -> void:
	var tw := card.create_tween()
	tw.tween_property(card, "position", _origin_position, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		card.z_index = _origin_z_index
		card_drag_cancelled.emit(card)
	)

func _find_drop_zone_under(card: Control) -> Node:
	var zones := get_tree().get_nodes_in_group("drop_zone")
	var card_center := card.global_position + card.size * 0.5

	for zone in zones:
		if zone is Control:
			var rect: Rect2 = (zone as Control).get_global_rect()
			if rect.has_point(card_center):
				return zone
		elif zone.has_method("get_drop_rect"):
			var rect2: Rect2 = zone.get_drop_rect()
			if rect2.has_point(card_center):
				return zone

	return null
