## Deals a fixed damage amount to the target, independent of any unit stat.
## Used by zone/tile/trap effects that have their own damage value rather than
## inheriting from an attacking unit's attack_damage.
class_name FixedDamageCommand
extends BaseCommand

@export var damage: int = 3

func _init(d: int = 3) -> void:
	damage = d

func execute_async(_ctx: BaseContext) -> void:
	var target := _ctx.target_unit
	if target == null and _ctx.grid_system != null:
		var action_ctx := _ctx as ActionContext
		if action_ctx != null:
			target = _ctx.grid_system.get_occupant(action_ctx.target_cell)
	if target != null and target.is_alive():
		target.take_damage(damage)
