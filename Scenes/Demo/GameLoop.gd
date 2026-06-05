## Root node — manages the full game lifecycle from launch to exit.
## Owns the game loop (_process / _physics_process) and orchestrates
## initialization phases so systems start in the correct order.
##
## Responsibilities:
##   1. Trigger SystemManager.initialize() (internal system setup + wiring)
##   2. Wire cross-boundary connections (SystemManager systems ↔ UI nodes outside it)
##   3. Kick off the battle via SystemManager.start_battle()
##
## SystemManager does NOT know about UI layers — GameLoop bridges the two.
class_name GameLoop
extends Node

@onready var system_manager: SystemManager            = $SystemManager
@onready var _health_ui_manager: HealthUIManager      = $WorldUIManager/HealthUIManager
@onready var _action_menu: ActionMenu                 = $UI/ScreenUIManager/ActionMenu
@onready var _status_label: Label                     = $UI/StatusLabel

func _ready() -> void:
	system_manager.initialize()
	_wire_cross_boundary()
	system_manager.start_battle()

func _process(_delta: float) -> void:
	pass  # Future: per-frame game logic (pause, scene transitions, global timers)

func _physics_process(_delta: float) -> void:
	pass  # Future: physics-driven game state updates

# --- Cross-boundary wiring ---
# Connects systems inside SystemManager with UI nodes that live outside it.

func _wire_cross_boundary() -> void:
	_health_ui_manager.setup(system_manager.unit_manager)

	system_manager.action_system.show_menu_requested.connect(_action_menu.show_for_unit)
	_action_menu.action_chosen.connect(system_manager.action_system.on_action_chosen)
	_action_menu.menu_closed.connect(system_manager.action_system.on_menu_closed)

	system_manager.turn_system.turn_started.connect(_on_turn_started)
	system_manager.turn_system.unit_turn_started.connect(_on_unit_turn_started)
	system_manager.turn_system.battle_ended.connect(_on_battle_ended)
	system_manager.action_system.action_execution_finished.connect(_on_action_finished)

# --- Display callbacks ---

func _on_turn_started(turn_number: int) -> void:
	_status_label.text = "— Round %d —" % turn_number

func _on_unit_turn_started(unit: Unit) -> void:
	var team_str := "Player" if unit.team == 0 else "Enemy"
	_status_label.text = "Round %d  |  %s: %s  HP:%d/%d  AP:%d" % [
		system_manager.turn_system.current_turn, team_str, unit.unit_name,
		unit.current_hp, unit.max_hp, unit.action_points
	]

func _on_battle_ended(result: StringName) -> void:
	var msg: String
	match result:
		&"win":  msg = "Victory! All enemies defeated."
		&"lose": msg = "Defeat! All player units lost."
		&"draw": msg = "Draw!"
		_:       msg = "Battle ended."
	_status_label.text = msg

func _on_action_finished(_action: BaseAction, _unit: Unit, result: ActionResult) -> void:
	if result.is_interrupted():
		_status_label.text += "  [INTERRUPTED: %s]" % result.reason
