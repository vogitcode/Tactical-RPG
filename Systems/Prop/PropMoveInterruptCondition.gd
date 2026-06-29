class_name PropMoveInterruptCondition
extends MoveInterruptCondition

## Shared interrupt condition for all props that stop unit movement.
## PropSystem owns one instance; notify_triggered() is called synchronously
## inside unit_stepped before any await. MoveSystem polls should_abort() at
## the next checkpoint after unit_stepped returns.

var _triggered: bool = false
var _trigger_unit: Unit = null

func notify_triggered(unit: Unit) -> void:
	_triggered = true
	_trigger_unit = unit

func should_abort(unit: Unit) -> bool:
	return _triggered and _trigger_unit == unit

func get_reason() -> String:
	return "prop"

func reset() -> void:
	_triggered = false
	_trigger_unit = null
