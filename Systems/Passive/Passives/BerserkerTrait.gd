## Berserker trait — accumulates rage stacks in unit's Blackboard each time
## the unit takes damage. Each stack grants +1 effective move point.
##
## Demonstrates the Blackboard pattern: passive manages dynamic state on the
## unit without adding any fields to Unit.gd.
class_name BerserkerTrait
extends BasePassive

func _init() -> void:
	passive_name = "Berserker"
	is_trait = false
	description = "Each time this unit takes damage, gains 1 rage stack. Each rage stack grants +1 move point."

func get_hook_ids() -> Array[StringName]:
	return [
		HookId.ON_PASSIVE_ATTACHED,
		HookId.ON_PASSIVE_DETACHED,
		HookId.ON_TAKE_DAMAGE,
		HookId.GET_MOVE_POINTS,
	]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	match hook_id:
		HookId.ON_PASSIVE_ATTACHED:
			var c := ctx as AttachContext
			if c == null:
				return
			c.unit.set_capability(&"rage_stacks", 0)
			print("[BerserkerTrait] Attached to %s — rage_stacks = 0" % c.unit.unit_name)

		HookId.ON_PASSIVE_DETACHED:
			var c := ctx as DetachContext
			if c == null:
				return
			c.unit.remove_capability(&"rage_stacks")
			print("[BerserkerTrait] Detached from %s — rage_stacks cleared" % c.unit.unit_name)

		HookId.ON_TAKE_DAMAGE:
			var c := ctx as TakeDamageContext
			if c == null or not c.unit.has_capability(&"rage_stacks"):
				return
			var stacks: int = c.unit.get_capability(&"rage_stacks", 0) + 1
			c.unit.set_capability(&"rage_stacks", stacks)
			print("[BerserkerTrait] Damage received — rage_stacks → %d" % stacks)

		HookId.GET_MOVE_POINTS:
			var c := ctx as MoveQueryContext
			if c == null or c.unit == null:
				return
			var stacks: int = c.unit.get_capability(&"rage_stacks", 0)
			if stacks > 0:
				c.bonus_move_points += stacks
