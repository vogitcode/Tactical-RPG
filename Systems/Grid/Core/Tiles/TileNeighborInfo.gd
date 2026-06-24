## Snapshot of one neighbor cell passed to tile hooks via context objects.
## Tiles must not pull world state directly — context injection only.
class_name TileNeighborInfo
extends RefCounted

var pos: Vector2i
var tile: BaseTile
var occupant: Node  # Unit or null
