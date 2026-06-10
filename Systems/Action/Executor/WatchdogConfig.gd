## Per-category timeout configuration for the watchdog system.
## Assign instances to InterruptManager.watchdog_configs in the editor.
class_name WatchdogConfig
extends Resource

@export var category: StringName = &""
@export var timeout_sec: float = 10.0
