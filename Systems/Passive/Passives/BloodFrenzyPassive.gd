## Compound passive — activates when BerserkerTrait's rage reaches threshold.
##
## Demonstrates Boundary-1 compound effect (object-internal):
##   BerserkerTrait sets rage_stacks on Blackboard
##   + BloodFrenzyPassive reads rage_stacks
##   → when stacks >= threshold: reduce incoming damage (unstoppable frenzy)
##
## Neither passive knows about the other. The compound emerges from shared
## Blackboard state. Adding or removing either passive is fully independent.
class_name BloodFrenzyPassive
extends BasePassive

@export var rage_threshold: int = 3
@export var damage_reduction: int = 3

func _init() -> void:
	passive_name = "Blood Frenzy"
	description = "When rage stacks reach 3 or more, reduces incoming damage by 3. Works in tandem with Berserker."

func get_hook_ids() -> Array[StringName]:
	return [HookId.ON_TAKE_DAMAGE]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as TakeDamageContext
	if c == null:
		return
	if not c.unit.has_capability(&"rage_stacks"):
		return
	var stacks: int = c.unit.get_capability(&"rage_stacks", 0)
	if stacks >= rage_threshold:
		var old := c.modified_damage
		c.modified_damage = maxi(0, c.modified_damage - damage_reduction)
		print("[BloodFrenzy] COMPOUND ACTIVE (rage=%d) — damage %d → %d" % [stacks, old, c.modified_damage])
		c.unit.show_active_hook_icons(HookId.ON_TAKE_DAMAGE)
