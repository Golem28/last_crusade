extends Node

var passed := 0
var failed := 0

func assert_true(cond: bool, message := "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("    assert_true failed: %s" % message)

func assert_eq(actual, expected, message := "") -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("    assert_eq failed: %s (expected `%s`, got `%s`)" % [message, expected, actual])

func assert_not_null(obj, message := "") -> void:
	if obj != null:
		passed += 1
	else:
		failed += 1
		push_error("    assert_not_null failed: %s" % message)
