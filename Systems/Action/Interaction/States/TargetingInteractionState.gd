## Awaiting a grid click to resolve the pending action's target.
## Cancel returns to MENU_OPEN; closing the menu has no effect (we keep targeting).
class_name TargetingInteractionState
extends PlayerInteractionState

func on_tile_clicked(pos: Vector2i) -> void:
	var action: BaseAction = _sm.ctx.pending_action
	if action == null:
		return
	if not action.resolve_target(pos, _sm.ctx.active_unit, _sm.ctx.grid_system):
		return
	action.on_deselected(_sm.ctx.active_unit, _sm.ctx.grid_system)
	_sm.ctx.action_system.request_execute(action)
	transition_requested.emit(self, Phase.IDLE)

func on_cancel() -> void:
	var action: BaseAction = _sm.ctx.pending_action
	if action != null:
		action.on_deselected(_sm.ctx.active_unit, _sm.ctx.grid_system)
	_sm.ctx.pending_action = null
	transition_requested.emit(self, Phase.MENU_OPEN)

func on_menu_closed() -> void:
	pass  # menu closes when targeting begins — ignore, stay in TARGETING
