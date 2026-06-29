class_name MoveInterruptCondition
extends RefCounted

## Contract interface for move interrupt sources.
## Concrete implementations (TrapInterruptCondition, TileInterruptCondition) registered into
## MoveExecutionContext by the compositor — MoveSystem never references them directly.

func should_abort(unit: Unit) -> bool:
	return false

func get_reason() -> String:
	return ""
