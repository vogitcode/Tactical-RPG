class_name BattleStartState
extends BattleStateNode

signal activated(token: StateCompletionToken)

func _activate(_context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(token)
	return token

func _transition(_context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
	else:
		await _turn_system.go_to_turn_start()
