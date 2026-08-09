extends ColorRect

class_name DropZone

enum ZONE_TYPE {FRONT, FLANK, REAR}
enum SIDE {PLAYER, ENEMY}

var _drop_zone_type := ZONE_TYPE.FRONT
var _side := SIDE.PLAYER

var row := 0
var column := 0
@export var zone_size := Vector2(100, 100)

var _base_color := Color.WHITE

## Assigned by the GameBoard based on the zone's index in the 6x3 grid.
func configure(board_index: int) -> void:
	row = int(board_index / 3.0)
	column = board_index % 3
	_side = SIDE.ENEMY if row < 3 else SIDE.PLAYER
	_drop_zone_type = _type_for_row(row)
	_base_color = Color(0.42, 0.25, 0.3, 1) if _side == SIDE.ENEMY else Color(0.32, 0.37, 0.52, 1)
	color = _base_color

## Brightens the zone while its row is the current topic.
func set_topic_highlight(is_topic: bool) -> void:
	color = _base_color.lightened(0.35) if is_topic else _base_color

func _type_for_row(r: int) -> ZONE_TYPE:
	match r:
		0, 5:
			return ZONE_TYPE.REAR
		1, 4:
			return ZONE_TYPE.FLANK
		_:
			return ZONE_TYPE.FRONT

## Rank 0 is the front line (closest to the enemy boundary).
## Higher ranks are further back on either side.
func get_front_rank() -> int:
	if _side == SIDE.ENEMY:
		return 2 - row
	return row - 3

func get_drop_rect() -> Rect2:
	return Rect2(global_position - zone_size * 0.5, zone_size)

func get_card_anchor_position() -> Vector2:
	return global_position

func get_drop_zone_type() -> ZONE_TYPE:
	return _drop_zone_type

func is_enemy() -> bool:
	return _side == SIDE.ENEMY

func is_player() -> bool:
	return _side == SIDE.PLAYER

func is_occupied() -> bool:
	return get_child_count() > 0
