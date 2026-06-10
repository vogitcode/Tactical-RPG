## System compositor — wires all gameplay systems together and provides
## the test map configuration for the current battle.
##
## Responsibilities:
##   - Hold @onready references to every gameplay system
##   - initialize(): build map, spawn units, wire internal signals
##   - start_battle(): delegate to TurnSystem (called by GameLoop)
##
## Does NOT know about WorldUIManager — that lives at GameLoop level.
## Does NOT own game lifecycle (no _ready startup) — GameLoop controls init order.
class_name SystemManager
extends Node2D

# --- System references ---
@onready var grid_system: GridSystem                   = $GridSystem
@onready var turn_system: TurnSystem                   = $TurnSystem
@onready var action_system: ActionSystem               = $ActionHolder/ActionSystem
@onready var _interrupt_manager: InterruptManager      = $ActionHolder/InterruptManager
@onready var _move_system: MoveSystem                  = $ActionHolder/MoveSystem
@onready var reaction_system: ReactionSystem           = $ReactionSystem
@onready var input_system: InputSystem                 = $InputSystem
@onready var unit_manager: UnitManager                 = $UnitManager
@onready var goal_system: GoalSystem                   = $GoalSystem
@onready var turn_effect_processor: TurnEffectProcessor = $TurnEffectProcessor
@onready var process_monitor: ProcessMonitor           = $ProcessMonitor
@onready var _combat_system: CombatSystem               = $ActionHolder/CombatSystem
@onready var ai_system: AISystem                       = $AISystem

# --- Public API (called by GameLoop) ---

## Phase 1–3 of initialization. Safe to call after all @onready vars are set.
func initialize() -> void:
	_build_map()
	_spawn_units()
	_wire_systems()
	_setup_reactions()
	turn_system.register_units(unit_manager.get_all_units())

## Starts the battle. Called by GameLoop after cross-boundary wiring is done.
func start_battle() -> void:
	turn_system.start_battle()

# --- Map layout ---

func _build_map() -> void:
	var walls: Array[Vector2i] = [
		Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4),
		Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7),
		Vector2i(5, 1), Vector2i(5, 2),
		Vector2i(9, 3), Vector2i(9, 4), Vector2i(9, 5),
	]
	for pos in walls:
		grid_system.set_tile(pos, WallTile.new())

	var water: Array[Vector2i] = [
		Vector2i(1, 7), Vector2i(2, 7), Vector2i(2, 8), Vector2i(1, 8),
	]
	for pos in water:
		grid_system.set_tile(pos, WaterTile.new())

# --- Unit spawning ---
# UnitManager creates and owns the Unit nodes.
# SystemManager coordinates the cross-system handshake: spawn → place on grid.

func _spawn_units() -> void:
	var knight: UnitData = load("res://Data/Units/KnightData.tres")
	var p1 := unit_manager.spawn_unit(knight, 0)
	grid_system.place_unit(p1, Vector2i(1, 2))

	var rogue: UnitData = load("res://Data/Units/RogueData.tres")
	var p2 := unit_manager.spawn_unit(rogue, 0)
	grid_system.place_unit(p2, Vector2i(2, 4))

	var bandit: UnitData = load("res://Data/Units/BanditData.tres")
	var e1 := unit_manager.spawn_unit(bandit, 1)
	grid_system.place_unit(e1, Vector2i(9, 2))

	var e2 := unit_manager.spawn_unit(bandit, 1)
	grid_system.place_unit(e2, Vector2i(10, 6))

# --- Internal system wiring ---

func _wire_systems() -> void:
	input_system.setup(grid_system)
	_move_system.setup(grid_system, _interrupt_manager)
	_combat_system.setup(grid_system, _interrupt_manager)
	action_system.setup(grid_system, turn_system)
	action_system.register_handler(&"move", _move_system)
	action_system.register_handler(&"combat", _combat_system)
	action_system.register_handler(&"turn_control", turn_system)
	reaction_system.setup(_interrupt_manager, grid_system, action_system)
	_move_system.unit_stepped.connect(reaction_system.evaluate_step)
	ai_system.setup(grid_system, unit_manager, action_system)
	action_system.ai_turn_requested.connect(ai_system.on_ai_turn_requested)

	input_system.tile_clicked.connect(grid_system.on_tile_clicked)
	input_system.tile_hovered.connect(grid_system.on_tile_hovered)
	input_system.action_hotkey_pressed.connect(action_system.handle_hotkey)
	input_system.cancel_requested.connect(action_system.cancel_pending)

	turn_system.unit_turn_start_state.activated.connect(turn_effect_processor.on_unit_turn_start)
	turn_system.unit_turn_end_state.activated.connect(turn_effect_processor.on_unit_turn_end)
	turn_system.unit_acting_state.activated.connect(action_system.on_unit_acting)
	action_system.unit_turn_finished.connect(turn_system.unit_acting_state.release_unit_turn, CONNECT_DEFERRED)

	turn_system.unit_turn_started.connect(grid_system.fire_unit_turn_start)
	turn_system.unit_turn_started.connect(_on_unit_turn_started)
	turn_system.unit_turn_ended.connect(_on_unit_turn_ended)

	unit_manager.unit_died.connect(_on_unit_died)

	# GoalSystem: subscribe to unit death, notify TurnSystem via signal
	goal_system.setup(unit_manager)
	goal_system.goal_achieved.connect(turn_system.trigger_battle_end)

# --- Reactions ---

func _setup_reactions() -> void:
	reaction_system.register_interrupt_rule(
		func(unit: Unit, cell: Vector2i) -> bool:
			return cell == Vector2i(6, 3) and unit.team == 0,
		"trap"
	)
	grid_system.visualizer.highlight_cells([Vector2i(6, 3)], GridVisualizer.HighlightType.DANGER)

# --- Display callbacks ---

func _on_unit_turn_started(unit: Unit) -> void:
	grid_system.highlight_selected(unit.grid_position)

func _on_unit_turn_ended(_unit: Unit) -> void:
	grid_system.visualizer.clear_highlights(GridVisualizer.HighlightType.SELECTED)

func _on_unit_died(unit: Unit) -> void:
	grid_system.data.clear_occupant(unit.grid_position)
