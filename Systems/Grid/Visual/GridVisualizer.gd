## Godot-specific visual layer for the grid.
## TileMapLayer child renders the base tile sprites.
## This Node2D renders highlights, grid lines, and hover overlay via _draw()
## on top of the TileMapLayer (z_index layering).
## Swap this class (or its adapter) to change visual style without touching GridData/GridLogic.
class_name GridVisualizer
extends Node2D

enum HighlightType {
	MOVE_RANGE,
	ATTACK_RANGE,
	PATH,
	SELECTED,
	DANGER,
}

const HIGHLIGHT_COLORS: Dictionary = {
	HighlightType.MOVE_RANGE:    Color(0.20, 0.70, 1.00, 0.35),
	HighlightType.ATTACK_RANGE:  Color(1.00, 0.20, 0.20, 0.35),
	HighlightType.PATH:          Color(1.00, 0.90, 0.20, 0.50),
	HighlightType.SELECTED:      Color(0.20, 1.00, 0.40, 0.45),
	HighlightType.DANGER:        Color(1.00, 0.25, 0.00, 0.55),
}
const DANGER_ACCENT := Color(1.0, 0.10, 0.00, 0.90)

const GRID_LINE_COLOR := Color(0.0, 0.0, 0.0, 0.25)
const GRID_LINE_WIDTH := 0.8

# TileSet source IDs — must match the order sources are added in _build_tile_set().
const TILES_SOURCE_ID   := 0  # tiles.png
const ANIM_SOURCE_ID    := 1  # animated-tiles.png
const CUSTOM_SOURCE_ID  := 2  # tileset 32x32.png (fire, deepwater, corruption, void)

const PATH_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.90)
const PATH_LINE_WIDTH := 3.0

var _grid_data: GridData = null
var _adapter: GridCoordinateAdapter = null
var _highlights: Dictionary = {}   # Vector2i -> HighlightType
var _hovered_cell: Vector2i = Vector2i(-1, -1)
var _path_points: PackedVector2Array = []

var _tile_map: TileMapLayer = null
var _tile_set: TileSet = null
var _tiles_source: TileSetAtlasSource = null
var _anim_source: TileSetAtlasSource = null
var _custom_source: TileSetAtlasSource = null

func setup(grid_data: GridData, adapter: GridCoordinateAdapter) -> void:
	_grid_data = grid_data
	_adapter = adapter
	_build_tile_set()
	_create_tile_map()
	_rebuild_tile_map()
	queue_redraw()

# --- Highlight API ---

func highlight_cells(cells: Array[Vector2i], type: HighlightType) -> void:
	for cell in cells:
		_highlights[cell] = type
	queue_redraw()

func clear_highlights(type: HighlightType = -1) -> void:
	if type == -1:
		_highlights.clear()
		_path_points.clear()
	else:
		for key in _highlights.keys():
			if _highlights[key] == type:
				_highlights.erase(key)
	queue_redraw()

func show_path_line(cells: Array[Vector2i]) -> void:
	_path_points.clear()
	var half := Vector2(_adapter.get_cell_size()) * 0.5
	for cell in cells:
		_path_points.append(_adapter.grid_to_world(cell) + half)
	queue_redraw()

func clear_path_line() -> void:
	_path_points.clear()
	queue_redraw()

func set_selected_cell(pos: Vector2i) -> void:
	for key in _highlights.keys():
		if _highlights[key] == HighlightType.SELECTED:
			_highlights.erase(key)
	if _grid_data and _grid_data.is_valid(pos):
		_highlights[pos] = HighlightType.SELECTED
	queue_redraw()

func set_hovered_cell(pos: Vector2i) -> void:
	if pos != _hovered_cell:
		_hovered_cell = pos
		queue_redraw()

# --- Tile refresh (called by GridSystem.set_tile) ---

func refresh_tile(pos: Vector2i, tile: BaseTile) -> void:
	if _tile_map == null:
		return
	if tile == null or tile.atlas_coords == Vector2i(-1, -1):
		_tile_map.erase_cell(pos)
		return
	_ensure_tile_registered(tile.atlas_source_id, tile.atlas_coords)
	_tile_map.set_cell(pos, tile.atlas_source_id, tile.atlas_coords)

# --- Drawing (highlights + grid lines + hover only — tiles handled by TileMapLayer) ---

