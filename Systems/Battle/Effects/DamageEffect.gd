## Applies damage from source unit to target, passing through both attacker and defender hooks.
## on_before_deal_damage → fires on attacker (source can modify damage output)
## take_damage → fires on_take_damage on defender (defender can modify damage received)
class_name DamageEffect
extends BaseEffect

func execute_async(ctx: ActionContext) -> void:
	var target := ctx.target_unit
	if target == null:
		target = ctx.grid_system.get_occupant(ctx.target_cell)
	if target == null or not target.is_alive():
		return

	var deal_ctx := DealDamageContext.new()
	deal_ctx.source_unit = ctx.unit
	deal_ctx.target_unit = target
	deal_ctx.damage = ctx.unit.attack_damage
	ctx.unit.fire_hook(HookId.ON_BEFORE_DEAL_DAMAGE, deal_ctx)

	target.take_damage(deal_ctx.damage)
