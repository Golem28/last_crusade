extends Node

const SUITES: Array[Script] = [
	preload("res://tests/suites/game_manager_test.gd"),
	preload("res://tests/suites/drop_zone_test.gd"),
	preload("res://tests/suites/card_test.gd"),
	preload("res://tests/suites/game_board_test.gd"),
	preload("res://tests/suites/dragable_manager_test.gd"),
]

func _ready() -> void:
	var total_passed := 0
	var total_failed := 0

	print("== Last Crusade tests ==")

	for suite_script in SUITES:
		var suite: Node = suite_script.new()
		add_child(suite)
		var suite_passed := 0
		var suite_failed := 0

		for test_name in _test_methods(suite):
			suite.call("before_each") if suite.has_method("before_each") else null
			suite.passed = 0
			suite.failed = 0
			await suite.call(test_name)
			suite_passed += suite.passed
			suite_failed += suite.failed
			if suite.failed > 0:
				push_error("FAIL: %s::%s" % [suite_script.resource_path.get_file().get_basename(), test_name])

		suite.queue_free()
		await get_tree().process_frame
		print("%s: %d passed, %d failed" % [suite_script.resource_path.get_file(), suite_passed, suite_failed])
		total_passed += suite_passed
		total_failed += suite_failed

	print("")
	print("TOTAL: %d passed, %d failed" % [total_passed, total_failed])
	get_tree().quit(1 if total_failed > 0 else 0)

func _test_methods(obj: Object) -> Array[String]:
	var names: Array[String] = []
	for method in obj.get_method_list():
		if method.name.begins_with("test_") and (method.flags & METHOD_FLAG_NORMAL) == METHOD_FLAG_NORMAL:
			names.append(method.name)
	return names
