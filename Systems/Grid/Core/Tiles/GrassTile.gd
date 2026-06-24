class_name GrassTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.25, 0.55, 0.25)
	movement_cost = 1
	blocks_los = false
	atlas_source_id = 0
	atlas_coords = Vector2i(0, 15)
