class_name FireTile
extends BaseTile

@export var fire_damage: int = 3

func _init() -> void:
	base_color = Color(1.0, 0.45, 0.0)
	movement_cost = 1
	hazard_cost = 5   # A* prefers to route around fire; actual MP cost remains 1
	blocks_los = false
	atlas_source_id = 2  # tileset 32x32.png
	atlas_coords = Vector2i(0, 1)  # bottom-left = red
	reacts_to_turn_start = true

func on_turn_start(ctx: TileContexts.TileTurnContext) -> Array[TileRequest]:
	return _fire_requests(ctx.unit)

func _fire_requests(node: Node) -> Array[TileRequest]:
	var unit := node as Unit
	if unit == null or not unit.is_alive():
		return []
	var req := TileRequest.TileCommandRequest.new()
	req.target = unit
	req.command = FixedDamageCommand.new(fire_damage)
	return [req]
