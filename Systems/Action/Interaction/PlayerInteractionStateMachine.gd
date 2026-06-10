## Player interaction state machine — manages IDLE / MENU_OPEN / TARGETING phases.
## Routes input from ActionSystem to the current state.
## ActionSystem owns execution logic; this SM owns interaction mode.
class_name PlayerInteractionStateMachine
extends Node

var ctx: PlayerInteractionContext
var current_state: PlayerInteractionState

var _states: Dictionary = {}  # Phase → PlayerInteractionState

func _ready() -> void:
	ctx = PlayerInteractionContext.new()

func init(action_system: ActionSystem, grid_system: GridSystem) -> void:
	ctx.action_system = action_system
	ctx.grid_system = grid_system
	for child in get_children():
		if child is PlayerInteractionState:
			_states[child.phase] = child
			child.transition_requested.connect(_on_transition_requested)
	current_state = _states.get(PlayerInteractionState.Phase.IDLE)
	if current_state:
		current_state.enter()

## Helper used by states to show the action menu at the unit's grid position.
func show_menu(unit: Unit) -> void:
	if unit == null:
		return
	var pos: Vector2 = ctx.grid_system.get_cell_center(unit.grid_position)
	ctx.action_system.show_menu_requested.emit(unit, pos + Vector2(40, -20))

# --- Input routing (called by ActionSystem) ---

func on_unit_acting(unit: Unit) -> void:
	if current_state:
		current_state.on_unit_acting(unit)

func on_tile_clicked(pos: Vector2i) -> void:
	if current_state:
		current_state.on_tile_clicked(pos)

func on_action_chosen(action: BaseAction) -> void:
	if current_state:
		current_state.on_action_chosen(action)

func on_menu_closed() -> void:
	if current_state:
		current_state.on_menu_closed()

func on_cancel() -> void:
	if current_state:
		current_state.on_cancel()

# --- Queries ---

func is_targeting() -> bool:
	return current_state != null and current_state.phase == PlayerInteractionState.Phase.TARGETING

func is_idle() -> bool:
	return current_state == null or current_state.phase == PlayerInteractionState.Phase.IDLE

# --- Transition ---

func _on_transition_requested(from: PlayerInteractionState, to: PlayerInteractionState.Phase) -> void:
	if from != current_state:
		return
	var new_state: PlayerInteractionState = _states.get(to)
	if new_state == null:
		return
	current_state.exit()
	current_state = new_state
	current_state.enter()
