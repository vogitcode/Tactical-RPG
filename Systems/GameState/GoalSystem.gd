## Evaluates win/lose conditions independently of TurnSystem.
## Subscribes to unit death events (not turn boundaries) so conditions
## are caught the moment they become true — mid-turn included.
##
## To notify TurnSystem: wire goal_achieved → turn_system.trigger_battle_end
## in the Compositor (SystemManager). GoalSystem does NOT reference TurnSystem directly.
class_name GoalSystem
extends Node

signal goal_achieved(result: StringName)

var _unit_manager: UnitManager = null

func setup(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager

func on_unit_died(_unit: Unit) -> void:
	_evaluate_conditions()

func _evaluate_conditions() -> void:
	var team0_alive := not _unit_manager.get_units_of_team(0).is_empty()
	var team1_alive := not _unit_manager.get_units_of_team(1).is_empty()

	if not team0_alive and not team1_alive:
		goal_achieved.emit(&"draw")
	elif not team1_alive:
		goal_achieved.emit(&"win")
	elif not team0_alive:
		goal_achieved.emit(&"lose")
