## Grants the unit +3 extra move points per turn.
## Assign icon = Assets/Icon/fb593.png in the .tres to see the activation indicator.
class_name SwiftMoverPassive
extends BasePassive

const BONUS: int = 3

func _init() -> void:
	passive_name = "Swift Mover"
	description = "Grants +3 bonus move points each turn, allowing this unit to cover more ground."

func get_hook_ids() -> Array[StringName]:
	return [HookId.GET_MOVE_POINTS]

func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	var c := ctx as MoveQueryContext
	if c == null:
		return
	c.bonus_move_points += BONUS
