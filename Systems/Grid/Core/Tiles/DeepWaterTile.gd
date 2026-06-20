class_name DeepWaterTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.05, 0.12, 0.40)
	movement_cost = 1
	blocks_movement = true
	blocks_los = false
	atlas_source_id = 2  # tileset 32x32.png
	atlas_coords = Vector2i(0, 0)  # top-left = dark navy blue
