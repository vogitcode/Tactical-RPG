## Watchdog wrapper for async action execution.
## Not currently wired in the dispatch flow — kept for future per-system watchdog integration.
## Each handler system (MoveSystem, CombatSystem) will use this when watchdog support is added.
class_name ActionExecutor
extends Node

signal execution_started(action: BaseAction, unit: Unit)
signal execution_finished(action: BaseAction, unit: Unit, result: ActionResult)

var is_executing: bool = false
var _interrupt_manager: InterruptManager
var _process_monitor: ProcessMonitor = null

func setup(im: InterruptManager) -> void:
	_interrupt_manager = im

func set_process_monitor(monitor: ProcessMonitor) -> void:
	_process_monitor = monitor

func get_process_report() -> ProcessReport:
	var r := ProcessReport.new()
	r.reporter_id = &"ActionExecutor"
	r.status = ProcessReport.Status.COMPLETED
	return r
