extends Node

func _ready() -> void:
	_diag_lambda_direct()
	await _diag_lambda_async()
	_diag_dragable_geometry()
	get_tree().quit(0)

func _diag_lambda_direct() -> void:
	print("--- lambda capture (no await) ---")
	var rejected := false
	GameManager.action_rejected.connect(func(_reason: String) -> void: rejected = true, CONNECT_ONE_SHOT)
	GameManager.actions_remaining = 1
	print("  before try_spend, rejected=", rejected)
	var ok := GameManager.try_spend(2)
	print("  try_spend returned ", ok, ", rejected=", rejected)

func _diag_lambda_async() -> void:
	print("--- lambda capture (with await) ---")
	var turns := 0
	GameManager.turn_started.connect(func() -> void: turns += 1)
	GameManager.actions_remaining = GameManager.MAX_ACTIONS
	GameManager.try_spend(1)
	GameManager.try_spend(1)
	print("  after spends, actions=", GameManager.actions_remaining)
	await get_tree().process_frame
	print("  after frame, actions=", GameManager.actions_remaining, ", turns=", turns)

func _diag_dragable_geometry() -> void:
	print("--- dragable move geometry ---")
	GameManager.actions_remaining = GameManager.MAX_ACTIONS
	GameManager.row_topic = DropZone.ZONE_TYPE.REAR
	DragableManager._attack_selection = null
	DragableManager._attack_targets = []
	DragableManager._dragging_dragable = null
	DragableManager._click_potential = false
	var game := load("res://game.tscn").instantiate()
	add_child(game)
	var board := game.get_node("Board") as GameBoard
	var zones := board.get_zones()
	var zone9 := zones[9]
	var zone10 := zones[10]
	var card: Card = preload("res://Components/card.tscn").instantiate()
	card.card_data = {"name": "Hero", "attack": 3, "health": 9, "has_range": false}
	zone9.add_child(card)
	card.anchor_left = 0.0
	card.anchor_right = 0.0
	card.anchor_top = 0.0
	card.anchor_bottom = 0.0
	card.size = Vector2(100, 100)
	print("  card.size = ", card.size)
	print("  card.global_position = ", card.global_position)
	var drop_center: Vector2 = zone10.get_global_rect().get_center()
	print("  zone10 rect = ", zone10.get_global_rect())
	print("  zone10 center = ", drop_center)
	card.global_position = drop_center - card.size * 0.5
	print("  after set: card.global_position = ", card.global_position)
	print("  card.get_global_rect() = ", card.get_global_rect())
	var card_center := card.global_position + card.size * 0.5
	print("  card_center = ", card_center)
	print("  zone10.contains(card_center) = ", zone10.get_global_rect().has_point(card_center))
	print("  zone10 occupied=", zone10.is_occupied(), " enemy=", zone10.is_enemy())
	var zones_containing := 0
	for z in board.get_nodes_in_group("drop_zone"):
		if (z as DropZone).get_global_rect().has_point(card_center):
			zones_containing += 1
			print("    contains: ", z)
	print("  zones containing card_center: ", zones_containing)
	DragableManager._dragging_dragable = card
	DragableManager._click_potential = false
	var under := DragableManager._find_drop_zone_under(card)
	print("  _find_drop_zone_under = ", under)
