class_name BaseProp
extends Resource

@export var prop_id: StringName
@export var priority: int = 0
@export var blocks_movement: bool = false
@export var one_shot: bool = false
@export var active: bool = true
@export var is_visible: bool = true

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
