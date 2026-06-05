## Phase 2 watchdog — monitors action execution, not player thinking.
## Created per execution by ActionExecutor (short-lived Node, queue_free'd when done).
##
## TH1: all reporters done before warning → normal exit.
## TH2: reporters responding but slow → extend up to MAX_SLOW_EXTENSIONS times.
## TH3: no reporter response → extend once, then force-complete.
## Force-complete: flags interrupt on the executing unit via InterruptManager.
class_name EnhancedWatchdog
extends Node

const BASE_TIMEOUT: float = 10.0
const WARN_RATIO: float = 0.7        # warn at 70% elapsed (7 s)
const MAX_SLOW_EXTENSIONS: int = 3   # TH2: max 3 extensions (~40 s total)
const MAX_NO_RESPONSE_EXTENSIONS: int = 1  # TH3: 1 extension then force

signal extension_granted(n: int, scenario: String)
signal force_completing(reason: String)

var _reporters: Array = []           # duck-typed: get_process_report() -> ProcessReport
var _interrupt_manager: InterruptManager = null
var _unit: Unit = null
var _monitor: ProcessMonitor = null
var _context: String = ""

var _completed: bool = false
var _slow_ext: int = 0
var _no_resp_ext: int = 0

func setup(
	reporters: Array,
	interrupt_manager: InterruptManager,
	unit: Unit,
	monitor: ProcessMonitor,
	context: String
) -> void:
	_reporters = reporters
	_interrupt_manager = interrupt_manager
	_unit = unit
	_monitor = monitor
	_context = context

## Call after setup(). Starts the background monitoring coroutine.
func start() -> void:
	_run_cycle()

## ActionExecutor calls this when execution finishes normally.
func mark_completed() -> void:
	_completed = true

# --- Internal ---

func _run_cycle() -> void:
	# Safety cap: total cycles = max extensions across both scenarios + 1 initial pass.
	var total_cycles := MAX_SLOW_EXTENSIONS + MAX_NO_RESPONSE_EXTENSIONS + 1

	for _i in range(total_cycles):
		# ── Wait until warning threshold ──
		await get_tree().create_timer(BASE_TIMEOUT * WARN_RATIO).timeout

		if _completed or not is_inside_tree():
			return  # TH1: normal completion beat the timer

		# ── Query reporters ──
		var reports := _collect_reports()

		if _all_done(reports):
			return  # TH1 late: finished just before timer fired

		var has_responses := not reports.is_empty()

		if not has_responses:
			# TH3: reporters not reachable or returning null
			if _monitor:
				_monitor.log_no_response(_context, _no_resp_ext + 1)
			if _no_resp_ext >= MAX_NO_RESPONSE_EXTENSIONS:
				_force_complete("TH3: no response — extension limit reached")
				return
			_no_resp_ext += 1
			extension_granted.emit(_no_resp_ext, "TH3")
		else:
			# TH2: slow but responding
			if _slow_ext >= MAX_SLOW_EXTENSIONS:
				_force_complete("TH2: slow progress — extension limit reached")
				return
			_slow_ext += 1
			extension_granted.emit(_slow_ext, "TH2")

		if _monitor:
			var reason := "no response" if not has_responses else _format_progress(reports)
			_monitor.log_extension(_context, _slow_ext + _no_resp_ext, reason)

		# ── Wait remaining window then loop ──
		await get_tree().create_timer(BASE_TIMEOUT * (1.0 - WARN_RATIO)).timeout

		if _completed or not is_inside_tree():
			return

	_force_complete("safety cap: total cycle limit exceeded")

func _force_complete(reason: String) -> void:
	force_completing.emit(reason)
	if _monitor:
		_monitor.log_force_complete(_context, reason)
	# Abort execution via existing interrupt mechanism — MoveSystem checks this after each cell.
	if _interrupt_manager and is_instance_valid(_unit):
		_interrupt_manager.flag_interrupt(_unit, "watchdog_abort")

func _collect_reports() -> Array[ProcessReport]:
	var result: Array[ProcessReport] = []
	for r in _reporters:
		if not is_instance_valid(r):
			continue
		if not r.has_method("get_process_report"):
			continue
		var report: ProcessReport = r.get_process_report()
		if report:
			result.append(report)
	return result

func _all_done(reports: Array[ProcessReport]) -> bool:
	if reports.is_empty():
		return false
	for r in reports:
		if r.status == ProcessReport.Status.RUNNING:
			return false
	return true

func _format_progress(reports: Array[ProcessReport]) -> String:
	var parts: Array[String] = []
	for r in reports:
		parts.append("%s %.0f%%" % [r.reporter_id, r.progress * 100.0])
	return ", ".join(parts)
