## AI infrastructure — routes turn requests to the correct FactionAIBrain.
## Scans children for FactionAIBrain nodes at _ready(); adding a new faction = adding a child node.
## Brain fills action data before submitting — is_target_resolved() returns true, executes immediately.
class_name AISystem
extends Node

## Enable to briefly show move/attack highlights before AI executes — useful for debugging.
@export var show_debug_highlights: bool = false
@export var debug_highlight_duration: float = 0.6

## faction_relationships[faction_id] = list of hostile faction ids
var _faction_relationships: Dictionary = {
	1: [0, 2],
	2: [0, 1],
}

var _brains: Dictionary = {}  # int → FactionAIBrain

var _grid_system: GridSystem = null
var _unit_manager: UnitManager = null
var _action_system: ActionSystem = null

func _ready() -> void:
	for child in get_children():
		if child is FactionAIBrain:
			_brains[child.faction_id] = child

func setup(grid: GridSystem, units: UnitManager, actions: ActionSystem) -> void:
	_grid_system = grid
	_unit_manager = units
	_action_system = actions

func on_ai_turn_requested(unit: Unit) -> void:
	var brain: FactionAIBrain = _brains.get(unit.team) as FactionAIBrain
	if brain == null:
		_action_system.on_action_chosen(EndTurnAction.new())
		return

	await unit.get_tree().create_timer(0.4).timeout

	var ctx: AIContext = _build_context(unit)
	var action: BaseAction = brain.decide(unit, ctx)
	if action == null:
		action = EndTurnAction.new()

	if show_debug_highlights and not (action is TurnControlAction):
		action.on_selected(unit, _grid_system)
		await unit.get_tree().create_timer(debug_highlight_duration).timeout
		action.on_deselected(unit, _grid_system)

	_action_system.on_action_chosen(action)

func _build_context(unit: Unit) -> AIContext:
	var ctx := AIContext.new()
	ctx.acting_unit = unit
	ctx.grid_system = _grid_system

	var hostile: Variant = _faction_relationships.get(unit.team, [])

	for u in _unit_manager.get_living_units():
		if u == unit:
			continue
		if u.team == unit.team:
			ctx.allies.append(u)
		elif u.team in hostile:
			ctx.enemies.append(u)

	return ctx
