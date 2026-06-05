## Adds +10 RP to all combat checks (attacks and reactions).
class_name AggressivePassive
extends BasePassive

const BONUS: int = 10

func _init() -> void:
	passive_name = "Aggressive"

func get_hook_ids() -> Array[StringName]:
	return [&"get_rp_bonus"]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as RPQueryContext
	if c == null:
		return
	c.bonus_rp += BONUS
