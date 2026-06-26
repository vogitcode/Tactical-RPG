## Manages temporary zone effects on the battle grid.
##
## Zones coexist with tiles on the same cell. ZoneProcessor:
##   - Handles placement conflict (priority wins — higher number survives).
##   - Tracks which unit is currently inside which zone (apply-once per entry).
##   - Dispatches effects on "unit_entered", "unit_stepped", "on_turn_start" triggers.
##   - Ticks duration once per complete turn cycle; removes expired zones.
##
## Wire in SystemManager._wire_systems():
##   zone_processor.setup(grid_system)
##   _move_system.unit_stepped.connect(zone_processor._on_unit_stepped)
##   turn_system.unit_turn_started.connect(zone_processor._on_unit_turn_started)
##   turn_system.turn_started.connect(zone_processor._on_turn_cycle_started)
##   unit_manager.unit_died.connect(zone_processor._on_unit_died)
class_name ZoneProcessor
extends Node

var _grid_system: GridSystem

## Vector2i → ZoneData
var _zones: Dictionary = {}
## Vector2i → int (remaining turns; -1 = permanent, managed separately from ZoneData)
var _zone_turns: Dictionary = {}
## Unit → Vector2i (the zone cell the unit is currently tracked inside)
var _unit_zone_cell: Dictionary = {}

func setup(grid: GridSystem) -> void:
	_grid_system = grid

# --- Zone management ---

func place_zone(zone: ZoneData, cell: Vector2i) -> void:
	var existing := _zones.get(cell, null) as ZoneData
	if existing != null and zone.priority <= existing.priority:
		return
	_zones[cell] = zone
	_zone_turns[cell] = zone.duration_turns

func remove_zone(cell: Vector2i) -> void:
	_zones.erase(cell)
	_zone_turns.erase(cell)
	for unit in _unit_zone_cell.keys():
		if _unit_zone_cell[unit] == cell:
			_unit_zone_cell.erase(unit)

func get_zone_at(cell: Vector2i) -> ZoneData:
	return _zones.get(cell, null) as ZoneData

func has_zone_at(cell: Vector2i) -> bool:
	return _zones.has(cell)

# --- Signal subscribers ---

## Called after each movement step tween completes (MoveSystem.unit_stepped).
## Fires "unit_entered" when unit first enters a zone cell, "unit_stepped" if already inside.
func _on_unit_stepped(unit: Unit, cell: Vector2i) -> void:
	var prev_cell: Variant = _unit_zone_cell.get(unit, null)

	if prev_cell != null and prev_cell != cell:
		_unit_zone_cell.erase(unit)
		prev_cell = null

	var zone := get_zone_at(cell)
	if zone == null:
		return

	if prev_cell == null:
		_unit_zone_cell[unit] = cell
		if &"unit_entered" in zone.triggers:
			_apply_zone_effect(zone, unit, cell)
	else:
		if &"unit_stepped" in zone.triggers:
			_apply_zone_effect(zone, unit, cell)

## Called at the start of each unit's turn (TurnSystem.unit_turn_started).
## Fires "on_turn_start" for the zone on the unit's current cell.
func _on_unit_turn_started(unit: Unit, is_deferred: bool) -> void:
	if is_deferred:
		return
	var zone := get_zone_at(unit.grid_position)
	if zone == null or not &"on_turn_start" in zone.triggers:
		return
	_apply_zone_effect(zone, unit, unit.grid_position)

## Called once per complete turn cycle (TurnSystem.turn_started).
## Decrements duration and removes expired zones.
func _on_turn_cycle_started(_turn: int) -> void:
	var to_remove: Array = []
	for cell in _zone_turns.keys():
		var turns: int = _zone_turns[cell]
		if turns > 0:
			_zone_turns[cell] = turns - 1
			if _zone_turns[cell] == 0:
				to_remove.append(cell)
	for cell in to_remove:
		remove_zone(cell)

## Cleans up tracking when a unit dies (UnitManager.unit_died).
func _on_unit_died(unit: Unit) -> void:
	_unit_zone_cell.erase(unit)

# --- Internal ---

func _apply_zone_effect(zone: ZoneData, unit: Unit, cell: Vector2i) -> void:
	if zone.default_command == null or not unit.is_alive():
		return
	var ctx := ActionContext.new()
	ctx.target_unit = unit
	ctx.target_cell = cell
	ctx.grid_system = _grid_system
	zone.default_command.execute_async(ctx)
