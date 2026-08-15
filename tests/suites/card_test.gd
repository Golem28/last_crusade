extends "res://tests/test_case.gd"

const CARD_SCENE := preload("res://Components/card.tscn")

var _card: Card

func before_each() -> void:
	GameManager.actions_remaining = GameManager.MAX_ACTIONS
	GameManager.row_topic = DropZone.ZONE_TYPE.REAR
	if is_instance_valid(_card):
		_card.free()
	_card = _new_card({"name": "Test", "attack": 3, "health": 9, "has_range": false})
	add_child(_card)

func _new_card(data: Dictionary) -> Card:
	var card := CARD_SCENE.instantiate() as Card
	card.card_data = data
	return card

func test_parses_card_data() -> void:
	assert_eq(_card.card_name, "Test", "name parsed")
	assert_eq(_card.attack, 3, "attack parsed")
	assert_eq(_card.health, 9, "health parsed")
	assert_true(not _card.has_range, "range flag parsed")

func test_take_damage_updates_health_and_label() -> void:
	_card.take_damage(2)
	assert_eq(_card.health, 7, "health reduced")
	var label := _card.get_node("Content/Heading/Health/Label") as RichTextLabel
	assert_eq(label.text, "7", "health label updated")

func test_lethal_damage_frees_card() -> void:
	_card.take_damage(9)
	assert_eq(_card.health, 0, "health cannot go below zero")
	await get_tree().process_frame
	assert_true(not is_instance_valid(_card), "card is freed on lethal damage")

func test_acted_flag_resets_on_new_turn() -> void:
	_card.mark_acted()
	assert_true(_card.acted_this_turn(), "acted after mark_acted")
	GameManager.turn_started.emit()
	assert_true(not _card.acted_this_turn(), "acted cleared on turn start")