func _draw() -> void:
	if _grid_data == null or _adapter == null:
		return
	_draw_highlights()
	_draw_grid_lines()
	_draw_hover()
	_draw_path_line()

func _draw_highlights() -> void:
	var cell_size := Vector2(_adapter.get_cell_size())
	for pos in _highlights:
		var type: HighlightType = _highlights[pos]
		var world := _adapter.grid_to_world(pos)
		var color: Color = HIGHLIGHT_COLORS.get(type, Color(1, 1, 1, 0.3))
		draw_rect(Rect2(world, cell_size), color)
		if type == HighlightType.DANGER:
			draw_rect(Rect2(world, cell_size), DANGER_ACCENT, false, 2.0)
			var m := cell_size * 0.2
			draw_line(world + m, world + cell_size - m, DANGER_ACCENT, 1.5)
			draw_line(world + Vector2(cell_size.x - m.x, m.y),
					world + Vector2(m.x, cell_size.y - m.y), DANGER_ACCENT, 1.5)

func _draw_grid_lines() -> void:
	for x in range(_grid_data.width + 1):
		var top := _adapter.grid_to_world(Vector2i(x, 0))
		var bot := _adapter.grid_to_world(Vector2i(x, _grid_data.height))
		draw_line(top, bot, GRID_LINE_COLOR, GRID_LINE_WIDTH)
	for y in range(_grid_data.height + 1):
		var left := _adapter.grid_to_world(Vector2i(0, y))
		var right := _adapter.grid_to_world(Vector2i(_grid_data.width, y))
		draw_line(left, right, GRID_LINE_COLOR, GRID_LINE_WIDTH)

func _draw_path_line() -> void:
	if _path_points.size() < 2:
		return
	draw_polyline(_path_points, PATH_LINE_COLOR, PATH_LINE_WIDTH, true)

func _draw_hover() -> void:
	if _hovered_cell == Vector2i(-1, -1):
		return
	if _grid_data == null or not _grid_data.is_valid(_hovered_cell):
		return
	var world := _adapter.grid_to_world(_hovered_cell)
	var size := Vector2(_adapter.get_cell_size())
	draw_rect(Rect2(world, size), Color(1, 1, 1, 0.15))

# --- Private setup ---

func _build_tile_set() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = _adapter.get_cell_size()

	_tiles_source = TileSetAtlasSource.new()
	_tiles_source.texture = load("res://Assets/Character and Tile/32rogues/tiles.png")
	_tiles_source.texture_region_size = Vector2i(32, 32)
	_tile_set.add_source(_tiles_source, TILES_SOURCE_ID)

	_anim_source = TileSetAtlasSource.new()
	_anim_source.texture = load("res://Assets/Character and Tile/32rogues/animated-tiles.png")
	_anim_source.texture_region_size = Vector2i(32, 32)
	_tile_set.add_source(_anim_source, ANIM_SOURCE_ID)

	_custom_source = TileSetAtlasSource.new()
	_custom_source.texture = load("res://Assets/Character and Tile/Tileset/tileset 32x32.png")
	_custom_source.texture_region_size = Vector2i(32, 32)
	_tile_set.add_source(_custom_source, CUSTOM_SOURCE_ID)

func _create_tile_map() -> void:
	_tile_map = TileMapLayer.new()
	_tile_map.tile_set = _tile_set
	# Render tiles behind this Node2D's _draw() content (highlights/grid lines).
	_tile_map.z_index = -1
	add_child(_tile_map)

func _rebuild_tile_map() -> void:
	if _grid_data == null or _tile_map == null:
		return
	for x in range(_grid_data.width):
		for y in range(_grid_data.height):
			var grid_pos := Vector2i(x, y)
			var tile := _grid_data.get_tile(grid_pos)
			if tile == null:
				continue
			if tile.atlas_coords == Vector2i(-1, -1):
				continue
			_ensure_tile_registered(tile.atlas_source_id, tile.atlas_coords)
			_tile_map.set_cell(grid_pos, tile.atlas_source_id, tile.atlas_coords)

func _ensure_tile_registered(source_id: int, coords: Vector2i) -> void:
	var source := _tile_set.get_source(source_id) as TileSetAtlasSource
	if source and not source.has_tile(coords):
		source.create_tile(coords)
