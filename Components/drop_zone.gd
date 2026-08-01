extends ColorRect

class_name DropZone

enum ZONE_TYPE {FRONT, FLANK, REAR}

@export var zone_size := Vector2(100, 140)

func get_drop_rect() -> Rect2:
	return Rect2(global_position - zone_size * 0.5, zone_size)

func get_card_anchor_position() -> Vector2:
	return global_position

func get_drop_zone_type() -> ZONE_TYPE:
	var values := ZONE_TYPE.values()
	return values[randi() % ZONE_TYPE.size()]

func is_occupied() -> bool:
	return get_child_count() > 0
