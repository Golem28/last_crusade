extends Label

func _ready() -> void:
	GameManager.row_topic_changed.connect(_on_topic_changed)
	_on_topic_changed(GameManager.row_topic)

func _on_topic_changed(topic: int) -> void:
	var names := {
		DropZone.ZONE_TYPE.FRONT: "Front",
		DropZone.ZONE_TYPE.FLANK: "Flank",
		DropZone.ZONE_TYPE.REAR: "Rear",
	}
	text = "Row Topic: %s" % names[topic]
