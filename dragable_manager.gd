extends Node2D

## DragableManager
##
## Handles a hand/board of draggable nodes (Control-based).
##
## Expects each dragable to be a Control with:
##   - A unique instance for drag state
##
## Drop zones are any node in the "drop_zone" group with a get_rect()/global rect
## you can test against, or you can swap in your own zone detection.

signal card_picked_up(card: Dragable)
signal card_dropped(card: Dragable, drop_zone: Node)
signal card_drag_cancelled(card: Dragable)

var _dragging_dragable: Dragable = null

## Call this from each card's _ready(), or connect these from the card
## scene itself via `card_manager.register_card(self)`.
func register_card(card: Control) -> void:
	if not card.gui_input.is_connected(_on_card_gui_input):
		card.gui_input.connect(_on_card_gui_input.bind(card))
	if not card.mouse_entered.is_connected(_on_card_mouse_entered):
		card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
	if not card.mouse_exited.is_connected(_on_card_mouse_exited):
		card.mouse_exited.connect(_on_card_mouse_exited.bind(card))

func _on_card_mouse_entered(dragable: Dragable) -> void:
	if _dragging_dragable == null and !_is_card_fixed(dragable):
		dragable.start_hover()

func _on_card_mouse_exited(dragable: Dragable) -> void:
	if _dragging_dragable != dragable and !_is_card_fixed(dragable):
		dragable.end_hover()

func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drag(card)
			else:
				_end_drag(card)

func _start_drag(dragable: Card) -> void:
	if _dragging_dragable != null:
		return

	if _is_card_fixed(dragable):
		return
	
	_dragging_dragable = dragable
	dragable.start_drag()
	card_picked_up.emit(dragable)

func _process(_delta: float) -> void:
	if _dragging_dragable:
		# Follow the mouse while dragging.
		_dragging_dragable.hover_update()

func _end_drag(dragable: Dragable) -> void:
	if _dragging_dragable != dragable:
		return

	var drop_zone: DropZone = _find_drop_zone_under(dragable)
	dragable.end_drag()

	# Moving an already placed card is allowed on every row; placing a card
	# from the hand is limited to the current row topic.
	var is_move := dragable.get_parent() is DropZone

	if drop_zone and !drop_zone.is_occupied() and !drop_zone.is_enemy() \
			and (is_move or drop_zone.get_drop_zone_type() == GameManager.row_topic) \
			and GameManager.try_spend(1):
		dragable.handle_valid_drop(drop_zone)
		card_dropped.emit(dragable, drop_zone)
	else:
		dragable.return_to_origin()
		card_drag_cancelled.emit(dragable)

	_dragging_dragable = null

func _is_card_fixed(card: Card) -> bool:
	return card.is_enemy or GameManager.actions_remaining == 0 or card.acted_this_turn()

func _find_drop_zone_under(card: Control) -> DropZone:
	var zones := get_tree().get_nodes_in_group("drop_zone")
	var card_center := card.global_position + card.size * 0.5

	for zone in zones:
		if zone is DropZone:
			var rect: Rect2 = (zone as DropZone).get_global_rect()
			if rect.has_point(card_center):
				return zone

	return null
