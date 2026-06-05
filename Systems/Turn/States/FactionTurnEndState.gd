class_name FactionTurnEndState
extends BattleStateNode

signal activated(faction_id: int, token: StateCompletionToken)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("faction", -1) as int, token)
	return token

func _transition(_context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
		return
	var next_faction := _turn_system.get_next_faction_with_units()
	if next_faction >= 0:
		await _turn_system.go_to_faction_turn(next_faction)
	else:
		await _turn_system.go_to_turn_end()
