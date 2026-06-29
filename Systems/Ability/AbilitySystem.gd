## Handler for player abilities — registered with ActionSystem for category &"ability".
## Dispatches to BaseAbility.execute(ctx) via Strategy pattern.
## Needs setup() before use — called by SystemManager._wire_systems().
class_name AbilitySystem
extends Node

var _grid_system: GridSystem
var _unit_manager: UnitManager
var _turn_system: TurnSystem
var _prop_system: PropSystem
var _unit_spawner: UnitSpawner

func setup(grid: GridSystem, unit_manager: UnitManager, turn_system: TurnSystem, prop_system: PropSystem, unit_spawner: UnitSpawner) -> void:
	_grid_system = grid
	_unit_manager = unit_manager
	_turn_system = turn_system
	_prop_system = prop_system
	_unit_spawner = unit_spawner

## Handler interface — called by ActionSystem._dispatch() for category &"ability".
func handle_action(action: BaseAction, source_unit: Unit) -> ActionResult:
	await get_tree().process_frame
	var ctx := _build_context(source_unit)
	return await (action as BaseAbility).execute(ctx)

func _build_context(unit: Unit) -> AbilityExecutionContext:
	var ctx := AbilityExecutionContext.new()
	ctx.source_unit = unit
	ctx.grid_system = _grid_system
	ctx.unit_manager = _unit_manager
	ctx.turn_system = _turn_system
	ctx.prop_system = _prop_system
	ctx.unit_spawner = _unit_spawner
	return ctx
