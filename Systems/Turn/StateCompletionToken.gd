## Passed to each BattleStateNode.activated signal.
## Subscribers call claim() to register async work; release the returned Callable when done.
## State node awaits all_done before transitioning.
class_name StateCompletionToken
extends RefCounted

signal all_done()

var pending_count: int = 0

## Register async work. Returns a Callable — invoke it when the work is complete.
func claim() -> Callable:
	pending_count += 1
	return _release

func _release() -> void:
	pending_count = maxi(0, pending_count - 1)
	if pending_count == 0:
		all_done.emit()

## Called by watchdog on timeout — forces completion so state machine never hangs.
func force_complete() -> void:
	pending_count = 0
	all_done.emit()
