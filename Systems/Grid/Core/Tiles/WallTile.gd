class_name WallTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.22, 0.20, 0.18)
	movement_cost = 1
	passable = false
	blocks_los = true
	atlas_source_id = 0
	atlas_coords = Vector2i(0, 3)
