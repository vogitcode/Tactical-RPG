class_name BaseProp
extends Resource

@export var prop_id: StringName
@export var priority: int = 0
@export var passable: bool = true
@export var one_shot: bool = false
@export var active: bool = true
@export var is_visible: bool = true
## Visual — atlas position in PropVisualizer's TileSet (source 0 = Prop 32x32.png).
## Set to Vector2i(-1, -1) to skip rendering.
@export var atlas_source_id: int = 0
@export var atlas_coords: Vector2i = Vector2i(-1, -1)

## SYNC — returns interrupt decision. Called before any await.
func on_unit_enter(_unit: Node, _cell: Vector2i) -> PropInteractionResult:
	return PropInteractionResult.none()

## ASYNC — visual/effect phase. Only called if on_unit_enter returned no interrupt.
func execute_effect_async(_unit: Node, _cell: Vector2i) -> void:
	pass

func on_unit_exit(_unit: Node, _cell: Vector2i) -> void:
	pass

func on_turn_start(_unit: Node, _cell: Vector2i) -> void:
	pass

func on_interact(_unit: Node, _cell: Vector2i) -> void:
	pass

func on_damaged(_amount: int, _source: Node) -> void:
	pass

func on_destroyed(_cell: Vector2i) -> void:
	pass
