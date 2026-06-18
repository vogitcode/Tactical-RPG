class_name DashAttack
extends CombatAction

@export var min_range: int = 1
@export var max_range: int = 3

func _init() -> void:
	super()
	action_id = &"dash_attack"
	action_name = "Dash Attack"
	action_description = "Dash to the target and strike."
	ap_cost = 1
	base_rp = 10
	_sets_has_acted = true
	pre_effects.assign([DashMoveEffect.new()])
	on_hit_effects.assign([DelayEffect.new(0.1), DamageEffect.new()])

func can_execute(unit: Unit) -> bool:
	if not super(unit):
		return false
	return not unit.has_acted

func on_selected(unit: Unit, grid_system: GridSystem) -> void:
	var effective_max := unit.get_effective_attack_range(max_range)
	unit.show_active_hook_icons(HookId.GET_ATTACK_RANGE)
	var cells: Array[Vector2i] = grid_system.get_attack_range_cells(unit.grid_position, min_range, effective_max)
	grid_system.show_attack_range(cells)
	grid_system.highlight_selected(unit.grid_position)

func on_deselected(_unit: Unit, grid_system: GridSystem) -> void:
	grid_system.clear_highlights()
