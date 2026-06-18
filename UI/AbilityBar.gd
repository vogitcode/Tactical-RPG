## Bottom-center HUD bar.
## Top section: passive icon row.
## Bottom section: ability buttons (left), then Wait + EndTurn (right).
## Passive row sits ABOVE ability row with a gap.
class_name AbilityBar
extends Control

signal ability_hovered(action: BaseAction)
signal ability_exited()
signal passive_hovered(passive: BasePassive)
signal passive_exited()
signal ability_chosen(action: BaseAction)

const PASSIVE_SLOT_SIZE := 32
const ABILITY_SLOT_MIN_W := 52
const ABILITY_SLOT_H := 48
const GAP_HEIGHT := 8

var _passive_row: HBoxContainer
var _ability_row: HBoxContainer
var _is_active: bool = false
var _current_unit: Unit = null

func _ready() -> void:
	_build_structure()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func _build_structure() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	_passive_row = HBoxContainer.new()
	_passive_row.add_theme_constant_override("separation", 4)
	_passive_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_passive_row)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, GAP_HEIGHT)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(gap)

	_ability_row = HBoxContainer.new()
	_ability_row.add_theme_constant_override("separation", 4)
	_ability_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_ability_row)

# --- Public API ---

func show_for_unit(unit: Unit, is_active: bool) -> void:
	_current_unit = unit
	_is_active = is_active
	_clear_row(_passive_row)
	_clear_row(_ability_row)

	for passive in unit.get_runtime_passives():
		_add_passive_slot(passive)

	var all_actions: Array[BaseAction] = []
	if unit.unit_data != null:
		all_actions.assign(unit.unit_data.actions)

	var abilities: Array[BaseAction] = []
	var system_controls: Array[BaseAction] = []
	for action in all_actions:
		if action.action_id == &"wait" or action.action_id == &"end_turn":
			system_controls.append(action)
		else:
			abilities.append(action)

	for action in abilities:
		_add_ability_slot(action, is_active, unit)
	for action in system_controls:
		_add_ability_slot(action, is_active, unit)

	show()

## Call when the active unit's turn ends to lock the bar.
func set_active(active: bool) -> void:
	_is_active = active
	for child in _ability_row.get_children():
		if child is Button:
			(child as Button).disabled = not active

func clear() -> void:
	_current_unit = null
	_clear_row(_passive_row)
	_clear_row(_ability_row)
	hide()

# --- Private ---

func _add_passive_slot(passive: BasePassive) -> void:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(PASSIVE_SLOT_SIZE, PASSIVE_SLOT_SIZE)
	_passive_row.add_child(slot)

	if passive.icon != null:
		var tex := TextureRect.new()
		tex.texture = passive.icon
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(tex)
	else:
		var abbrev := Label.new()
		abbrev.text = passive.passive_name.left(2).to_upper()
		abbrev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		abbrev.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		abbrev.add_theme_font_size_override("font_size", 10)
		abbrev.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(abbrev)

	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_entered.connect(func() -> void:
		passive_hovered.emit(passive)
	)
	slot.mouse_exited.connect(func() -> void:
		passive_exited.emit()
	)

func _add_ability_slot(action: BaseAction, is_active: bool, unit: Unit) -> void:
	var btn := Button.new()
	btn.text = action.action_name
	btn.custom_minimum_size = Vector2(ABILITY_SLOT_MIN_W, ABILITY_SLOT_H)
	btn.add_theme_font_size_override("font_size", 11)
	btn.disabled = not (is_active and action.can_execute(unit))
	_ability_row.add_child(btn)

	btn.mouse_entered.connect(func() -> void:
		ability_hovered.emit(action)
	)
	btn.mouse_exited.connect(func() -> void:
		ability_exited.emit()
	)
	btn.pressed.connect(func() -> void:
		if _is_active:
			ability_chosen.emit(action)
	)

func _clear_row(row: HBoxContainer) -> void:
	for child in row.get_children():
		child.queue_free()
