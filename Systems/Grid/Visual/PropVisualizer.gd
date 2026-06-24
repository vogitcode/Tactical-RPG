## Visual layer for props — renders a TileMapLayer on top of tile graphics.
## One TileMapLayer per PropVisualizer; source 0 = Prop 32x32.png.
## Attach as a child Node2D of GridVisualizer so coordinate spaces match.
class_name PropVisualizer
extends Node2D

var _prop_map: TileMapLayer = null
var _tile_set: TileSet = null
var _prop_source: TileSetAtlasSource = null

func setup(cell_size: Vector2i) -> void:
	_build_tile_set(cell_size)
	_create_prop_map()

func place(cell: Vector2i, prop: BaseProp) -> void:
	if _prop_map == null or prop.atlas_coords == Vector2i(-1, -1):
		return
	_ensure_tile_registered(prop.atlas_source_id, prop.atlas_coords)
	_prop_map.set_cell(cell, prop.atlas_source_id, prop.atlas_coords)

func remove_at(cell: Vector2i) -> void:
	if _prop_map != null:
		_prop_map.erase_cell(cell)

func _build_tile_set(cell_size: Vector2i) -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = cell_size
	_prop_source = TileSetAtlasSource.new()
	_prop_source.texture = load("res://Assets/Character and Tile/Tileset/Prop 32x32.png")
	_prop_source.texture_region_size = cell_size
	_tile_set.add_source(_prop_source, 0)

func _create_prop_map() -> void:
	_prop_map = TileMapLayer.new()
	_prop_map.tile_set = _tile_set
	add_child(_prop_map)

func _ensure_tile_registered(source_id: int, coords: Vector2i) -> void:
	var source := _tile_set.get_source(source_id) as TileSetAtlasSource
	if source != null and not source.has_tile(coords):
		source.create_tile(coords)
