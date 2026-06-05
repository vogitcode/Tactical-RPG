class_name GridLogic
extends RefCounted

# --- Flood fill: movement range (BFS, ignores occupants on intermediate cells) ---

static func get_reachable_cells(
	grid: GridData,
	from: Vector2i,
	move_points: int,
	passable_override: Callable = Callable()  # optional: func(pos) -> bool
) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var queue: Array = [[from, 0]]
	var visited: Dictionary = {from: 0}

	while not queue.is_empty():
		var current: Array = queue.pop_front()
		var pos: Vector2i = current[0]
		var cost: int = current[1]

		if pos != from:
			reachable.append(pos)

		for neighbor in get_4_neighbors(pos):
			if not grid.is_valid(neighbor):
				continue
			var passable: bool
			if passable_override.is_valid():
				passable = passable_override.call(neighbor)
			else:
				passable = grid.is_passable(neighbor)
			if not passable:
				continue
			var tile_cost := 1
			var neighbor_cell := grid.get_cell(neighbor)
			if neighbor_cell and neighbor_cell.tile:
				tile_cost = neighbor_cell.tile.movement_cost
			var new_cost: int = cost + tile_cost
			if new_cost <= move_points and (not visited.has(neighbor) or visited[neighbor] > new_cost):
				visited[neighbor] = new_cost
				queue.append([neighbor, new_cost])

	return reachable

# --- A* pathfinding ---

static func find_path(grid: GridData, from: Vector2i, to: Vector2i, unit: Node = null) -> Array[Vector2i]:
	if not grid.is_valid(to):
		return []

	var open_set: Array = [[_heuristic(from, to), 0, from, []]]
	var visited: Dictionary = {}

	while not open_set.is_empty():
		open_set.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var current: Array = open_set.pop_front()
		var g: int = current[1]
		var pos: Vector2i = current[2]
		var path: Array = current[3]

		if visited.has(pos):
			continue
		visited[pos] = true

		if pos == to:
			var result: Array[Vector2i] = []
			result.assign(path + [pos])
			return result

		for neighbor in get_4_neighbors(pos):
			if visited.has(neighbor):
				continue
			if not grid.is_valid(neighbor):
				continue
			var passable: bool = grid.is_passable_for(neighbor, unit) if unit != null else grid.is_passable(neighbor)
			if not passable and neighbor != to:
				continue
			var tile_cost := 1
			var neighbor_cell := grid.get_cell(neighbor)
			if neighbor_cell and neighbor_cell.tile:
				tile_cost = neighbor_cell.tile.get_movement_cost(unit) if unit != null else neighbor_cell.tile.movement_cost
			var new_g: int = g + tile_cost
			var new_f: int = new_g + _heuristic(neighbor, to)
			open_set.append([new_f, new_g, neighbor, path + [pos]])

	return []  # no path found

# --- Attack / ability range (Manhattan distance ring) ---

static func get_range_cells(
	grid: GridData,
	from: Vector2i,
	min_range: int,
	max_range: int
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var dist: int = abs(x) + abs(y)
			if dist < min_range or dist > max_range:
				continue
			var target := from + Vector2i(x, y)
			if grid.is_valid(target):
				cells.append(target)
	return cells

# --- Line of sight (simple ray march on grid) ---

static func has_line_of_sight(grid: GridData, from: Vector2i, to: Vector2i) -> bool:
	var cells := _get_line_cells(from, to)
	for i in range(1, cells.size() - 1):  # skip start and end
		var cell := grid.get_cell(cells[i])
		if cell == null or cell.tile == null or cell.tile.blocks_los:
			return false
	return true

# --- Utility ---

static func get_4_neighbors(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(0, -1),
		pos + Vector2i(1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(-1, 0),
	]

static func get_manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# --- Private ---

static func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

static func _get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var dx: int = abs(to.x - from.x)
	var dy: int = abs(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx - dy
	var x: int = from.x
	var y: int = from.y

	while true:
		cells.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

	return cells
