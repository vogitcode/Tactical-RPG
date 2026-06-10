## Coupling interface between a system's execution and InterruptManager's watchdog timer.
##
## Lifecycle per execution:
##   1. InterruptManager.start_watch() creates and returns a handle.
##   2. System connects timed_out signal for system-specific abort logic.
##   3. System calls complete() when execution finishes normally.
##   4. If timer fires before complete(), _fire_timeout() emits timed_out.
##
## System does not know about timers or InterruptManager internals — only this handle.
class_name WatchdogHandle
extends RefCounted

signal timed_out(unit: Unit, reason: String)

var _unit: Unit
var _category: StringName
var _completed: bool = false

func _init(u: Unit, cat: StringName) -> void:
	_unit = u
	_category = cat

## Call when execution finishes normally. Prevents timed_out from firing.
func complete() -> void:
	_completed = true

func is_completed() -> bool:
	return _completed

## Called by InterruptManager's timer callback. Not intended for external callers.
func _fire_timeout(reason: String) -> void:
	if not _completed and is_instance_valid(_unit):
		timed_out.emit(_unit, reason)
