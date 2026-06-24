class_name MoveExecutionContext
extends RefCounted

## Per-execution contract for move interrupt sources.
## Created fresh each handle_action call — no state leaks between executions.
## Compositor registers AbortCheck instances here; MoveSystem polls evaluate() at each step.

var _checks: Array[AbortCheck] = []
var _interrupt_reason: String = ""
var _forced: bool = false

func register(check: AbortCheck) -> void:
	_checks.append(check)

## Called by watchdog timeout — bypasses registered checks, marks abort immediately.
func force_abort(reason: String) -> void:
	_forced = true
	_interrupt_reason = reason

## Returns true if any registered check (or force_abort) wants to stop this unit's movement.
func evaluate(unit: Unit) -> bool:
	if _forced:
		return true
	for check in _checks:
		if check.should_abort(unit):
			_interrupt_reason = check.get_reason()
			return true
	return false

func get_reason() -> String:
	return _interrupt_reason
