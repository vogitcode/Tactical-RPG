## Snapshot of an executor's current state, returned when watchdog queries for progress.
## Objects participating in Phase 2 monitoring implement get_process_report() -> ProcessReport.
class_name ProcessReport
extends RefCounted

enum Status { RUNNING, COMPLETED, FAILED }

var reporter_id: StringName = &""
var status: Status = Status.RUNNING
var progress: float = 0.0  # 0.0 to 1.0, optional
var message: String = ""
