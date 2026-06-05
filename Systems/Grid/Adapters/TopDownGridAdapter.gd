class_name TopDownGridAdapter
extends GridCoordinateAdapter

var cell_size: Vector2i = Vector2i(32, 32)
var origin: Vector2 = Vector2.ZERO

func _init(cfg: GridConfig) -> void:
	cell_size = cfg.cell_size
	origin = cfg.cell_offset

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y) + origin

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local := world_pos - origin
	return Vector2i(
		int(local.x / cell_size.x),
		int(local.y / cell_size.y)
	)

func get_cell_size() -> Vector2i:
	return cell_size
