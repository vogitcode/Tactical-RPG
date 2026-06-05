## Abstract base for actions that control turn flow — end turn, wait, guard, etc.
## TurnSystem reads turn_effect to determine how to handle the action.
class_name TurnControlAction
extends BaseAction

enum TurnEffect { END_TURN, DEFER, GUARD }

var turn_effect: TurnEffect = TurnEffect.END_TURN
## Status name to apply when turn_effect == GUARD. Set in subclass _init().
var status_to_apply: StringName = &""

func _init() -> void:
	category = &"turn_control"
