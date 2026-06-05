class_name VoidTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.08, 0.08, 0.08)
	movement_cost = 1
	blocks_movement = true
	blocks_los = true
	atlas_source_id = 0
	atlas_coords = Vector2i(0, 11)  # very dark row
