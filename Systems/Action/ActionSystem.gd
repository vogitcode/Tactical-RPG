## Pure dispatcher — receives action requests and routes to the registered handler.
## Handler systems register themselves via register_handler(category, handler).
## ActionSystem does NOT know action business logic; each handler system owns its domain.
class_name ActionSystem
extends Node

signal action_execution_started(action: BaseAction, unit: Unit)
signal action_execution_finished(action: BaseAction, unit: Unit, result: ActionResult)
signal show_menu_requested(unit: Unit, position: Vector2)
signal ai_turn_requested(unit: Unit)
signal unit_turn_finished

@onready var _interrupt_manager: InterruptManager = $InterruptManager

var _grid_system: GridSystem = null
var _turn_system: TurnSystem = null
var _handlers: Dictionary = {}  # StringName → Node

var _active_unit: Unit = null
var _pending_action: BaseAction = null
var _state: _State = _State.IDLE

enum _State { IDLE, AWAITING_TARGET, EXECUTING }

# --- Setup ---

func setup(grid: GridSystem, turns: TurnSystem) -> void:
	_grid_system = grid
	_turn_system = turns
	_grid_system.tile_clicked.connect(_on_tile_clicked)

func register_handler(category: StringName, handler: Node) -> void:
	_handlers[category] = handler

# --- TurnSystem callback ---

func on_unit_acting(unit: Unit, _token: StateCompletionToken) -> void:
	_active_unit = unit
	_state = _State.IDLE
	_pending_action = null

	if unit.team == 0:
		var screen_pos: Vector2 = _grid_system.get_cell_center(unit.grid_position)
		show_menu_requested.emit(unit, screen_pos + Vector2(40, -20))
	else:
		ai_turn_requested.emit(unit)

# --- Action submission (public) ---

func on_action_chosen(action: BaseAction) -> void:
	if _active_unit == null:
		return
	_pending_action = action

	if action.is_target_resolved():
		_execute_pending(action)
	else:
		action.on_selected(_active_unit, _grid_system)
		_state = _State.AWAITING_TARGET

func on_menu_closed() -> void:
	if _state == _State.AWAITING_TARGET and _pending_action != null:
		return
	_pending_action = null
	_state = _State.IDLE

# --- Grid click callback ---

func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if _state != _State.AWAITING_TARGET or _active_unit == null or _pending_action == null:
		var occupant: Unit = _grid_system.get_occupant(grid_pos)
		if occupant != null and occupant == _active_unit and _turn_system.is_unit_acting():
			var screen_pos: Vector2 = _grid_system.get_cell_center(grid_pos)
			show_menu_requested.emit(_active_unit, screen_pos + Vector2(40, -20))
		return

	if not _pending_action.resolve_target(grid_pos, _active_unit, _grid_system):
		return

	_pending_action.on_deselected(_active_unit, _grid_system)
	_execute_pending(_pending_action)

# --- Execution ---

func _execute_pending(action: BaseAction) -> void:
	_state = _State.EXECUTING
	_pending_action = null

	var unit_name := _active_unit.unit_name if _active_unit != null else "???"
	print("  [Action] %s → %s (AP before: %d)" % [unit_name, action.action_name, _active_unit.action_points if _active_unit != null else -1])
	action_execution_started.emit(action, _active_unit)
	var result: ActionResult = await _dispatch(action, _active_unit)
	action.clear_target()
	print("  [Result] %s → %s status=%s (AP after: %d)" % [unit_name, action.action_name, ActionResult.Status.keys()[result.status], _active_unit.action_points if _active_unit != null else -1])
	action_execution_finished.emit(action, _active_unit, result)

	_state = _State.IDLE

	if _active_unit == null:
		return
	if result.status == ActionResult.Status.DEFERRED:
		_turn_system.defer_unit(_active_unit)
		_finish_unit_turn()
	elif _active_unit.action_points <= 0 or action.action_id == &"end_turn":
		_finish_unit_turn()
	elif _active_unit.team == 0:
		var screen_pos: Vector2 = _grid_system.get_cell_center(_active_unit.grid_position)
		show_menu_requested.emit(_active_unit, screen_pos + Vector2(40, -20))
	else:
		ai_turn_requested.emit(_active_unit)

func _dispatch(action: BaseAction, source_unit: Unit) -> ActionResult:
	var handler: Node = _handlers.get(action.category)
	if handler == null:
		push_error("ActionSystem: no handler for category '%s'" % action.category)
		return ActionResult.failed("no handler")
	return await handler.handle_action(action, source_unit)

func _finish_unit_turn() -> void:
	var unit_name := _active_unit.unit_name if _active_unit != null else "???"
	print("  [Finish] %s releases turn" % unit_name)
	unit_turn_finished.emit()

# --- InputSystem callbacks ---

func handle_hotkey(action_id: StringName) -> void:
	if _active_unit == null or _state == _State.EXECUTING:
		return
	if not _turn_system.is_unit_acting():
		return
	if _active_unit.team != 0:
		return
	for action in _active_unit.get_available_actions():
		if action.action_id == action_id:
			on_action_chosen(action)
			return

func cancel_pending() -> void:
	if _state != _State.AWAITING_TARGET or _pending_action == null:
		return
	_pending_action.on_deselected(_active_unit, _grid_system)
	_pending_action = null
	_state = _State.IDLE
	if _active_unit != null and _active_unit.team == 0:
		var screen_pos := _grid_system.get_cell_center(_active_unit.grid_position)
		show_menu_requested.emit(_active_unit, screen_pos + Vector2(40, -20))

func get_interrupt_manager() -> InterruptManager:
	return _interrupt_manager
