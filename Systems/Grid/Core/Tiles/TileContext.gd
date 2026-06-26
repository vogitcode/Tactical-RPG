## Context for tile-triggered effect pipelines.
## Carries the affected unit, the tile that triggered the effect, and its grid position.
class_name TileContext
extends BaseContext

var tile: BaseTile = null
var pos: Vector2i = Vector2i.ZERO
