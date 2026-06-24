class_name TrapProp
extends BaseProp

@export var trap_damage: int = 3

func _init() -> void:
	prop_id = &"trap"
	passable = true
	one_shot = true
	active = true
	atlas_source_id = 0
	atlas_coords = Vector2i(0, 0)

func on_unit_enter(unit: Node, _cell: Vector2i) -> PropInteractionResult:
	var u := unit as Unit
	if u == null:
		return PropInteractionResult.none()
	u.take_damage(trap_damage)
	return PropInteractionResult.interrupt()
