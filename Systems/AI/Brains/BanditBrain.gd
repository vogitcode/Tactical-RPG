## Bandit faction AI — aggro, targets nearest enemy, attack if in range else advance.
class_name BanditBrain
extends FactionAIBrain

func decide(unit: Unit, ctx: AIContext) -> BaseAction:
	if ctx.enemies.is_empty():
		return null

	var nearest: Unit = _get_nearest(unit.grid_position, ctx.enemies)
	var dist := GridLogic.get_manhattan_distance(unit.grid_position, nearest.grid_position)

	if dist <= unit.attack_range and not unit.has_acted:
		var attack := AttackAction.new()
		attack.target_cell = nearest.grid_position
		attack.target_unit = nearest
		return attack

	if not unit.has_moved:
		var reachable: Array[Vector2i] = ctx.grid_system.get_reachable_cells(unit.grid_position, unit.move_points)
		if not reachable.is_empty():
			var best := _closest_to(nearest.grid_position, reachable)
			var path: Array[Vector2i] = ctx.grid_system.find_path(unit.grid_position, best, unit)
			if not path.is_empty():
				var move := MoveAction.new()
				move.path = path
				return move

	return null

func _get_nearest(from: Vector2i, units: Array[Unit]) -> Unit:
	var nearest: Unit = units[0]
	var min_dist := GridLogic.get_manhattan_distance(from, nearest.grid_position)
	for u in units.slice(1):
		var d := GridLogic.get_manhattan_distance(from, u.grid_position)
		if d < min_dist:
			min_dist = d
			nearest = u
	return nearest

func _closest_to(target: Vector2i, cells: Array[Vector2i]) -> Vector2i:
	var best := cells[0]
	var min_d := GridLogic.get_manhattan_distance(target, best)
	for c in cells.slice(1):
		var d := GridLogic.get_manhattan_distance(target, c)
		if d < min_d:
			min_d = d
			best = c
	return best
