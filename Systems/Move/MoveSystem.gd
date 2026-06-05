## Standalone movement system.
## Handles reachability queries, pathfinding, and async unit movement execution.
## Other actions (Dash, Blink, AI pathing) call this directly instead of re-implementing.
class_name MoveSystem
extends Node

const MOVE_DURATION: float = 0.15

var _grid_system: GridSystem = null
var _reaction_system: ReactionSystem = null
var _interrupt_manager: InterruptManager = null

func setup(grid: GridSystem, reaction_system: ReactionSystem = null, interrupt_manager: InterruptManager = null) -> void:
	_grid_system = grid
	_reaction_system = reaction_system
	_interrupt_manager = interrupt_manager

## Handler interface — called by ActionSystem dispatch for category &"move".
func handle_action(action: BaseAction, source_unit: Unit) -> ActionResult:
	var move_action := action as MoveAction
	source_unit.show_active_hook_icons(&"get_move_points")
	var result: ActionResult = await execute_move_async(
		source_unit, move_action.path, Vector2i(-1, -1), _interrupt_manager
	)
	if result.is_completed():
		source_unit.has_moved = true
		source_unit.action_points -= move_action.ap_cost
	return result

# --- Queries (callable by any mechanic) ---

func get_reachable_cells(from: Vector2i, move_points: int) -> Array[Vector2i]:
	return GridLogic.get_reachable_cells(_grid_system.data, from, move_points)

func find_path(from: Vector2i, to: Vector2i, unit: Unit = null) -> Array[Vector2i]:
	return GridLogic.find_path(_grid_system.data, from, to, unit)

# --- Execution ---

## Moves unit along path one cell at a time, checking for interrupts at each step.
## If path is empty, attempts to find one from unit.grid_position to target_cell.
func execute_move_async(
	unit: Unit,
	path: Array[Vector2i],
	target_cell: Vector2i,
	interrupt_manager: InterruptManager
) -> ActionResult:
	var actual_path := path
	if actual_path.is_empty() and target_cell != Vector2i(-1, -1):
		actual_path = find_path(unit.grid_position, target_cell, unit)
	if actual_path.is_empty():
		return ActionResult.failed("no path to target")

	_grid_system.clear_highlights()

	for i in range(1, actual_path.size()):
		var next_cell: Vector2i = actual_path[i]
		_grid_system.show_path(actual_path.slice(i))

		var start_pos := unit.position
		_grid_system.move_unit(unit, next_cell)
		var end_pos := unit.position
		unit.position = start_pos

		var tween := unit.create_tween()
		tween.tween_property(unit, "position", end_pos, MOVE_DURATION)
		await tween.finished

		# TODO: TEMPORARY — will be replaced by BattleProcessor reaction collection
		if _reaction_system != null:
			_reaction_system.evaluate_step(unit, next_cell)

		if interrupt_manager.has_interrupt(unit):
			_grid_system.clear_highlights()
			return ActionResult.interrupted(interrupt_manager.consume_interrupt(unit))

	_grid_system.clear_highlights()
	return ActionResult.completed()
