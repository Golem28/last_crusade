extends "res://tests/test_case.gd"

const CARD_SCENE := preload("res://Components/card.tscn")

var _game: Node2D
var _board: GameBoard

func before_each() -> void:
	GameManager.actions_remaining = GameManager.MAX_ACTIONS
	GameManager.row_topic = DropZone.ZONE_TYPE.REAR
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

func test_board_has_eighteen_zones() -> void:
	assert_eq(_board.get_zones().size(), 18, "6x3 grid")

func test_three_columns() -> void:
	assert_eq(_board.columns, 3, "three columns")

func test_zone_sides_are_balanced() -> void:
	assert_eq(_board.get_enemy_zones().size(), 9, "nine enemy zones")
	assert_eq(_board.get_player_zones().size(), 9, "nine player zones")

func test_enemies_are_spawned() -> void:
	var enemies := _board.get_enemy_cards()
	assert_eq(enemies.size(), 9, "one enemy per enemy zone")
	for enemy in enemies:
		assert_true(enemy.is_enemy, "spawned card is an enemy")

func test_melee_targets_one_enemy_per_column() -> void:
	var attacker := _place_player_card(9, false)
	var targets := _board.get_attackable_targets(attacker)
	assert_eq(targets.size(), 3, "melee hits the front enemy of each column")

func test_ranged_targets_every_enemy() -> void:
	var attacker := _place_player_card(9, true)
	var targets := _board.get_attackable_targets(attacker)
	assert_eq(targets.size(), 9, "ranged can hit any enemy")

func test_is_front_of_column() -> void:
	var front := _place_player_card(9, false)
	var back := _place_player_card(12, false)
	assert_true(_board.is_front_of_column(front), "front-line card is front of column")
	assert_true(not _board.is_front_of_column(back), "card behind the front line is not")

func test_enemies_attack_only_in_active_row() -> void:
	var card := _place_player_card(9, false)
	GameManager.turn_ended.emit()
	assert_eq(card.health, 5, "two grunts deal 4 damage to the front player card")
