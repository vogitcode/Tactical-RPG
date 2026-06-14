## Standalone testbed for the Blackboard + Compound Effect system.
## Creates one unit and provides manual triggers to observe behavior in real time.
## Open TraitDemo.tscn to run this scene.
extends Node

var _demo_unit: Unit
var _berserker_trait: BerserkerTrait
var _blood_frenzy: BloodFrenzyPassive
var _output_label: Label

func _ready() -> void:
	_berserker_trait = BerserkerTrait.new()
	_blood_frenzy = BloodFrenzyPassive.new()
	_create_unit()
	_create_ui()
	_refresh()

func _create_unit() -> void:
	_demo_unit = Unit.new()
	_demo_unit.unit_name = "Berserker"
	_demo_unit.max_hp = 50
	_demo_unit.move_points = 3
	_demo_unit.attack_damage = 8
	add_child(_demo_unit)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.custom_minimum_size = Vector2(320, 0)
	canvas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	margin.add_child(inner)

	_output_label = Label.new()
	_output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_output_label.custom_minimum_size = Vector2(0, 220)
	inner.add_child(_output_label)

	var sep := HSeparator.new()
	inner.add_child(sep)

	_add_button(inner, "Add BerserkerTrait", _on_add_berserker)
	_add_button(inner, "Add BloodFrenzyPassive  [Compound]", _on_add_frenzy)
	_add_button(inner, "Remove BerserkerTrait", _on_remove_berserker)
	_add_button(inner, "Remove BloodFrenzyPassive", _on_remove_frenzy)

	var sep2 := HSeparator.new()
	inner.add_child(sep2)

	_add_button(inner, "Take Damage  (5)", _on_take_damage)
	_add_button(inner, "Heal  (10)", _on_heal)

func _add_button(parent: VBoxContainer, label: String, callable: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(callable)
	parent.add_child(btn)

# --- Button handlers ---

func _on_add_berserker() -> void:
	if not _demo_unit.get_runtime_passives().has(_berserker_trait):
		_demo_unit.add_passive(_berserker_trait)
	_refresh()

func _on_add_frenzy() -> void:
	if not _demo_unit.get_runtime_passives().has(_blood_frenzy):
		_demo_unit.add_passive(_blood_frenzy)
	_refresh()

func _on_remove_berserker() -> void:
	_demo_unit.remove_passive(_berserker_trait)
	_refresh()

func _on_remove_frenzy() -> void:
	_demo_unit.remove_passive(_blood_frenzy)
	_refresh()

func _on_take_damage() -> void:
	_demo_unit.take_damage(5)
	_refresh()

func _on_heal() -> void:
	_demo_unit.heal(10)
	_refresh()

# --- Display ---

func _refresh() -> void:
	var lines: PackedStringArray = []
	lines.append("=== %s ===" % _demo_unit.unit_name)
	lines.append("HP: %d / %d" % [_demo_unit.current_hp, _demo_unit.max_hp])
	lines.append("Move (base):      %d" % _demo_unit.move_points)
	lines.append("Move (effective): %d" % _demo_unit.get_effective_move_points())
	lines.append("")
	lines.append("--- Passives ---")
	var passives := _demo_unit.get_runtime_passives()
	if passives.is_empty():
		lines.append("  (none)")
	else:
		for p: BasePassive in passives:
			lines.append("  • %s" % p.passive_name)
	lines.append("")
	lines.append("--- Capabilities (Blackboard) ---")
	if _demo_unit._capabilities.is_empty():
		lines.append("  (none)")
	else:
		for key in _demo_unit._capabilities:
			lines.append("  %s = %s" % [str(key), str(_demo_unit._capabilities[key])])
	_output_label.text = "\n".join(lines)
