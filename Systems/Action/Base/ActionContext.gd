## Context for combat / ability / reaction effect pipelines.
## Carries source unit, target, grid access, and combat outcome.
class_name ActionContext
extends BaseContext

var source_unit: Unit = null
var target_cell: Vector2i = Vector2i(-1, -1)
var condition_result: ConditionResult = null
