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
@onready var prop_visualizer: PropVisualizer = $PropVisualizer

func _ready() -> void:
	if config == null:
		config = GridConfig.new()
	_adapter = TopDownGridAdapter.new(config)
	data = GridData.new(config)
	visualizer.setup(data, _adapter)
	prop_visualizer.setup(config.cell_size)

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
	data.move_occupant(from, to)
	_position_unit_on_grid(unit, to)
	unit.set_grid_position(to)
	unit_moved.emit(unit, from, to)

# --- Passable check registry (Option B — no GridData changes) ---

## Register an extra passability condition: func(pos: Vector2i) -> bool
## Returns true if pos is BLOCKED by that condition.
func register_passable_check(check: Callable) -> void:
	_extra_passable_checks.append(check)

## Generic passable override — no unit, uses tile.passable + occupant.
func _build_passable_override() -> Callable:
	if _extra_passable_checks.is_empty():
		return Callable()
	var checks := _extra_passable_checks.duplicate()
	return func(pos: Vector2i) -> bool:
		for c in checks:
			if c.call(pos):
				return false
		return data.is_passable_tile(pos) and not is_occupied(pos)

## Traversal override for BFS mid-expansion — capability-aware tile check + friendly occupant allowed.
## Enemy-occupied cells block expansion by default.
func _build_traversal_override(unit: Unit) -> Callable:
	var checks := _extra_passable_checks.duplicate()
	return func(pos: Vector2i) -> bool:
		for c in checks:
			if c.call(pos):
				return false
		if not unit.can_traverse(data.get_tile(pos)):
			return false
		var occ := data.get_occupant(pos) as Unit
		if occ == null:
			return true
		return occ.team == unit.team  # friendly = traversable, enemy = blocked

# --- Queries exposed to other systems ---

func get_reachable_cells(from: Vector2i, move_points: int, unit: Unit = null) -> Array[Vector2i]:
	if unit != null:
		var all_cells := GridLogic.get_reachable_cells(data, from, move_points, _build_traversal_override(unit))
		# Post-filter: unit cannot end turn on an occupied cell
		var destinations: Array[Vector2i] = []
		for pos in all_cells:
			if not is_occupied(pos):
				destinations.append(pos)
		return destinations
	return GridLogic.get_reachable_cells(data, from, move_points, _build_passable_override())

func get_attack_range_cells(from: Vector2i, min_r: int, max_r: int) -> Array[Vector2i]:
	return GridLogic.get_range_cells(data, from, min_r, max_r)

func find_path(from: Vector2i, to: Vector2i, unit: Unit = null) -> Array[Vector2i]:
	if unit != null:
		return GridLogic.find_path(data, from, to, unit, _build_traversal_override(unit))
	return GridLogic.find_path(data, from, to, null, _build_passable_override())

## Returns the cell in the [min_r, max_r] ring from `from` that is closest to `toward`.
## Does not filter by occupancy — caller decides what to do with the result.
## Returns Vector2i(-1, -1) if the ring is empty (e.g. out-of-bounds map).
func get_nearest_in_range(from: Vector2i, toward: Vector2i, min_r: int, max_r: int) -> Vector2i:
	var ring := GridLogic.get_range_cells(data, from, min_r, max_r)
	if ring.is_empty():
		return Vector2i(-1, -1)
	var best := ring[0]
	var best_dist := GridLogic.get_manhattan_distance(best, toward)
	for cell in ring.slice(1):
		var d := GridLogic.get_manhattan_distance(cell, toward)
		if d < best_dist:
			best_dist = d
			best = cell
	return best

func get_occupant(pos: Vector2i) -> Unit:
	return data.get_occupant(pos) as Unit

func is_occupied(pos: Vector2i) -> bool:
	return data.get_occupant(pos) != null

func is_valid(pos: Vector2i) -> bool:
	return data.is_valid(pos)

func is_passable(pos: Vector2i) -> bool:
	return data.is_passable_tile(pos) and not is_occupied(pos)

# --- Highlight shortcuts ---

func show_move_range(cells: Array[Vector2i]) -> void:
	visualizer.clear_highlights()
	visualizer.highlight_cells(cells, GridVisualizer.HighlightType.MOVE_RANGE)

func show_attack_range(cells: Array[Vector2i]) -> void:
	visualizer.clear_highlights()
	visualizer.highlight_cells(cells, GridVisualizer.HighlightType.ATTACK_RANGE)

func show_path(cells: Array[Vector2i]) -> void:
	visualizer.show_path_line(cells)

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

## Returns the local position for a cell — same coordinate space as unit.position.
## Use this to compute tween targets without touching occupant data.
func get_cell_position(pos: Vector2i) -> Vector2:
	return visualizer.to_local(_adapter.grid_to_world(pos)) + Vector2(config.cell_size) * 0.5

## Atomic commit after movement completes (or is interrupted).
## Fires tile exit/enter hooks and updates occupant data in one operation.
## Call once at the end of execute_move_async, never during traversal.
func commit_unit_move(unit: Unit, origin: Vector2i, final_cell: Vector2i) -> void:
	data.move_occupant(origin, final_cell)
	unit.set_grid_position(final_cell)
	unit_moved.emit(unit, origin, final_cell)

# --- Turn hook callbacks (called by TurnSystem via SystemManager wiring) ---


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
