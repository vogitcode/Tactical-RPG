## Pre-effect for DashAttack: moves the attacker to the adjacent cell closest to target.
## Internal version — no path traversal, no unit_stepped signal, no zone/prop reactions
## along the dash path. Fires ON_DASH_EXECUTED on attacker after landing.
##
## Upgrade path (external): call MoveSystem.execute_move_async() with a computed path,
## emitting unit_stepped per cell to trigger prop/zone reactions and "charge through" damage.
class_name DashMoveEffect
extends BaseEffect

const DASH_DURATION: float = 0.08

func execute_async(ctx: ActionContext) -> void:
	if ctx.target_cell == Vector2i(-1, -1):
		return

	var dest := _find_dash_dest(ctx.unit.grid_position, ctx.target_cell, ctx.grid_system)

	if dest != ctx.unit.grid_position:
		var start_pos := ctx.unit.position
		ctx.grid_system.move_unit(ctx.unit, dest)
		var end_pos := ctx.unit.position
		ctx.unit.position = start_pos

		var tween := ctx.unit.create_tween()
		tween.tween_property(ctx.unit, "position", end_pos, DASH_DURATION)
		await tween.finished

	var dash_ctx := DashContext.new()
	dash_ctx.unit = ctx.unit
	dash_ctx.target_unit = ctx.target_unit
	ctx.unit.fire_hook(HookId.ON_DASH_EXECUTED, dash_ctx)

## Returns the adjacent cell of [target] closest to [from].
## Falls back to [from] (no movement) if all adjacent cells are blocked.
func _find_dash_dest(from: Vector2i, target: Vector2i, grid: GridSystem) -> Vector2i:
	var candidates: Array[Vector2i] = [
		target + Vector2i(1, 0),
		target + Vector2i(-1, 0),
		target + Vector2i(0, 1),
		target + Vector2i(0, -1),
	]
	var best := from
	var best_dist := INF
	for cell in candidates:
		if cell == from:
			continue
		if not grid.is_valid(cell):
			continue
		if not grid.is_passable(cell):
			continue
		if grid.get_occupant(cell) != null:
			continue
		var dist: float = Vector2(cell - from).length()
		if dist < best_dist:
			best_dist = dist
			best = cell
	return best
