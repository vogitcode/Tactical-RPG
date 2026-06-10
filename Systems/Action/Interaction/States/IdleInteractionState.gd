## Waiting state — no active unit, no pending action.
## Transitions to MENU_OPEN when TurnSystem assigns a player unit.
class_name IdleInteractionState
extends PlayerInteractionState

func on_unit_acting(unit: Unit) -> void:
	_sm.ctx.active_unit = unit
	transition_requested.emit(self, Phase.MENU_OPEN)

func on_tile_clicked(pos: Vector2i) -> void:
	if _sm.ctx.active_unit == null:
		return
	var occupant: Unit = _sm.ctx.grid_system.get_occupant(pos)
	if occupant == _sm.ctx.active_unit:
		transition_requested.emit(self, Phase.MENU_OPEN)
