## Player ability: spawn a clone of the caster on a nearby empty tile.
## Clone inherits the same unit_data (stats + actions + passives) and matches caster's current HP.
## Costs all AP — caster cannot act again after cloning.
class_name CloneAbility
extends BaseAction

const PLACEMENT_RANGE: int = 2

var target_cell: Vector2i = Vector2i(-1, -1)

func _init() -> void:
	action_id = &"clone"
	action_name = "Clone"
	action_description = "Triệu hồi bản sao tại ô trống lân cận (phạm vi 2). Bản sao có cùng stats và passives."
	ap_cost = 2
	_sets_has_acted = true
	target_mode = TargetMode.TILE
	category = &"ability"

func can_execute(unit: Unit) -> bool:
	if not super.can_execute(unit):
		return false
	if unit.unit_data == null:
		return false
	return true

func on_selected(unit: Unit, grid_system: GridSystem) -> void:
	grid_system.show_move_range(_get_valid_cells(unit, grid_system))

func on_deselected(_unit: Unit, grid_system: GridSystem) -> void:
	grid_system.clear_highlights()

func resolve_target(grid_pos: Vector2i, source_unit: Unit, grid_system: GridSystem) -> bool:
	var dx: int = abs(grid_pos.x - source_unit.grid_position.x)
	var dy: int = abs(grid_pos.y - source_unit.grid_position.y)
	var dist: int = dx + dy
	if dist < 1 or dist > PLACEMENT_RANGE:
		return false
	if not grid_system.is_valid(grid_pos):
		return false
	if grid_system.get_occupant(grid_pos) != null:
		return false
	var tile: BaseTile = grid_system.get_tile(grid_pos)
	if tile == null or not tile.can_enter(source_unit):
		return false
	target_cell = grid_pos
	return true

func is_target_resolved() -> bool:
	return target_cell != Vector2i(-1, -1)

func clear_target() -> void:
	target_cell = Vector2i(-1, -1)

func get_category() -> String:
	return "ability"

func _get_valid_cells(unit: Unit, grid_system: GridSystem) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var origin := unit.grid_position
	for dx in range(-PLACEMENT_RANGE, PLACEMENT_RANGE + 1):
		for dy in range(-PLACEMENT_RANGE, PLACEMENT_RANGE + 1):
			var dist: int = abs(dx) + abs(dy)
			if dist < 1 or dist > PLACEMENT_RANGE:
				continue
			var pos := origin + Vector2i(dx, dy)
			if not grid_system.is_valid(pos):
				continue
			if grid_system.get_occupant(pos) != null:
				continue
			var tile: BaseTile = grid_system.get_tile(pos)
			if tile != null and tile.can_enter(unit):
				result.append(pos)
	return result
