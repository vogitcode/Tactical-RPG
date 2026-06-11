## The state where a unit performs its actions.
## TurnSystem enters this state to notify ActionSystem, then returns immediately.
## The coroutine chain resumes via TurnSystem.on_unit_turn_finished when the unit is done.
class_name UnitActingState
extends BattleStateNode

signal activated(unit: Unit)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("unit") as Unit)
	return token

func _transition(_context: Dictionary) -> void:
	pass
