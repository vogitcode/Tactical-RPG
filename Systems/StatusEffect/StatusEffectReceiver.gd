## Node child of Unit. Owns all active status effects on that unit.
## Queried by TurnEffectProcessor and Unit for status checks.
class_name StatusEffectReceiver
extends Node

var _effects: Array[StatusEffect] = []

# --- Mutation ---

## Applies effect. Replaces existing effect with the same status_id.
func apply(effect: StatusEffect) -> void:
	for i in range(_effects.size()):
		if _effects[i].status_id == effect.status_id:
			_effects[i] = effect
			return
	_effects.append(effect)

func remove_effect(status_id: StringName) -> void:
	for i in range(_effects.size() - 1, -1, -1):
		if _effects[i].status_id == status_id:
			_effects.remove_at(i)

# --- Queries ---

func has_effect(status_id: StringName) -> bool:
	for e in _effects:
		if e.status_id == status_id:
			return true
	return false

func get_all() -> Array[StatusEffect]:
	return _effects.duplicate()

# --- Turn boundary processing ---

## Called at the start of the unit's turn: fires on_turn_start hooks only.
## Ticking is handled by Unit.reset_turn() (fresh turns only) — deferred turns do not tick.
func process_turn_start(unit: Unit) -> void:
	for effect in _effects.duplicate():
		effect.on_turn_start(unit)

## Called by Unit.reset_turn() to decrement durations and expire effects.
## Separate from process_turn_start so deferred turns don't double-tick.
func tick_and_expire(unit: Unit) -> void:
	_tick_and_expire(unit)

func _tick_and_expire(unit: Unit) -> void:
	for i in range(_effects.size() - 1, -1, -1):
		_effects[i].tick()
		if _effects[i].is_expired():
			_effects[i].on_expire(unit)
			_effects.remove_at(i)
