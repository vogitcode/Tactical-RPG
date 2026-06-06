## When this unit is hit in combat, reflects 2 damage back to the attacker.
## Demo passive for &"on_combat_resolved".
class_name ThornsPassive
extends BasePassive

const REFLECT_DAMAGE := 2

func get_hook_ids() -> Array[StringName]:
	return [&"on_combat_resolved"]

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
	c.firing_unit.show_active_hook_icons(&"on_combat_resolved")
	c.attacker.take_damage(REFLECT_DAMAGE)
