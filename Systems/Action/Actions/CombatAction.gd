## Abstract base for all combat actions — attack, ability, item use, etc.
## Carries target data and effect arrays that EffectExecutor runs.
## Subclasses declare specific effects in _init(); system executes them.
class_name CombatAction
extends BaseAction

var target_cell: Vector2i = Vector2i(-1, -1)
var target_unit: Unit = null
## "deterministic" (default) or "probabilistic" — opt-in via item/passive/mechanic.
var check_type: StringName = &"deterministic"

## Effect pipeline — populated in subclass _init(). Not @export so _init() values are used.
var pre_effects: Array[BaseEffect] = []
var on_hit_effects: Array[BaseEffect] = []
var on_miss_effects: Array[BaseEffect] = []
var post_effects: Array[BaseEffect] = []

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
