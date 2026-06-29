## Holder for all Unit entities — is the parent node of every Unit.
## Does NOT create units. UnitSpawner creates; UnitManager adopts and tracks.
class_name UnitManager
extends Node

signal unit_spawned(unit: Unit)
signal unit_died(unit: Unit)
signal clone_spawned(unit: Unit)
signal clone_expired(unit: Unit)

var _units: Array[Unit] = []

## Adopts a unit created by UnitSpawner — adds as child, tracks, connects lifecycle, emits unit_spawned.
func adopt(unit: Unit) -> void:
	add_child(unit)
	_units.append(unit)
	unit.unit_died.connect(_on_unit_died.bind(unit))
	unit_spawned.emit(unit)

## Adopts a clone — same as adopt() but also emits clone_spawned for expiry wiring.
func adopt_clone(clone: Unit) -> void:
	adopt(clone)
	clone_spawned.emit(clone)

## Called by SystemManager._on_clone_expired after grid + turn cleanup.
func on_clone_expired(unit: Unit) -> void:
	_units.erase(unit)
	clone_expired.emit(unit)
	unit.queue_free()

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
