## Abstract base for all combat actions — attack, ability, item use, etc.
## Carries target data and command arrays that CombatCommandExecutor runs.
## Subclasses declare specific commands in _init(); system executes them.
class_name CombatAction
extends BaseAction

var target_cell: Vector2i = Vector2i(-1, -1)
var target_unit: Unit = null
## "deterministic" (default) or "probabilistic" — opt-in via item/passive/mechanic.
var check_type: StringName = &"deterministic"

## Command pipeline — populated in subclass _init(). Not @export so _init() values are used.
var pre_commands: Array[BaseCommand] = []
var on_hit_commands: Array[BaseCommand] = []
var on_miss_commands: Array[BaseCommand] = []
var post_commands: Array[BaseCommand] = []

func _init() -> void:
	target_mode = TargetMode.UNIT
	category = &"combat"

func is_target_resolved() -> bool:
	return target_unit != null

func resolve_target(grid_pos: Vector2i, _source_unit: Unit, grid_system: GridSystem) -> bool:
	target_cell = grid_pos
	target_unit = grid_system.get_occupant(grid_pos)
	return true

func clear_target() -> void:
	target_cell = Vector2i(-1, -1)
	target_unit = null
