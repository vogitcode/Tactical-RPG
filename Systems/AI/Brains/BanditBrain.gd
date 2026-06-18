## Bandit faction AI — aggro, targets nearest enemy, attack if in range else advance.
## Committed-path anti-oscillation: path is computed once per approach and reused
## across multiple decide() calls within the same turn. Recalculates only when blocked.
class_name BanditBrain
extends FactionAIBrain

# One brain instance is shared by all bandit units — use per-unit keyed dict.
var _committed_paths: Dictionary = {}  # Unit → Array[Vector2i]

func decide(unit: Unit, ctx: AIContext) -> BaseAction:
	if ctx.enemies.is_empty():
		return null

	var nearest: Unit = _get_nearest(unit.grid_position, ctx.enemies)
	var dist := GridLogic.get_manhattan_distance(unit.grid_position, nearest.grid_position)

	var attack_template: AttackAction = _find_attack_action(unit)
	if attack_template != null and not unit.has_acted:
		var effective_max := unit.get_effective_attack_range(attack_template.max_range)
		if dist >= attack_template.min_range and dist <= effective_max:
			var attack := AttackAction.new()
			attack.min_range = attack_template.min_range
			attack.max_range = attack_template.max_range
			attack.target_cell = nearest.grid_position
			attack.target_unit = nearest
			return attack

	if unit.remaining_mp > 0:
		var full_path := _get_or_commit_path(unit, nearest, ctx)
		if full_path.size() < 2:
			_committed_paths.erase(unit)
			return null

		var reachable: Array[Vector2i] = ctx.grid_system.get_reachable_cells(
			unit.grid_position, unit.remaining_mp, unit
		)
		# Walk committed path; take the furthest step reachable with remaining MP.
		var best := unit.grid_position
		for i in range(1, full_path.size()):
			if full_path[i] in reachable:
				best = full_path[i]
			else:
				break  # past reachable horizon or blocked

		if best == unit.grid_position:
			_committed_paths.erase(unit)  # path blocked — will recompute next call
			return null

		var end_idx := full_path.find(best)
		var path_segment: Array[Vector2i] = []
		path_segment.assign(full_path.slice(0, end_idx + 1))
		var move := MoveAction.new()
		move.path = path_segment
		return move

	return null

## Returns the remaining committed path from unit's current position, or computes a new one.
## Committed path persists across multiple decide() calls within a turn.
## Recalculates only when the unit has drifted off the stored path.
func _get_or_commit_path(unit: Unit, target: Unit, ctx: AIContext) -> Array[Vector2i]:
	var stored: Array[Vector2i] = []
	if _committed_paths.has(unit):
		stored.assign(_committed_paths[unit])
	var idx := stored.find(unit.grid_position)
	if idx >= 0 and idx + 1 < stored.size():
		var remaining: Array[Vector2i] = []
		remaining.assign(stored.slice(idx))
		return remaining
	var path: Array[Vector2i] = ctx.grid_system.find_path(
		unit.grid_position, target.grid_position, unit
	)
	_committed_paths[unit] = path
	return path

func _find_attack_action(unit: Unit) -> AttackAction:
	for action in unit.get_available_actions():
		if action is AttackAction:
			return action as AttackAction
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
