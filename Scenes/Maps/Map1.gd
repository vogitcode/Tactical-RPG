## Map 1 compositor — lifecycle + cross-boundary wiring for the tutorial map.
## AbilityBar replaces ActionMenu as the primary ability selection UI.
## UnitStatsPanel + TurnOrderPanel + DescriptionTooltip round out the tutorial HUD.
class_name Map1
extends Node

@onready var system_manager: SystemManager         = $SystemManager
@onready var _health_ui_manager: HealthUIManager   = $WorldUIManager/HealthUIManager
@onready var _status_label: Label                  = $UI/StatusLabel
@onready var _stats_panel: UnitStatsPanel          = $UI/UnitStatsPanel
@onready var _ability_bar: AbilityBar              = $UI/AbilityBar
@onready var _turn_order_panel: TurnOrderPanel     = $UI/TurnOrderPanel
@onready var _tooltip: DescriptionTooltip          = $UI/DescriptionTooltip

func _ready() -> void:
	system_manager.initialize()
	_wire_cross_boundary()
	system_manager.load_map_data(Battle1aLayout.build())
	system_manager.start_battle()

# --- Cross-boundary wiring ---

func _wire_cross_boundary() -> void:
	system_manager.unit_manager.unit_spawned.connect(_health_ui_manager.register_unit)
	system_manager.unit_manager.clone_expired.connect(_health_ui_manager.unregister_unit)

	# Ability bar replaces ActionMenu — wire show_menu_requested to update HUD instead
	system_manager.action_system.show_menu_requested.connect(_on_active_unit_ready)

	# Ability bar → ActionSystem (PISM is in MENU_OPEN when this fires)
	_ability_bar.ability_chosen.connect(system_manager.action_system.on_action_chosen)

	# Inspect any unit by clicking its tile
	system_manager.input_system.tile_clicked.connect(_on_tile_clicked_for_hud)

	# Tooltip on hover
	_ability_bar.ability_hovered.connect(_on_ability_hovered)
	_ability_bar.ability_exited.connect(_tooltip.hide_tooltip)
	_ability_bar.passive_hovered.connect(_on_passive_hovered)
	_ability_bar.passive_exited.connect(_tooltip.hide_tooltip)

	# Turn order panel — refresh after each unit's turn starts
	system_manager.turn_system.unit_turn_started.connect(_on_unit_turn_started_for_hud)

	# Lock ability bar when active unit finishes their turn
	system_manager.action_system.unit_turn_finished.connect(_on_unit_turn_finished_for_hud)

	# Battle end — hide HUD
	system_manager.turn_system.battle_ended.connect(_on_battle_ended_hud)

	# Status label
	system_manager.turn_system.turn_started.connect(_on_turn_started)
	system_manager.turn_system.unit_turn_started.connect(_on_unit_turn_started)
	system_manager.turn_system.battle_ended.connect(_on_battle_ended)
	system_manager.action_system.action_execution_finished.connect(_on_action_finished)

# --- HUD callbacks ---

func _on_active_unit_ready(unit: Unit, _pos: Vector2) -> void:
	# Called when a player unit enters MENU_OPEN — show their abilities as active
	_stats_panel.show_unit(unit)
	_ability_bar.show_for_unit(unit, unit.team == 0)

func _on_tile_clicked_for_hud(grid_pos: Vector2i) -> void:
	var occupant: Unit = system_manager.grid_system.get_occupant(grid_pos)
	if occupant == null or not occupant.is_alive():
		return
	var is_active: bool = (
		occupant == system_manager.turn_system.current_unit
		and occupant.team == 0
		and system_manager.turn_system.is_unit_acting()
	)
	_stats_panel.show_unit(occupant)
	_ability_bar.show_for_unit(occupant, is_active)

func _on_ability_hovered(action: BaseAction) -> void:
	var text := action.action_name
	if action.action_description != "":
		text += "\n\n" + action.action_description
	_tooltip.show_description(text)

func _on_passive_hovered(passive: BasePassive) -> void:
	var text := passive.passive_name
	if passive.description != "":
		text += "\n\n" + passive.description
	_tooltip.show_description(text)

func _on_unit_turn_started_for_hud(_unit: Unit, _is_deferred: bool) -> void:
	_turn_order_panel.update_order(system_manager.unit_manager.get_living_units())

func _on_unit_turn_finished_for_hud(_unit: Unit) -> void:
	_ability_bar.set_active(false)

func _on_battle_ended_hud(_result: StringName) -> void:
	_ability_bar.clear()
	_stats_panel.clear()
	_turn_order_panel.update_order([])

# --- Status label callbacks ---

func _on_turn_started(turn_number: int) -> void:
	_status_label.text = "— Round %d —" % turn_number

func _on_unit_turn_started(unit: Unit, _is_deferred: bool) -> void:
	var team_str := "Player" if unit.team == 0 else "Enemy"
	_status_label.text = "Round %d  |  %s: %s  HP:%d/%d  AP:%d" % [
		system_manager.turn_system.current_turn, team_str, unit.unit_name,
		unit.current_hp, unit.max_hp, unit.action_points
	]

func _on_battle_ended(result: StringName) -> void:
	match result:
		&"win":  _status_label.text = "Victory! All enemies defeated."
		&"lose": _status_label.text = "Defeat! All player units lost."
		&"draw": _status_label.text = "Draw!"
		_:       _status_label.text = "Battle ended."

func _on_action_finished(_action: BaseAction, _unit: Unit, result: ActionResult) -> void:
	if result.is_interrupted():
		_status_label.text += "  [INTERRUPTED: %s]" % result.reason
