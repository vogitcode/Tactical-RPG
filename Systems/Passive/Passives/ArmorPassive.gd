## Reduces all incoming damage by a flat amount (minimum 0).
## Demo passive for HookId.ON_TAKE_DAMAGE.
class_name ArmorPassive
extends BasePassive

@export var armor_value: int = 2

func _init() -> void:
	passive_name = "Armor"
	description = "Reduces all incoming damage by 2 (minimum 0 damage received)."

func get_hook_ids() -> Array[StringName]:
	return [HookId.ON_TAKE_DAMAGE]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as TakeDamageContext
	if c == null:
		return
	c.modified_damage = maxi(0, c.modified_damage - armor_value)
	c.unit.show_active_hook_icons(HookId.ON_TAKE_DAMAGE)
