## Applies damage from source unit to target, passing through both attacker and defender hooks.
## on_before_deal_damage → fires on attacker (source can modify damage output)
## take_damage → fires on_take_damage on defender (defender can modify damage received)
class_name DamageCommand
extends BaseCommand

func execute_async(_ctx: BaseContext) -> void:
	var ctx := _ctx as ActionContext
	if ctx == null or ctx.source_unit == null:
		return
	var target := ctx.target_unit
	if target == null:
		target = ctx.grid_system.get_occupant(ctx.target_cell)
	if target == null or not target.is_alive():
		return

	var deal_ctx := DealDamageContext.new()
	deal_ctx.source_unit = ctx.source_unit
	deal_ctx.target_unit = target
	deal_ctx.damage = ctx.source_unit.attack_damage
	ctx.source_unit.fire_hook(HookId.ON_BEFORE_DEAL_DAMAGE, deal_ctx)

	target.take_damage(deal_ctx.damage)
