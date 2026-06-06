## One execution unit in the CombatSystem queue.
## Holds a typed combat action, its source, and the best reaction found (NullReaction if none).
class_name BattleProcess
extends RefCounted

var action: CombatAction
var source_unit: Unit
var reaction: BaseReaction
var reactor_unit: Unit
var condition_result: ConditionResult
