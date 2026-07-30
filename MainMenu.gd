extends Control

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")

func _on_options_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://options.tscn")

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
