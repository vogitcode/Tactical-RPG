## Restores 2 HP at the start of each turn.
class_name RegenerationPassive
extends BasePassive

const REGEN: int = 2

func _init() -> void:
	passive_name = "Regeneration"

func get_hook_ids() -> Array[StringName]:
	return [&"on_unit_turn_start"]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as TurnStartContext
	if c == null:
		return
	c.unit.heal(REGEN)
