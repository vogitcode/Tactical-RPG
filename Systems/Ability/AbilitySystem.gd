## Handler for player abilities (Clone, TimeReset, SpaceRift, etc.)
## Registered as ActionSystem handler for category &"ability".
## Needs setup() before use — called by SystemManager._wire_systems().
class_name AbilitySystem
extends Node

var _grid_system: GridSystem
var _unit_manager: UnitManager
var _turn_system: TurnSystem

func setup(grid: GridSystem, unit_manager: UnitManager, turn_system: TurnSystem) -> void:
	_grid_system = grid
	_unit_manager = unit_manager
	_turn_system = turn_system

## Handler interface — called by ActionSystem._dispatch() for category &"ability".
func handle_action(action: BaseAction, source_unit: Unit) -> ActionResult:
	match action.action_id:
		&"clone":
			return await _handle_clone(action as CloneAbility, source_unit)
		_:
			push_error("AbilitySystem: no handler for ability '%s'" % action.action_id)
			return ActionResult.failed("unknown ability")

func _handle_clone(action: CloneAbility, source: Unit) -> ActionResult:
	await get_tree().process_frame
	var clone := _unit_manager.spawn_clone(source.unit_data, source.team, 1)
	_grid_system.place_unit(clone, action.target_cell)
	clone.current_hp = source.current_hp
	_turn_system.add_unit(clone)
	source.action_points -= action.ap_cost
	source.has_acted = true
	return ActionResult.completed()
