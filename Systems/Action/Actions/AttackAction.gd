class_name AttackAction
extends CombatAction

@export var min_range: int = 1
@export var max_range: int = 1

func _init() -> void:
	super()
	action_id = &"attack"
	action_name = "Attack"
	action_description = "Attack an enemy within range."
	ap_cost = 1
	needs_target = true
	base_rp = 10
	_sets_has_acted = true
	on_hit_effects.assign([DelayEffect.new(0.2), DamageEffect.new()])

func can_execute(unit: Unit) -> bool:
	if not super(unit):
		return false
	return not unit.has_acted

func on_selected(unit: Unit, grid_system: GridSystem) -> void:
	var effective_max := unit.get_effective_attack_range(max_range)
	unit.show_active_hook_icons(&"get_attack_range")
	var cells: Array[Vector2i] = grid_system.get_attack_range_cells(unit.grid_position, min_range, effective_max)
	grid_system.show_attack_range(cells)
	grid_system.highlight_selected(unit.grid_position)

func on_deselected(_unit: Unit, grid_system: GridSystem) -> void:
	grid_system.clear_highlights()
