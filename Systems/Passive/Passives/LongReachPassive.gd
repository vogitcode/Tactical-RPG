## Grants the unit +1 attack range.
class_name LongReachPassive
extends BasePassive

const BONUS: int = 1

func _init() -> void:
	passive_name = "Long Reach"
	description = "Extends attack range by +1 tile, allowing strikes from further away."

func get_hook_ids() -> Array[StringName]:
	return [HookId.GET_ATTACK_RANGE]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as AttackRangeQueryContext
	if c == null:
		return
	c.bonus_range += BONUS
