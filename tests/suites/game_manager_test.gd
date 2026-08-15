extends "res://tests/test_case.gd"

func before_each() -> void:
	GameManager.actions_remaining = GameManager.MAX_ACTIONS
	GameManager.row_topic = DropZone.ZONE_TYPE.REAR

func test_start_turn_resets_actions() -> void:
	GameManager.actions_remaining = 0
	GameManager.start_turn()
	assert_eq(GameManager.actions_remaining, GameManager.MAX_ACTIONS, "start_turn restores actions")

func test_start_turn_rotates_topic() -> void:
	GameManager.start_turn()
	assert_eq(GameManager.row_topic, DropZone.ZONE_TYPE.FRONT, "topic REAR -> FRONT")

func test_topic_cycles_after_three_turns() -> void:
	GameManager.start_turn()
	GameManager.start_turn()
	GameManager.start_turn()
	assert_eq(GameManager.row_topic, DropZone.ZONE_TYPE.REAR, "topic wraps back to REAR")

func test_try_spend_deducts_cost() -> void:
	assert_true(GameManager.try_spend(1), "spending 1 is allowed")
	assert_eq(GameManager.actions_remaining, 1, "one action remains")

func test_try_spend_rejects_insufficient_actions() -> void:
	GameManager.actions_remaining = 1
	var rejected := false
	GameManager.action_rejected.connect(func(_reason: String) -> void: rejected = true, CONNECT_ONE_SHOT)
	assert_true(not GameManager.try_spend(2), "spending 2 with 1 left is rejected")
	assert_eq(GameManager.actions_remaining, 1, "no action spent on rejection")
	assert_true(rejected, "action_rejected signal emitted")

func test_last_action_ends_the_turn() -> void:
	var turns := 0
	GameManager.turn_started.connect(func() -> void: turns += 1)
	assert_true(GameManager.try_spend(1), "spend 1")
	assert_true(GameManager.try_spend(1), "spend 2")
	assert_eq(GameManager.actions_remaining, 0, "all actions spent")
	await get_tree().process_frame
	assert_eq(GameManager.actions_remaining, GameManager.MAX_ACTIONS, "next turn started with full actions")
	assert_eq(turns, 1, "turn_started fired exactly once")
