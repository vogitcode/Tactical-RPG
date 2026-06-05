class_name FloorTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.20, 0.18, 0.20)
	movement_cost = 1
	blocks_movement = false
	blocks_los = false
	atlas_source_id = 0
	atlas_coords = Vector2i(0, 12)
