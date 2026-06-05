## Background supervisor. No gameplay role — receives reports from watchdogs,
## logs anomalies to console, and keeps a session-level event log.
## Placed in scene tree by Compositor. Watchdogs receive a reference via setup().
class_name ProcessMonitor
extends Node

signal anomaly_detected(event: ProcessMonitorEvent)

var _log: Array[ProcessMonitorEvent] = []

# --- API called by EnhancedWatchdog ---

func log_extension(context: String, extension_num: int, reason: String) -> void:
	_record(&"extension", context, "Extension %d granted — %s" % [extension_num, reason])

func log_no_response(context: String, attempt: int) -> void:
	_record(&"no_response", context, "No reporter response (attempt %d)" % attempt)

func log_force_complete(context: String, reason: String) -> void:
	_record(&"force_complete", context, "Force-completed — %s" % reason)

# --- Query ---

func get_log() -> Array[ProcessMonitorEvent]:
	return _log.duplicate()

func print_session_summary() -> void:
	print("[ProcessMonitor] === Session log (%d events) ===" % _log.size())
	for e in _log:
		print("  [%.2fs][%s] %s — %s" % [e.timestamp, e.event_type, e.context, e.message])

# --- Internal ---

func _record(type: StringName, context: String, message: String) -> void:
	var e := ProcessMonitorEvent.create(type, context, message)
	_log.append(e)
	push_warning("[ProcessMonitor][%s] %s — %s" % [type, context, message])
	anomaly_detected.emit(e)
