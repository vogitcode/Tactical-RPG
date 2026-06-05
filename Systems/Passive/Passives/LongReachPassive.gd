## Grants the unit +1 attack range.
class_name LongReachPassive
extends BasePassive

const BONUS: int = 1

func _init() -> void:
	passive_name = "Long Reach"

func get_hook_ids() -> Array[StringName]:
	return [&"get_attack_range"]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as AttackRangeQueryContext
	if c == null:
		return
	c.bonus_range += BONUS
