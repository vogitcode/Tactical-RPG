class_name CorruptionTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.35, 0.00, 0.45)
	movement_cost = 2
	hazard_cost = 3   # slow AND dangerous — A* avoids unless no alternative
	blocks_movement = false
	blocks_los = false
	atlas_source_id = 2  # tileset 32x32.png
	atlas_coords = Vector2i(1, 0)  # top-right = dark purple
