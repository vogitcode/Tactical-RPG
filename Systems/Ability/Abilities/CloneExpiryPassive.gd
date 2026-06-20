## Passive added to clones at spawn time. Tracks alive turns and emits expired
## when the clone has lived long enough. Self-contained: no external refs needed.
## Compositor wires expired → cleanup via UnitManager.clone_spawned.
class_name CloneExpiryPassive
extends BasePassive

signal expired

var max_alive_turns: int = 1
var _alive_turns: int = 0

func get_hook_ids() -> Array[StringName]:
	return [HookId.ON_UNIT_TURN_END]

func handle_hook(hook_id: StringName, _ctx: PassiveContext) -> void:
	if hook_id == HookId.ON_UNIT_TURN_END:
		_alive_turns += 1
		if _alive_turns >= max_alive_turns:
			expired.emit()
