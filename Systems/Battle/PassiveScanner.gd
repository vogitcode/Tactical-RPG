## Fires the &"on_combat_resolved" hook on both combatants after each BattleProcess.
## Lives as a child Node of CombatSystem; called from _drain() after _run_process().
## Future: may also enqueue counter-attack BattleProcesses here.
class_name PassiveScanner
extends Node

## Call after _run_process() completes. process.condition_result must be set.
func scan(process: BattleProcess) -> void:
	if process.source_unit == null:
		return
	var ctx := CombatResolvedContext.new()
	ctx.attacker = process.source_unit
	ctx.defender = process.reactor_unit
	ctx.action = process.action
	ctx.condition_result = process.condition_result

	ctx.firing_unit = process.source_unit
	process.source_unit.fire_hook(&"on_combat_resolved", ctx)

	if process.reactor_unit != null and process.reactor_unit.is_alive():
		ctx.firing_unit = process.reactor_unit
		process.reactor_unit.fire_hook(&"on_combat_resolved", ctx)
