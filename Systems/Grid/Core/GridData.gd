class_name GridData
extends RefCounted

class CellData:
	var tile: BaseTile = null
	var elevation: int = 0
	var occupant: Node = null  # Unit reference
	var prop: Node = null      # Interactable object reference

var width: int
var height: int
var _cells: Dictionary = {}  # Vector2i -> CellData

func _init(cfg: GridConfig) -> void:
	width = cfg.grid_width
	height = cfg.grid_height
	_fill_default()

func _fill_default() -> void:
	for x in range(width):
		for y in range(height):
			var cell := CellData.new()
			cell.tile = FloorTile.new()
			_cells[Vector2i(x, y)] = cell

# --- Query ---

func is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_cell(pos: Vector2i) -> CellData:
	return _cells.get(pos)

func get_tile(pos: Vector2i) -> BaseTile:
	var cell := get_cell(pos)
	return cell.tile if cell else null

## Unit-agnostic: blocks_movement + occupant check.
func is_passable(pos: Vector2i) -> bool:
	var cell := get_cell(pos)
	return cell != null and not cell.tile.blocks_movement and cell.occupant == null

## Unit-agnostic: blocks_movement only (ignores occupant).
func is_passable_ignore_occupant(pos: Vector2i) -> bool:
	var cell := get_cell(pos)
	return cell != null and not cell.tile.blocks_movement

## Unit-aware: delegates to tile.can_enter(unit) + occupant check.
## Use this for movement range and pathfinding when the unit is known.
func is_passable_for(pos: Vector2i, unit: Node) -> bool:
	var cell := get_cell(pos)
	return cell != null and cell.tile.can_enter(unit) and cell.occupant == null

## Unit-aware: tile.can_enter(unit) only (ignores occupant).
func is_passable_ignore_occupant_for(pos: Vector2i, unit: Node) -> bool:
	var cell := get_cell(pos)
	return cell != null and cell.tile.can_enter(unit)

func get_occupant(pos: Vector2i) -> Node:
	var cell := get_cell(pos)
	return cell.occupant if cell else null

# --- Mutation ---

func set_tile(pos: Vector2i, tile: BaseTile) -> void:
	var cell := get_cell(pos)
	if cell:
		cell.tile = tile

func set_occupant(pos: Vector2i, unit: Node) -> void:
	var cell := get_cell(pos)
	if cell:
		cell.occupant = unit

func clear_occupant(pos: Vector2i) -> void:
	var cell := get_cell(pos)
	if cell:
		cell.occupant = null

func move_occupant(from: Vector2i, to: Vector2i) -> void:
	var unit := get_occupant(from)
	clear_occupant(from)
	set_occupant(to, unit)

func set_prop(pos: Vector2i, prop: Node) -> void:
	var cell := get_cell(pos)
	if cell:
		cell.prop = prop

# --- Bulk helpers ---

## Returns all cell positions matching a predicate: func(cell: CellData) -> bool
func get_all_cells_where(predicate: Callable) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in _cells:
		if predicate.call(_cells[pos]):
			result.append(pos)
	return result
