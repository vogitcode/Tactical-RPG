## Base class for all values returned by tile hooks.
## Tiles return Array[TileRequest]; TileProcessor dispatches on subtype.
class_name TileRequest
extends RefCounted


## Request to execute a command on a unit standing on or entering the tile.
## The tile sets target + command; TileProcessor builds TileContext and invokes.
class TileCommandRequest extends TileRequest:
	var target: Node          # Unit
	var command: BaseCommand  # what to execute on target


## Request to replace a tile with a different type (e.g. WaterTile → IceTile).
class TileTransformRequest extends TileRequest:
	var target_pos: Vector2i
	var new_tile: BaseTile
