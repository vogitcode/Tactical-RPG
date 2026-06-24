## Base class for all values returned by tile hooks.
## Tiles return Array[TileRequest]; TileProcessor dispatches on subtype.
class_name TileRequest
extends RefCounted


## Request to apply a gameplay effect to a unit standing on or entering the tile.
class TileEffectRequest extends TileRequest:
	var target: Node          # Unit
	var effect_type: StringName  # &"damage", &"heal", &"apply_status"
	var amount: int = 0
	var status_id: StringName = &""


## Request to replace a tile with a different type (e.g. WaterTile → IceTile).
class TileTransformRequest extends TileRequest:
	var target_pos: Vector2i
	var new_tile: BaseTile
