## Restores 2 HP at the start of each turn.
class_name RegenerationPassive
extends BasePassive

const REGEN: int = 2

func _init() -> void:
	passive_name = "Regeneration"
	description = "Restores 2 HP at the start of each turn."

func get_hook_ids() -> Array[StringName]:
	return [HookId.ON_UNIT_TURN_START]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as TurnStartContext
	if c == null:
		return
	c.unit.heal(REGEN)
