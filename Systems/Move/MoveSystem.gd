## Standalone movement system.
## Handles reachability queries, pathfinding, and async unit movement execution.
## Other actions (Dash, Blink, AI pathing) call execute_move_async directly.
class_name MoveSystem
extends Node

## Emitted after each step tween completes. Subscribers (PropSystem, ReactionSystem, tile hooks)
## can register AbortCheck instances via move_execution_started to interrupt movement.
signal unit_stepped(unit: Unit, cell: Vector2i)

## Emitted once per handle_action call, before execution begins.
## Compositor connects this to register AbortCheck instances into the context.
signal move_execution_started(ctx: MoveExecutionContext)

const MOVE_DURATION: float = 0.15

var _grid_system: GridSystem = null
var _interrupt_manager: InterruptManager = null

func setup(grid: GridSystem, interrupt_manager: InterruptManager = null) -> void:
	_grid_system = grid
	_interrupt_manager = interrupt_manager

## Handler interface — called by ActionSystem dispatch for category &"move".
func handle_action(action: BaseAction, source_unit: Unit) -> ActionResult:
	var move_action := action as MoveAction
	var ctx := MoveExecutionContext.new()
	move_execution_started.emit(ctx)
	var handle := _interrupt_manager.start_watch(&"move", source_unit)
	handle.timed_out.connect(func(_unit: Unit, _reason: String) -> void:
		ctx.force_abort("watchdog_timeout")
	)
	source_unit.show_active_hook_icons(&"get_move_points")
	var result: ActionResult = await execute_move_async(source_unit, move_action.path, ctx)
	handle.complete()
	if result.is_completed() or result.is_interrupted():
		var cost := _compute_path_cost(move_action.path, source_unit.grid_position)
		source_unit.remaining_mp = maxi(0, source_unit.remaining_mp - cost)
	return result

func _compute_path_cost(path: Array[Vector2i], final_pos: Vector2i) -> int:
	var cost := 0
	for i in range(1, path.size()):
		var cell := path[i]
		var tile := _grid_system.data.get_tile(cell)
		if tile:
			cost += tile.movement_cost
		if cell == final_pos:
			break
	return cost

# --- Queries (callable by any mechanic) ---

func get_reachable_cells(from: Vector2i, move_points: int) -> Array[Vector2i]:
	return GridLogic.get_reachable_cells(_grid_system.data, from, move_points)

func find_path(from: Vector2i, to: Vector2i, unit: Unit = null) -> Array[Vector2i]:
	return GridLogic.find_path(_grid_system.data, from, to, unit)

# --- Execution ---

## Moves unit along path one cell at a time, checking for interrupts at each step.
## ctx is optional — pass null or omit for moves that have no registered interrupt sources.
## Phase 1 (traversal): read-only — GridData is not touched, unit.grid_position unchanged.
## Phase 2 (commit): atomic — one move_occupant call at origin → final_cell.
func execute_move_async(
	unit: Unit,
	path: Array[Vector2i],
	ctx: MoveExecutionContext = null
) -> ActionResult:
	var _ctx := ctx if ctx != null else MoveExecutionContext.new()
	if path.is_empty():
		return ActionResult.failed("no path to target")

	_grid_system.clear_highlights()

	var origin := unit.grid_position
	var current_cell := origin

	for i in range(1, path.size()):
		var stepped_cell: Vector2i = path[i]
		_grid_system.show_path(path.slice(i))

		var end_pos := _grid_system.get_cell_position(stepped_cell)
		var tween := unit.create_tween()
		tween.tween_property(unit, "position", end_pos, MOVE_DURATION)
		await tween.finished

		current_cell = stepped_cell
		unit_stepped.emit(unit, stepped_cell)

		if not unit.is_alive():
			_grid_system.commit_unit_move(unit, origin, current_cell)
			_grid_system.clear_highlights()
			return ActionResult.interrupted("unit_died")

		if _ctx.evaluate(unit):
			_grid_system.commit_unit_move(unit, origin, current_cell)
			_grid_system.clear_highlights()
			return ActionResult.interrupted(_ctx.get_reason())

	_grid_system.commit_unit_move(unit, origin, current_cell)
	_grid_system.clear_highlights()
	return ActionResult.completed()
