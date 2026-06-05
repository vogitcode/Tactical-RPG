## Fires after a unit finishes acting. Status effects, DoT, cooldowns should subscribe here.
class_name UnitTurnEndState
extends BattleStateNode

signal activated(unit: Unit, token: StateCompletionToken)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("unit") as Unit, token)
	return token

func _transition(_context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
		return
	var next_unit := _turn_system.get_next_unit_in_faction()
	if next_unit != null:
		await _turn_system.go_to_unit_turn(next_unit)
		return
	var deferred_unit := _turn_system.get_next_deferred_unit_in_faction()
	if deferred_unit != null:
		await _turn_system.go_to_unit_turn(deferred_unit)
	else:
		await _turn_system.go_to_faction_turn_end()
