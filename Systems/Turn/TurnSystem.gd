## Battle state machine — context holder, transition router, and navigation service.
## States own sequencing decisions; TurnSystem handles signal emissions and context updates.
class_name TurnSystem
extends Node

enum BattleState {
	IDLE,
	BATTLE_START,
	TURN_START,
	FACTION_TURN_START,
	UNIT_TURN_START,
	UNIT_ACTING,
	UNIT_TURN_END,
	FACTION_TURN_END,
	TURN_END,
	BATTLE_END,
}

signal state_changed(new_state: BattleState)
signal battle_started()
signal turn_started(turn_number: int)
signal faction_turn_started(faction_id: int)
signal unit_turn_started(unit: Unit)
signal unit_turn_ended(unit: Unit)
signal faction_turn_ended(faction_id: int)
signal turn_ended(turn_number: int)
signal battle_ended(result: StringName)

# Public — wired by SystemManager
@onready var unit_acting_state: UnitActingState         = $UnitActingState
@onready var unit_turn_start_state: UnitTurnStartState  = $UnitTurnStartState
@onready var unit_turn_end_state: UnitTurnEndState      = $UnitTurnEndState

@onready var _battle_start_state: BattleStartState            = $BattleStartState
@onready var _turn_start_state: TurnStartState                = $TurnStartState
@onready var _faction_turn_start_state: FactionTurnStartState = $FactionTurnStartState
@onready var _faction_turn_end_state: FactionTurnEndState     = $FactionTurnEndState
@onready var _turn_end_state: TurnEndState                    = $TurnEndState
@onready var _battle_end_state: BattleEndState                = $BattleEndState

var current_state: BattleState = BattleState.IDLE
var current_unit: Unit = null
var current_faction: int = -1
var current_turn: int = 0
var faction_order: Array[int] = []

var _units: Array[Unit] = []
var _deferred_units: Array[Unit] = []
var _completed_units: Array[Unit] = []
var _battle_ending: bool = false
var _battle_result: StringName = &""

# --- Setup ---

func register_units(units: Array[Unit]) -> void:
	_units = units.duplicate()
	_detect_faction_order()

func _detect_faction_order() -> void:
	var seen: Dictionary = {}
	for u in _units:
		seen[u.team] = true
	faction_order = Array(seen.keys(), TYPE_INT, "", null)
	faction_order.sort()

func start_battle() -> void:
	_battle_ending = false
	_battle_result = &""
	_deferred_units = []
	_completed_units = []
	current_turn = 0
	_set_state(BattleState.BATTLE_START)
	battle_started.emit()
	await transition_to(_battle_start_state, {})

# --- External control ---

## Called by ActionSystem when a unit uses WaitAction.
func defer_unit(unit: Unit) -> void:
	if not _deferred_units.has(unit):
		_deferred_units.append(unit)

## Called by GoalSystem when a win/lose condition is met.
## State machine exits cleanly at the next state boundary.
func trigger_battle_end(result: StringName) -> void:
	if _battle_ending:
		return
	_battle_result = result
	_battle_ending = true

## Handler interface — called by ActionSystem dispatch for category &"turn_control".
func handle_action(action: BaseAction, source_unit: Unit) -> ActionResult:
	await source_unit.get_tree().process_frame
	var turn_action := action as TurnControlAction
	match turn_action.turn_effect:
		TurnControlAction.TurnEffect.DEFER:
			source_unit.has_waited = true
			return ActionResult.deferred()
		TurnControlAction.TurnEffect.GUARD:
			source_unit.apply_status(turn_action.status_to_apply)
			source_unit.has_acted = true
			source_unit.action_points -= turn_action.ap_cost
			return ActionResult.completed()
		_:  # END_TURN
			return ActionResult.completed()

# --- State queries ---

func is_unit_acting() -> bool:
	return current_state == BattleState.UNIT_ACTING

func is_battle_ending() -> bool:
	return _battle_ending

func get_turn() -> int:
	return current_turn

# --- Navigation queries (called by states) ---

func get_first_faction_with_units() -> int:
	for fid in faction_order:
		if _has_alive_units(fid):
			return fid
	return -1

func get_next_faction_with_units() -> int:
	var idx := faction_order.find(current_faction)
	for i in range(idx + 1, faction_order.size()):
		var fid: int = faction_order[i]
		if _has_alive_units(fid):
			return fid
	return -1

func get_first_unit_in_faction(faction_id: int) -> Unit:
	for u in _units:
		if u.team == faction_id and u.is_alive():
			return u
	return null

