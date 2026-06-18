## Adds +10 RP to all combat checks (attacks and reactions).
class_name AggressivePassive
extends BasePassive

const BONUS: int = 10

func _init() -> void:
	passive_name = "Aggressive"
	description = "Adds +10 Reaction Power to all attacks and reactions, increasing hit chance and combat effectiveness."

func get_hook_ids() -> Array[StringName]:
	return [HookId.GET_RP_BONUS]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as RPQueryContext
	if c == null:
		return
	c.bonus_rp += BONUS
