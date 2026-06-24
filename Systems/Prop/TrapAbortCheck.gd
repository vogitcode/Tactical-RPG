class_name TrapAbortCheck
extends AbortCheck

## Concrete AbortCheck adapter for trap-triggered move interrupts.
## PropSystem calls notify_triggered() synchronously inside unit_stepped handler.
## MoveSystem polls should_abort() at the next checkpoint after unit_stepped returns.

var _triggered: bool = false
var _trigger_unit: Unit = null

## Called by PropSystem when a trap fires and result.interrupts is true.
func notify_triggered(unit: Unit) -> void:
	_triggered = true
	_trigger_unit = unit

func should_abort(unit: Unit) -> bool:
	return _triggered and _trigger_unit == unit

func get_reason() -> String:
	return "trap"

## Called by compositor at the start of each new execution context.
func reset() -> void:
	_triggered = false
	_trigger_unit = null