func get_next_unit_in_faction() -> Unit:
	if current_unit == null:
		return null
	var passed_current := false
	for u in _units:
		if u == current_unit:
			passed_current = true
			continue
		if passed_current and u.team == current_unit.team and u.is_alive() and not _deferred_units.has(u) and not _completed_units.has(u):
			return u
	return null

func get_next_deferred_unit_in_faction() -> Unit:
	for u in _deferred_units:
		if u.team == current_faction and u.is_alive():
			return u
	return null

# --- Semantic entry methods (called by states) ---

func go_to_turn_start() -> void:
	current_turn += 1
	_set_state(BattleState.TURN_START)
	turn_started.emit(current_turn)
	await transition_to(_turn_start_state, {"turn": current_turn})

func go_to_faction_turn(faction_id: int) -> void:
	current_faction = faction_id
	_clear_deferred_for_faction(faction_id)
	_completed_units.clear()
	_set_state(BattleState.FACTION_TURN_START)
	faction_turn_started.emit(faction_id)
	await transition_to(_faction_turn_start_state, {"faction": faction_id})

func go_to_unit_turn(unit: Unit) -> void:
	current_unit = unit
	var deferred_idx := _deferred_units.find(unit)
	var is_deferred := deferred_idx >= 0
	if is_deferred:
		_deferred_units.remove_at(deferred_idx)
	else:
		unit.reset_turn()
	print("[Turn %d][Faction %d] >> %s begins turn%s" % [
		current_turn, unit.team, unit.unit_name,
		" (deferred)" if is_deferred else ""
	])
	_set_state(BattleState.UNIT_TURN_START)
	unit_turn_started.emit(unit)
	await transition_to(unit_turn_start_state, {"unit": unit})

func go_to_unit_acting(unit: Unit) -> void:
	if not unit.is_alive():
		await go_to_unit_turn_end(unit)
		return
	_set_state(BattleState.UNIT_ACTING)
	transition_to(unit_acting_state, {"unit": unit})

## Entry point of the next coroutine chain — called (deferred) by ActionSystem.unit_turn_finished.
func on_unit_turn_finished(unit: Unit) -> void:
	if current_state != BattleState.UNIT_ACTING:
		return
	if is_battle_ending():
		await go_to_battle_end()
		return
	await go_to_unit_turn_end(unit)

func go_to_unit_turn_end(unit: Unit) -> void:
	print("[Turn %d][Faction %d] << %s ends turn (AP:%d moved:%s acted:%s)" % [
		current_turn, unit.team, unit.unit_name,
		unit.action_points, unit.has_moved, unit.has_acted
	])
	if not _deferred_units.has(unit) and not _completed_units.has(unit):
		_completed_units.append(unit)
	_set_state(BattleState.UNIT_TURN_END)
	unit_turn_ended.emit(unit)
	await transition_to(unit_turn_end_state, {"unit": unit})

func go_to_faction_turn_end() -> void:
	_set_state(BattleState.FACTION_TURN_END)
	faction_turn_ended.emit(current_faction)
	await transition_to(_faction_turn_end_state, {"faction": current_faction})

func go_to_turn_end() -> void:
	_set_state(BattleState.TURN_END)
	turn_ended.emit(current_turn)
	await transition_to(_turn_end_state, {"turn": current_turn})

func go_to_battle_end() -> void:
	_set_state(BattleState.BATTLE_END)
	await transition_to(_battle_end_state, {"result": _battle_result})
	battle_ended.emit(_battle_result)
	_set_state(BattleState.IDLE)
	current_unit = null
	current_faction = -1

## Enters a state and awaits its completion (including subscriber chain + next transition).
func transition_to(state: BattleStateNode, context: Dictionary = {}) -> void:
	await state.enter(context)

# --- Private ---

func _set_state(s: BattleState) -> void:
	current_state = s
	state_changed.emit(s)

func _clear_deferred_for_faction(faction_id: int) -> void:
	var i := _deferred_units.size() - 1
	while i >= 0:
		if _deferred_units[i].team == faction_id:
			_deferred_units.remove_at(i)
		i -= 1

func _get_alive_units(faction_id: int) -> Array[Unit]:
	var result: Array[Unit] = []
	for u in _units:
		if u.team == faction_id and u.is_alive():
			result.append(u)
	return result

func _has_alive_units(faction_id: int) -> bool:
	for u in _units:
		if u.team == faction_id and u.is_alive():
			return true
	return false
