class_name MoveAction
extends BaseAction

## Computed path — populated by resolve_target() when player clicks a reachable tile.
var path: Array[Vector2i] = []

func _init() -> void:
	action_id = &"move"
	action_name = "Move"
	action_description = "Move to a reachable tile."
	ap_cost = 1
	target_mode = TargetMode.TILE
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

func resolve_target(grid_pos: Vector2i, source_unit: Unit, grid_system: GridSystem) -> bool:
	var reachable: Array[Vector2i] = grid_system.get_reachable_cells(
		source_unit.grid_position, source_unit.get_effective_move_points()
	)
	if grid_pos not in reachable:
		return false
	path = grid_system.find_path(source_unit.grid_position, grid_pos, source_unit)
	return true

func clear_target() -> void:
	path.clear()
