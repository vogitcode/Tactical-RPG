## Tutorial battle 1a — "First Contact".
## Two player units vs two enemies, open field with wall cover.
## Purpose: teach movement, attack, basic positioning.
## Props: one pressure trap at (5,3) to test TrapAbortCheck.
class_name Battle1aLayout
extends RefCounted

static func build() -> MapData:
	var data := MapData.new()
	_add_tiles(data)
	_add_units(data)
	_add_props(data)
	return data

static func _add_tiles(data: MapData) -> void:
	# Left wall pillar — cover near player spawn
	for pos: Vector2i in [Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3),
			Vector2i(3, 7), Vector2i(3, 8)]:
		data.tiles[pos] = WallTile.new()

	# Right wall pillar — cover near enemy spawn
	for pos: Vector2i in [Vector2i(8, 2), Vector2i(8, 3),
			Vector2i(8, 6), Vector2i(8, 7)]:
		data.tiles[pos] = WallTile.new()

	# Center grass patches — visual variety, same movement cost as floor
	for pos: Vector2i in [Vector2i(5, 4), Vector2i(6, 4),
			Vector2i(5, 5), Vector2i(6, 5)]:
		data.tiles[pos] = GrassTile.new()

static func _add_props(data: MapData) -> void:
	# Pressure trap on the center path — unit walking through takes 3 damage + move interrupted
	data.prop_placements.append({
		"prop": TrapProp.new(),
		"cell": Vector2i(5, 3),
		"highlight": true,
	})

static func _add_units(data: MapData) -> void:
	data.unit_placements.append({
		"unit_data": preload("res://Data/Units/KnightData.tres"),
		"cell": Vector2i(1, 3),
		"team": 0,
	})
	data.unit_placements.append({
		"unit_data": preload("res://Data/Units/RogueData.tres"),
		"cell": Vector2i(1, 6),
		"team": 0,
	})
	data.unit_placements.append({
		"unit_data": preload("res://Data/Units/BanditData.tres"),
		"cell": Vector2i(10, 3),
		"team": 1,
	})
	data.unit_placements.append({
		"unit_data": preload("res://Data/Units/BanditData.tres"),
		"cell": Vector2i(10, 6),
		"team": 1,
	})
