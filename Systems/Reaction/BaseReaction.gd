## Abstract base for all reactions — passive responses to incoming combat actions.
## Subclass this and override can_trigger() + execute_async().
## Stored as Resource (.tres) so reactions are data-driven and shareable.
class_name BaseReaction
extends Resource

@export var base_rp: int = 5
@export var defensive_stat: StringName = &""

## Returns true if this reaction should fire in response to the given combat action.
func can_trigger(_action: CombatAction, _reactor: Unit) -> bool:
	return false

## Visual/mechanical execution when this reaction wins. Override in subclasses.
func execute_async(_reactor: Unit) -> void:
	pass
