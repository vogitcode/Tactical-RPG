## Player ability: place a trap on an adjacent tile.
## Any unit stepping on the cell takes damage and has movement interrupted.
class_name SetTrapAbility
extends BaseAbility

const PLACEMENT_RANGE: int = 1

var target_cell: Vector2i = Vector2i(-1, -1)

func _init() -> void:
	action_id = &"set_trap"
	action_name = "Set Trap"
	action_description = "Đặt bẫy tại ô lân cận. Unit bước vào sẽ chịu sát thương và bị dừng di chuyển."
	ap_cost = 1
	target_mode = TargetMode.TILE
	category = &"ability"

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
	if grid_system.is_prop_at(grid_pos):
		return false
	var tile: BaseTile = grid_system.get_tile(grid_pos)
	if tile == null or not tile.passable:
		return false
	target_cell = grid_pos
	return true

func is_target_resolved() -> bool:
	return target_cell != Vector2i(-1, -1)

func clear_target() -> void:
	target_cell = Vector2i(-1, -1)

func execute(ctx: AbilityExecutionContext) -> ActionResult:
	ctx.prop_system.place_prop(TrapProp.new(), target_cell)
	ctx.source_unit.action_points -= ap_cost
	return ActionResult.completed()

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
			if grid_system.is_prop_at(pos):
				continue
			var tile: BaseTile = grid_system.get_tile(pos)
			if tile != null and tile.passable:
				result.append(pos)
	return result
