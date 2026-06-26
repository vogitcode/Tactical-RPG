## Dispatches tile hook calls and executes tile commands.
##
## Subscribes to movement and turn signals; builds context objects and
## passes them to BaseTile hooks; executes TileCommandRequest inline
## (same invoker pattern as ZoneProcessor).
##
## Wire in SystemManager._wire_systems():
##   tile_processor.setup(grid_system)
##   _move_system.unit_stepped.connect(tile_processor._on_unit_stepped)
##   turn_system.unit_turn_started.connect(tile_processor._on_unit_turn_started)
##   turn_system.turn_started.connect(tile_processor._on_round_started)
class_name TileProcessor
extends Node

## Prevents infinite tile transform cascades (A → B → A → ...).
const MAX_TRANSFORM_DEPTH: int = 3

var _grid_system: GridSystem

func setup(grid_system: GridSystem) -> void:
	_grid_system = grid_system

# --- Signal handlers ---

func _on_unit_stepped(unit: Unit, cell: Vector2i) -> void:
	var tile := _grid_system.data.get_tile(cell)
	if tile == null or not tile.reacts_to_unit_enter:
		return
	var ctx := TileContexts.TileEnterContext.new()
	ctx.unit = unit
	ctx.pos = cell
	_apply_requests(tile.on_unit_enter(ctx), cell, 0)

func _on_unit_turn_started(unit: Unit, is_deferred: bool) -> void:
	if is_deferred:
		return
	var cell := unit.grid_position
	var tile := _grid_system.data.get_tile(cell)
	if tile == null or not tile.reacts_to_turn_start:
		return
	var ctx := TileContexts.TileTurnContext.new()
	ctx.unit = unit
	ctx.pos = cell
	_apply_requests(tile.on_turn_start(ctx), cell, 0)

## Fires on_round_start for every tile that opts in — once per full turn cycle.
func _on_round_started(_turn_number: int) -> void:
	for pos in _grid_system.data.get_all_tile_positions():
		var tile := _grid_system.data.get_tile(pos)
		if tile == null or not tile.reacts_to_round_start:
			continue
		var ctx := TileContexts.TileRoundContext.new()
		ctx.pos = pos
		ctx.neighbors = _build_neighbors(pos)
		_apply_requests(tile.on_round_start(ctx), pos, 0)

# --- Request dispatch ---

func _apply_requests(requests: Array[TileRequest], pos: Vector2i, depth: int) -> void:
	if depth >= MAX_TRANSFORM_DEPTH:
		return
	var pending_transforms: Array[TileRequest.TileTransformRequest] = []
	for req in requests:
		var cmd_req := req as TileRequest.TileCommandRequest
		if cmd_req != null:
			_execute_command(cmd_req, pos)
			continue
		var transform := req as TileRequest.TileTransformRequest
		if transform != null:
			pending_transforms.append(transform)

	for transform in pending_transforms:
		_grid_system.set_tile(transform.target_pos, transform.new_tile)

func _execute_command(req: TileRequest.TileCommandRequest, pos: Vector2i) -> void:
	if req.command == null:
		return
	var target := req.target as Unit
	if target == null or not target.is_alive():
		return
	var ctx := TileContext.new()
	ctx.target_unit = target
	ctx.grid_system = _grid_system
	ctx.pos = pos
	req.command.execute_async(ctx)

# --- Context helpers ---

func _build_neighbors(pos: Vector2i) -> Array[TileNeighborInfo]:
	var neighbors: Array[TileNeighborInfo] = []
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for d in dirs:
		var npos := pos + d
		if not _grid_system.data.is_valid(npos):
			continue
		var info := TileNeighborInfo.new()
		info.pos = npos
		info.tile = _grid_system.data.get_tile(npos)
		info.occupant = _grid_system.data.get_occupant(npos)
		neighbors.append(info)
	return neighbors
