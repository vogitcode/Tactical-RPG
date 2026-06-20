class_name FireTile
extends BaseTile

@export var fire_damage: int = 3

func _init() -> void:
	base_color = Color(1.0, 0.45, 0.0)
	movement_cost = 1
	hazard_cost = 5   # A* prefers to route around fire; actual MP cost remains 1
	blocks_movement = false
	blocks_los = false
	atlas_source_id = 2  # tileset 32x32.png
	atlas_coords = Vector2i(0, 1)  # bottom-left = red

func on_unit_enter(unit: Node, _grid_pos: Vector2i) -> void:
	_apply_fire(unit)

func on_turn_start(unit: Node, _grid_pos: Vector2i) -> void:
	_apply_fire(unit)

func _apply_fire(node: Node) -> void:
	var unit := node as Unit
	if unit == null or not unit.is_alive():
		return
	print("[FireTile] ", unit.unit_name, " bị apply burn effect")
	unit.take_damage(fire_damage)
