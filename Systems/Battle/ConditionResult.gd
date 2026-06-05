## Result of an Arbitrator resolution — who wins the confrontation.
## Both flags true = tie (both sides execute partially).
class_name ConditionResult
extends RefCounted

var initiator_wins: bool = false
var reactor_wins: bool = false

static func full_initiator() -> ConditionResult:
	var r := ConditionResult.new()
	r.initiator_wins = true
	return r

static func full_reactor() -> ConditionResult:
	var r := ConditionResult.new()
	r.reactor_wins = true
	return r

## Tie — both sides execute with partial outcome.
static func both_partial() -> ConditionResult:
	var r := ConditionResult.new()
	r.initiator_wins = true
	r.reactor_wins = true
	return r

func initiator_hit() -> bool:
	return initiator_wins

func reactor_hit() -> bool:
	return reactor_wins
