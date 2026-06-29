class_name PropSystem
extends Node

## Manages placed props (traps, barrels, chests, breakable walls, etc.).
## Owns all prop data; GridSystem holds no prop state.
## Integrates with GridSystem via register_passable_check() — no GridData changes.

signal prop_triggered(prop: BaseProp, unit: Unit, cell: Vector2i)
signal prop_placed(cell: Vector2i, prop: BaseProp)
signal prop_removed(cell: Vector2i)

var _props: Dictionary = {}  # Vector2i -> BaseProp
var _move_interrupt: PropMoveInterruptCondition = PropMoveInterruptCondition.new()
var _grid_system: GridSystem = null

func setup(grid_system: GridSystem) -> void:
	_grid_system = grid_system
	grid_system.register_passable_check(has_blocking_prop)
	grid_system.register_prop_query(has_prop)

# --- Placement ---

func can_place_prop(cell: Vector2i) -> bool:
	return not _props.has(cell)

func place_prop(prop: BaseProp, cell: Vector2i) -> void:
	_props[cell] = prop
	prop_placed.emit(cell, prop)

func remove_prop(cell: Vector2i) -> void:
	_props.erase(cell)
	prop_removed.emit(cell)

func get_prop(cell: Vector2i) -> BaseProp:
	return _props.get(cell)

func has_prop(cell: Vector2i) -> bool:
	return _props.has(cell)

## Used as passable_check callable registered with GridSystem.
func has_blocking_prop(cell: Vector2i) -> bool:
	var prop: BaseProp = _props.get(cell)
	if prop == null:
		return false
	return not prop.passable and prop.active

# --- State mutations ---

func activate_prop(cell: Vector2i) -> void:
	var prop: BaseProp = _props.get(cell)
	if prop:
		prop.active = true

func deactivate_prop(cell: Vector2i) -> void:
	var prop: BaseProp = _props.get(cell)
	if prop:
		prop.active = false

func reveal_prop(cell: Vector2i) -> void:
	var prop: BaseProp = _props.get(cell)
	if prop:
		prop.is_visible = true

# --- Signal handlers ---

func _on_move_execution_started(ctx: MoveExecutionContext) -> void:
	_move_interrupt.reset()
	ctx.register(_move_interrupt)

func _on_unit_stepped(unit: Unit, cell: Vector2i) -> void:
	var prop: BaseProp = _props.get(cell)
	if prop == null or not prop.active:
		return

	if unit.has_capability(&"trap_immunity"):
		return

	# Phase 1 — Decision
	var result: PropInteractionResult = prop.on_unit_enter(unit, cell)

	if result.interrupts:
		# SYNC: set interrupt flag BEFORE any await
		_move_interrupt.notify_triggered(unit)
		# Phase 2 — Execution (command from Phase 1 result)
		if result.command != null:
			var ctx := BaseContext.new()
			ctx.target_unit = unit
			ctx.grid_system = _grid_system
			await result.command.execute_async(ctx)
		prop_triggered.emit(prop, unit, cell)
		if prop.one_shot:
			remove_prop(cell)
		return

	# Phase 2 — Execution (non-interrupt async path)
	prop_triggered.emit(prop, unit, cell)
	await prop.execute_effect_async(unit, cell)

	if prop.one_shot:
		remove_prop(cell)

func _on_unit_turn_started(unit: Unit, is_deferred: bool) -> void:
	if is_deferred:
		return
	var cell: Vector2i = unit.grid_position
	var prop: BaseProp = _props.get(cell)
	if prop == null or not prop.active:
		return
	prop.on_turn_start(unit, cell)

func _on_unit_died(unit: Unit) -> void:
	var cell: Vector2i = unit.grid_position
	var prop: BaseProp = _props.get(cell)
	if prop == null:
		return
	prop.on_unit_exit(unit, cell)
