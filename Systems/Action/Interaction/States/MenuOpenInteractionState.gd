## Action menu is visible for the active unit.
## Routes action choices to execution or targeting depending on whether target is resolved.
class_name MenuOpenInteractionState
extends PlayerInteractionState

func enter() -> void:
	_sm.show_menu(_sm.ctx.active_unit)

func on_action_chosen(action: BaseAction) -> void:
	_sm.ctx.pending_action = action
	if action.is_target_resolved():
		_sm.ctx.action_system.request_execute(action)
		transition_requested.emit(self, Phase.IDLE)
	else:
		action.on_selected(_sm.ctx.active_unit, _sm.ctx.grid_system)
		transition_requested.emit(self, Phase.TARGETING)

func on_menu_closed() -> void:
	_sm.ctx.pending_action = null
	transition_requested.emit(self, Phase.IDLE)

func on_tile_clicked(pos: Vector2i) -> void:
	var occupant: Unit = _sm.ctx.grid_system.get_occupant(pos)
	if occupant == _sm.ctx.active_unit:
		_sm.show_menu(_sm.ctx.active_unit)
