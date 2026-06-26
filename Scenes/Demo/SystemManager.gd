## System compositor — wires all gameplay systems together.
## Map data is provided externally via load_map_data(MapData).
##
## Responsibilities:
##   - Hold @onready references to every gameplay system
##   - initialize(): wire internal signals between systems
##   - load_map_data(): build tiles, spawn units, place zones/props
##   - start_battle(): delegate to TurnSystem
##
## Does NOT know about WorldUIManager — that lives at the compositor (Map1) level.
## Does NOT own game lifecycle — the scene compositor controls init order.
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
@onready var zone_processor: ZoneProcessor             = $ZoneProcessor
@onready var prop_system: PropSystem                   = $PropSystem
@onready var tile_processor: TileProcessor             = $TileProcessor
@onready var ability_system: AbilitySystem             = $ActionHolder/AbilitySystem

# --- Public API (called by GameLoop) ---

## Phase 1 — wire all gameplay systems together.
## Call before load_map_data().
func initialize() -> void:
	_wire_systems()

## Phase 2 — build tiles, spawn units, place zones/props, register units.
## Call after initialize(), before start_battle().
func load_map_data(map_data: MapData) -> void:
	_build_tiles(map_data)
	_spawn_units(map_data)
	_place_zones(map_data)
	_place_props(map_data)
	turn_system.register_units(unit_manager.get_all_units())

## Starts the battle. Called by GameLoop after cross-boundary wiring is done.
func start_battle() -> void:
	turn_system.start_battle()

# --- Map data population ---

func _build_tiles(map_data: MapData) -> void:
	for pos: Vector2i in map_data.tiles:
		grid_system.set_tile(pos, map_data.tiles[pos])

func _spawn_units(map_data: MapData) -> void:
	for entry: Dictionary in map_data.unit_placements:
		var unit_data: UnitData = entry["unit_data"]
		var cell: Vector2i = entry["cell"]
		var team: int = entry["team"]
		var unit := unit_manager.spawn_unit(unit_data, team)
		grid_system.place_unit(unit, cell)

# --- Internal system wiring ---

func _wire_systems() -> void:
	input_system.setup(grid_system)
	_move_system.setup(grid_system, _interrupt_manager)
	_combat_system.setup(grid_system, _interrupt_manager)
	action_system.setup(grid_system, turn_system)
	action_system.register_handler(&"move", _move_system)
	action_system.register_handler(&"combat", _combat_system)
	action_system.register_handler(&"turn_control", turn_system)
	ability_system.setup(grid_system, unit_manager, turn_system)
	action_system.register_handler(&"ability", ability_system)
	reaction_system.setup(_interrupt_manager, grid_system, action_system)
	_move_system.unit_stepped.connect(reaction_system.evaluate_step)
	ai_system.setup(grid_system, unit_manager, action_system)
	action_system.ai_turn_requested.connect(ai_system.on_ai_turn_requested)

	zone_processor.setup(grid_system)
	_move_system.unit_stepped.connect(zone_processor._on_unit_stepped)
	# Zone fires before tile on turn_start — connection order determines call order.
	turn_system.unit_turn_started.connect(zone_processor._on_unit_turn_started)
	turn_system.turn_started.connect(zone_processor._on_turn_cycle_started)
	unit_manager.unit_died.connect(zone_processor._on_unit_died)

	prop_system.setup(grid_system)
	_move_system.unit_stepped.connect(prop_system._on_unit_stepped)
	turn_system.unit_turn_started.connect(prop_system._on_unit_turn_started)
	unit_manager.unit_died.connect(prop_system._on_unit_died)
	prop_system.prop_removed.connect(grid_system.prop_visualizer.remove_at)

	var trap_check := TrapAbortCheck.new()
	prop_system.set_trap_abort_check(trap_check)
	_move_system.move_execution_started.connect(func(ctx: MoveExecutionContext) -> void:
		trap_check.reset()
		ctx.register(trap_check)
	)

	tile_processor.setup(grid_system)
	_move_system.unit_stepped.connect(tile_processor._on_unit_stepped)
	# unit_turn_started: zone → prop → tile (connection order = call order)
	turn_system.unit_turn_started.connect(tile_processor._on_unit_turn_started)
	turn_system.turn_started.connect(tile_processor._on_round_started)

	input_system.tile_clicked.connect(grid_system.on_tile_clicked)
	input_system.tile_hovered.connect(grid_system.on_tile_hovered)
	input_system.action_hotkey_pressed.connect(action_system.handle_hotkey)
	input_system.cancel_requested.connect(action_system.cancel_pending)

	turn_system.unit_turn_start_state.activated.connect(turn_effect_processor.on_unit_turn_start)
	turn_system.unit_turn_end_state.activated.connect(turn_effect_processor.on_unit_turn_end)
	turn_system.unit_acting_state.activated.connect(action_system.on_unit_acting)
	action_system.unit_turn_finished.connect(turn_system.on_unit_turn_finished, CONNECT_DEFERRED)

	turn_system.unit_turn_started.connect(_on_unit_turn_started)
	turn_system.unit_turn_ended.connect(_on_unit_turn_ended)

	unit_manager.unit_died.connect(_on_unit_died)
	unit_manager.unit_died.connect(action_system.on_unit_died)
	unit_manager.unit_died.connect(turn_system.on_unit_died)

	unit_manager.clone_spawned.connect(_on_clone_spawned)

	# GoalSystem: subscribe to unit death, notify TurnSystem via signal
	goal_system.setup(unit_manager)
	unit_manager.unit_died.connect(goal_system.on_unit_died)
	goal_system.goal_achieved.connect(turn_system.trigger_battle_end)

# --- Zones ---

func _place_zones(map_data: MapData) -> void:
	for entry: Dictionary in map_data.zone_placements:
		var zone: ZoneData = entry["zone"]
		var cells: Array[Vector2i] = []
		cells.assign(entry["cells"])
		for cell in cells:
			zone_processor.place_zone(zone, cell)
		if entry.get("highlight", false):
			grid_system.visualizer.highlight_cells(cells, GridVisualizer.HighlightType.DANGER)

# --- Props ---

func _place_props(map_data: MapData) -> void:
	for entry: Dictionary in map_data.prop_placements:
		var prop: BaseProp = entry["prop"]
		var cell: Vector2i = entry["cell"]
		prop_system.place_prop(prop, cell)
		grid_system.prop_visualizer.place(cell, prop)
		if entry.get("highlight", false):
			grid_system.visualizer.highlight_cells([cell], GridVisualizer.HighlightType.DANGER)

# --- Display callbacks ---

func _on_unit_turn_started(unit: Unit, _is_deferred: bool) -> void:
	grid_system.highlight_selected(unit.grid_position)

func _on_unit_turn_ended(_unit: Unit) -> void:
	grid_system.visualizer.clear_highlights(GridVisualizer.HighlightType.SELECTED)

func _on_unit_died(unit: Unit) -> void:
	grid_system.data.clear_occupant(unit.grid_position)

func _on_clone_spawned(clone: Unit) -> void:
	var expiry := clone.get_capability(&"clone_expiry") as CloneExpiryPassive
	expiry.expired.connect(_on_clone_expired.bind(clone))

func _on_clone_expired(clone: Unit) -> void:
	grid_system.data.clear_occupant(clone.grid_position)
	turn_system.remove_unit(clone)
	unit_manager.on_clone_expired(clone)
