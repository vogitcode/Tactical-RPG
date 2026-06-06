## Abstract base for every action a unit can perform.
## Subclass this and override can_execute() if needed.
## Execution is handled by the handler system registered for this action's category.
class_name BaseAction
extends Resource

## SELF  — targets the caster; executes immediately without a tile click.
## TILE  — requires the player to click a destination tile (movement, AoE placement).
## UNIT  — requires the player to click a tile occupied by a target unit.
enum TargetMode { SELF, TILE, UNIT }

@export var action_id: StringName = &""
@export var action_name: String = "Action"
@export var action_description: String = ""
@export var ap_cost: int = 1
@export var base_rp: int = 10
@export var offensive_stat: StringName = &""

## Set in subclass _init(). Determines whether a tile click is required before execution.
var target_mode: TargetMode = TargetMode.SELF

## Dispatch routing — set in subclass _init(). Matches registered handler key in ActionSystem.
var category: StringName = &""

## Set to true in subclass _init() if execution should mark unit.has_acted on completion.
var _sets_has_acted: bool = false

func can_execute(unit: Unit) -> bool:
	if not unit.is_alive():
		return false
	if unit.action_points < ap_cost:
		return false
	return true

func on_selected(_unit: Unit, _grid_system: GridSystem) -> void:
	pass

func on_deselected(_unit: Unit, _grid_system: GridSystem) -> void:
	pass

## Returns true when this action has enough data to execute immediately.
## SELF actions are always resolved. TILE/UNIT actions override this to check runtime data.
func is_target_resolved() -> bool:
	return target_mode == TargetMode.SELF

## Called by ActionSystem when the player clicks a tile during AWAITING_TARGET.
## Validate the tile and populate target data on the action.
## Return false to reject the click and stay in AWAITING_TARGET.
func resolve_target(_grid_pos: Vector2i, _source_unit: Unit, _grid_system: GridSystem) -> bool:
	return true

## Clear any target data set during the selection phase.
## Called after execution so the next turn starts fresh.
func clear_target() -> void:
	pass

## Display category for grouping in the action menu.
func get_category() -> String:
	return "basic"
