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

func is_target_resolved() -> bool:
	return target_unit != null

func clear_target() -> void:
	target_cell = Vector2i(-1, -1)
	target_unit = null

func _init() -> void:
	category = &"combat"
