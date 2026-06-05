## A single recorded event from a watchdog or monitored process.
class_name ProcessMonitorEvent
extends RefCounted

var event_type: StringName = &""
var context: String = ""
var message: String = ""
var timestamp: float = 0.0

static func create(type: StringName, ctx: String, msg: String) -> ProcessMonitorEvent:
	var e := ProcessMonitorEvent.new()
	e.event_type = type
	e.context = ctx
	e.message = msg
	e.timestamp = Time.get_ticks_msec() / 1000.0
	return e
