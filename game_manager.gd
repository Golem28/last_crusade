extends Node

signal turn_started()
signal turn_ended()
signal actions_changed(remaining: int)
signal action_rejected(reason: String)

const MAX_ACTIONS := 2

var actions_remaining := MAX_ACTIONS

func start_turn() -> void:
	actions_remaining = MAX_ACTIONS
	actions_changed.emit(actions_remaining)
	turn_started.emit()

func end_turn() -> void:
	print("Turn ended")
	turn_ended.emit()
	start_turn()

## Central gate every action calls before doing anything.
## Returns true if the action is allowed AND deducts the cost.
func try_spend(cost: int) -> bool:
	if cost > actions_remaining:
		action_rejected.emit("Not enough actions (%d needed, %d left)" % [cost, actions_remaining])
		return false

	actions_remaining -= cost
	actions_changed.emit(actions_remaining)

	if actions_remaining <= 0:
		# deferred so current action finishes first
		call_deferred("end_turn")

	return true

func pass_turn() -> void:
	end_turn()
