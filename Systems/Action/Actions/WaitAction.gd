## Defers the unit to the end of the current faction's turn order.
## Can only be used once per faction turn — has_waited prevents re-deferral.
class_name WaitAction
extends TurnControlAction

func _init() -> void:
	super()
	action_id = &"wait"
	action_name = "Wait"
	action_description = "Move to end of turn order."
	ap_cost = 0
	target_mode = TargetMode.SELF
	turn_effect = TurnEffect.DEFER

func can_execute(unit: Unit) -> bool:
	return unit.is_alive() and not unit.has_waited
