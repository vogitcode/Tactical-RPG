## Base class for all player abilities.
## Subclass this and implement execute(ctx) — AbilitySystem calls it via Strategy dispatch.
## Target resolution (on_selected, resolve_target, is_target_resolved) stays in each subclass.
class_name BaseAbility
extends BaseAction

## Override in subclass to implement ability logic.
## ctx carries all service references — use only what the ability needs.
func execute(_ctx: AbilityExecutionContext) -> ActionResult:
	return ActionResult.completed()
