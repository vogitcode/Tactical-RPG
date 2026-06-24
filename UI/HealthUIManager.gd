## Manages world-space HP bar and name label displays for all units.
## Lives as a Node2D in the main scene — NOT under CanvasLayer — so displays
## follow units in world space and zoom correctly with the camera.
## Wired by the Compositor via unit_manager.unit_spawned.connect(register_unit).
class_name HealthUIManager
extends Node2D

const HP_BAR_WIDTH := 28
const HP_BAR_HEIGHT := 4
const BAR_OFFSET := Vector2(-HP_BAR_WIDTH / 2.0, 12.0)
const LABEL_OFFSET := Vector2(-HP_BAR_WIDTH / 2.0, -22.0)

# unit -> { root: Node2D, fill: ColorRect }
var _displays: Dictionary = {}

## Called by compositor for each spawned unit (including mid-battle spawns).
## Compositor wires: unit_manager.unit_spawned.connect(health_ui_manager.register_unit)
func register_unit(unit: Unit) -> void:
	var root := Node2D.new()
	add_child(root)

	var bg := ColorRect.new()
	bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	bg.position = BAR_OFFSET
	bg.color = Color(0.2, 0.2, 0.2)
	root.add_child(bg)

	var fill := ColorRect.new()
	fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	fill.position = BAR_OFFSET
	fill.color = Color(0.2, 0.8, 0.2)
	root.add_child(fill)

	var label := Label.new()
	label.text = unit.unit_name
	label.position = LABEL_OFFSET
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	root.add_child(label)

	_displays[unit] = { "root": root, "fill": fill }

	unit.hp_changed.connect(_on_hp_changed.bind(unit))
	unit.unit_died.connect(_on_unit_died.bind(unit))

	root.position = unit.global_position

func _process(_delta: float) -> void:
	for unit: Unit in _displays:
		if is_instance_valid(unit):
			_displays[unit].root.position = unit.global_position

func _on_hp_changed(_old_hp: int, _new_hp: int, unit: Unit) -> void:
	if not _displays.has(unit):
		return
	var fill: ColorRect = _displays[unit].fill
	var ratio := float(unit.current_hp) / float(unit.max_hp)
	fill.size.x = HP_BAR_WIDTH * ratio
	fill.color = Color(0.2, 0.8, 0.2).lerp(Color(0.8, 0.1, 0.1), 1.0 - ratio)

func unregister_unit(unit: Unit) -> void:
	if not _displays.has(unit):
		return
	if unit.hp_changed.is_connected(_on_hp_changed.bind(unit)):
		unit.hp_changed.disconnect(_on_hp_changed.bind(unit))
	if unit.unit_died.is_connected(_on_unit_died.bind(unit)):
		unit.unit_died.disconnect(_on_unit_died.bind(unit))
	_displays[unit].root.queue_free()
	_displays.erase(unit)

func _on_unit_died(unit: Unit) -> void:
	if _displays.has(unit):
		_displays[unit].root.modulate = Color(1.0, 1.0, 1.0, 0.4)
