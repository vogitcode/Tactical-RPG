## Terminal state — no _transition() needed.
## go_to_battle_end() emits battle_ended and cleans up after this state's enter() returns.
class_name BattleEndState
extends BattleStateNode

signal activated(result: StringName, token: StateCompletionToken)

func _activate(context: Dictionary) -> StateCompletionToken:
	var token := StateCompletionToken.new()
	activated.emit(context.get("result", &"") as StringName, token)
	return token
