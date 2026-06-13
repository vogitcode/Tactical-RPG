## Facade — the only entry point other systems use to interact with the grid.
## Owns GridData (state), uses GridLogic (algorithms), delegates visuals to GridVisualizer.
class_name GridSystem
extends Node

signal tile_clicked(grid_pos: Vector2i)
signal tile_hovered(grid_pos: Vector2i)
signal unit_moved(unit: Unit, from: Vector2i, to: Vector2i)

@export var config: GridConfig

var data: GridData
var _adapter: TopDownGridAdapter
var _extra_passable_checks: Array[Callable] = []

@onready var visualizer: GridVisualizer = $GridVisualizer

func _ready() -> void:
	if config == null:
		config = GridConfig.new()
	_adapter = TopDownGridAdapter.new(config)
	data = GridData.new(config)
	visualizer.setup(data, _adapter)

# --- Map setup ---

func set_tile(pos: Vector2i, tile: BaseTile) -> void:
	data.set_tile(pos, tile)
	visualizer.refresh_tile(pos, tile)

func get_tile(pos: Vector2i) -> BaseTile:
	return data.get_tile(pos)

func place_unit(unit: Unit, pos: Vector2i) -> void:
	data.set_occupant(pos, unit)
	_position_unit_on_grid(unit, pos)
	unit.set_grid_position(pos)

# --- Unit movement ---

func move_unit(unit: Unit, to: Vector2i) -> void:
	var from: Vector2i = unit.grid_position
	var from_tile := data.get_tile(from)
	var to_tile := data.get_tile(to)

	if from_tile:
		from_tile.on_unit_exit(unit, from)

	data.move_occupant(from, to)
	_position_unit_on_grid(unit, to)
	unit.set_grid_position(to)

	if to_tile:
		to_tile.on_unit_enter(unit, to)

	unit_moved.emit(unit, from, to)

# --- Passable check registry (Option B — no GridData changes) ---

## Register an extra passability condition: func(pos: Vector2i) -> bool
## Returns true if pos is BLOCKED by that condition.
func register_passable_check(check: Callable) -> void:
	_extra_passable_checks.append(check)

func _build_passable_override(unit: Unit = null) -> Callable:
	if _extra_passable_checks.is_empty():
		return Callable()
	var checks := _extra_passable_checks.duplicate()
	return func(pos: Vector2i) -> bool:
		for c in checks:
			if c.call(pos):
				return false
		if unit != null:
			return data.is_passable_for(pos, unit)
		return data.is_passable(pos)

# --- Queries exposed to other systems ---

func get_reachable_cells(from: Vector2i, move_points: int, unit: Unit = null) -> Array[Vector2i]:
	return GridLogic.get_reachable_cells(data, from, move_points, _build_passable_override(unit))

func get_attack_range_cells(from: Vector2i, min_r: int, max_r: int) -> Array[Vector2i]:
	return GridLogic.get_range_cells(data, from, min_r, max_r)

func find_path(from: Vector2i, to: Vector2i, unit: Unit = null) -> Array[Vector2i]:
	return GridLogic.find_path(data, from, to, unit, _build_passable_override(unit))

func get_occupant(pos: Vector2i) -> Unit:
	return data.get_occupant(pos) as Unit

func is_valid(pos: Vector2i) -> bool:
	return data.is_valid(pos)

func is_passable(pos: Vector2i) -> bool:
	return data.is_passable(pos)

# --- Highlight shortcuts ---

func show_move_range(cells: Array[Vector2i]) -> void:
	visualizer.clear_highlights()
	visualizer.highlight_cells(cells, GridVisualizer.HighlightType.MOVE_RANGE)

func show_attack_range(cells: Array[Vector2i]) -> void:
	visualizer.clear_highlights()
	visualizer.highlight_cells(cells, GridVisualizer.HighlightType.ATTACK_RANGE)

func show_path(cells: Array[Vector2i]) -> void:
	visualizer.highlight_cells(cells, GridVisualizer.HighlightType.PATH)

func highlight_selected(pos: Vector2i) -> void:
	visualizer.set_selected_cell(pos)

func clear_highlights() -> void:
	visualizer.clear_highlights()

# --- World position helpers ---

func grid_to_world(pos: Vector2i) -> Vector2:
	return visualizer.to_global(_adapter.grid_to_world(pos))

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return _adapter.world_to_grid(visualizer.to_local(world_pos))

func get_cell_center(pos: Vector2i) -> Vector2:
	var world := _adapter.grid_to_world(pos)
	return visualizer.to_global(world + Vector2(config.cell_size) * 0.5)

# --- Turn hook callbacks (called by TurnSystem via SystemManager wiring) ---

func fire_unit_turn_start(unit: Unit) -> void:
	var tile := data.get_tile(unit.grid_position)
	if tile:
		tile.on_turn_start(unit, unit.grid_position)

# --- Input receivers (called by InputSystem via Demo wiring) ---

func on_tile_clicked(grid_pos: Vector2i) -> void:
	tile_clicked.emit(grid_pos)

func on_tile_hovered(grid_pos: Vector2i) -> void:
	visualizer.set_hovered_cell(grid_pos)
	if data.is_valid(grid_pos):
		tile_hovered.emit(grid_pos)

# --- Private ---

func _position_unit_on_grid(unit: Unit, pos: Vector2i) -> void:
	var world := _adapter.grid_to_world(pos)
	unit.position = visualizer.to_local(world) + Vector2(config.cell_size) * 0.5
