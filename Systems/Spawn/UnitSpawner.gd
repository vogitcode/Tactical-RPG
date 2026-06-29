## Factory node — creates Unit instances from UnitData.
## Does NOT manage unit lifecycle. Call unit_manager.adopt(unit) after creation.
## Owns texture loading and data-to-Unit mapping.
class_name UnitSpawner
extends Node

var _rogues_texture: Texture2D

func _ready() -> void:
	_rogues_texture = load("res://Assets/Character and Tile/32rogues/rogues.png")

## Creates a Unit from UnitData (data phase only — no node references).
## Caller must: adopt(unit) → configure_visuals(unit, data) → place_unit(unit, cell).
func create_unit(data: UnitData, team: int) -> Unit:
	return _build_unit(data, team)

## Creates a clone with CloneExpiryPassive pre-attached.
## Caller must: adopt_clone(clone) → configure_visuals(clone, data) → place_unit(clone, cell).
func create_clone(data: UnitData, team: int, max_alive_turns: int) -> Unit:
	var clone := _build_unit(data, team)
	var expiry := CloneExpiryPassive.new()
	expiry.max_alive_turns = max_alive_turns
	clone.add_passive(expiry)
	clone.set_capability(&"clone_expiry", expiry)
	return clone

## Call AFTER unit is in scene tree (after adopt). Sets sprite texture via node reference.
func configure_visuals(unit: Unit, data: UnitData) -> void:
	if _rogues_texture:
		unit.set_sprite_atlas(
			_rogues_texture,
			Rect2(data.atlas_cell.x * 32, data.atlas_cell.y * 32, 32, 32)
		)

func _build_unit(data: UnitData, team: int) -> Unit:
	var unit := Unit.new()
	unit.unit_data = data
	unit.unit_name = data.unit_name
	unit.team = team
	unit.max_hp = data.max_hp
	unit.max_action_points = data.max_action_points
	unit.move_points = data.move_points
	unit.attack_range = data.attack_range
	unit.attack_damage = data.attack_damage
	for cap in data.initial_capabilities:
		unit.set_capability(cap, true)
	return unit
