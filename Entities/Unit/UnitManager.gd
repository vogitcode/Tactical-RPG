## Manages the lifecycle of all Unit entities in the scene.
## Is the parent node of every Unit — units are added as children here.
## Does NOT know about GridSystem; the Compositor (Demo.gd) handles placement coordination.
class_name UnitManager
extends Node

signal unit_spawned(unit: Unit)
signal unit_died(unit: Unit)

var _units: Array[Unit] = []
var _rogues_texture: Texture2D

func _ready() -> void:
	_rogues_texture = load("res://Assets/Character and Tile/32rogues/rogues.png")

## Spawns a unit from a UnitData resource, adds it as a child, and returns it.
## Caller is responsible for calling grid_system.place_unit(unit, pos) afterwards.
func spawn_unit(data: UnitData, team: int) -> Unit:
	var unit := Unit.new()
	unit.unit_data = data
	unit.unit_name = data.unit_name
	unit.team = team
	unit.max_hp = data.max_hp
	unit.max_action_points = data.max_action_points
	unit.move_points = data.move_points
	unit.attack_range = data.attack_range
	unit.attack_damage = data.attack_damage
	add_child(unit)

	if _rogues_texture:
		unit.set_sprite_atlas(
			_rogues_texture,
			Rect2(data.atlas_cell.x * 32, data.atlas_cell.y * 32, 32, 32)
		)

	unit.unit_died.connect(_on_unit_died.bind(unit))
	_units.append(unit)
	unit_spawned.emit(unit)
	return unit

func get_all_units() -> Array[Unit]:
	return _units.duplicate()

func get_living_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for u in _units:
		if u.is_alive():
			result.append(u)
	return result

func get_units_of_team(team: int) -> Array[Unit]:
	var result: Array[Unit] = []
	for u in _units:
		if u.team == team and u.is_alive():
			result.append(u)
	return result

func _on_unit_died(unit: Unit) -> void:
	unit_died.emit(unit)
