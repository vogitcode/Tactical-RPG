class_name GuardAction
extends TurnControlAction

func _init() -> void:
	super()
	action_id = &"guard"
	action_name = "Guard"
	action_description = "Brace for incoming attacks. Reduces damage until next turn."
	ap_cost = 1
	target_mode = TargetMode.SELF
	_sets_has_acted = true
	turn_effect = TurnEffect.GUARD
	status_to_apply = &"guarding"

func can_execute(unit: Unit) -> bool:
	if not super(unit):
		return false
	return not unit.has_acted
