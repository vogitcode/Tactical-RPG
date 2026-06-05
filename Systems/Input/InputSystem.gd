## Single entry point for all player input.
## Converts raw Godot events into game-meaningful signals.
## Uses _unhandled_input() so GUI (ActionMenu buttons, etc.) always takes priority.
class_name InputSystem
extends Node

signal tile_clicked(grid_pos: Vector2i)
signal tile_hovered(grid_pos: Vector2i)   # emits Vector2i(-1,-1) when mouse off-grid
signal action_hotkey_pressed(action_id: StringName)
signal cancel_requested()

const ACTION_HOTKEYS: Dictionary = {
	KEY_1: &"move",
	KEY_2: &"attack",
	KEY_3: &"guard",
	KEY_4: &"wait",
	KEY_5: &"end_turn",
}

var _grid_system: GridSystem = null

func setup(grid_system: GridSystem) -> void:
	_grid_system = grid_system

func _unhandled_input(event: InputEvent) -> void:
	if _grid_system == null:
		return

	if event is InputEventMouseMotion:
		var grid_pos := _grid_system.world_to_grid(event.position)
		var valid_pos := grid_pos if _grid_system.is_valid(grid_pos) else Vector2i(-1, -1)
		tile_hovered.emit(valid_pos)

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos := _grid_system.world_to_grid(event.position)
		if _grid_system.is_valid(grid_pos):
			tile_clicked.emit(grid_pos)
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_requested.emit()
		get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in ACTION_HOTKEYS:
			action_hotkey_pressed.emit(ACTION_HOTKEYS[event.keycode])
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			cancel_requested.emit()
			get_viewport().set_input_as_handled()
