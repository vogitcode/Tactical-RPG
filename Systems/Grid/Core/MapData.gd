## Data container produced by a layout script or MapGenerator.
## GridSystem consumes this via SystemManager.load_map_data().
## Keys in tiles are Vector2i → BaseTile overrides.
## Cells not listed remain as FloorTile (GridData default).
class_name MapData
extends Resource

## Tile overrides. Keys: Vector2i, Values: BaseTile instance.
var tiles: Dictionary = {}

## { unit_data: UnitData, cell: Vector2i, team: int }
var unit_placements: Array[Dictionary] = []

## { prop: BaseProp, cell: Vector2i, highlight: bool }
var prop_placements: Array[Dictionary] = []

## { zone: ZoneData, cells: Array[Vector2i], highlight: bool }
var zone_placements: Array[Dictionary] = []
