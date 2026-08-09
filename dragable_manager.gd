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
var _attack_selection: Card = null
var _attack_targets: Array[Card] = []
var _click_potential := false
var _press_position := Vector2.ZERO

func _ready() -> void:
	GameManager.turn_started.connect(_clear_attack_selection)
	GameManager.actions_changed.connect(func(_remaining: int) -> void:
		if GameManager.actions_remaining <= 0:
			_clear_attack_selection()
	)

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
				_on_card_pressed(card)
			else:
				_on_card_released(card)

func _on_card_pressed(card: Control) -> void:
	if _dragging_dragable != null:
		return

	if card is Card:
		var clicked := card as Card
		if clicked.is_enemy:
			# Enemies can't be dragged. In attack mode, clicking a highlighted
			# enemy attacks it; otherwise the click just clears the selection.
			if _attack_selection != null and _attack_targets.has(clicked):
				_resolve_attack(_attack_selection, clicked)
			else:
				_clear_attack_selection()
			return

	_clear_attack_selection()
	if _is_card_fixed(card as Card):
		return

	_click_potential = true
	_press_position = card.global_position
	_dragging_dragable = card
	card.start_drag()
	card_picked_up.emit(card)

func _on_card_released(card: Control) -> void:
	if _dragging_dragable != card:
		return

	_dragging_dragable = null
	card.end_drag()

	# A release that barely moved the mouse is a click, not a drag.
	if _click_potential:
		_click_potential = false
		if card.get_parent() is DropZone:
			_select_for_attack(card as Card)
			# The card was nudged to follow the mouse while pressed; put it
			# back on its drop zone so the selection doesn't leave it askew.
			card.return_to_origin()
		return

	var drop_zone: DropZone = _find_drop_zone_under(card)

	# Moving an already placed card is allowed on every row; placing a card
	# from the hand is limited to the current row topic.
	var is_move := card.get_parent() is DropZone

	if drop_zone and !drop_zone.is_occupied() and !drop_zone.is_enemy() \
			and (is_move or drop_zone.get_drop_zone_type() == GameManager.row_topic) \
			and GameManager.try_spend(1):
		card.handle_valid_drop(drop_zone)
		card_dropped.emit(card, drop_zone)
	else:
		card.return_to_origin()
		card_drag_cancelled.emit(card)

## Enters attack mode for a placed player card that hasn't acted this turn,
## highlighting every enemy it can hit. Only cards standing in the active
## row may attack.
func _select_for_attack(card: Card) -> void:
	var zone := card.get_drop_zone()
	if zone == null or zone.get_drop_zone_type() != GameManager.row_topic:
		return
	# Melee cards only fight from the front of their column.
	if not card.has_range and not _game_board().is_front_of_column(card):
		return

	var targets := _game_board().get_attackable_targets(card)
	if targets.is_empty():
		return

	_clear_attack_selection()
	_attack_selection = card
	_attack_targets = targets
	card.set_selected(true)
	for target in targets:
		target.set_attack_target(true)

func _resolve_attack(attacker: Card, target: Card) -> void:
	if GameManager.try_spend(1):
		attacker.mark_acted()
		target.take_damage(attacker.attack)
	_clear_attack_selection()

func _clear_attack_selection() -> void:
	if _attack_selection != null and is_instance_valid(_attack_selection):
		_attack_selection.set_selected(false)
	for target in _attack_targets:
		if is_instance_valid(target):
			target.set_attack_target(false)
	_attack_selection = null
	_attack_targets.clear()

func _game_board() -> GameBoard:
	return get_tree().get_first_node_in_group("game_board") as GameBoard

func _process(_delta: float) -> void:
	if _dragging_dragable:
		_dragging_dragable.hover_update()
		# A drag that actually moves the card is not a click anymore.
		if _click_potential and _dragging_dragable.global_position.distance_to(_press_position) > 10.0:
			_click_potential = false

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
