## When this unit is hit in combat, reflects 2 damage back to the attacker.
## Demo passive for HookId.ON_COMBAT_RESOLVED.
class_name ThornsPassive
extends BasePassive

const REFLECT_DAMAGE := 2

func _init() -> void:
	passive_name = "Thorns"
	description = "When struck in melee combat, reflects 2 damage back to the attacker."

func get_hook_ids() -> Array[StringName]:
	return [HookId.ON_COMBAT_RESOLVED]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as CombatResolvedContext
	if c == null:
		return
	if c.firing_unit != c.defender:
		return
	if not c.condition_result.initiator_hit():
		return
	if c.attacker == null or not c.attacker.is_alive():
		return
	c.firing_unit.show_active_hook_icons(HookId.ON_COMBAT_RESOLVED)
	c.attacker.take_damage(REFLECT_DAMAGE)
