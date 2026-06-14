## Berserker trait — accumulates rage stacks in unit's Blackboard each time
## the unit takes damage. Each stack grants +1 effective move point.
##
## Demonstrates the Blackboard pattern: passive manages dynamic state on the
## unit without adding any fields to Unit.gd.
class_name BerserkerTrait
extends BasePassive

func _init() -> void:
	passive_name = "Berserker"
	is_trait = true

func get_hook_ids() -> Array[StringName]:
	return [
		&"on_passive_attached",
		&"on_passive_detached",
		&"on_take_damage",
		&"get_move_points",
	]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	match hook_id:
		&"on_passive_attached":
			var c := ctx as AttachContext
			if c == null:
				return
			c.unit.set_capability(&"rage_stacks", 0)
			print("[BerserkerTrait] Attached to %s — rage_stacks = 0" % c.unit.unit_name)

		&"on_passive_detached":
			var c := ctx as DetachContext
			if c == null:
				return
			c.unit.remove_capability(&"rage_stacks")
			print("[BerserkerTrait] Detached from %s — rage_stacks cleared" % c.unit.unit_name)

		&"on_take_damage":
			var c := ctx as TakeDamageContext
			if c == null or not c.unit.has_capability(&"rage_stacks"):
				return
			var stacks: int = c.unit.get_capability(&"rage_stacks", 0) + 1
			c.unit.set_capability(&"rage_stacks", stacks)
			print("[BerserkerTrait] Damage received — rage_stacks → %d" % stacks)

		&"get_move_points":
			var c := ctx as MoveQueryContext
			if c == null or c.unit == null:
				return
			var stacks: int = c.unit.get_capability(&"rage_stacks", 0)
			if stacks > 0:
				c.bonus_move_points += stacks
