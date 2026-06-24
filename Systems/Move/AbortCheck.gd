class_name AbortCheck
extends RefCounted

## Port interface for move interrupt sources.
## Concrete implementations (TrapAbortCheck, TileAbortCheck) registered into
## MoveExecutionContext by the compositor — MoveSystem never references them directly.

func should_abort(unit: Unit) -> bool:
	return false

func get_reason() -> String:
	return ""
