## Bottom-left HUD panel showing selected unit's stats.
## Connects to unit.hp_changed to stay live; disconnects when unit changes.
class_name UnitStatsPanel
extends Control

var _name_label: Label
var _hp_label: Label
var _ap_label: Label
var _move_label: Label
var _current_unit: Unit = null

func _ready() -> void:
	_build_structure()
	hide()

func _build_structure() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 0)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_name_label = _make_label("", 14)
	vbox.add_child(_name_label)

	_hp_label = _make_label("", 12)
	vbox.add_child(_hp_label)

	_ap_label = _make_label("", 12)
	vbox.add_child(_ap_label)

	_move_label = _make_label("", 12)
	vbox.add_child(_move_label)

func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label

# --- Public API ---

func show_unit(unit: Unit) -> void:
	_disconnect_current()
	_current_unit = unit
	unit.hp_changed.connect(_on_hp_changed)
	unit.unit_died.connect(_on_unit_died)
	_refresh()
	show()

func refresh_stats() -> void:
	_refresh()

func clear() -> void:
	_disconnect_current()
	hide()

# --- Private ---

func _disconnect_current() -> void:
	if _current_unit != null and is_instance_valid(_current_unit):
		if _current_unit.hp_changed.is_connected(_on_hp_changed):
			_current_unit.hp_changed.disconnect(_on_hp_changed)
		if _current_unit.unit_died.is_connected(_on_unit_died):
			_current_unit.unit_died.disconnect(_on_unit_died)
	_current_unit = null

func _refresh() -> void:
	if _current_unit == null:
		return
	_name_label.text = _current_unit.unit_name
	_hp_label.text = "HP   %d / %d" % [_current_unit.current_hp, _current_unit.max_hp]
	_ap_label.text = "AP   %d / %d" % [_current_unit.action_points, _current_unit.max_action_points]
	_move_label.text = "MOV  %d" % _current_unit.get_effective_move_points()

func _on_hp_changed(_old: int, _new: int) -> void:
	_refresh()

func _on_unit_died() -> void:
	clear()
