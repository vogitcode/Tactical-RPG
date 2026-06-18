## Abstract base class for all tile types.
## Defines the interface for tile behavior and visual data.
## Extend this to create new tile types with custom logic.
class_name BaseTile
extends Resource

## Visual — atlas position in the TileSet spritesheet.
## source_id 0 = tiles.png, source_id 1 = animated-tiles.png.
## Set atlas_coords to Vector2i(-1, -1) to skip rendering (invisible tile).
@export var base_color: Color = Color(0.32, 0.45, 0.25)  # fallback when no atlas tile set
@export var atlas_source_id: int = 0
@export var atlas_coords: Vector2i = Vector2i(-1, -1)

## Gameplay defaults — override in subclasses via _init or @export in Inspector.
@export var movement_cost: int = 1
@export var hazard_cost: int = 0   # A* routing penalty — does not affect actual MP deduction
@export var blocks_movement: bool = false
@export var blocks_los: bool = false

# --- Virtual interface ---
# Unit params are typed as Node (not Unit) to keep the Core layer free of
# Entity dependencies — the same convention as CellData.occupant: Node.
# Facade layer (GridSystem) casts to Unit when needed.

func can_enter(_unit: Node) -> bool:
	return not blocks_movement

func get_movement_cost(_unit: Node) -> int:
	return movement_cost

## A* pathfinding weight. Inflated for hazard tiles so pathfinder prefers safe routes.
## Does NOT affect actual MP cost — only routing preference.
func get_pathfinding_cost(_unit: Node) -> int:
	return movement_cost + hazard_cost

func on_unit_enter(_unit: Node, _grid_pos: Vector2i) -> void:
	pass

func on_unit_exit(_unit: Node, _grid_pos: Vector2i) -> void:
	pass

func on_turn_start(_unit: Node, _grid_pos: Vector2i) -> void:
	pass
