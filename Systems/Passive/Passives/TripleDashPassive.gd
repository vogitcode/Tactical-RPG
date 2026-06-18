## Triple Dash passive — tracks consecutive dashes via capability store.
## After 3 dashes, the next attack deals double damage.
##
## Demonstrates compound effect: ON_DASH_EXECUTED sets state, ON_BEFORE_DEAL_DAMAGE reads it.
## The two hooks don't know about each other — compound emerges through shared capability store.
class_name TripleDashPassive
extends BasePassive

func _init() -> void:
	passive_name = "Triple Dash"
	is_trait = false
	description = "After 3 dashes, next attack deals double damage."

func get_hook_ids() -> Array[StringName]:
	return [
		HookId.ON_PASSIVE_ATTACHED,
		HookId.ON_PASSIVE_DETACHED,
		HookId.ON_DASH_EXECUTED,
		HookId.ON_BEFORE_DEAL_DAMAGE,
	]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	match hook_id:
		HookId.ON_PASSIVE_ATTACHED:
			var c := ctx as AttachContext
			if c == null:
				return
			c.unit.set_capability(&"dash_count", 0)
			c.unit.set_capability(&"triple_dash_ready", false)
			print("[TripleDashPassive] Attached to %s" % c.unit.unit_name)

		HookId.ON_PASSIVE_DETACHED:
			var c := ctx as DetachContext
			if c == null:
				return
			c.unit.remove_capability(&"dash_count")
			c.unit.remove_capability(&"triple_dash_ready")

		HookId.ON_DASH_EXECUTED:
			var c := ctx as DashContext
			if c == null or c.unit == null:
				return
			var count: int = c.unit.get_capability(&"dash_count", 0) + 1
			if count >= 3:
				c.unit.set_capability(&"triple_dash_ready", true)
				c.unit.set_capability(&"dash_count", 0)
				print("[TripleDashPassive] Triple dash ready!")
			else:
				c.unit.set_capability(&"dash_count", count)
				print("[TripleDashPassive] Dash count: %d/3" % count)

		HookId.ON_BEFORE_DEAL_DAMAGE:
			var c := ctx as DealDamageContext
			if c == null:
				return
			if not c.source_unit.get_capability(&"triple_dash_ready", false):
				return
			c.damage *= 2
			c.source_unit.set_capability(&"triple_dash_ready", false)
			print("[TripleDashPassive] Triple dash triggered — damage x2!")
