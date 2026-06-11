## Pure dispatcher — receives action requests and routes to the registered handler.
## Handler systems register themselves via register_handler(category, handler).
## Interaction state (menu/targeting) is managed by PlayerInteractionStateMachine.
class_name ActionSystem
extends Node

signal action_execution_started(action: BaseAction, unit: Unit)
signal action_execution_finished(action: BaseAction, unit: Unit, result: ActionResult)
signal show_menu_requested(unit: Unit, position: Vector2)
signal ai_turn_requested(unit: Unit)
signal unit_turn_finished(unit: Unit)

@onready var _sm: PlayerInteractionStateMachine = $PlayerInteractionStateMachine

var _grid_system: GridSystem = null
var _turn_system: TurnSystem = null
var _handlers: Dictionary = {}

var _is_executing: bool = false

# --- Setup ---

func setup(grid: GridSystem, turns: TurnSystem) -> void:
	_grid_system = grid
	_turn_system = turns
	_grid_system.tile_clicked.connect(_on_tile_clicked)
	_sm.init(self, grid)

func register_handler(category: StringName, handler: Node) -> void:
	_handlers[category] = handler

# --- TurnSystem callback ---

func on_unit_acting(unit: Unit) -> void:
	_sm.ctx.pending_action = null
	if unit.team == 0:
		_sm.on_unit_acting(unit)
	else:
		_sm.ctx.active_unit = unit
		ai_turn_requested.emit(unit)

# --- Action submission (called by ActionMenu) ---

func on_action_chosen(action: BaseAction) -> void:
	var unit: Unit = _sm.ctx.active_unit
	if unit == null:
		return
	if unit.team != 0:
		request_execute(action)  # AI bypasses interaction SM — execute directly
	else:
		_sm.on_action_chosen(action)

func on_menu_closed() -> void:
	_sm.on_menu_closed()

## Called by interaction states to start execution.
## Fire-and-forget — starts the async coroutine and returns immediately.
func request_execute(action: BaseAction) -> void:
	_execute_pending(action)

# --- Grid click callback ---

func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if _is_executing:
		return
	_sm.on_tile_clicked(grid_pos)

# --- Execution ---

func _execute_pending(action: BaseAction) -> void:
	_is_executing = true
	_sm.ctx.pending_action = null
	var unit: Unit = _sm.ctx.active_unit

	var unit_name := unit.unit_name if unit != null else "???"
	print("  [Action] %s → %s (AP before: %d)" % [unit_name, action.action_name, unit.action_points if unit != null else -1])
	action_execution_started.emit(action, unit)
	var result: ActionResult = await _dispatch(action, unit)
	action.clear_target()
	print("  [Result] %s → %s status=%s (AP after: %d)" % [unit_name, action.action_name, ActionResult.Status.keys()[result.status], unit.action_points if unit != null else -1])
	action_execution_finished.emit(action, unit, result)

	_is_executing = false

	if unit == null:
		return
	if not unit.is_alive():
		_finish_unit_turn(unit)
		return
	if result.status == ActionResult.Status.DEFERRED:
		_turn_system.defer_unit(unit)
		_finish_unit_turn(unit)
	elif unit.action_points <= 0 or action.action_id == &"end_turn":
		_finish_unit_turn(unit)
	elif unit.team == 0:
		_sm.on_unit_acting(unit)  # player still has AP — re-enter MENU_OPEN
	else:
		ai_turn_requested.emit(unit)

func _dispatch(action: BaseAction, source_unit: Unit) -> ActionResult:
	var handler: Node = _handlers.get(action.category)
	if handler == null:
		push_error("ActionSystem: no handler for category '%s'" % action.category)
		return ActionResult.failed("no handler")
	return await handler.handle_action(action, source_unit)

func _finish_unit_turn(unit: Unit) -> void:
	var unit_name := unit.unit_name if unit != null else "???"
	print("  [Finish] %s releases turn" % unit_name)
	_sm.ctx.active_unit = null
	unit_turn_finished.emit(unit)

# --- InputSystem callbacks ---

func handle_hotkey(action_id: StringName) -> void:
	if _sm.ctx.active_unit == null or _is_executing:
		return
	if not _turn_system.is_unit_acting():
		return
	if _sm.ctx.active_unit.team != 0:
		return
	for action in _sm.ctx.active_unit.get_available_actions():
		if action.action_id == action_id:
			on_action_chosen(action)
			return

func cancel_pending() -> void:
	_sm.on_cancel()

func on_unit_died(unit: Unit) -> void:
	if unit == _sm.ctx.active_unit and not _is_executing:
		_finish_unit_turn(unit)
