class_name TrapProp
extends BaseProp

@export var damage: int = 5

func _init() -> void:
	prop_id = &"trap"
	blocks_movement = false
	one_shot = true
	is_visible = false

func on_unit_enter(unit: Node, _cell: Vector2i) -> PropInteractionResult:
	if not active:
		return PropInteractionResult.none()
	var u := unit as Unit
	if u:
		u.take_damage(damage)
	return PropInteractionResult.interrupt()
