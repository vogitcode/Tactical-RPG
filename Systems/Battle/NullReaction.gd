## Placeholder reaction representing the absence of a response.
## When Arbitrator receives NullReaction, the initiator wins fully by definition.
class_name NullReaction
extends BaseReaction

func can_trigger(_action: CombatAction, _reactor: Unit) -> bool:
	return false

func execute_async(_reactor: Unit) -> void:
	pass
