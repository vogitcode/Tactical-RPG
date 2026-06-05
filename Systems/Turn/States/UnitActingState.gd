## The state where a unit performs its actions.
## Owns its own token — claims it in _activate(), releases via release_unit_turn().
## ActionSystem notifies via signal (unit_turn_finished) when the unit is done.
class_name UnitActingState
extends BattleStateNode

signal activated(unit: Unit, token: StateCompletionToken)

var _pending_release: Callable = Callable()

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	_pending_release = token.claim()
	activated.emit(context.get("unit") as Unit, token)
	return token

func _transition(context: Dictionary) -> void:
	if _turn_system.is_battle_ending():
		await _turn_system.go_to_battle_end()
		return
	var unit := context.get("unit") as Unit
	await _turn_system.go_to_unit_turn_end(unit)

## Called (deferred) by ActionSystem.unit_turn_finished signal.
## Deferred wiring breaks the synchronous call stack so next unit activates on a fresh frame.
func release_unit_turn() -> void:
	if _pending_release.is_valid():
		var r := _pending_release
		_pending_release = Callable()
		r.call()
