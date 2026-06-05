class_name MoveAction
extends BaseAction

## Computed path — set by ActionSystem when player clicks destination tile.
var path: Array[Vector2i] = []

func _init() -> void:
	action_id = &"move"
	action_name = "Move"
	action_description = "Move to a reachable tile."
	ap_cost = 1
	needs_target = true
	category = &"move"

func can_execute(unit: Unit) -> bool:
	if not super(unit):
		return false
	return not unit.has_moved

func is_target_resolved() -> bool:
	return not path.is_empty()

func on_selected(unit: Unit, grid_system: GridSystem) -> void:
	var reachable: Array[Vector2i] = grid_system.get_reachable_cells(unit.grid_position, unit.get_effective_move_points())
	grid_system.show_move_range(reachable)
	grid_system.highlight_selected(unit.grid_position)

func on_deselected(_unit: Unit, grid_system: GridSystem) -> void:
	grid_system.clear_highlights()

func clear_target() -> void:
	path.clear()
