class_name Dragable
extends Control

@export var drag_z_index := 100
@export var return_speed := 12.0        # higher = snappier return-to-origin
@export var snap_to_drop_zone := true
@export var hover_scale := 1.05
@export var drag_scale := 1.1

var _drag_offset := Vector2.ZERO
var _origin_position := Vector2.ZERO
var _origin_parent: Node = null
var _origin_z_index := 0

func start_hover() -> void:
	var tw := self.create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * hover_scale, 0.1)

func end_hover() -> void:
	var tw := self.create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)

func hover_update() -> void:
	self.global_position = get_viewport().get_mouse_position() - _drag_offset

func start_drag() -> void:
	_origin_position = self.position
	_origin_parent = self.get_parent()
	_origin_z_index = self.z_index

	_drag_offset = self.get_global_mouse_position() - self.global_position
	self.z_index = drag_z_index

	var tw := self.create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * drag_scale, 0.08)

func end_drag() -> void:
	var tw := self.create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)

func handle_valid_drop(drop_zone: DropZone) -> void:
	var target_pos: Vector2 = drop_zone.get_card_anchor_position()
	self.reparent(drop_zone)
	var tw := self.create_tween()
	tw.tween_property(self, "global_position", target_pos, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	self.z_index = _origin_z_index

func return_to_origin() -> void:
	var tw := self.create_tween()
	tw.tween_property(self, "position", _origin_position, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		self.z_index = _origin_z_index
	)
