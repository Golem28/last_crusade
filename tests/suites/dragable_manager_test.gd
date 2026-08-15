extends "res://tests/test_case.gd"

const CARD_SCENE := preload("res://Components/card.tscn")

var _game: Node2D
var _board: GameBoard

func before_each() -> void:
	GameManager.actions_remaining = GameManager.MAX_ACTIONS
	GameManager.row_topic = DropZone.ZONE_TYPE.REAR
	DragableManager._attack_selection = null
	DragableManager._attack_targets = []
	DragableManager._dragging_dragable = null
	DragableManager._click_potential = false
	if is_instance_valid(_game):
		_game.free()
	_game = load("res://game.tscn").instantiate()
	add_child(_game)
	_board = _game.get_node("Board") as GameBoard

func _place_player_card(zone_index: int, has_range: bool) -> Card:
	var zone := _board.get_zones()[zone_index]
	var card := CARD_SCENE.instantiate() as Card
	card.card_data = {"name": "Hero", "attack": 3, "health": 9, "has_range": has_range}
	zone.add_child(card)
	return card

func _highlighted_enemy_count() -> int:
	var count := 0
	for enemy in _board.get_enemy_cards():
		var highlight := enemy.get_node("Highlight") as ColorRect
		if highlight.visible:
			count += 1
	return count

func test_select_for_attack_highlights_front_enemies() -> void:
	var card := _place_player_card(9, false)
	DragableManager._select_for_attack(card)
	assert_eq(_highlighted_enemy_count(), 3, "melee attacker highlights three front enemies")
	var highlight := card.get_node("Highlight") as ColorRect
	assert_true(highlight.visible, "attacker is highlighted as selected")

func test_clicking_highlighted_enemy_attacks() -> void:
	var card := _place_player_card(9, false)
	DragableManager._select_for_attack(card)
	var target := _board.get_attackable_targets(card)[0]
	var before: int = target.health
	DragableManager._on_card_pressed(target)
	assert_eq(target.health, before - card.attack, "enemy takes the attacker's damage")
	assert_eq(GameManager.actions_remaining, 1, "attack costs one action")
	assert_true(card.acted_this_turn(), "attacker has acted this turn")

func test_resolve_attack_deals_damage() -> void:
	var card := _place_player_card(9, false)
	var target := _board.get_attackable_targets(card)[0]
	var before: int = target.health
	DragableManager._resolve_attack(card, target)
	assert_eq(target.health, before - card.attack, "enemy takes damage")
	assert_eq(GameManager.actions_remaining, 1, "attack spends one action")

func test_move_placed_card_to_empty_zone() -> void:
	var card := _place_player_card(9, false)
	card.anchor_left = 0.0
	card.anchor_right = 0.0
	card.anchor_top = 0.0
	card.anchor_bottom = 0.0
	card.size = Vector2(100, 100)
	var drop := _board.get_zones()[10]
	var drop_center: Vector2 = drop.get_global_rect().get_center()
	card.global_position = drop_center - card.size * 0.5
	DragableManager._dragging_dragable = card
	DragableManager._click_potential = false
	DragableManager._on_card_released(card)
	assert_eq(card.get_parent(), drop, "card moved into the empty zone")
	assert_true(card.acted_this_turn(), "move marks the card as acted")
	assert_eq(GameManager.actions_remaining, 1, "move spends one action")
