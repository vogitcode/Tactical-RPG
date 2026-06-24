class_name VoidTile
extends BaseTile

func _init() -> void:
	base_color = Color(0.08, 0.08, 0.08)
	movement_cost = 1
	passable = false
	blocks_los = true
	atlas_source_id = 2  # tileset 32x32.png
	atlas_coords = Vector2i(1, 1)  # bottom-right = black (abyss)
