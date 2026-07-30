extends ColorRect

@export var zone_size := Vector2(100, 140)

func get_drop_rect() -> Rect2:
	return Rect2(global_position - zone_size * 0.5, zone_size)

func get_card_anchor_position() -> Vector2:
	return global_position
