class_name ActionResult
extends RefCounted

enum Status {
	COMPLETED,    # Action finished normally
	INTERRUPTED,  # Action stopped mid-execution (trap, stun, death)
	CANCELLED,    # Player cancelled before execution started
	FAILED,       # Precondition failed at execution time
	DEFERRED,     # Unit deferred to end of faction turn order (WaitAction)
}

var status: Status
var reason: String = ""

static func completed() -> ActionResult:
	return _make(Status.COMPLETED)

static func interrupted(why: String = "") -> ActionResult:
	return _make(Status.INTERRUPTED, why)

static func cancelled() -> ActionResult:
	return _make(Status.CANCELLED)

static func failed(why: String = "") -> ActionResult:
	return _make(Status.FAILED, why)

static func deferred() -> ActionResult:
	return _make(Status.DEFERRED)

func is_completed() -> bool:
	return status == Status.COMPLETED

func is_interrupted() -> bool:
	return status == Status.INTERRUPTED

static func _make(s: Status, r: String = "") -> ActionResult:
	var result := ActionResult.new()
	result.status = s
	result.reason = r
	return result
