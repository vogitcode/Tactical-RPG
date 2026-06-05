## Applies the acting unit's attack_damage to the target.
## Resolves target from ctx.target_unit first, then falls back to ctx.target_cell occupant.
class_name DamageEffect
extends BaseEffect

func execute_async(ctx: ActionContext) -> void:
	var target := ctx.target_unit
	if target == null:
		target = ctx.grid_system.get_occupant(ctx.target_cell)
	if target != null and target.is_alive():
		target.take_damage(ctx.unit.attack_damage)
