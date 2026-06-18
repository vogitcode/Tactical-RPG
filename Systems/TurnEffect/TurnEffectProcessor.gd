## Processes gameplay effects at turn boundaries.
## Claims StateCompletionToken for UnitTurnStart and UnitTurnEnd states.
## on_unit_turn_start: fires effect hooks (DoT, regen, etc.) via StatusEffectReceiver.
## on_unit_turn_end: placeholder for future end-of-turn effects (reactions, passives).
class_name TurnEffectProcessor
extends Node

func on_unit_turn_start(unit: Unit, token: StateCompletionToken) -> void:
	var release := token.claim()
	unit.get_status_receiver().process_turn_start(unit)
	var ctx := TurnStartContext.new()
	ctx.unit = unit
	unit.fire_hook(HookId.ON_UNIT_TURN_START, ctx)
	release.call()

func on_unit_turn_end(unit: Unit, token: StateCompletionToken) -> void:
	var release := token.claim()
	# Future: end-of-turn passive triggers, reaction cooldown tracking
	release.call()
