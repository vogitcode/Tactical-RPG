## Runs a CombatAction's effect arrays according to the ConditionResult.
## pre → hit/miss (based on condition) → post.
## Handles AP deduction, has_acted bookkeeping, and clears grid highlights.
class_name EffectExecutor
extends Node

func execute(action: CombatAction, source_unit: Unit, condition: ConditionResult, grid_system: GridSystem) -> ActionResult:
	var ctx := ActionContext.new()
	ctx.unit = source_unit
	ctx.target_cell = action.target_cell
	ctx.target_unit = action.target_unit
	ctx.grid_system = grid_system
	ctx.condition_result = condition

	await _run_effects(action.pre_effects, ctx)
	if condition.initiator_hit():
		await _run_effects(action.on_hit_effects, ctx)
	else:
		await _run_effects(action.on_miss_effects, ctx)
	await _run_effects(action.post_effects, ctx)

	source_unit.action_points -= action.ap_cost
	if action._sets_has_acted:
		source_unit.has_acted = true
	grid_system.clear_highlights()
	return ActionResult.completed()

func _run_effects(effects: Array[BaseEffect], ctx: ActionContext) -> void:
	for effect in effects:
		await effect.execute_async(ctx)
