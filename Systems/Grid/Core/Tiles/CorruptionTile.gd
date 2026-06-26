class_name CorruptionTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.35, 0.00, 0.45)
	movement_cost = 2
	hazard_cost = 3   # slow AND dangerous — A* avoids unless no alternative
	blocks_los = false
	atlas_source_id = 2  # tileset 32x32.png
	atlas_coords = Vector2i(1, 0)  # top-right = dark purple
	reacts_to_round_start = true

func on_round_start(ctx: TileContexts.TileRoundContext) -> Array[TileRequest]:
	var requests: Array[TileRequest] = []
	for neighbor in ctx.neighbors:
		if neighbor.tile == null:
			continue
		var immune = neighbor.tile.get(&"immune_to_spread")
		if immune != null and immune:
			continue
		if neighbor.tile is CorruptionTile:
			continue
		var req := TileRequest.TileTransformRequest.new()
		req.target_pos = neighbor.pos
		req.new_tile = CorruptionTile.new()
		requests.append(req)
	return requests
