class_name CorruptionTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.35, 0.00, 0.45)
	movement_cost = 2
	hazard_cost = 3   # slow AND dangerous — A* avoids unless no alternative
	blocks_movement = false
	blocks_los = false
	atlas_source_id = 0
	atlas_coords = Vector2i(2, 16)  # row 16, last of the 3 terrain columns
