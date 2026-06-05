## Floating action menu that appears when a unit is selected.
## Reads available actions from unit, emits action_chosen when player picks one.
class_name ActionMenu
extends Control

signal action_chosen(action: BaseAction)
signal menu_closed()

const BUTTON_HEIGHT := 32
const MENU_WIDTH := 140

var _panel: PanelContainer
var _vbox: VBoxContainer
var _current_unit: Node = null

func _ready() -> void:
	_build_structure()
	hide()
	# Close on right-click anywhere
	set_process_unhandled_input(true)

func _build_structure() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(_vbox)

# --- Public API ---

func show_for_unit(unit: Node, screen_pos: Vector2) -> void:
	_current_unit = unit
	_clear_buttons()

	var actions: Array = unit.get_available_actions()
	if actions.is_empty():
		return

	for action in actions:
		_add_button(action)

	position = _clamp_to_viewport(screen_pos)
	show()

func close() -> void:
	_current_unit = null
	_clear_buttons()
	hide()
	menu_closed.emit()

# --- Private ---

func _add_button(action: BaseAction) -> void:
	var btn := Button.new()
	btn.text = action.action_name
	btn.custom_minimum_size = Vector2(MENU_WIDTH, BUTTON_HEIGHT)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = false
	_apply_button_style(btn)

	btn.pressed.connect(func() -> void:
		action_chosen.emit(action)
		close()
	)
	_vbox.add_child(btn)

func _apply_button_style(btn: Button) -> void:
	# Fallback style when .tres files don't exist yet
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	btn.add_theme_font_size_override("font_size", 13)

func _clear_buttons() -> void:
	for child in _vbox.get_children():
		child.queue_free()

func _clamp_to_viewport(pos: Vector2) -> Vector2:
	var vp_size := get_viewport_rect().size
	var menu_size := Vector2(MENU_WIDTH, _vbox.get_child_count() * (BUTTON_HEIGHT + 2) + 8)
	return Vector2(
		clamp(pos.x, 0.0, vp_size.x - menu_size.x),
		clamp(pos.y, 0.0, vp_size.y - menu_size.y)
	)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		close()
