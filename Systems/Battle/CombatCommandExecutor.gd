## Runs a CombatAction's command arrays according to the ConditionResult.
## pre → hit/miss (based on condition) → post.
## Handles AP deduction, has_acted bookkeeping, and clears grid highlights.
class_name CombatCommandExecutor
extends Node

func execute(action: CombatAction, source_unit: Unit, condition: ConditionResult, grid_system: GridSystem) -> ActionResult:
	var ctx := ActionContext.new()
	ctx.source_unit = source_unit
	ctx.target_cell = action.target_cell
	ctx.target_unit = action.target_unit
	ctx.grid_system = grid_system
	ctx.condition_result = condition

	await _run_commands(action.pre_commands, ctx)
	if condition.initiator_hit():
		await _run_commands(action.on_hit_commands, ctx)
	else:
		await _run_commands(action.on_miss_commands, ctx)
	await _run_commands(action.post_commands, ctx)

	source_unit.action_points -= action.ap_cost
	if action._sets_has_acted:
		source_unit.has_acted = true
	grid_system.clear_highlights()
	return ActionResult.completed()

func _run_commands(commands: Array[BaseCommand], ctx: BaseContext) -> void:
	for command in commands:
		await command.execute_async(ctx)
