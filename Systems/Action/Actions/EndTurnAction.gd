## Ends the unit's turn immediately without consuming any resource.
class_name EndTurnAction
extends TurnControlAction

func _init() -> void:
	super()
	action_id = &"end_turn"
	action_name = "End Turn"
	action_description = "End your turn."
	ap_cost = 0
	needs_target = false
	turn_effect = TurnEffect.END_TURN

func can_execute(unit: Unit) -> bool:
	return unit.is_alive()
