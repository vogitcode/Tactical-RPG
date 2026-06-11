## Deals a fixed damage amount to the target, independent of any unit stat.
## Used by zone/trap effects that have their own damage value rather than
## inheriting from an attacking unit's attack_damage.
class_name FixedDamageEffect
extends BaseEffect

@export var damage: int = 3

func execute_async(ctx: ActionContext) -> void:
	var target := ctx.target_unit
	if target == null:
		target = ctx.grid_system.get_occupant(ctx.target_cell)
	if target != null and target.is_alive():
		target.take_damage(damage)
