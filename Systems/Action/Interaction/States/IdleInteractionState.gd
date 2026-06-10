## Waiting state — no active unit, no pending action.
## Transitions to MENU_OPEN when TurnSystem assigns a player unit.
class_name IdleInteractionState
extends PlayerInteractionState

func on_unit_acting(unit: Unit) -> void:
	_sm.ctx.active_unit = unit
	transition_requested.emit(self, Phase.MENU_OPEN)
