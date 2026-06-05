## Tracks interrupt flags per unit.
## ReactionSystem writes here; ActionExecutor reads here after each checkpoint.
class_name InterruptManager
extends Node

var _interrupts: Dictionary = {}

func flag_interrupt(unit: Unit, reason: String = "") -> void:
	_interrupts[unit] = reason

func has_interrupt(unit: Unit) -> bool:
	return _interrupts.has(unit)

func consume_interrupt(unit: Unit) -> String:
	var reason: String = _interrupts.get(unit, "")
	_interrupts.erase(unit)
	return reason

func clear_all() -> void:
	_interrupts.clear()
