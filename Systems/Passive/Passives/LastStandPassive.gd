## Prevents death once — unit survives at 1 HP, then this passive removes itself.
## Demo passive for &"on_death_check".
class_name LastStandPassive
extends BasePassive

func get_hook_ids() -> Array[StringName]:
	return [&"on_death_check"]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as DeathCheckContext
	if c == null:
		return
	c.prevent_death = true
	c.unit.show_active_hook_icons(&"on_death_check")
	c.unit.remove_passive(self)
