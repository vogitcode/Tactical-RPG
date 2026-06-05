## Queries the target unit's reaction list and returns the first that can trigger.
## Returns NullReaction when no reaction applies (no target, or no matching reaction).
class_name ReactionCollector
extends Node

func collect(action: CombatAction, reactor: Unit) -> BaseReaction:
	if reactor == null:
		return NullReaction.new()
	for reaction in reactor.get_reactions():
		var r := reaction as BaseReaction
		if r != null and r.can_trigger(action, reactor):
			return r
	return NullReaction.new()
