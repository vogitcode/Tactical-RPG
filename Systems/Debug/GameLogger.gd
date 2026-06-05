## Development logger — inject as child node anywhere in the scene tree.
## Tag-based enable/disable via GameLogger.disable_tag() / enable_tag() static methods.
## All logger instances respect the global disabled-tags registry.
class_name GameLogger
extends Node

enum Level { DEBUG, INFO, WARN, ERROR }

## Log tag — used for group enable/disable. Set in Inspector.
@export var tag: String = "Default"
## Whether this logger instance is active.
@export var enabled: bool = true
## Minimum level to print. Messages below this level are silently dropped.
@export var min_level: Level = Level.DEBUG

# --- Static tag registry ---

static var _disabled_tags: Array[String] = []

## Disable all loggers with the given tag globally.
static func disable_tag(t: String) -> void:
	if t not in _disabled_tags:
		_disabled_tags.append(t)

## Re-enable all loggers with the given tag globally.
static func enable_tag(t: String) -> void:
	_disabled_tags.erase(t)

## Returns true if the tag is currently enabled globally.
static func is_tag_enabled(t: String) -> bool:
	return t not in _disabled_tags

# --- Instance logging API ---

func debug(msg: String, ctx: Dictionary = {}) -> void:
	_emit(Level.DEBUG, msg, ctx)

func info(msg: String, ctx: Dictionary = {}) -> void:
	_emit(Level.INFO, msg, ctx)

func warn(msg: String, ctx: Dictionary = {}) -> void:
	_emit(Level.WARN, msg, ctx)

func error(msg: String, ctx: Dictionary = {}) -> void:
	_emit(Level.ERROR, msg, ctx)

## Logs an error if condition is false. Use for runtime invariant checks.
func expect(condition: bool, label: String, ctx: Dictionary = {}) -> void:
	if not condition:
		error("[EXPECT FAILED] " + label, ctx)

## Returns a dictionary snapshot of an object's fields for use in ctx.
## Example: logger.debug("unit state", logger.snap(unit, ["current_hp","grid_position"]))
func snap(obj: Object, fields: Array[String]) -> Dictionary:
	var result: Dictionary = {"_obj": str(obj)}
	for f in fields:
		result[f] = obj.get(f)
	return result

# --- Internal ---

func _emit(level: Level, msg: String, ctx: Dictionary) -> void:
	if not enabled:
		return
	if level < min_level:
		return
	if not GameLogger.is_tag_enabled(tag):
		return

	const COLORS := ["gray", "cyan", "yellow", "red"]
	const LABELS := ["DEBUG", "INFO", "WARN", "ERROR"]

	var color: String = COLORS[level]
	var label: String = LABELS[level]
	var text := "[color=%s][%s][%s][/color] %s" % [color, label, tag, msg]
	if not ctx.is_empty():
		text += "\n         [color=gray]%s[/color]" % str(ctx)
	print_rich(text)
