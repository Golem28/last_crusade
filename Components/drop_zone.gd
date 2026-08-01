extends ColorRect

class_name DropZone

enum ZONE_TYPE {FRONT, FLANK, REAR}

var _drop_zone_type := ZONE_TYPE.FRONT
@export var zone_size := Vector2(100, 140)

func _ready() -> void:
	var values := ZONE_TYPE.values()
	_drop_zone_type = values[randi() % ZONE_TYPE.size()]

func get_drop_rect() -> Rect2:
	return Rect2(global_position - zone_size * 0.5, zone_size)

func get_card_anchor_position() -> Vector2:
	return global_position

func get_drop_zone_type() -> ZONE_TYPE:
	return _drop_zone_type

func is_occupied() -> bool:
	return get_child_count() > 0
