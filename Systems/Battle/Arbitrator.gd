## Resolves a binary confrontation between an initiator action and a reactor.
##
## Flow:
##   1. NullReaction → full_initiator() immediately (no RP calculation).
##   2. Otherwise: compute final_RP for each side, dispatch on check_type.
##
## RP formula (Phase 2: base_rp only):
##   final_RP = base_rp
##   Future: + stat_modifier + trait + passive + status + equip + tile + level
##
## Deterministic (default): RP1 > RP2 → initiator wins; tie → both_partial.
## Probabilistic (opt-in via action.check_type): RP1/(RP1+RP2) = win probability.
class_name Arbitrator
extends Node

func resolve(action: CombatAction, source_unit: Unit, reaction: BaseReaction, reactor_unit: Unit) -> ConditionResult:
	if reaction is NullReaction:
		return ConditionResult.full_initiator()

	var initiator_rp := _compute_rp(action.base_rp, source_unit, action.offensive_stat)
	var reactor_rp := _compute_rp(reaction.base_rp, reactor_unit, reaction.defensive_stat)

	if action.check_type == &"probabilistic":
		return _resolve_probabilistic(initiator_rp, reactor_rp)
	return _resolve_deterministic(initiator_rp, reactor_rp)

func _compute_rp(base_rp: int, unit: Unit, stat_name: StringName) -> int:
	var ctx := RPQueryContext.new()
	ctx.stat_name = stat_name
	unit.fire_hook(HookId.GET_RP_BONUS, ctx)
	return base_rp + ctx.bonus_rp

func _resolve_deterministic(initiator_rp: int, reactor_rp: int) -> ConditionResult:
	if initiator_rp > reactor_rp:
		return ConditionResult.full_initiator()
	if reactor_rp > initiator_rp:
		return ConditionResult.full_reactor()
	return ConditionResult.both_partial()

func _resolve_probabilistic(initiator_rp: int, reactor_rp: int) -> ConditionResult:
	var total := initiator_rp + reactor_rp
	if total == 0:
		return ConditionResult.full_initiator()
	if randf() <= float(initiator_rp) / float(total):
		return ConditionResult.full_initiator()
	return ConditionResult.full_reactor()
