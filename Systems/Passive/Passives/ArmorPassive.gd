## Reduces all incoming damage by a flat amount (minimum 0).
## Demo passive for &"on_take_damage".
class_name ArmorPassive
extends BasePassive

@export var armor_value: int = 2

func get_hook_ids() -> Array[StringName]:
	return [&"on_take_damage"]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as TakeDamageContext
	if c == null:
		return
	c.modified_damage = maxi(0, c.modified_damage - armor_value)
	c.unit.show_active_hook_icons(&"on_take_damage")
