class_name UnitTurnStartState
extends BattleStateNode

signal activated(unit: Unit, token: StateCompletionToken)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("unit") as Unit, token)
	return token

func _transition(context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
		return
	var unit := context.get("unit") as Unit
	await _turn_system.go_to_unit_acting(unit)
