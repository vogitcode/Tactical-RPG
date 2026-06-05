## Abstract base — swap implementations to change visual projection
## (TopDown, Isometric, 3D) without touching GridData or GridLogic.
class_name GridCoordinateAdapter
extends RefCounted

func grid_to_world(_grid_pos: Vector2i) -> Vector2:
	return Vector2.ZERO

func world_to_grid(_world_pos: Vector2) -> Vector2i:
	return Vector2i.ZERO

func get_cell_size() -> Vector2i:
	return Vector2i.ZERO
