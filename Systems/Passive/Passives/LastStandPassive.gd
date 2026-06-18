## Prevents death once — unit survives at 1 HP, then this passive removes itself.
## Demo passive for HookId.ON_DEATH_CHECK.
class_name LastStandPassive
extends BasePassive

func _init() -> void:
	passive_name = "Last Stand"
	description = "Prevents death once — the unit survives a lethal hit at 1 HP. Consumed after triggering."

func get_hook_ids() -> Array[StringName]:
	return [HookId.ON_DEATH_CHECK]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as DeathCheckContext
	if c == null:
		return
	c.prevent_death = true
	c.unit.show_active_hook_icons(HookId.ON_DEATH_CHECK)
	c.unit.remove_passive(self)
