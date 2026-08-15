extends "res://tests/test_case.gd"

const DROP_ZONE_SCENE := preload("res://Components/drop_zone.tscn")
const CARD_SCENE := preload("res://Components/card.tscn")

var _zone: DropZone

func before_each() -> void:
	if is_instance_valid(_zone):
		_zone.free()
	_zone = DROP_ZONE_SCENE.instantiate() as DropZone
	add_child(_zone)
	_zone.configure(0)

func test_configure_index_zero() -> void:
	assert_eq(_zone.row, 0, "row 0")
	assert_eq(_zone.column, 0, "column 0")
	assert_true(_zone.is_enemy(), "enemy side for top half")
	assert_eq(_zone.get_drop_zone_type(), DropZone.ZONE_TYPE.REAR, "top row is rear")
	assert_eq(_zone.get_front_rank(), 2, "top row is furthest from the front")

func test_configure_front_enemy_row() -> void:
	_zone.configure(7)
	assert_eq(_zone.row, 2, "row 2")
	assert_eq(_zone.column, 1, "column 1")
	assert_true(_zone.is_enemy(), "still enemy side")
	assert_eq(_zone.get_drop_zone_type(), DropZone.ZONE_TYPE.FRONT, "row 2 is front")
	assert_eq(_zone.get_front_rank(), 0, "row 2 is rank 0")

func test_configure_player_front_row() -> void:
	_zone.configure(9)
	assert_eq(_zone.row, 3, "row 3")
	assert_true(_zone.is_player(), "player side for bottom half")
	assert_eq(_zone.get_drop_zone_type(), DropZone.ZONE_TYPE.FRONT, "row 3 is front")
	assert_eq(_zone.get_front_rank(), 0, "row 3 is rank 0")

func test_configure_player_rear_row() -> void:
	_zone.configure(17)
	assert_eq(_zone.row, 5, "row 5")
	assert_true(_zone.is_player(), "player side")
	assert_eq(_zone.get_drop_zone_type(), DropZone.ZONE_TYPE.REAR, "bottom row is rear")
	assert_eq(_zone.get_front_rank(), 2, "bottom row is furthest back")

func test_front_rank_matrix() -> void:
	var expected := [2, 1, 0, 0, 1, 2]
	for board_index in 18:
		var zone := DROP_ZONE_SCENE.instantiate() as DropZone
		add_child(zone)
		zone.configure(board_index)
		assert_eq(zone.get_front_rank(), expected[board_index / 3], "rank for index %d" % board_index)

func test_type_per_row() -> void:
	for board_index in 18:
		var zone := DROP_ZONE_SCENE.instantiate() as DropZone
		add_child(zone)
		zone.configure(board_index)
		var row := board_index / 3
		var expected_type: int
		match row:
			0, 5:
				expected_type = DropZone.ZONE_TYPE.REAR
			1, 4:
				expected_type = DropZone.ZONE_TYPE.FLANK
			_:
				expected_type = DropZone.ZONE_TYPE.FRONT
		assert_eq(zone.get_drop_zone_type(), expected_type, "type for row %d" % row)

func test_is_occupied_tracks_children() -> void:
	assert_true(not _zone.is_occupied(), "empty zone is not occupied")
	_zone.add_child(CARD_SCENE.instantiate())
	assert_true(_zone.is_occupied(), "zone with a card is occupied")

func test_topic_highlight_brightens_then_restores() -> void:
	var base := _zone.color
	_zone.set_topic_highlight(true)
	assert_eq(_zone.color, base.lightened(0.35), "topic zone brightens")
	_zone.set_topic_highlight(false)
	assert_eq(_zone.color, base, "non-topic zone restores base color")
