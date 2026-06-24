## Tracks interrupt flags per unit and manages per-execution watchdog timers.
##
## Interrupt flags: written by ReactionSystem, read by MoveSystem after each step.
## Watchdog: start_watch() returns a WatchdogHandle — systems connect timed_out
## for their own abort logic without knowing timer internals.
##
## Assign WatchdogConfig .tres files to watchdog_configs in the editor inspector.
class_name InterruptManager
extends Node

@export var watchdog_configs: Array[WatchdogConfig] = []

var _interrupts: Dictionary = {}
var _config_map: Dictionary = {}

func _ready() -> void:
	for cfg in watchdog_configs:
		if cfg != null:
			_config_map[cfg.category] = cfg

# --- Interrupt flags ---

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

# --- Watchdog ---

## Creates a WatchdogHandle for the given execution category and unit.
## If no WatchdogConfig is registered for the category, returns a no-op handle
## (no timer is started — complete() and timed_out are still valid but inert).
func start_watch(category: StringName, unit: Unit) -> WatchdogHandle:
	var handle := WatchdogHandle.new(unit, category)
	var cfg: WatchdogConfig = _config_map.get(category, null)
	if cfg == null:
		return handle
	var unit_name: String = unit.name
	var timer := get_tree().create_timer(cfg.timeout_sec)
	timer.timeout.connect(func() -> void:
		if handle.is_completed():
			return
		push_warning("[Watchdog] %.1fs timeout — category: %s, unit: %s" % [
			cfg.timeout_sec, category, unit_name
		])
		handle._fire_timeout("%.1fs timeout" % cfg.timeout_sec)
	)
	return handle
