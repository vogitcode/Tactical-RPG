## Floating tooltip showing description text for abilities and passives.
## Caller positions it via show_description(); tooltip renders near cursor.
class_name DescriptionTooltip
extends Control

const TOOLTIP_WIDTH := 220
const PADDING := 8

var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	_build_structure()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	hide()

func _build_structure() -> void:
	_panel = PanelContainer.new()
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PADDING)
	margin.add_theme_constant_override("margin_right", PADDING)
	margin.add_theme_constant_override("margin_top", PADDING)
	margin.add_theme_constant_override("margin_bottom", PADDING)
	_panel.add_child(margin)

	_label = Label.new()
	_label.custom_minimum_size.x = TOOLTIP_WIDTH
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 12)
	margin.add_child(_label)

func _process(_delta: float) -> void:
	if visible:
		position = get_global_mouse_position() + Vector2(14.0, -10.0)

func show_description(text: String) -> void:
	_label.text = text
	show()

func hide_tooltip() -> void:
	hide()
