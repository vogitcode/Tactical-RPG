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
@export var passable: bool = true
@export var blocks_los: bool = false
## If non-empty, unit must have this capability to traverse. Checked by Unit.can_traverse().
@export var required_capability: StringName = &""

## Optimization flags — TileProcessor skips hook calls when false.
## Subclasses set these to true in their class body to opt in.
var reacts_to_unit_enter: bool = false
var reacts_to_turn_start: bool = false
var reacts_to_round_start: bool = false
var reacts_to_external_effect: bool = false

# --- Virtual interface ---
# Unit params are typed as Node (not Unit) to keep the Core layer free of
# Entity dependencies — GridData._units stores Node, GridSystem casts to Unit.
# Facade layer (GridSystem) casts to Unit when needed.

func can_enter(_unit: Node) -> bool:
	return passable

func get_movement_cost(_unit: Node) -> int:
	return movement_cost

## A* pathfinding weight. Inflated for hazard tiles so pathfinder prefers safe routes.
## Does NOT affect actual MP cost — only routing preference.
func get_pathfinding_cost(_unit: Node) -> int:
	return movement_cost + hazard_cost

func on_unit_enter(_ctx: TileContexts.TileEnterContext) -> Array[TileRequest]:
	return []

func on_turn_start(_ctx: TileContexts.TileTurnContext) -> Array[TileRequest]:
	return []

func on_round_start(_ctx: TileContexts.TileRoundContext) -> Array[TileRequest]:
	return []

func on_external_effect(_type: StringName, _ctx: TileContexts.TileEffectContext) -> Array[TileRequest]:
	return []
