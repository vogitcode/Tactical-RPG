## Data bag passed into BaseEffect.execute_async().
## Carries what an effect needs: source unit, target, grid access, and combat outcome.
class_name ActionContext
extends RefCounted

var unit: Unit = null
var target_cell: Vector2i = Vector2i(-1, -1)
var target_unit: Unit = null
var grid_system: GridSystem = null
var condition_result: ConditionResult = null
