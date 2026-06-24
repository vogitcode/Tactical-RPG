class_name GridData
extends RefCounted

var width: int
var height: int
var _tiles: Dictionary = {}  # Vector2i -> BaseTile
var _units: Dictionary = {}  # Vector2i -> Node (Unit)
var _props: Dictionary = {}  # Vector2i -> Node (Prop)

func _init(cfg: GridConfig) -> void:
	width = cfg.grid_width
	height = cfg.grid_height
	_fill_default()

func _fill_default() -> void:
	for x in range(width):
		for y in range(height):
			_tiles[Vector2i(x, y)] = FloorTile.new()

# --- Tile layer ---

func is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_tile(pos: Vector2i) -> BaseTile:
	return _tiles.get(pos)

func set_tile(pos: Vector2i, tile: BaseTile) -> void:
	if is_valid(pos):
		_tiles[pos] = tile

## Tile-only check: is the terrain passable? Does NOT check unit occupancy.
## Combined check (tile + occupant) lives in GridSystem.is_occupied() / _build_traversal_override().
func is_passable_tile(pos: Vector2i) -> bool:
	var tile := _tiles.get(pos) as BaseTile
	return tile != null and tile.passable

## All valid tile positions — used by TileProcessor for round-start spread iteration.
func get_all_tile_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_tiles.keys())
	return result

## Returns all tile positions matching a predicate: func(tile: BaseTile) -> bool
func get_all_cells_where(predicate: Callable) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in _tiles:
		if predicate.call(_tiles[pos]):
			result.append(pos)
	return result

# --- Unit occupancy layer ---

func get_occupant(pos: Vector2i) -> Node:
	return _units.get(pos)

func set_occupant(pos: Vector2i, unit: Node) -> void:
	_units[pos] = unit

func clear_occupant(pos: Vector2i) -> void:
	_units.erase(pos)

func move_occupant(from: Vector2i, to: Vector2i) -> void:
	var unit:Node = _units.get(from)
	_units.erase(from)
	if unit != null:
		_units[to] = unit

# --- Prop layer ---

func get_prop(pos: Vector2i) -> Node:
	return _props.get(pos)

func set_prop(pos: Vector2i, prop: Node) -> void:
	_props[pos] = prop

func clear_prop(pos: Vector2i) -> void:
	_props.erase(pos)
