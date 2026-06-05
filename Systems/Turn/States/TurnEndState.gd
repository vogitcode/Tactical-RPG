class_name TurnEndState
extends BattleStateNode

signal activated(turn_number: int, token: StateCompletionToken)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("turn", 0) as int, token)
	return token

func _transition(_context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
	else:
		await _turn_system.go_to_turn_start()
