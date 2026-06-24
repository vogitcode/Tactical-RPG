class_name WaterTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.18, 0.38, 0.62)
	movement_cost = 2
	blocks_los = false
	atlas_source_id = 1  # animated-tiles.png
	atlas_coords = Vector2i(0, 10)  # blue water row
