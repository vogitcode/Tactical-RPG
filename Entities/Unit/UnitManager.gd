## Manages the lifecycle of all Unit entities in the scene.
## Is the parent node of every Unit — units are added as children here.
## Does NOT know about GridSystem; the Compositor (Demo.gd) handles placement coordination.
class_name UnitManager
extends Node

signal unit_spawned(unit: Unit)
signal unit_died(unit: Unit)
signal clone_spawned(unit: Unit)
signal clone_expired(unit: Unit)

var _units: Array[Unit] = []
var _rogues_texture: Texture2D

func _ready() -> void:
	_rogues_texture = load("res://Assets/Character and Tile/32rogues/rogues.png")

## Spawns a unit from a UnitData resource, adds it as a child, and returns it.
## Caller is responsible for calling grid_system.place_unit(unit, pos) afterwards.
func spawn_unit(data: UnitData, team: int) -> Unit:
	var unit := _create_unit(data, team)
	_units.append(unit)
	unit_spawned.emit(unit)
	return unit

## Spawns a clone with a CloneExpiryPassive pre-attached.
## Emits unit_spawned (HealthUI) then clone_spawned (expiry wiring).
func spawn_clone(data: UnitData, team: int, max_alive_turns: int) -> Unit:
	var clone := _create_unit(data, team)
	var expiry := CloneExpiryPassive.new()
	expiry.max_alive_turns = max_alive_turns
	clone.add_passive(expiry)
	clone.set_capability(&"clone_expiry", expiry)
	_units.append(clone)
	unit_spawned.emit(clone)   # HealthUI registers clone like any unit
	clone_spawned.emit(clone)  # compositor wires expiry.expired → cleanup
	return clone

## Called by SystemManager._on_clone_expired after grid + turn cleanup.
func on_clone_expired(unit: Unit) -> void:
	_units.erase(unit)
	clone_expired.emit(unit)
	unit.queue_free()

func _create_unit(data: UnitData, team: int) -> Unit:
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
