class_name FactionTurnStartState
extends BattleStateNode

signal activated(faction_id: int, token: StateCompletionToken)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("faction", -1) as int, token)
	return token

func _transition(context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
		return
	var faction_id := context.get("faction", -1) as int
	var first_unit := _turn_system.get_first_unit_in_faction(faction_id)
	if first_unit != null:
		await _turn_system.go_to_unit_turn(first_unit)
	else:
		await _turn_system.go_to_faction_turn_end()
