## Top-right HUD panel showing the upcoming turn order.
## Prototype: unit names only, colored by team (player=blue, enemy=red).
class_name TurnOrderPanel
extends Control

var _container: HBoxContainer

func _ready() -> void:
	_build_structure()
	hide()

func _build_structure() -> void:
	var panel := PanelContainer.new()
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	_container = HBoxContainer.new()
	_container.add_theme_constant_override("separation", 14)
	margin.add_child(_container)

# --- Public API ---

func update_order(units: Array[Unit]) -> void:
	for child in _container.get_children():
		child.queue_free()

	for unit in units:
		var label := Label.new()
		label.text = unit.unit_name
		label.add_theme_font_size_override("font_size", 11)
		var color := Color(0.5, 0.9, 1.0) if unit.team == 0 else Color(1.0, 0.5, 0.5)
		label.add_theme_color_override("font_color", color)
		_container.add_child(label)

	if not units.is_empty():
		show()
	else:
		hide()
